import logging
import os
from random import randint, seed
from itertools import batched

seed(42)

import cocotb
from cocotb.triggers import Timer, RisingEdge

os.makedirs("./logs", exist_ok=True)
logger = logging.getLogger("test_button_controller")
logger.setLevel(logging.DEBUG)
fh = logging.FileHandler("./logs/test_button_controller.log")
fh.setLevel(logging.DEBUG)
logger.addHandler(fh)


async def generate_clock(dut):
    for _ in range(10000):
        dut.clk.value = 0
        await Timer(1, unit='ns')
        dut.clk.value = 1
        await Timer(1, unit='ns')
        log_debug(dut)


def log_debug(dut):
    buttons = []
    for i in range(6):
        buttons.append(int(dut.buttons_data[i].value))
    
    string = "reset={reset} copy_start={copy_start} " \
    "state={state} state_new={state_new} " \
    "addr={addr} addr_new={addr_new} " \
    "buttons={buttons} " \
    "mem_dout_we={mem_dout_we} mem_dout_addr={mem_dout_addr} mem_dout={mem_dout}".format(
        reset=int(dut.reset.value),
        copy_start=int(dut.copy_start.value),
        state=int(dut.state.value),
        state_new=int(dut.state_new.value),
        addr=dut.addr.value.to_unsigned(),
        addr_new=dut.addr_new.value.to_unsigned(),
        buttons=buttons,
        mem_dout_we=int(dut.mem_dout_we.value),
        mem_dout_addr=dut.mem_dout_addr.value.to_unsigned(),
        mem_dout=dut.mem_dout.value.to_unsigned(),
    )
    logger.debug(string)

@cocotb.test(skip=False)
async def tect_rect_copy_controller(dut):
    dut.reset.value = 0
    dut.copy_start.value = 0
    dut.buttons_in.value = 0b000000
    cocotb.start_soon(generate_clock(dut))

    await RisingEdge(dut.clk)

    dut.buttons_in.value = 0b010110
    await Timer(2 * 260, 'ns')

    await RisingEdge(dut.clk)
    dut.copy_start.value = 1
    await RisingEdge(dut.clk)
    dut.copy_start.value = 0
    for i in range(6):
        print(dut.mem_dout)
        await RisingEdge(dut.clk)
    
    dut.reset.value = 1
    await RisingEdge(dut.clk)
    dut.reset.value = 0
    await Timer(2 * 5, 'ns')
