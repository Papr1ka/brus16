/*
    1*READ 1*WRITE sync memory
    intended to be implemented as block ram
    sync read, sync write
*/

`include "constants.svh"


module gpu_bram
#(
    parameter ADDR_WIDTH = 10,
    parameter SIZE       = 1024,
    parameter DATA_WIDTH = 64
)
(
    input  wire                  clk,
    // read
    input  wire [ADDR_WIDTH-1:0] mem_dout_addr,
    output reg  [DATA_WIDTH-1:0] mem_dout,
    // write
    input  wire                  we,
    input  wire [ADDR_WIDTH-1:0] mem_din_addr,
    input  wire [DATA_WIDTH-1:0] mem_din
);

reg [DATA_WIDTH-1:0] data [SIZE-1:0];

always_ff @(posedge clk) begin
    if (we) begin
        data[mem_din_addr] <= mem_din;
    end
    mem_dout <= data[mem_dout_addr];
end

endmodule
