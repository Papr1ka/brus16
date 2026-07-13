module sfx_tb(
    input wire clk,
    input wire reset,
    input wire copy,
    input wire copy_pulse
);

wire [15:0] read_addr;
wire [15:0] read_data;
wire [15:0] sample_out;

/* verilator lint_off WIDTHTRUNC */
/* verilator lint_off PINMISSING */
data_memory memory(
    .clk(clk),
    .mem_addr_1(read_addr),
    .mem_dout_1(read_data)
);
/* verilator lint_on WIDTHTRUNC */
/* verilator lint_on PINMISSING */

sfx_top sfx(
    .clk(clk),
    .reset(reset),
    .copy(copy),
    .copy_pulse(copy_pulse),

    .mem_din_addr(read_addr),
    .mem_din(read_data),

    .sample_out(sample_out)
);

endmodule
