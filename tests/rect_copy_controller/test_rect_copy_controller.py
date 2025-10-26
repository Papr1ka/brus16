import logging
import os
from random import randint, seed
from itertools import batched

seed(42)

import cocotb
from cocotb.triggers import Timer, RisingEdge

os.makedirs("./logs", exist_ok=True)
logger = logging.getLogger("test_rect_copy_controller")
logger.setLevel(logging.DEBUG)
fh = logging.FileHandler("./logs/test_rect_copy_controller.log")
fh.setLevel(logging.DEBUG)
logger.addHandler(fh)


async def generate_clock(dut):
    for i in range(10000):
        dut.clk.value = 0
        await Timer(1, unit='ns')
        dut.clk.value = 1
        await Timer(1, unit='ns')
        if i > 0:
            log_debug(dut)

def generate_rect(i):
    if i == 0:
        abs = 1
    else:
        abs = randint(0, 1)
    x = randint(-10000, 2 ** 10 - 1)
    y = randint(-10000, 2 ** 10 - 1)
    width = randint(0, 2 ** 10 - 1)
    height = randint(0, 2 ** 10 - 1)
    color = randint(0, 2 ** 16 - 1)
    return [abs, x, y, width, height, color]


mem = []
for i in range(64):
    mem += generate_rect(i)

with open("rects.txt", 'w') as file:
    file.write("\n".join([str(e) for e in mem]) + "\n")

def setup_mem(dut, mem, start=8192-6*64):
    for i, val in zip(range(start, start + len(mem)), mem):
        dut.memory.data[i].value = val

def log_debug(dut):
    string = "copy_start={copy_start} mem_din={mem_din:<6d} " \
    "mem_dout={mem_dout:<6d} " \
    "addr={addr:<6d} addr_new={addr_new:<6d} " \
    "state={state:<2d} state_new={state_new:<2d} " \
    "reading_abs={reading_abs} reading_abs_new={reading_abs_new} " \
    "cursor_x={cursor_x:<6d} cursor_x_new={cursor_x_new:<6d} " \
    "cursor_y={cursor_y:<6d} cursor_y_new={cursor_y_new:<6d} ".format(
        copy_start=int(dut.copy_start.value),
        mem_din=dut.controller.mem_din.value.to_signed(),
        mem_dout=dut.controller.mem_dout.value.to_signed(),
        state=dut.controller.state.value.to_unsigned(),
        state_new=dut.controller.state_new.value.to_unsigned(),
        addr=dut.controller.addr.value.to_unsigned(),
        addr_new=dut.controller.addr_new.value.to_unsigned(),
        reading_abs=int(dut.controller.reading_abs.value),
        reading_abs_new=int(dut.controller.reading_abs_new.value),
        cursor_x=dut.controller.cursor_x.value.to_signed(),
        cursor_x_new=dut.controller.cursor_x_new.value.to_signed(),
        cursor_y=dut.controller.cursor_y.value.to_unsigned(),
        cursor_y_new=dut.controller.cursor_y_new.value.to_unsigned(),
    )
    logger.debug(string)

@cocotb.test(skip=False)
async def tect_rect_copy_controller(dut):
    dut.copy_start.value = 0
    dut.reset.value = 1
    cocotb.start_soon(generate_clock(dut))
    setup_mem(dut, mem)
    await RisingEdge(dut.clk)
    dut.reset.value = 0
    await RisingEdge(dut.clk)
    dut.copy_start.value = 1
    await RisingEdge(dut.clk)
    dut.copy_start.value = 0
    cursor_x = 0
    cursor_y = 0
    await RisingEdge(dut.clk)
    for abs, x, y, w, h, c in batched(mem, 6):
        if (abs):
            cursor_x = x
            cursor_y = y
        else:
            x += cursor_x
            y += cursor_y
        # print(dut.controller.mem_dout.value.to_unsigned(), 0)
        assert dut.controller.mem_dout.value.to_unsigned() == (0)
        await RisingEdge(dut.clk)
        # print(dut.controller.mem_dout.value.to_unsigned(), x)
        assert dut.controller.mem_dout.value.to_signed() == x
        await RisingEdge(dut.clk)
        # print(dut.controller.mem_dout.value.to_unsigned(), y)
        assert dut.controller.mem_dout.value.to_signed() == y
        await RisingEdge(dut.clk)
        # print(dut.controller.mem_dout.value.to_unsigned(), w)
        assert dut.controller.mem_dout.value.to_unsigned() == w
        await RisingEdge(dut.clk)
        # print(dut.controller.mem_dout.value.to_unsigned(), h)
        assert dut.controller.mem_dout.value.to_unsigned() == h
        await RisingEdge(dut.clk)
        # print(dut.controller.mem_dout.value.to_unsigned(), c)
        assert dut.controller.mem_dout.value.to_unsigned() == c
        await RisingEdge(dut.clk)

    dut.reset.value = 1
    await RisingEdge(dut.clk)
    dut.reset.value = 0
    await RisingEdge(dut.clk)

    # double check after reset to be sure

    dut.copy_start.value = 1
    await RisingEdge(dut.clk)
    dut.copy_start.value = 0
    cursor_x = 0
    cursor_y = 0
    await RisingEdge(dut.clk)
    for abs, x, y, w, h, c in batched(mem, 6):
        if (abs):
            cursor_x = x
            cursor_y = y
        else:
            x += cursor_x
            y += cursor_y
        # print(dut.controller.mem_dout.value.to_unsigned(), 0)
        assert dut.controller.mem_dout.value.to_unsigned() == (0)
        await RisingEdge(dut.clk)
        # print(dut.controller.mem_dout.value.to_unsigned(), x)
        assert dut.controller.mem_dout.value.to_signed() == x
        await RisingEdge(dut.clk)
        # print(dut.controller.mem_dout.value.to_unsigned(), y)
        assert dut.controller.mem_dout.value.to_signed() == y
        await RisingEdge(dut.clk)
        # print(dut.controller.mem_dout.value.to_unsigned(), w)
        assert dut.controller.mem_dout.value.to_unsigned() == w
        await RisingEdge(dut.clk)
        # print(dut.controller.mem_dout.value.to_unsigned(), h)
        assert dut.controller.mem_dout.value.to_unsigned() == h
        await RisingEdge(dut.clk)
        # print(dut.controller.mem_dout.value.to_unsigned(), c)
        assert dut.controller.mem_dout.value.to_unsigned() == c
        await RisingEdge(dut.clk)
