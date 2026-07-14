import logging
import os
from random import randint, seed
from itertools import batched

seed(42)

import cocotb
from cocotb.triggers import Timer, RisingEdge, FallingEdge
from cocotb.types import Logic

os.makedirs("./logs", exist_ok=True)
logger = logging.getLogger("test_sfx")
logger.setLevel(logging.DEBUG)
fh = logging.FileHandler("./logs/test_sfx.log")
fh.setLevel(logging.DEBUG)
logger.addHandler(fh)


async def generate_clock(dut):
    for i in range(120000):
        dut.clk.value = 0
        await Timer(1, unit='ns')
        dut.clk.value = 1
        await Timer(1, unit='ns')
        if i > 0:
            log_debug(dut)

def signed(logic_array, placeholder=-99999):
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

def to_list(regfile, length=17, bits=16):
    array = []
    packed_array = regfile.value
    for i in range(length, 0, -1):
        val = unsigned(packed_array[i * bits - 1: (i - 1) * bits])
        array.append(val)
    return array

def log_debug(dut):
    string = "" \
    "amp=[{amp}]\ntarget_amp=[{target_amp}]\ndecay=[{decay}]\nstep=[{step}]\nphase=[{phase}]\n" \
    "curr_amp=[{curr_amp}] curr_target_amp=[{curr_target_amp}] curr_decay=[{curr_decay}] curr_step=[{curr_step}] curr_phase=[{curr_phase}] \n" \
    "din_addr={din_addr} din={din} state={state} reading_abs={reading_abs} abs_amp={abs_amp} abs_step={abs_step}\n" \
    "shift={shift} mem_din={mem_din} mem_din_addr={mem_din_addr} mem_din_we={mem_din_we}\n" \
    "sample={sample} sample_out={sample_out} sample_valid={sample_valid} stage_counter={stage_counter} acc={acc} acc_diff={acc_diff} decay_counter={decay_counter} shift_counter={shift_counter} phase_upd={phase_upd} target_amp_upd={target_amp_upd} amp_upd={amp_upd} pos={pos} sine_wave={sine_wave}\n" \
    "reset={reset} copy={copy} sample_counter={sample_counter} process_en={process_en} dma_start={dma_start}\n\n".format(
        amp=to_list(dut.sfx.sfx_mem.amp),
        target_amp=to_list(dut.sfx.sfx_mem.target_amp),
        decay=to_list(dut.sfx.sfx_mem.decay),
        step=to_list(dut.sfx.sfx_mem.step),
        phase=to_list(dut.sfx.sfx_mem.phase),

        curr_amp=unsigned(dut.sfx.curr_amp.value),
        curr_target_amp=unsigned(dut.sfx.curr_target_amp.value),
        curr_decay=unsigned(dut.sfx.curr_decay.value),
        curr_step=unsigned(dut.sfx.curr_step.value),
        curr_phase=unsigned(dut.sfx.curr_phase.value),

        din_addr=unsigned(dut.sfx.sfx_dma.mem_din_addr.value),
        din=unsigned(dut.sfx.sfx_dma.mem_din.value),
        state=unsigned(dut.sfx.sfx_dma.state.value),
        reading_abs=unsigned(dut.sfx.sfx_dma.reading_abs.value),
        abs_amp=unsigned(dut.sfx.sfx_dma.abs_amp.value),
        abs_step=unsigned(dut.sfx.sfx_dma.abs_step.value),

        shift=int(dut.sfx.sfx_shift.value),
        mem_din=unsigned(dut.sfx.sfx_mem_din.value),
        mem_din_addr=unsigned(dut.sfx.sfx_mem_din_addr.value),
        mem_din_we=int(dut.sfx.sfx_mem_din_we.value),

        sample=signed(dut.sfx.sample.value),
        sample_out=signed(dut.sfx.sample_out.value),
        sample_valid=int(dut.sfx.sample_valid.value),
        stage_counter=unsigned(dut.sfx.sfx_process.stage_counter.value),
        acc=signed(dut.sfx.sfx_process.acc.value),
        acc_diff=signed(dut.sfx.sfx_process.acc_diff.value),
        decay_counter=unsigned(dut.sfx.sfx_process.decay_counter.value),
        shift_counter=unsigned(dut.sfx.sfx_process.shift_counter.value),

        phase_upd=unsigned(dut.sfx.sfx_process.curr_phase_updated.value),
        target_amp_upd=unsigned(dut.sfx.sfx_process.curr_target_amp_updated.value),
        amp_upd=unsigned(dut.sfx.sfx_process.curr_amp_updated.value),

        pos=unsigned(dut.sfx.sfx_process.pos.value),
        sine_wave=signed(dut.sfx.sfx_process.sin_wave.value) / 32768,

        copy=int(dut.copy.value),
        reset=int(dut.reset.value),
        sample_counter=unsigned(dut.sfx.sfx_controller.sample_counter.value),
        process_en=int(dut.sfx.process_en.value),
        dma_start=int(dut.sfx.dma_start.value),
    )
    logger.debug(string)

import math

SR = 44100
TABLE_SIZE = 1024
TABLE_BITS = 6
AMP_BITS = 15
RATIO_BITS = 10
DECAY_BITS = 6
DECAY_SCALE = 64
VOICES_NUM = 16

def get_amp(val):
    return min(round(val * 32768), 65535)

def get_period(freq):
    return min(round((TABLE_SIZE * freq / SR) * (1 << TABLE_BITS)), 65535)

def get_decay(sec):
    steps = (sec * SR) / DECAY_SCALE
    k = math.exp(math.log(0.01) / steps)
    return round(k * 32768)

def get_ratio(x):
    return min(round(x * (1 << RATIO_BITS)), 65535)


voices = [
    [1, get_amp(0.8), get_decay(2.5), get_period(440)],
    [0, get_ratio(0.6), get_decay(1.8), get_ratio(2.002)],
    [0, get_ratio(0.4), get_decay(1.4), get_ratio(3.005)],
    [0, get_ratio(0.3), get_decay(1.0), get_ratio(4.01)],
    [0, get_ratio(0.2), get_decay(0.8), get_ratio(5.02)],
    [0, get_ratio(0.15), get_decay(0.5), get_ratio(6.03)],
    [0, get_ratio(0.1), get_decay(0.3), get_ratio(7.05)],
    [0, get_ratio(0.1), get_decay(0.1), get_ratio(12.1)],
    
    [1, get_amp(0.5), get_decay(2000), get_period(110)],
    [0, get_ratio(1), get_decay(2000), get_ratio(0.5)],
    [0, get_ratio(1), get_decay(2000), get_ratio(2)],
    [0, get_ratio(1), get_decay(2000), get_ratio(3)],

    [1, get_amp(0.5), get_decay(2000), get_period(110)],
    [0, get_ratio(1), get_decay(2000), get_ratio(0.5)],
    [0, get_ratio(1), get_decay(2000), get_ratio(2)],
    [0, get_ratio(1), get_decay(2000), get_ratio(3)],
]

target_amps = [0] * 16
periods = [0] * 16
amps = [0] * 16
phases = [0] * 16
decay_counter = 0

def update_params(voices, target_amps, periods):
    master_amp = 0
    master_period = 0    
    for i in range(VOICES_NUM):
        is_master, amp, _, period = voices[i]
        if is_master:
            master_amp = amp
            master_period = period
        else:
            period = (master_period * period) >> RATIO_BITS
            amp = (master_amp * amp) >> RATIO_BITS
        if amp:
            target_amps[i] = amp
        periods[i] = period

def update_audio(voices, target_amps, amps, phases, periods, is_decay):
    acc = 0
    for v in range(VOICES_NUM):
        _, _, decay, _ = voices[v]
        amps[v] += (target_amps[v] - amps[v]) >> DECAY_BITS
        index = (phases[v] >> TABLE_BITS) & (TABLE_SIZE - 1)
        val = sine_table[index]
        acc += (val * amps[v]) >> AMP_BITS
        phases[v] = (phases[v] + periods[v]) & 0xffff
        if is_decay:
            target_amps[v] = (target_amps[v] * decay) >> AMP_BITS
    return min(max(acc, -32768), 32767)

def make_sine_table(size):
    table = []
    for i in range(size):
        phase = (2 * math.pi * i) / size
        table.append(round(32767 * math.sin(phase)))
    return table

sine_table = make_sine_table(TABLE_SIZE)

update_params(voices, target_amps, periods)

def project(array, i):
    return [e[i] for e in array]

sfx_mem = [
    (amp, target_amp, decay, step, phase) for amp, target_amp, decay, step, phase in zip(
        [0] * 16, target_amps, project(voices, 2), periods, [0] * 16
    )
]

from pprint import pformat

@cocotb.test(skip=False)
async def test_sfx(dut):
    global decay_counter, target_amps, periods
    logger.debug(pformat(sfx_mem) + "\n")

    # setup OSC data
    i = 0
    for voice in voices:
        dut.memory.data[7728 + i + 0].value = voice[0]
        dut.memory.data[7728 + i + 1].value = voice[3]
        dut.memory.data[7728 + i + 2].value = voice[1]
        dut.memory.data[7728 + i + 3].value = voice[2]
        i += 4

    logger.debug("STATE:\n" \
            "target_amps={target_amps}\n" \
            "periods={periods}\n" \
            "amps={amps}\n" \
            "phases={phases}\n" \
            "decays={decays}\n" \
            "decay_counter={decay_counter}\n".format(
                target_amps=target_amps,
                periods=periods,
                amps=amps,
                phases=phases,
                decay_counter=decay_counter,
                decays=project(voices, 2),
            ))

    dut.reset.value = 0
    dut.copy.value = 0
    dut.copy_pulse.value = 0

    cocotb.start_soon(generate_clock(dut))

    await RisingEdge(dut.clk)
    dut.reset.value = 1
    await RisingEdge(dut.clk)
    dut.reset.value = 0
    dut.sfx.sfx_controller.sample_counter.value = 200
    dut.sfx.sfx_controller.samples_completed.value = 734

    # idle
    for _ in range(10):
        await RisingEdge(dut.clk)
    
    dut.copy_pulse.value = 1
    await RisingEdge(dut.clk)
    dut.copy_pulse.value = 0
    dut.copy.value = 1
    await RisingEdge(dut.clk)

    # dma work
    for _ in range(200):
        await RisingEdge(dut.clk)
    
    dut.copy.value = 0
    
    dut.sfx.sfx_shift.value = 1
    await RisingEdge(dut.clk)
    logger.debug("HERE!")

    # check sfx_mem after dma work
    for i, expected in enumerate(sfx_mem):
        actual = (
            unsigned(dut.sfx.curr_amp.value),
            unsigned(dut.sfx.curr_target_amp.value),
            unsigned(dut.sfx.curr_decay.value),
            unsigned(dut.sfx.curr_step.value),
            unsigned(dut.sfx.curr_phase.value),
        )
        # amp and phase may be random
        assert actual[1:-1] == expected[1:-1], f"{i}, actual: {actual} != expected: {expected}"
        await RisingEdge(dut.clk)
    
    dut.sfx.sfx_shift.value = 0
    await RisingEdge(dut.clk)

    SAMPLES = 15
    for n_sample in range(SAMPLES):

        sample_counter = unsigned(dut.sfx.sfx_controller.sample_counter.value)
        while sample_counter != 0:
            await RisingEdge(dut.clk)
            sample_counter = unsigned(dut.sfx.sfx_controller.sample_counter.value)

        logger.debug(f"SAMPLE: {n_sample}")

        is_decay = (decay_counter & (DECAY_SCALE - 1)) == 0
        decay_counter += 1
        expected_sample = update_audio(voices, target_amps, amps, phases, periods, is_decay)

        for _ in range(16):
            for i in range(6):
                await RisingEdge(dut.clk)
        
        logger.debug("STATE:\n" \
            "target_amps={target_amps}\n" \
            "periods={periods}\n" \
            "amps={amps}\n" \
            "phases={phases}\n" \
            "decays={decays}\n" \
            "decay_counter={decay_counter}\n".format(
                target_amps=target_amps,
                periods=periods,
                amps=amps,
                phases=phases,
                decay_counter=decay_counter,
                decays=project(voices, 2),
            ))
        await RisingEdge(dut.clk)
        actual_sample = signed(dut.sample_out.value)
        assert actual_sample == expected_sample, f"{n_sample}, actual: {actual_sample} != expected: {expected_sample}"
