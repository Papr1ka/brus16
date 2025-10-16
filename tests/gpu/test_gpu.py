
import logging
import os
from random import randint, seed
import cocotb
from cocotb.triggers import RisingEdge, Timer

seed(42)


def generate_rect():
    abs = 1
    x = randint(-1000, 2 ** 10 - 1)
    y = randint(-1000, 2 ** 10 - 1)
    width = randint(0, 2 ** 10 - 1)
    height = randint(0, 2 ** 10 - 1)
    color = randint(0, 2 ** 16 - 1)
    return [abs, x, y, width, height, color]


mem = []
for i in range(64):
    mem += generate_rect()

with open("rects.txt", 'w') as file:
    file.write("\n".join([str(e) for e in mem]) + "\n")


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
    x = 0
    y = 0
    dut.x_coord.value = x
    dut.y_coord.value = y
    for _ in range(256):
        await RisingEdge(dut.clk)
        x += 1
        dut.x_coord.value = x
        dut.y_coord.value = y


async def generate_clock(dut):
    for _ in range(1000):
        dut.clk.value = 0
        await Timer(1, unit='ns')
        dut.clk.value = 1
        await Timer(1, unit='ns')
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
    rect_idx = dut.rect_idx.value
    rect_idx = rect_idx.to_unsigned() if rect_idx.is_resolvable else "xxx"
    
    color = dut.color.value
    color = color.to_unsigned() if color.is_resolvable else "xxx"
    
    string = "reset={reset} state={state} state_new={state_new} " \
    "copy_state={copy_state} copy_state_new={copy_state_new} " \
    "rect_counter={rect_counter} rect_counter_new={rect_counter_new} " \
    "rect_x1_true={rect_x1_true}, rect_y1_true={rect_y1_true} " \
    "rect_idx={rect_idx} color={color} x={x} y={y} " \
    "mem_din={mem_din} copy_start={copy_start} " \
    "rect_lefts={rect_lefts} rect_tops={rect_tops} " \
    "rect_rights={rect_rights} rect_bottoms={rect_bottoms} " \
    "rect_colors={rect_colors}".format(
        reset = int(dut.reset.value),
        state = dut.state.value.to_unsigned(),
        state_new = dut.state_new.value.to_unsigned(),
        copy_state = dut.copy_state.value.to_unsigned(),
        copy_state_new = dut.copy_state_new.value.to_unsigned(),
        rect_counter = dut.rect_counter.value.to_unsigned(),
        rect_counter_new = dut.rect_counter_new.value.to_unsigned(),
        rect_x1_true = dut.rect_x1_true.value.to_signed(),
        rect_y1_true = dut.rect_y1_true.value.to_signed(),
        rect_idx = rect_idx,
        color = color,
        x = dut.x_coord.value,
        y = dut.y_coord.value,
        mem_din = dut.mem_din.value.to_unsigned() if dut.mem_din.value.is_resolvable else "z",
        copy_start = dut.copy_start.value,
        rect_lefts = convert_array(dut.rect_lefts),
        rect_tops = convert_array(dut.rect_tops),
        rect_rights = convert_array(dut.rect_rights),
        rect_bottoms = convert_array(dut.rect_bottoms),
        rect_colors = convert_array(dut.rect_colors),
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

def clamp(val, left=0, right=640):
    if val < left:
        return left
    if val > right:
        return right
    return val

@cocotb.test
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
    
    # cocotb.start_soon(generate_coords(dut))
    # await RisingEdge(dut.clk)
    # await RisingEdge(dut.clk)
    # for i in range(256):
    #     out_color = dut.color.value.to_unsigned()
    #     expected = expected_colors[i]
    #     assert out_color == expected, f"collor mismatch {out_color} != {expected}"
    #     await RisingEdge(dut.clk)

