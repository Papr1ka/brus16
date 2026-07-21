--cc --exe simulator.cpp
./src/buttons/button_controller.sv
./src/buttons/buttons_top.sv
./src/buttons/dualshock_spi_master.sv

./src/cpu/alu.sv
./src/cpu/cpu.sv
./src/cpu/rstack.sv
./src/cpu/stack.sv

./src/gpu/btree_mux_layer.sv
./src/gpu/btree_mux.sv
./src/gpu/comparator.sv
./src/gpu/gpu_bram.sv
./src/gpu/gpu_buffer.sv
./src/gpu/gpu_receiver_fsm.sv
./src/gpu/rect_copy_controller.sv
./src/gpu/gpu.sv
./src/gpu/gpu_top.sv

./src/sfx/sfx_controller.sv
./src/sfx/sfx_dma.sv
./src/sfx/sfx_mem.sv
./src/sfx/sfx_process.sv
./src/sfx/sfx_top.sv
./src/sfx/sine_table.sv

./src/brus16_controller.sv
./src/brus16_top.sv
./src/data_memory.sv
./src/program_memory.sv
./src/vga_controller.sv
./src/pll_generic.sv

./src/control_core/control_core.sv
./src/control_core/spi_master.sv
./src/control_core/uart_loader.sv
./src/control_core/uart.sv

--top brus16_top
-Wall
--trace-vcd
-LDFLAGS -lglut -LDFLAGS -lGLU -LDFLAGS -lGL
-Wno-fatal
-I./src/
