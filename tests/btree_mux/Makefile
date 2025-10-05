# Makefile

# defaults
SIM ?= icarus
TOPLEVEL_LANG ?= verilog

VERILOG_SOURCES += ../../src/btree_mux_layer.v
VERILOG_SOURCES += ../../src/btree_mux.v
# use VHDL_SOURCES for VHDL files

# COCOTB_TOPLEVEL is the name of the toplevel module in your Verilog or VHDL file
COCOTB_TOPLEVEL = btree_mux

# COCOTB_TEST_MODULES is the basename of the Python test file(s)
COCOTB_TEST_MODULES = test_btree_mux

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim

