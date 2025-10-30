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
    x = randint(-2 ** 13, 2 ** 13 - 1)
    y = randint(-2 ** 13, 2 ** 13 - 1)
    width = randint(0, 2 ** 13 - 1)
    height = randint(0, 2 ** 13 - 1)
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
    string = "reset={reset} copy_start={copy_start} mem_din={mem_din:<6d} " \
    "mem_dout={mem_dout:<6d} " \
    "addr={addr:<6d} addr_new={addr_new:<6d} " \
    "state={state:<3d} state_new={state_new:<3d} " \
    "localstate={localstate:<2d} localstate_new={localstate_new:<2d} " \
    "reading_abs={reading_abs} reading_abs_new={reading_abs_new} " \
    "rect_counter={rect_counter:<4d} wait_counter={wait_counter:<10d} batch_counter={batch_counter:<2d} " \
    "batch_completed={batch_completed} " \
    "cursor_coord={cursor_coord:<6d} cursor_coord_new={cursor_coord_new:<6d} " \
    "buffer_reg={buffer_reg:<16d} buffer_reg_new={buffer_reg_new:<16d} ".format(
        reset=dut.reset.value,
        copy_start=int(dut.copy_start.value),
        mem_din=dut.controller.mem_din.value.to_signed(),
        mem_dout=dut.controller.mem_dout.value.to_signed(),
        state=dut.controller.state.value.to_unsigned(),
        state_new=dut.controller.state_new.value.to_unsigned(),
        localstate=dut.controller.localstate.value.to_unsigned(),
        localstate_new=dut.controller.localstate_new.value.to_unsigned(),
        addr=dut.controller.addr.value.to_unsigned(),
        addr_new=dut.controller.addr_new.value.to_unsigned(),
        reading_abs=dut.controller.reading_abs.value,
        reading_abs_new=dut.controller.reading_abs_new.value,
        rect_counter=dut.controller.rect_counter.value.to_unsigned(),
        wait_counter=dut.controller.wait_counter.value.to_unsigned(),
        batch_counter=dut.controller.batch_counter.value.to_unsigned(),
        batch_completed=dut.controller.batch_completed.value,
        cursor_coord=dut.controller.cursor_coord.value.to_signed(),
        cursor_coord_new=dut.controller.cursor_coord_new.value.to_signed(),
        buffer_reg=dut.controller.buffer_reg.value.to_signed(),
        buffer_reg_new=dut.controller.buffer_reg_new.value.to_signed(),
    )
    logger.debug(string)

@cocotb.test(skip=True)
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

def clamp(val, left=0, right=640):
    if val < left:
        return left
    if val > right:
        return right
    return val

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
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)

    cursor_x = 0
    cursor_y = 0
    expected = []
    for abs, x, y, w, h, c in batched(mem, 6):
        if (abs):
            cursor_x = x
            cursor_y = y
        else:
            x += cursor_x
            y += cursor_y
        expected.append((clamp(x), clamp(x + w), clamp(y, right=480), clamp(y + h, right=480), c))

    for batch in range(4):
        for i in range(16):
            logger.debug("Yahoo!")
            await RisingEdge(dut.clk)
            await RisingEdge(dut.clk)
            await RisingEdge(dut.clk)
            sout = dut.controller.mem_dout.value.to_signed()
            assert sout == expected[16 * batch + i][0], f"(batch={batch}, i={i}) fail on xs"
        await Timer(2 * 640, unit='ns')
        await RisingEdge(dut.clk)
    
    for batch in range(4):
        for i in range(16):
            logger.debug("Yahoo!")
            await RisingEdge(dut.clk)
            await RisingEdge(dut.clk)
            await RisingEdge(dut.clk)
            sout = dut.controller.mem_dout.value.to_signed()
            assert sout == expected[16 * batch + i][1], f"(batch={batch}, i={i}) fail on xs + widths"
        await Timer(2 * 640, unit='ns')
        await RisingEdge(dut.clk)
    
    for batch in range(4):
        for i in range(16):
            logger.debug("Yahoo!")
            await RisingEdge(dut.clk)
            await RisingEdge(dut.clk)
            await RisingEdge(dut.clk)
            sout = dut.controller.mem_dout.value.to_signed()
            assert sout == expected[16 * batch + i][2], f"(batch={batch}, i={i}) fail on ys"
        await Timer(2 * 480, unit='ns')
        await RisingEdge(dut.clk)
    
    for batch in range(4):
        for i in range(16):
            logger.debug("Yahoo!")
            await RisingEdge(dut.clk)
            await RisingEdge(dut.clk)
            await RisingEdge(dut.clk)
            sout = dut.controller.mem_dout.value.to_signed()
            assert sout == expected[16 * batch + i][3], f"(batch={batch}, i={i}) fail on ys + heights"
        await Timer(2 * 480, unit='ns')
        await RisingEdge(dut.clk)
    
    for batch in range(4):
        for i in range(16):
            logger.debug("Yahoo!")
            await RisingEdge(dut.clk)
            await RisingEdge(dut.clk)
            await RisingEdge(dut.clk)
            uout = dut.controller.mem_dout.value.to_unsigned()
            assert uout == expected[16 * batch + i][4], f"(batch={batch}, i={i}) fail on colors"
        await Timer(2 * 16, unit='ns')
        await RisingEdge(dut.clk)

