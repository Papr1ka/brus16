add_file -type verilog "../src/brus16_controller.sv"
add_file -type verilog "../src/brus16_top.sv"
add_file -type verilog "../src/buttons/button_controller.sv"
add_file -type verilog "../src/buttons/buttons_top.sv"
add_file -type verilog "../src/buttons/dualshock_spi_master.sv"
add_file -type verilog "../src/cpu/alu.sv"
add_file -type verilog "../src/cpu/cpu.sv"
add_file -type verilog "../src/cpu/rstack.sv"
add_file -type verilog "../src/cpu/stack.sv"
add_file -type verilog "../src/data_memory.sv"
add_file -type verilog "../src/gpu/btree_mux.sv"
add_file -type verilog "../src/gpu/btree_mux_layer.sv"
add_file -type verilog "../src/gpu/comparator.sv"
add_file -type verilog "../src/gpu/gpu.sv"
add_file -type verilog "../src/gpu/gpu_bram.sv"
add_file -type verilog "../src/gpu/gpu_buffer.sv"
add_file -type verilog "../src/gpu/gpu_receiver_fsm.sv"
add_file -type verilog "../src/gpu/gpu_top.sv"
add_file -type verilog "../src/gpu/rect_copy_controller.sv"
add_file -type verilog "../src/hdmi/audio_clock_regeneration_packet.sv"
add_file -type verilog "../src/hdmi/audio_info_frame.sv"
add_file -type verilog "../src/hdmi/audio_sample_packet.sv"
add_file -type verilog "../src/hdmi/auxiliary_video_information_info_frame.sv"
add_file -type verilog "../src/hdmi/hdmi.sv"
add_file -type verilog "../src/hdmi/packet_assembler.sv"
add_file -type verilog "../src/hdmi/packet_picker.sv"
add_file -type verilog "../src/hdmi/serializer.sv"
add_file -type verilog "../src/hdmi/source_product_description_info_frame.sv"
add_file -type verilog "../src/hdmi/tmds_channel.sv"
add_file -type verilog "../src/pll_generic.sv"
add_file -type verilog "../src/program_memory.sv"
add_file -type verilog "../src/sfx/sfx_controller.sv"
add_file -type verilog "../src/sfx/sfx_dma.sv"
add_file -type verilog "../src/sfx/sfx_mem.sv"
add_file -type verilog "../src/sfx/sfx_process.sv"
add_file -type verilog "../src/sfx/sfx_top.sv"
add_file -type verilog "../src/sfx/sine_table.sv"
add_file -type verilog "../src/vga_controller.sv"
add_file -type verilog "../src/control_core/control_core.sv"
add_file -type verilog "../src/control_core/spi_master.sv"
add_file -type verilog "../src/control_core/uart_loader.sv"
add_file -type verilog "../src/control_core/uart.sv"

add_file -type verilog "src/tn9k/gowin_clkdiv/gowin_clkdiv.v"
add_file -type verilog "src/tn9k/gowin_rpll/gowin_rpll.v"
add_file -type cst "src/tn9k/9k.cst"
add_file -type sdc "src/tn9k/9k.sdc"

add_file -type other "../firm/code.hex"
add_file -type other "../firm/data.hex"
add_file -type other "../firm/sine.hex"
add_file -type other "../src/constants.svh"

set_device GW1NR-LV9QN88PC6/I5 -device_version C
set_option -synthesis_tool gowinsynthesis
set_option -output_base_name tn9k
set_option -top_module brus16_top
set_option -include_path {"../src"}
set_option -verilog_std sysv2017
set_option -looplimit 10000
set_option -maxfan 10000
set_option -use_sspi_as_gpio 1

run all
