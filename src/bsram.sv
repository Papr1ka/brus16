/*
    1*READ 1*WRITE sync memory
    intended to be implemented as block ram
    sync read, sync write
*/

`include "constants.svh"


module bsram
#(
    parameter WIDTH = `DATA_ADDR_WIDTH,
    parameter SIZE = `DATA_SIZE
)
(
    input wire clk,

    // read
    input wire [WIDTH-1:0] mem_dout_addr,
    output reg [15:0] mem_dout,
    
    // write
    input wire we,
    input wire [WIDTH-1:0] mem_din_addr,
    input wire [15:0] mem_din
) /*synthesis syn_ramstyle="block_ram"*/;

`ifdef SIM

reg [15:0] data [SIZE-1:0];

always_ff @(posedge clk) begin
    if (we) begin
        data[mem_din_addr] <= mem_din;
    end
    mem_dout <= data[mem_dout_addr];
end

initial begin
    for (integer i = 0; i < SIZE; i = i + 1) begin
        data[i] = 16'b0;
    end
    // game data
    $readmemh("data.txt", data);
end
`endif

`ifdef GOWIN

Gowin_SDPB SDPB(
    .dout(mem_dout), //output [15:0] dout
    .clka(clk), //input clka
    .cea(we), //input cea
    .reseta(1'b0), //input reseta
    .clkb(clk), //input clkb
    .ceb(1'b1), //input ceb
    .resetb(1'b0), //input resetb
    .oce(1'b1), //input oce
    .ada(mem_din_addr), //input [12:0] ada
    .din(mem_din), //input [15:0] din
    .adb(mem_dout_addr) //input [12:0] adb
);

`endif

endmodule
