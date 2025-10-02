--binary
./src/comparator.v
./src/priority_encoder64.v
./src/example_rom_gpu.v
./src/gpu.v
./src/gpu_tb.v
--top gpu_tb
-Wall
-j 0
-Wno-fatal
