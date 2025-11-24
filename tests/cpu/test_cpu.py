from contextlib import asynccontextmanager
import logging
import os

import cocotb
from cocotb.triggers import RisingEdge, Timer
from cocotb.types import Logic


logger = logging.getLogger("test_cpu")
logger.setLevel(logging.DEBUG)

def load(filename):
    data_initial = [0] * 8192
    with open(filename, 'rb') as f:
        buf = f.read()
        vals = [int.from_bytes(buf[i:i + 2], 'little')
                for i in range(0, len(buf), 2)]
        code_size, data_size, *mem = vals
        code, data = mem[:code_size], mem[code_size:]
    for i, e in enumerate(data):
        data_initial[i] = e
    return code, data_initial

factorial_program, factorial_data = load("./factorial.bin")

game_program, game_data = load("./logo.bin")

CMDS = [(
    lambda xs: (xs[0], int(xs[1]))
 ) (string.split(" = ")) for string in """ADD = 0
SUB = 1
MUL = 2
AND = 3
OR = 4
XOR = 5
SHL = 6
SHR = 7
SHRA = 8
EQ = 9
NEQ = 10
LT = 11
LE = 12
GT = 13
GE = 14
LTU = 15
LOAD = 16
STORE = 17
LOCALS = 18
SET_FP = 19
RET = 20
PUSH_INT = 21
PUSH_MR = 22
WAIT = 23""".split("\n")]

CMDS = {opcode: literal for literal, opcode in CMDS}


def decode_imm(val, width):
    if (val & (1 << (width - 1))) != 0:
        val = val - (1 << width)
    return val


def decode_instr(instr):
    format = (instr >> 15) & 0b1
    if not format:
        opcode = (instr >> 10) & 0b11111
        mnemo = CMDS.get(opcode, str(opcode))
        mode = (instr >> 9) & 0b1
        immediate = decode_imm(instr & 0b111111111, 9)
    else:
        opcode = (instr >> 13) & 0b11
        mnemo = {0: "JMP", 1: "JZ", 2: "CALL", 3: "PUSH_ADDR"}.get(opcode)
        mode = 1
        immediate = instr & 0b1111111111111
    return mnemo, mode, immediate


def setup_program(dut, program, data):
    for i, instr in enumerate(program):
        dut.program_memory.data[i].value = instr
    
    for i, data in enumerate(data):
        dut.memory.data[i].value = data


async def generate_clock(dut):
    dut.resume.value = 0
    dut.reset.value = 1
    for _ in range(3):
        dut.clk.value = 0
        await Timer(1, unit='ns')
        dut.clk.value = 1
        await Timer(1, unit='ns')
        log_debug(dut)
    dut.reset.value = 0

    for _ in range(100000):
        log_debug(dut)
        dut.clk.value = 0
        await Timer(1, unit='ns')
        dut.clk.value = 1
        await Timer(1, unit='ns')


def signed(logic_array, placeholder=-99999999):
    if logic_array.is_resolvable:
        return logic_array.to_signed()
    else:
        return placeholder


def unsigned(logic_array, placeholder=-99999999):
    if isinstance(logic_array, Logic):
        if logic_array.is_resolvable:
            return int(logic_array)
        return 0
    if logic_array.is_resolvable:
        return logic_array.to_unsigned()
    else:
        return placeholder


def decode_stack(dut, size=8):
    stack = []
    for i in range(size):
        val = signed(dut.cpu.stack.data[i].value)
        stack.append(val)
    s0 = signed(dut.cpu.stack_top.value)
    s1 = signed(dut.cpu.stack_pre_top.value)
    return stack, s0, s1


def decode_rstack(dut, size=8):
    rstack = []
    for i in range(size):
        pc = signed(dut.cpu.rstack.data[i].value)
        rstack.append(pc)

    rs0 = unsigned(dut.cpu.rstack_top.value)
    return rstack, rs0


def decode_mem(dut, start=0, end=8):
    mem = []
    for i in range(start, end):
        val = unsigned(dut.memory.data[i].value)
        mem.append(val)
    return mem


def log_debug(dut):
    instr = unsigned(dut.cpu.instr.value)
    mnemo, mode, simm = decode_instr(instr)
    stack, s0, s1 = decode_stack(dut)
    rstack, rs0 = decode_rstack(dut)
    mem = decode_mem(dut, start=7802, end=7802+70)
    reset = int(dut.reset.value)
    resume = int(dut.resume.value)

    string = "reset={reset} resume={resume} pc={pc:<6d} pc_new={pc_new:<6d} " \
    "fp={fp:<6d} " \
    "instr={instr:<8} mode={mode:1d} simm={simm:<13d} " \
    "stack={stack} sp={sp:4d} sp_new={sp_new} s0={s0:4d} s1={s1:4d} s0_new={s0_new} we_stack={we_stack:1d} " \
    "rsp={rsp} rstack={rstack} rs0={rs0} we_rstack={we_rstack:1d} " \
    "mem={mem} mem_dout={mem_dout}, mem_dout_we={mem_dout_we} " \
    "mem_din={mem_din} mem_din_addr={mem_din_addr}".format(
        reset=reset,
        resume=resume,
        pc=unsigned(dut.cpu.pc.value),
        pc_new=unsigned(dut.cpu.pc_new.value),
        fp=unsigned(dut.cpu.fp.value),
        instr=mnemo,
        mode=mode,
        simm=simm,
        stack=stack,
        sp=unsigned(dut.cpu.sp.value),
        sp_new=unsigned(dut.cpu.sp_new.value),
        s0=s0,
        s1=s1,
        s0_new=signed(dut.cpu.stack_top_new.value),
        we_stack=int(dut.cpu.write_to_stack.value),
        rsp=unsigned(dut.cpu.rsp.value),
        rstack=rstack,
        rs0=rs0,
        mem=mem,
        we_rstack=int(dut.cpu.write_to_rstack.value),
        mem_dout=unsigned(dut.cpu.mem_dout.value),
        mem_dout_we=unsigned(dut.cpu.mem_dout_we.value),
        mem_din=unsigned(dut.cpu.mem_din.value),
        mem_din_addr=unsigned(dut.cpu.mem_din_addr.value)
    )
    logger.debug(string)


def dump_mem(dut, sys=False, i=0):
    if sys:
        mem = decode_mem(dut, start=7802, end=8192)
    else:
        mem = decode_mem(dut, start=0, end=8192)
    os.makedirs("./memory_actual", exist_ok=True)
    with open(f"memory_actual/memory_{i}.txt", 'w') as file:
        file.write("\n".join([str(val) for val in mem]) + "\n")

@asynccontextmanager
async def setup(dut, log_filename, program, data, logs_folder="./logs/"):
    os.makedirs(logs_folder, exist_ok=True)
    fh = logging.FileHandler(logs_folder + log_filename)
    fh.setLevel(logging.DEBUG)
    logger.addHandler(fh)
    setup_program(dut, program, data)
    task = cocotb.start_soon(generate_clock(dut))
    await Timer(6, 'ns')
    dut.resume.value = 1
    await RisingEdge(dut.clk)
    dut.resume.value = 0
    try:
        yield
    finally:
        logger.removeHandler(fh)
        task.cancel()


@cocotb.test(skip=False)
async def test_factorial(dut):
    program = factorial_program
    async with setup(dut, "factorial.log", program, factorial_data):
        await Timer(2 * 100 * 2, unit='ns')
        await RisingEdge(dut.clk)

        fact = dut.memory.data[0].value.to_signed()
        # s0 = dut.cpu.stack_top.value.to_signed()
        assert fact == 5040

@cocotb.test(skip=False)
async def test_game(dut):
    program = game_program
    async with setup(dut, "game.log", program, game_data):
        await Timer(2 * 7000, unit='ns')
        await RisingEdge(dut.clk)
        
        for i in range(10):
            if i != 0:
                dut.resume.value = 1
                await RisingEdge(dut.clk)
                dut.resume.value = 0
            await Timer(2 * 1500, unit='ns')
            dump_mem(dut, sys=False, i=i)

            with open(f"./memory_reference/memory_at_{i}.txt", "r") as file:
                ref_mem = [int(val) for val in file.read().split()]
            
            with open(f"./memory_actual/memory_{i}.txt", "r") as file:
                actual_mem = [int(val) for val in file.read().split()]
            
            for j, (a, b) in enumerate(zip(ref_mem, actual_mem)):
                assert a == b, f"(frame={i}) (row={j}) ref mem differ from actual mem ({a} != {b})"
            assert len(ref_mem) == len(actual_mem), "mem length mismatch"
