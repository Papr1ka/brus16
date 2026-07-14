# Makefile

# defaults
SIM ?= icarus
TOPLEVEL_LANG ?= verilog

# sources
VERILOG_SOURCES += ../../src/buttons/buttons_top.sv

VERILOG_SOURCES += ../../src/cpu/alu.sv
VERILOG_SOURCES += ../../src/cpu/cpu.sv
VERILOG_SOURCES += ../../src/cpu/rstack.sv
VERILOG_SOURCES += ../../src/cpu/stack.sv

VERILOG_SOURCES += ../../src/gpu/btree_mux_layer.sv
VERILOG_SOURCES += ../../src/gpu/btree_mux.sv
VERILOG_SOURCES += ../../src/gpu/comparator.sv
VERILOG_SOURCES += ../../src/gpu/gpu_buffer.sv
VERILOG_SOURCES += ../../src/gpu/gpu_bram.sv
VERILOG_SOURCES += ../../src/gpu/gpu_receiver_fsm.sv
VERILOG_SOURCES += ../../src/gpu/gpu.sv
VERILOG_SOURCES += ../../src/gpu/gpu_top.sv
VERILOG_SOURCES += ../../src/gpu/rect_copy_controller.sv

VERILOG_SOURCES += ../../src/sfx/sfx_controller.sv
VERILOG_SOURCES += ../../src/sfx/sfx_dma.sv
VERILOG_SOURCES += ../../src/sfx/sfx_mem.sv
VERILOG_SOURCES += ../../src/sfx/sfx_process.sv
VERILOG_SOURCES += ../../src/sfx/sfx_top.sv
VERILOG_SOURCES += ../../src/sfx/sine_table.sv

VERILOG_SOURCES += ../../src/brus16_controller.sv
VERILOG_SOURCES += ../../src/brus16_top.sv
VERILOG_SOURCES += ../../src/data_memory.sv
VERILOG_SOURCES += ../../src/program_memory.sv
VERILOG_SOURCES += ../../src/vga_controller.sv
VERILOG_SOURCES += ../../src/pll_generic.sv

VERILOG_INCLUDE_DIRS += ../../src/

# COCOTB_TOPLEVEL is the name of the toplevel module in your Verilog or VHDL file
COCOTB_TOPLEVEL = brus16_top

# COCOTB_TEST_MODULES is the basename of the Python test file(s)
COCOTB_TEST_MODULES = test_brus16

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim
