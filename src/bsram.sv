/*
    1*READ 1*WRITE sync memory
    intended to be implemented as block ram
    sync read, sync write
*/

`include "constants.svh"


module bsram
#(
    parameter WIDTH = `DATA_ADDR_WIDTH,
    parameter SIZE  = `DATA_SIZE
)
(
    input  wire             clk,
    // read
    input  wire [WIDTH-1:0] mem_dout_addr,
    output reg [15:0]       mem_dout,
    // write
    input  wire             we,
    input  wire [WIDTH-1:0] mem_din_addr,
    input  wire [15:0]      mem_din
);

/* ONLY FOR VERILATOR SIMULATION */
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
    $readmemh("data.txt", data);
end
`endif
/* END */

/* ONLY FOR GOWIN */
`ifdef GOWIN
Gowin_SDPB SDPB(
    .dout(mem_dout),    //output [15:0] dout
    .clka(clk),         //input clka
    .cea(we),           //input cea
    .clkb(clk),         //input clkb
    .ceb(1'b1),         //input ceb

`ifdef TP25k
   .reset(1'b0),       //input reset
`endif
`ifdef TN20K
    .reseta(1'b0),
    .resetb(1'b0),
`endif

    .oce(1'b1),         //input oce
    .ada(mem_din_addr), //input [12:0] ada
    .din(mem_din),      //input [15:0] din
    .adb(mem_dout_addr) //input [12:0] adb
);

`endif
/* END */

/* ONLY FOR VIVADO */
`ifdef VIVADO
memory mem(
    .clka(clk),
    .ena(1'b1),
    .wea(we),
    .addra(mem_din_addr),
    .dina(mem_din),
    .clkb(clk),
    .enb(1'b1),
    .addrb(mem_dout_addr),
    .doutb(mem_dout)
);
`endif
/* END */

endmodule
