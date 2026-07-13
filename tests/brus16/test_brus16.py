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
        dut.data_memory.data[i].value = data


async def generate_clock(dut):
    for _ in range(3):
        dut.clk.value = 0
        await Timer(1, unit='ns')
        dut.clk.value = 1
        await Timer(1, unit='ns')

    for _ in range(10_000_000):
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
    string = "reset={reset} hsync={hsync} vsync={vsync} hpos={hpos} vpos={vpos} peripheral_sel={peripheral_sel} resume={resume} sfx={sfx} sfx_pulse={sfx_pulse} " \
    "data_addr_bus_0={data_addr_bus_0} data_rd_bus_0={data_rd_bus_0} data_we_bus_0={data_we_bus_0} data_wd_bus_0={data_wd_bus_0} " \
    "data_addr_bus_1={data_addr_bus_1} data_rd_bus_1={data_rd_bus_1} data_we_bus_1={data_we_bus_1} data_wd_bus_1={data_wd_bus_1} " \
    "gpu_reset={gpu_reset} color={color} sample={sample} sample_counter={sample_counter} stage_counter={stage_counter}".format(
        reset=int(dut.reset.value),
        hsync=int(dut.hsync.value),
        vsync=int(dut.vsync.value),
        sfx=int(dut.peripheral_sel.value == 2),
        sfx_pulse=int(dut.sfx_controller_pulse.value),
        hpos=dut.hpos.value.to_unsigned(),
        vpos=dut.vpos.value.to_unsigned(),
        peripheral_sel=unsigned(dut.peripheral_sel.value),
        resume=int(dut.cpu_pulse.value),

        data_addr_bus_0=dut.data_memory_addr_bus_0.value.to_unsigned(),
        data_rd_bus_0=dut.data_memory_read_data_bus_0.value.to_unsigned(),
        data_we_bus_0=int(dut.data_memory_write_we_bus_0.value),
        data_wd_bus_0=dut.data_memory_write_data_bus_0.value.to_unsigned(),

        data_addr_bus_1=dut.data_memory_addr_bus_1.value.to_unsigned(),
        data_rd_bus_1=dut.data_memory_read_data_bus_1.value.to_unsigned(),
        data_we_bus_1=int(dut.data_memory_write_we_bus_1.value),
        data_wd_bus_1=dut.data_memory_write_data_bus_1.value.to_unsigned(),

        gpu_reset=int(dut.gpu_pulse.value),
        gpu_state=dut.gpu_top.gpu.state.value.to_unsigned(),
        gpu_fsm_state=dut.gpu_top.gpu.gpu_receiver_fsm.state.value.to_unsigned(),
        color=dut.gpu_top.pixel_color.value.to_unsigned() if dut.gpu_top.pixel_color.value.is_resolvable else "z",
        sample=signed(dut.sample.value),
        sample_counter=unsigned(dut.sfx_top.sfx_controller.sample_counter.value),
        stage_counter=unsigned(dut.sfx_top.sfx_process.stage_counter.value)
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
        await Timer(2 * 1_000_000, unit='ns')
        await RisingEdge(dut.clk)
