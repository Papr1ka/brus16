from contextlib import asynccontextmanager
import logging

import cocotb
from cocotb.triggers import RisingEdge, Timer


logger = logging.getLogger("test_cpu")
logger.setLevel(logging.DEBUG)


factorial = [533, 179, 48, 111, 65517, 65516, 170, 241, 85, 52, 65516, 65516, 97, 64947, 2, 52, 0]
stack_test = [533, 469, 405, 341, 23, 277, 23, 213, 23, 23, 23, 661, 48]
load_store_test = [367, 277, 341, 405, 469, 533, 65261, 65325, 65389, 65453, 65517, 65260, 65324, 65388, 65452, 65516, 0, 0, 0, 0, 48]
load_store_mode_0_test = [367, 277, 341, 405, 469, 533, 21, 13, 85, 13, 149, 13, 213, 13, 277, 13, 21, 12, 85, 12, 149, 12, 213, 12, 277, 12, 0, 0, 0, 0, 48, 0]
mem = []


def load(filename):
    with open(filename, 'rb') as f:
        buf = f.read()
        vals = [int.from_bytes(buf[i:i + 2], 'little')
                for i in range(0, len(buf), 2)]
        code_size, data_size, *mem = vals
        return mem[:code_size], mem[code_size:]


game_program, game_data = load("./game.bin")



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
LT = 10
LTU = 11
LOAD = 12
STORE = 13
LEA = 14
SET_FP = 15
JMP = 16
JZ = 17
JNZ = 18
CALL = 19
RET = 20
PUSH_LO = 21
PUSH_HI = 22
POP = 23""".split("\n")]

CMDS = {opcode: literal for literal, opcode in CMDS}


def decode_imm(val):
    if (val & (1 << (10 - 1))) != 0:
        val = val - (1 << 10)
    return val           


def decode_instr(instr):
    opcode = instr & 0b11111
    mnemo = CMDS.get(opcode, str(opcode))
    mode = (instr >> 5) & 0b1
    immediate = decode_imm((instr >> 6) & 0b1111111111)
    return mnemo, mode, immediate


def setup_program(dut, program, data):
    for i, instr in enumerate(program):
        dut.program_memory.data[i].value = instr
    
    for i, data in enumerate(data):
        dut.memory.data[i].value = data


async def generate_clock(dut):
    counter = 0
    dut.reset.value = 1
    for _ in range(3):
        dut.clk.value = 0
        await Timer(1, unit='ns')
        dut.clk.value = 1
        await Timer(1, unit='ns')
    dut.reset.value = 0

    for _ in range(10000):
        if counter == 0:
            logger.debug("") # new line before EXEC phase
        counter = (counter + 1) % 3

        dut.clk.value = 0
        await Timer(1, unit='ns')
        dut.clk.value = 1
        await Timer(1, unit='ns')
        log_debug(dut)


def signed(logic_array, placeholder=-99999999):
    if logic_array.is_resolvable:
        return logic_array.to_signed()
    else:
        return placeholder


def unsigned(logic_array, placeholder=-99999999):
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
        fp = signed(dut.cpu.rfpstack.data[i].value)
        rstack.append((pc, fp))
    rs0 = unsigned(dut.cpu.rstack_top.value)
    rfps0 = unsigned(dut.cpu.rfpstack_top.value)
    rs1 = unsigned(dut.cpu.rstack_pre_top.value)
    rfps1 = unsigned(dut.cpu.rfpstack_pre_top.value)
    return rstack, (rs0, rfps0), (rs1, rfps1)


def decode_mem(dut, size=8):
    mem = []
    for i in range(size):
        val = unsigned(dut.memory.data[i].value)
        mem.append(val)
    return mem


def log_debug(dut):
    instr = unsigned(dut.cpu.instr.value)
    mnemo, mode, simm = decode_instr(instr)
    stack, s0, s1 = decode_stack(dut)
    rstack, rs0, rs1 = decode_rstack(dut)
    mem = decode_mem(dut)
    state = {
        0: "FE",
        1: "EX",
        2: "WB"
    }.get(unsigned(dut.cpu.state.value))
    reset = int(dut.reset.value)

    string = "state={state:<4} reset={reset} pc={pc:<4d} " \
    "fp={fp:<4d}" \
    "instr={instr:<8} mode={mode:1d} simm={simm:<10d} " \
    "stack={stack} sp={sp:4d} s0={s0:4d} s1={s1:4d} we_stack={we_stack:1d} " \
    "rstack={rstack} rs0={rs0} rs1={rs1} we_rstack={we_rstack:1d}" \
    "mem={mem}".format(
        state=state,
        reset=reset,
        pc=unsigned(dut.cpu.pc.value),
        fp=unsigned(dut.cpu.fp.value),
        instr=mnemo,
        mode=mode,
        simm=simm,
        stack=stack,
        sp=unsigned(dut.cpu.sp.value),
        s0=s0,
        s1=s1,
        we_stack=int(dut.cpu.write_to_stack.value),
        rstack=rstack,
        rs0=rs0,
        rs1=rs1,
        mem=mem,
        we_rstack=int(dut.cpu.write_to_rstack.value),
    )
    logger.debug(string)


def dump_mem(dut):
    mem = decode_mem(dut, 1024)
    with open("memory.txt", 'w') as file:
        file.write("\n".join([str(val) for val in mem]))

@asynccontextmanager
async def setup(dut, log_filename, program, data, logs_folder="./logs/"):
    import os

    os.makedirs(logs_folder, exist_ok=True)
    fh = logging.FileHandler(logs_folder + log_filename)
    fh.setLevel(logging.DEBUG)
    logger.addHandler(fh)
    setup_program(dut, program, data)
    task = cocotb.start_soon(generate_clock(dut))
    await Timer(6, 'ns')
    try:
        yield
    finally:
        logger.removeHandler(fh)
        task.cancel()


@cocotb.test(skip=False)
async def test_stack(dut):
    program = stack_test
    async with setup(dut, "test_stack.log", program, []):
        await Timer(2 * len(program) * 3, unit='ns')
        await RisingEdge(dut.clk)

        s0 = dut.cpu.stack_top.value.to_signed()
        s1 = dut.cpu.stack_pre_top.value.to_signed()
        assert s0 == 10
        assert s1 == 8


@cocotb.test(skip=False)
async def test_mem(dut):
    program = load_store_test
    async with setup(dut, "load_store_test.log", program, []):
        await Timer(2 * len(program) * 3, unit='ns')
        await RisingEdge(dut.clk)

        s0 = dut.cpu.stack_top.value.to_signed()
        assert s0 == 30
        mem = decode_mem(dut, 5)
        assert tuple(mem) == (8, 7, 6, 5, 4)


@cocotb.test(skip=False)
async def test_mem_mode0(dut):
    program = load_store_test
    async with setup(dut, "load_store_mode0_test.log", program, []):
        await Timer(2 * len(program) * 3, unit='ns')
        await RisingEdge(dut.clk)

        s0 = dut.cpu.stack_top.value.to_signed()
        assert s0 == 30
        mem = decode_mem(dut, 5)
        assert tuple(mem) == (8, 7, 6, 5, 4)


@cocotb.test(skip=False)
async def test_game(dut):
    program = game_program
    async with setup(dut, "game.log", program, game_data):
        await Timer(2 * len(program) * 3, unit='ns')
        await RisingEdge(dut.clk)

        dump_mem(dut)
