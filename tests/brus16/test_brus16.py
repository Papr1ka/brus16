from contextlib import asynccontextmanager
import logging
import os

import cocotb
from cocotb.triggers import RisingEdge, Timer
from cocotb.types import Logic


logging.getLogger().handlers = []
logger = logging.getLogger("test_cpu")
logger.setLevel(logging.DEBUG)

def load(filename):
    with open(filename, 'rb') as f:
        buf = f.read()
        vals = [int.from_bytes(buf[i:i + 2], 'little')
                for i in range(0, len(buf), 2)]
        code_size, data_size, *mem = vals
        return mem[:code_size], mem[code_size:]


# game_program, game_data = load("./bug.bin")
game_data = [0] * 8192
game_program, game_data_new = load("./game.bin")
for i, e in enumerate(game_data_new):
    game_data[i] = e


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

def decode_mem(dut, start=0, end=8):
    mem = []
    for i in range(start, end):
        val = unsigned(dut.memory.data[i].value)
        mem.append(val)
    return mem


def log_debug(dut):
    string = "reset={reset} hsync={hsync} vsync={vsync} hpos={hpos} vpos={vpos} copy={copy} copy_start={copy_start} resume={resume} " \
    "data_mra_bus={data_mra_bus} data_mrd_bus={data_mrd_bus} " \
    "data_mwa_bus={data_mwa_bus} data_mwd_bus={data_mwd_bus} gpu_data={gpu_data} gpu_reset={gpu_reset} " \
    "gpu_state={gpu_state} gpu_copy_state={gpu_copy_state} color={color}".format(
        reset=int(dut.reset.value),
        hsync=int(dut.hsync.value),
        vsync=int(dut.vsync.value),
        hpos=dut.hpos.value.to_unsigned(),
        vpos=dut.vpos.value.to_unsigned(),
        copy=int(dut.copy.value),
        copy_start=int(dut.copy_start.value),
        resume=int(dut.resume.value),
        data_mra_bus=dut.data_memory_read_addr_bus.value.to_unsigned(),
        data_mrd_bus=dut.data_memory_read_data_bus.value.to_unsigned(),
        data_mwa_bus=dut.data_memory_write_addr_bus.value.to_unsigned(),
        data_mwd_bus=dut.data_memory_write_data_bus.value.to_unsigned(),
        gpu_data=dut.gpu_data.value.to_unsigned(),
        gpu_reset=int(dut.gpu_reset.value),
        gpu_state=dut.gpu.state.value.to_unsigned(),
        gpu_copy_state=dut.gpu.copy_state.value.to_unsigned(),
        color=dut.pixel_color.value.to_unsigned(),
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
    try:
        yield
    finally:
        logger.removeHandler(fh)
        task.cancel()


@cocotb.test(skip=False)
async def test_game(dut):
    program = game_program
    async with setup(dut, "brus16_game.log", program, game_data):
        await Timer(2 * 20_000, unit='ns')
        await RisingEdge(dut.clk)
        