# Makefile

# defaults
SIM ?= icarus
TOPLEVEL_LANG ?= verilog

# sources
VERILOG_SOURCES += ../../src/sfx/sfx_mem.sv
VERILOG_SOURCES += ../../src/sfx/sine_table.sv
VERILOG_SOURCES += ../../src/sfx/sfx_top.sv
VERILOG_SOURCES += ../../src/sfx/sfx_dma.sv
VERILOG_SOURCES += ../../src/sfx/sfx_controller.sv
VERILOG_SOURCES += ../../src/sfx/sfx_process.sv
VERILOG_SOURCES += ../../src/constants.svh
VERILOG_SOURCES += ../../src/data_memory.sv
VERILOG_SOURCES += ../../src/tb/sfx_tb.sv

VERILOG_INCLUDE_DIRS += ../../src/

# COCOTB_TOPLEVEL is the name of the toplevel module in your Verilog or VHDL file
COCOTB_TOPLEVEL = sfx_tb

# COCOTB_TEST_MODULES is the basename of the Python test file(s)
COCOTB_TEST_MODULES = test_sfx

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim
