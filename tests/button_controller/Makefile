# Makefile

# defaults
SIM ?= icarus
TOPLEVEL_LANG ?= verilog

# sources
VERILOG_SOURCES += ../../src/button_handler.sv
VERILOG_SOURCES += ../../src/button_controller.sv

VERILOG_INCLUDE_DIRS += ../../src/

# COCOTB_TOPLEVEL is the name of the toplevel module in your Verilog or VHDL file
COCOTB_TOPLEVEL = button_controller

# COCOTB_TEST_MODULES is the basename of the Python test file(s)
COCOTB_TEST_MODULES = test_button_controller

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim
