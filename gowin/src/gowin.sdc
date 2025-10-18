//Copyright (C)2014-2025 GOWIN Semiconductor Corporation.
//All rights reserved.
//File Title: Timing Constraints file
//Tool Version: V1.9.11.03 Education 
//Created Time: 2025-10-17 16:56:42
create_clock -name clk -period 37.037 -waveform {0 18.518} [get_ports {clk}]
create_generated_clock -name vga_x5 -source [get_ports {clk}] -master_clock clk -divide_by 3 -multiply_by 14 [get_nets {vga_x5}]
create_generated_clock -name system_clk -source [get_nets {vga_x5}] -master_clock vga_x5 -divide_by 5 [get_nets {system_clk}]
report_max_frequency -mod_ins {cpu cpu/alu cpu/rstack cpu/stack memory program_memory}
