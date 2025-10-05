import logging

from random import randint

import cocotb
from cocotb.triggers import Timer, RisingEdge


logger = logging.getLogger("test_encoder")
logger.setLevel(logging.DEBUG)



async def generate_clock(dut):
    for _ in range(10000):
        dut.clk.value = 0
        await Timer(1, unit='ns')
        dut.clk.value = 1
        await Timer(1, unit='ns')


@cocotb.test(skip=False)
async def test_encoder(dut):
    cocotb.start_soon(generate_clock(dut))

    dut.flags_in.value = 0
    for j in range(64):
        dut.data_in[j].value = j
    
    await RisingEdge(dut.clk)
    data_out = dut.data_out.value.to_unsigned()
    flag = int(dut.flag_out.value)
    assert flag == 0
    assert data_out == 0

    for i in range(64):
        dut.flags_in.value = (1 << i) + randint(0, (1 << i) - 1)
        for j in range(64):
            dut.data_in[j].value = j
        
        await RisingEdge(dut.clk)
        data_out = dut.data_out.value.to_unsigned()
        flag = int(dut.flag_out.value)
        assert flag == 1
        assert data_out == i
