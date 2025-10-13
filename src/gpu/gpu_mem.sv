/*
    64*READ 1*WRITE memory
    intended to be implemented as distributed ram
    async read, sync write
*/

`include "constants.svh"


module gpu_mem
#(
    parameter ADDR_WIDTH = `RECT_COUNT_WIDTH,
    parameter SIZE = `RECT_COUNT,
    parameter DATA_WIDTH = 16
)
(
    input wire clk,
    // write
    input wire we,
    input wire [ADDR_WIDTH-1:0] mem_din_addr,
    input wire [DATA_WIDTH-1:0] mem_din,

    // read
    output wire [DATA_WIDTH-1:0] dout [SIZE-1:0]
);

reg [DATA_WIDTH-1:0] data [SIZE-1:0];

always @(posedge clk) begin
    if (we) begin
        data[mem_din_addr] <= mem_din;
    end
end

assign dout = data; // async read

initial begin
    for (integer i = 0; i < SIZE; i = i + 1) begin
        data[i] = DATA_WIDTH'(0);
    end
end


endmodule
