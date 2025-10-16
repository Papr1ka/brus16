/*
    1*READ 1*WRITE sync memory
    intended to be implemented as block ram
    sync read, sync write
*/

`include "constants.svh"


module prom
#(
    parameter WIDTH = `CODE_ADDR_WIDTH,
    parameter SIZE = `CODE_SIZE
)
(
    input wire clk,

    // read
    input wire [WIDTH-1:0] mem_dout_addr,
    output reg [15:0] mem_dout
);

`ifdef SIM

reg [15:0] data [SIZE-1:0];

always_ff @(posedge clk) begin
    mem_dout <= data[mem_dout_addr];
end


initial begin
    for (integer i = 0; i < SIZE; i = i + 1) begin
        data[i] = 16'b0;
    end
//     game program
     $readmemh("program.txt", data);
end
`endif

`ifdef GOWIN

Gowin_pROM pROM(
    .dout(mem_dout), //output [15:0] dout
    .clk(clk), //input clk
    .oce(1'b1), //input oce
    .ce(1'b1), //input ce
    .reset(1'b0), //input reset
    .ad(mem_dout_addr) //input [12:0] ad
);

`endif

endmodule
