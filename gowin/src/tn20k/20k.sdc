create_clock -name clk -period 37.037 -waveform {0 18.518} [get_ports {clk}]
report_max_frequency -mod_ins {cpu cpu/alu cpu/rstack cpu/stack memory program_memory}
