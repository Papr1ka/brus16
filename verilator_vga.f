--cc --exe simulator.cpp
./src/cpu/alu.sv
./src/cpu/cpu.sv
./src/cpu/rstack.sv
./src/cpu/stack.sv

./src/gpu/btree_mux_layer.sv
./src/gpu/btree_mux.sv
./src/gpu/comparator.sv
./src/gpu/gpu_mem.sv
./src/gpu/gpu.sv

./src/brus16_controller.sv
./src/brus16_top.sv
./src/bsram.sv
./src/button_handler.sv
./src/button_controller.sv
./src/rect_copy_controller.sv
./src/vga_controller.sv
--top brus16_top
-Wall
-LDFLAGS -lglut -LDFLAGS -lGLU -LDFLAGS -lGL
-Wno-fatal
-I./src/
