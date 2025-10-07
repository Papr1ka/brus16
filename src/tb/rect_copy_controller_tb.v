module rect_copy_controller_tb(
    input wire clk,
    input wire reset,
    input wire copy_start
);

parameter DATA_WIDTH = 13;

wire [DATA_WIDTH-1:0] read_addr;
wire [15:0] read_data;
wire [15:0] gpu_data;
wire gpu_reset;

bsram memory(
    .clk(clk),
    .mem_dout_addr(read_addr),
    .mem_dout(read_data)
);

rect_copy_controller controller(
    .clk(clk),
    .reset(reset),
    .copy_start(copy_start),

    .mem_din_addr(read_addr), // data mem, read address
    .mem_din(read_data), // data mem, read data

    .mem_dout(gpu_data) // data mem, write data
);

endmodule
