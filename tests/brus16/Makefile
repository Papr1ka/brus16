# Makefile

# defaults
SIM ?= icarus
TOPLEVEL_LANG ?= verilog

VERILOG_SOURCES += ../../src/alu.v
VERILOG_SOURCES += ../../src/brus16_controller.v
VERILOG_SOURCES += ../../src/brus16_top.v
VERILOG_SOURCES += ../../src/bsram.v
VERILOG_SOURCES += ../../src/btree_mux_layer.v
VERILOG_SOURCES += ../../src/btree_mux.v
VERILOG_SOURCES += ../../src/button_handler.v
VERILOG_SOURCES += ../../src/button_controller.v
VERILOG_SOURCES += ../../src/comparator.v
VERILOG_SOURCES += ../../src/cpu.v
VERILOG_SOURCES += ../../src/dsram.v
VERILOG_SOURCES += ../../src/gpu_mem.v
VERILOG_SOURCES += ../../src/gpu.v
VERILOG_SOURCES += ../../src/rect_copy_controller.v
VERILOG_SOURCES += ../../src/stack.v
VERILOG_SOURCES += ../../src/vga_controller.v
# use VHDL_SOURCES for VHDL files

# COCOTB_TOPLEVEL is the name of the toplevel module in your Verilog or VHDL file
COCOTB_TOPLEVEL = brus16_top

# COCOTB_TEST_MODULES is the basename of the Python test file(s)
COCOTB_TEST_MODULES = test_brus16

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim

