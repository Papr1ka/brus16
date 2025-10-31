/*
    N*READ 1*WRITE memory
    async read, sync write
    There is no reset, because the memory is completely rewritten before use
*/

`include "constants.svh"


module gpu_buffer
#(
    parameter ADDR_WIDTH    = 4,
    parameter SIZE          = 16,
    parameter DATA_WIDTH    = 16
)
(
    input   wire                    clk,
    // write
    input   wire                    we,
    input   wire [ADDR_WIDTH-1:0]   mem_din_addr,
    input   wire [DATA_WIDTH-1:0]   mem_din,

    // read
    output  wire [DATA_WIDTH-1:0]   dout [SIZE-1:0]
);

reg [DATA_WIDTH-1:0] data [SIZE-1:0];

always @(posedge clk) begin
    if (we) begin
        data[mem_din_addr] <= mem_din;
    end
end

assign dout = data; // async read

endmodule
