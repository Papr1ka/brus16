# Makefile

# defaults
SIM ?= icarus
TOPLEVEL_LANG ?= verilog

VERILOG_SOURCES += ../../src/defs.vh
VERILOG_SOURCES += ../../src/alu.v
VERILOG_SOURCES += ../../src/dsram.v
VERILOG_SOURCES += ../../src/bsram.v
VERILOG_SOURCES += ../../src/stack.v
VERILOG_SOURCES += ../../src/cpu.v
VERILOG_SOURCES += ../../src/tb/cpu_tb.v
# use VHDL_SOURCES for VHDL files

# COCOTB_TOPLEVEL is the name of the toplevel module in your Verilog or VHDL file
COCOTB_TOPLEVEL = cpu_tb

# COCOTB_TEST_MODULES is the basename of the Python test file(s)
COCOTB_TEST_MODULES = test_cpu

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim

