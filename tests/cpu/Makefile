# Makefile

# defaults
SIM ?= icarus
TOPLEVEL_LANG ?= verilog

# sources
VERILOG_SOURCES += ../../src/cpu/alu.sv
VERILOG_SOURCES += ../../src/cpu/rstack.sv
VERILOG_SOURCES += ../../src/cpu/stack.sv
VERILOG_SOURCES += ../../src/cpu/cpu.sv
VERILOG_SOURCES += ../../src/bsram.sv
VERILOG_SOURCES += ../../src/tb/cpu_tb.sv

VERILOG_INCLUDE_DIRS += ../../src/

# COCOTB_TOPLEVEL is the name of the toplevel module in your Verilog or VHDL file
COCOTB_TOPLEVEL = cpu_tb

# COCOTB_TEST_MODULES is the basename of the Python test file(s)
COCOTB_TEST_MODULES = test_cpu

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim
