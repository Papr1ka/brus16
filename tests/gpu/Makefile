# Makefile

# defaults
SIM ?= icarus
TOPLEVEL_LANG ?= verilog

# sources
VERILOG_SOURCES += ../../src/gpu/btree_mux_layer.sv
VERILOG_SOURCES += ../../src/gpu/btree_mux.sv
VERILOG_SOURCES += ../../src/gpu/comparator.sv
VERILOG_SOURCES += ../../src/gpu/gpu_mem.sv
VERILOG_SOURCES += ../../src/gpu/gpu_receiver_fsm.sv
VERILOG_SOURCES += ../../src/gpu/gpu.sv

VERILOG_INCLUDE_DIRS += ../../src/

# COCOTB_TOPLEVEL is the name of the toplevel module in your Verilog or VHDL file
COCOTB_TOPLEVEL = gpu

# COCOTB_TEST_MODULES is the basename of the Python test file(s)
COCOTB_TEST_MODULES = test_gpu

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim
