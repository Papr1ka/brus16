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
    parameter DATA_WIDTH = 64,
    parameter COLLISIONS = 1
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

/* ONLY FOR VERILATOR SIMULATION */
`ifdef SIM
reg [DATA_WIDTH-1:0] data [SIZE-1:0];

always_ff @(posedge clk) begin
    if (we) begin
        data[mem_din_addr] <= mem_din;
    end
    mem_dout <= data[mem_dout_addr];
end
`endif
/* END */


/* FOR GOWIN ONLY */
`ifdef GOWIN
if (COLLISIONS == 1) begin
collisions_bram_SDPB collisions_bram(
    .dout(mem_dout),    //output [63:0] dout
    .clka(clk),         //input clka
    .cea(we),           //input cea
    .reseta(1'b0),      //input reseta
    .clkb(clk),         //input clkb
    .ceb(1'b1),         //input ceb
    .resetb(1'b0),      //input resetb
    .oce(1'b1),         //input oce
    .ada(mem_din_addr), //input [9:0] ada
    .din(mem_din),      //input [63:0] din
    .adb(mem_dout_addr) //input [9:0] adb
);
end else begin
colors_bram_SDPB colors_bram(
    .dout(mem_dout),    //output [15:0] dout
    .clka(clk),         //input clka
    .cea(we),           //input cea
    .reseta(1'b0),      //input reseta
    .clkb(clk),         //input clkb
    .ceb(1'b1),         //input ceb
    .resetb(1'b0),      //input resetb
    .oce(1'b1),         //input oce
    .ada(mem_din_addr), //input [5:0] ada
    .din(mem_din),      //input [15:0] din
    .adb(mem_dout_addr) //input [5:0] adb
);
end
`endif
/* END */

endmodule
