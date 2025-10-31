
from itertools import batched
import logging
import os
from random import randint, seed
import cocotb
from cocotb.triggers import RisingEdge, Timer

seed(42)


def generate_rect():
    abs = 1
    x = randint(-2 ** 9, 2 ** 10 - 1)
    y = randint(-2 ** 9, 2 ** 10 - 1)
    width = randint(0, 2 ** 10 - 1)
    height = randint(0, 2 ** 10 - 1)
    color = randint(0, 2 ** 16 - 1)
    return [abs, x, y, width, height, color]


def clamp(val, left=0, right=640):
    if val < left:
        return left
    if val > right:
        return right
    return val


mem = []
for i in range(64):
    mem += generate_rect()

with open("rects.txt", 'w') as file:
    file.write("\n".join([str(e) for e in mem]) + "\n")
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
        file.write(
            str(
                (abs, clamp(x), clamp(x + w), clamp(y, right=480), clamp(y + h, right=480), c)
            ) + "\n"
        )

rom = [1,
 0,
 0,
 256,
 256,
 14592,
 1,
 0,
 0,
 252,
 256,
 3278,
 1,
 0,
 0,
 248,
 256,
 36048,
 1,
 0,
 0,
 244,
 256,
 32098,
 1,
 0,
 0,
 240,
 256,
 29256,
 1,
 0,
 0,
 236,
 256,
 18289,
 1,
 0,
 0,
 232,
 256,
 13434,
 1,
 0,
 0,
 228,
 256,
 11395,
 1,
 0,
 0,
 224,
 256,
 55302,
 1,
 0,
 0,
 220,
 256,
 4165,
 1,
 0,
 0,
 216,
 256,
 3905,
 1,
 0,
 0,
 212,
 256,
 12280,
 1,
 0,
 0,
 208,
 256,
 28657,
 1,
 0,
 0,
 204,
 256,
 30495,
 1,
 0,
 0,
 200,
 256,
 3478,
 1,
 0,
 0,
 196,
 256,
 26062,
 1,
 0,
 0,
 192,
 256,
 54987,
 1,
 0,
 0,
 188,
 256,
 28893,
 1,
 0,
 0,
 184,
 256,
 58878,
 1,
 0,
 0,
 180,
 256,
 36463,
 1,
 0,
 0,
 176,
 256,
 851,
 1,
 0,
 0,
 172,
 256,
 20926,
 1,
 0,
 0,
 168,
 256,
 55392,
 1,
 0,
 0,
 164,
 256,
 44597,
 1,
 0,
 0,
 160,
 256,
 36421,
 1,
 0,
 0,
 156,
 256,
 20379,
 1,
 0,
 0,
 152,
 256,
 28221,
 1,
 0,
 0,
 148,
 256,
 44118,
 1,
 0,
 0,
 144,
 256,
 13396,
 1,
 0,
 0,
 140,
 256,
 12156,
 1,
 0,
 0,
 136,
 256,
 49797,
 1,
 0,
 0,
 132,
 256,
 12676,
 1,
 0,
 0,
 128,
 256,
 47052,
 1,
 0,
 0,
 124,
 256,
 45082,
 1,
 0,
 0,
 120,
 256,
 34671,
 1,
 0,
 0,
 116,
 256,
 5695,
 1,
 0,
 0,
 112,
 256,
 60217,
 1,
 0,
 0,
 108,
 256,
 16361,
 1,
 0,
 0,
 104,
 256,
 49615,
 1,
 0,
 0,
 100,
 256,
 10328,
 1,
 0,
 0,
 96,
 256,
 38427,
 1,
 0,
 0,
 92,
 256,
 47400,
 1,
 0,
 0,
 88,
 256,
 25203,
 1,
 0,
 0,
 84,
 256,
 9116,
 1,
 0,
 0,
 80,
 256,
 6006,
 1,
 0,
 0,
 76,
 256,
 29871,
 1,
 0,
 0,
 72,
 256,
 37930,
 1,
 0,
 0,
 68,
 256,
 10458,
 1,
 0,
 0,
 64,
 256,
 30512,
 1,
 0,
 0,
 60,
 256,
 13238,
 1,
 0,
 0,
 56,
 256,
 49823,
 1,
 0,
 0,
 52,
 256,
 36434,
 1,
 0,
 0,
 48,
 256,
 59429,
 1,
 0,
 0,
 44,
 256,
 47819,
 1,
 0,
 0,
 40,
 256,
 21319,
 1,
 0,
 0,
 36,
 256,
 48520,
 1,
 0,
 0,
 32,
 256,
 46566,
 1,
 0,
 0,
 28,
 256,
 27460,
 1,
 0,
 0,
 24,
 256,
 34993,
 1,
 0,
 0,
 20,
 256,
 9358,
 1,
 0,
 0,
 16,
 256,
 22431,
 1,
 0,
 0,
 12,
 256,
 32087,
 1,
 0,
 0,
 8,
 256,
 21417,
 1,
 0,
 0,
 4,
 256,
 60589]

expected_colors = [60589,
 60589,
 60589,
 60589,
 21417,
 21417,
 21417,
 21417,
 32087,
 32087,
 32087,
 32087,
 22431,
 22431,
 22431,
 22431,
 9358,
 9358,
 9358,
 9358,
 34993,
 34993,
 34993,
 34993,
 27460,
 27460,
 27460,
 27460,
 46566,
 46566,
 46566,
 46566,
 48520,
 48520,
 48520,
 48520,
 21319,
 21319,
 21319,
 21319,
 47819,
 47819,
 47819,
 47819,
 59429,
 59429,
 59429,
 59429,
 36434,
 36434,
 36434,
 36434,
 49823,
 49823,
 49823,
 49823,
 13238,
 13238,
 13238,
 13238,
 30512,
 30512,
 30512,
 30512,
 10458,
 10458,
 10458,
 10458,
 37930,
 37930,
 37930,
 37930,
 29871,
 29871,
 29871,
 29871,
 6006,
 6006,
 6006,
 6006,
 9116,
 9116,
 9116,
 9116,
 25203,
 25203,
 25203,
 25203,
 47400,
 47400,
 47400,
 47400,
 38427,
 38427,
 38427,
 38427,
 10328,
 10328,
 10328,
 10328,
 49615,
 49615,
 49615,
 49615,
 16361,
 16361,
 16361,
 16361,
 60217,
 60217,
 60217,
 60217,
 5695,
 5695,
 5695,
 5695,
 34671,
 34671,
 34671,
 34671,
 45082,
 45082,
 45082,
 45082,
 47052,
 47052,
 47052,
 47052,
 12676,
 12676,
 12676,
 12676,
 49797,
 49797,
 49797,
 49797,
 12156,
 12156,
 12156,
 12156,
 13396,
 13396,
 13396,
 13396,
 44118,
 44118,
 44118,
 44118,
 28221,
 28221,
 28221,
 28221,
 20379,
 20379,
 20379,
 20379,
 36421,
 36421,
 36421,
 36421,
 44597,
 44597,
 44597,
 44597,
 55392,
 55392,
 55392,
 55392,
 20926,
 20926,
 20926,
 20926,
 851,
 851,
 851,
 851,
 36463,
 36463,
 36463,
 36463,
 58878,
 58878,
 58878,
 58878,
 28893,
 28893,
 28893,
 28893,
 54987,
 54987,
 54987,
 54987,
 26062,
 26062,
 26062,
 26062,
 3478,
 3478,
 3478,
 3478,
 30495,
 30495,
 30495,
 30495,
 28657,
 28657,
 28657,
 28657,
 12280,
 12280,
 12280,
 12280,
 3905,
 3905,
 3905,
 3905,
 4165,
 4165,
 4165,
 4165,
 55302,
 55302,
 55302,
 55302,
 11395,
 11395,
 11395,
 11395,
 13434,
 13434,
 13434,
 13434,
 18289,
 18289,
 18289,
 18289,
 29256,
 29256,
 29256,
 29256,
 32098,
 32098,
 32098,
 32098,
 36048,
 36048,
 36048,
 36048,
 3278,
 3278,
 3278,
 3278,
 14592,
 14592,
 14592,
 14592]

logs_folder = "logs/"
logger = logging.getLogger("test_gpu")
logger.setLevel(logging.DEBUG)

os.makedirs(logs_folder, exist_ok=True)
fh = logging.FileHandler(logs_folder + "gpu.log")
fh.setLevel(logging.DEBUG)
logger.addHandler(fh)

async def generate_coords(dut):
    dut.x_coord.value = 0
    dut.y_coord.value = 0
    for y in range(480):
        for x in range(640):
            await RisingEdge(dut.clk)
            dut.x_coord.value = x
            dut.y_coord.value = y


async def generate_clock(dut):
    for i in range(40_000):
        dut.clk.value = 0
        await Timer(1, unit='ns')
        dut.clk.value = 1
        await Timer(1, unit='ns')
        if i > 0:
            log_debug(dut)

def convert_array(array, size=64):
    arr = []
    for i in range(size):
        if array[i].value.is_resolvable:
            arr.append(array[i].value.to_unsigned())
        else:
            arr.append("X")
    return arr

def log_debug(dut): 
    color = dut.gpu.color.value
    color = color.to_unsigned() if color.is_resolvable else "xxx"
    
    string = "reset={reset} copy_start={copy_start} " \
    "state={state} state_new={state_new} " \
    "color={color} x={x} y={y} " \
    "mem_din={mem_din:<8d} fsm_state={fsm_state} coord_generator={coord_generator:<4d} " \
    "rect_counter={rect_counter:<5d} batch_counter={batch_counter:<2d} batch_completed={batch_completed} " \
    "mem_select={mem_select} fsm_mem_din_addr={fsm_mem_din_addr:<4d} fsm_mem_din={fsm_mem_din:<32} fsm_mdina={fsm_mdina} fsm_we={fsm_we} " \
    "fsm_cba={fsm_cba} fsm_cu={fsm_cu} fsm_dout={fsm_dout} fsm_dout_addr={fsm_dout_addr} buffer={buffer} ".format(
        reset = dut.reset.value,
        copy_start = dut.copy_start.value,
        state = dut.gpu.state.value.to_unsigned(),
        state_new = dut.gpu.state_new.value.to_unsigned(),
        color = color,
        x = dut.gpu.x_coord.value.to_unsigned(),
        y = dut.gpu.y_coord.value.to_unsigned(),
        mem_din = dut.gpu.mem_din.value.to_unsigned() if dut.gpu.mem_din.value.is_resolvable else "z",
        fsm_state = dut.gpu.fsm_state.value.to_unsigned(),
        coord_generator = dut.gpu.coord_generator.value.to_unsigned(),
        rect_counter = dut.gpu.rect_counter.value.to_unsigned(),
        batch_counter = dut.gpu.batch_counter.value.to_unsigned(),
        batch_completed = dut.gpu.batch_completed.value,
        mem_select = dut.gpu.mem_select.value.to_unsigned(),
        fsm_mem_din_addr = dut.gpu.fsm_mem_din_addr.value.to_unsigned(),
        fsm_mem_din = dut.gpu.fsm_mem_din.value.to_unsigned() if dut.gpu.fsm_mem_din.value.is_resolvable else "z",
        fsm_mdina = dut.gpu.gpu_receiver_fsm.mem_din_aligned.value,
        fsm_we = dut.gpu.fsm_we.value,
        fsm_cba = dut.gpu.gpu_receiver_fsm.collisions_buffer_aligned.value,
        fsm_cu = dut.gpu.gpu_receiver_fsm.collisions_updated.value,
        fsm_dout = dut.gpu.fsm_dout.value,
        fsm_dout_addr = dut.gpu.fsm_dout_addr.value.to_unsigned() if dut.gpu.fsm_dout_addr.value.is_resolvable else "z",
        buffer = convert_array(dut.gpu.gpu_receiver_fsm.buffer, 16)
    )
    logger.debug(string)

@cocotb.test(skip=True)
async def test_gpu(dut):
    cocotb.start_soon(generate_clock(dut))
    dut.reset.value = 1
    await RisingEdge(dut.clk)
    dut.reset.value = 0
    await RisingEdge(dut.clk)
    dut.copy_start.value = 1
    await RisingEdge(dut.clk)
    dut.copy_start.value = 0

    for i in range(6 * 64):
        dut.mem_din.value = rom[i]
        await RisingEdge(dut.clk)

    await RisingEdge(dut.clk)
    for i in range(64):
        # print(type(dut.rect_left[i]), type(dut.rect_left[i].value))
        l, t, r, b, c = (
            dut.rect_lefts[i].value.to_signed(),
            dut.rect_tops[i].value.to_signed(),
            dut.rect_rights[i].value.to_signed(),
            dut.rect_bottoms[i].value.to_signed(),
            dut.rect_colors[i].value.to_unsigned()
        )
        logger.debug(
            "{:d} {:d} {:d} {:d} {:x}".format(
                l, t, r, b, c
            )
        )
        if rom[i * 6]:
            expected = (
                rom[i * 6 + 1],
                rom[i * 6 + 2],
                rom[i * 6 + 1] + rom[i * 6 + 3],
                rom[i * 6 + 2] + rom[i * 6 + 4],
                rom[i * 6 + 5]
            )
        else:
            expected = (0, 0, 0, 0, 0)
        assert (l, t, r, b, c) == expected, f"(rect_idx={i}) error on read, expected={expected}, actual={(l, t, r, b, c)}"
    
    cocotb.start_soon(generate_coords(dut))
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    for i in range(256):
        out_color = dut.color.value.to_unsigned()
        expected = expected_colors[i]
        assert out_color == expected, f"collor mismatch {out_color} != {expected}"
        await RisingEdge(dut.clk)

@cocotb.test(skip=True)
async def test_gpu_random(dut):
    cocotb.start_soon(generate_clock(dut))
    dut.reset.value = 1
    await RisingEdge(dut.clk)
    dut.reset.value = 0
    await RisingEdge(dut.clk)
    dut.copy_start.value = 1
    await RisingEdge(dut.clk)
    dut.copy_start.value = 0

    for i in range(6 * 64):
        dut.mem_din.value = mem[i]
        await RisingEdge(dut.clk)

    await RisingEdge(dut.clk)
    for i in range(64):
        # print(type(dut.rect_left[i]), type(dut.rect_left[i].value))
        l, t, r, b, c = (
            dut.rect_lefts[i].value.to_unsigned(),
            dut.rect_tops[i].value.to_unsigned(),
            dut.rect_rights[i].value.to_unsigned(),
            dut.rect_bottoms[i].value.to_unsigned(),
            dut.rect_colors[i].value.to_unsigned()
        )
        logger.debug(
            "{:d} {:d} {:d} {:d} {:x}".format(
                l, t, r, b, c
            )
        )
        if mem[i * 6]:
            expected = (
                clamp(mem[i * 6 + 1]),
                clamp(mem[i * 6 + 2], right=480),
                clamp(mem[i * 6 + 1] + mem[i * 6 + 3]),
                clamp(mem[i * 6 + 2] + mem[i * 6 + 4], right=480),
                mem[i * 6 + 5]
            )
        else:
            expected = (0, 0, 0, 0, 0)
        assert (l, t, r, b, c) == expected, f"(rect_idx={i}) error on read, expected={expected}, actual={(l, t, r, b, c)}"

def setup_mem(dut, mem, start=8192-6*64):
    for i, val in zip(range(start, start + len(mem)), mem):
        dut.memory.data[i].value = val

def get_masks(expected, func, max_coord=640):
    masks = []
    for coord in range(max_coord):
        mask = 0
        for i in range(64):
            x = expected[63 - i]
            mask <<= 1
            mask |= func(x, coord)
        masks.append(mask)
    return masks

@cocotb.test(skip=False)
async def test_gpu_new(dut):
    dut.x_coord.value = 0
    dut.y_coord.value = 0
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

    # expected
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

    # xs
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

    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    xs_mem = convert_array(dut.gpu.xs_mem.data, 640)
    masks = get_masks([rect[0] for rect in expected], lambda x_left, coord: x_left < coord)

    for i, (x_actual, x_expected) in enumerate(zip(xs_mem, masks)):
        # print("act", bin(x_actual & 0xffffffffffffffff))
        # print("exp", bin(x_expected & 0xffffffffffffffff))
        assert x_actual == x_expected, f"fail on xs[{i}]"
    
    # xs + widths
    for batch in range(4):
        for i in range(16):
            logger.debug("Yahoo!")
            if (batch != 0 or i != 0):
                await RisingEdge(dut.clk) # skip first
                await RisingEdge(dut.clk)
                await RisingEdge(dut.clk)
            sout = dut.controller.mem_dout.value.to_signed()
            assert sout == expected[16 * batch + i][1], f"(batch={batch}, i={i}) fail on xs + widths"
        await Timer(2 * 640, unit='ns')
        await RisingEdge(dut.clk)
    
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    xs_mem = convert_array(dut.gpu.xs_mem.data, 640)
    masks_new = get_masks([rect[1] for rect in expected], lambda x_right, coord: coord <= x_right)
    masks = [a & b for a, b in zip(masks, masks_new)]

    for i, (x_actual, x_expected) in enumerate(zip(xs_mem, masks)):
        # print("act", bin(x_actual & 0xffffffffffffffff))
        # print("exp", bin(x_expected & 0xffffffffffffffff))
        assert x_actual == x_expected, f"fail on xs+width[{i}]"
    
    # ys
    for batch in range(4):
        for i in range(16):
            logger.debug("Yahoo!")
            if (batch != 0 or i != 0):
                await RisingEdge(dut.clk)
                await RisingEdge(dut.clk)
                await RisingEdge(dut.clk)
            sout = dut.controller.mem_dout.value.to_signed()
            assert sout == expected[16 * batch + i][2], f"(batch={batch}, i={i}) fail on ys"
        await Timer(2 * 480, unit='ns')
        await RisingEdge(dut.clk)
    
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    ys_mem = convert_array(dut.gpu.ys_mem.data, 480)
    masks= get_masks([rect[2] for rect in expected], lambda y_top, coord: y_top < coord, max_coord=480)

    for i, (y_actual, y_expected) in enumerate(zip(ys_mem, masks)):
        # print("act", bin(x_actual & 0xffffffffffffffff))
        # print("exp", bin(x_expected & 0xffffffffffffffff))
        assert y_actual == y_expected, f"fail on ys[{i}]"
    
    # ys + heights
    for batch in range(4):
        for i in range(16):
            logger.debug("Yahoo!")
            if (batch != 0 or i != 0):
                await RisingEdge(dut.clk)
                await RisingEdge(dut.clk)
                await RisingEdge(dut.clk)
            sout = dut.controller.mem_dout.value.to_signed()
            assert sout == expected[16 * batch + i][3], f"(batch={batch}, i={i}) fail on ys + heights"
        await Timer(2 * 480, unit='ns')
        await RisingEdge(dut.clk)
    
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    ys_mem = convert_array(dut.gpu.ys_mem.data, 480)
    masks_new = get_masks([rect[3] for rect in expected], lambda y_bottom, coord: coord <= y_bottom, max_coord=480)
    masks = [a & b for a, b in zip(masks, masks_new)]

    for i, (y_actual, y_expected) in enumerate(zip(ys_mem, masks)):
        # print("act", bin(x_actual & 0xffffffffffffffff))
        # print("exp", bin(x_expected & 0xffffffffffffffff))
        assert y_actual == y_expected, f"fail on ys+heights[{i}]"

    # colors
    for batch in range(4):
        for i in range(16):
            logger.debug("Yahoo!")
            if (batch != 0 or i != 0):
                await RisingEdge(dut.clk)
                await RisingEdge(dut.clk)
                await RisingEdge(dut.clk)
            uout = dut.controller.mem_dout.value.to_unsigned()
            assert uout == expected[16 * batch + i][4], f"(batch={batch}, i={i}) fail on colors"
        await Timer(2 * 16, unit='ns')
        await RisingEdge(dut.clk)
    
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    colors_mem = convert_array(dut.gpu.colors_mem.data, 64)
    print(colors_mem)

    for i, (color_actual, color_expected) in enumerate(zip(colors_mem, [val[4] for val in expected])):
        # print("act", bin(x_actual & 0xffffffffffffffff))
        # print("exp", bin(x_expected & 0xffffffffffffffff))
        assert color_actual == color_expected, f"fail on colors[{i}]"

    await RisingEdge(dut.clk)
    cocotb.start_soon(generate_coords(dut))
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    for i in range(5000):
        # out_color = dut.color.value.to_unsigned()
        # expected = expected_colors[i]
        # assert out_color == expected, f"collor mismatch {out_color} != {expected}"
        await RisingEdge(dut.clk)

