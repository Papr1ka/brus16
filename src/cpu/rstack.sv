/*
    1*READ 1*WRITE return stack
    small in size
    async read, sync write
*/

`include "constants.svh"


module rstack
#(
    parameter WIDTH         = 4,
    parameter SIZE          = 16,
    parameter DATA_WIDTH    = 13
)
(
    input   wire                    clk,

    // read
    input   wire [WIDTH-1:0]        mem_dout_addr,
    output  wire [DATA_WIDTH-1:0]   mem_dout,
    
    // write
    input   wire                    we,
    input   wire [WIDTH-1:0]        mem_din_addr,
    input   wire [DATA_WIDTH-1:0]   mem_din
);

reg [DATA_WIDTH-1:0] data [SIZE-1:0];

always @(posedge clk) begin
    if (we) begin
        data[mem_din_addr] <= mem_din;
    end
end

assign mem_dout = data[mem_dout_addr]; // async read

/* ONLY FOR VERILATOR SIMULATION */
`ifdef SIM 
initial begin
    for (integer i = 0; i < SIZE; i = i + 1) begin
        data[i] = DATA_WIDTH'(0);
    end
end
`endif
/* END */


// /* GOWIN ONLY */
// `ifdef GOWIN
// rstack_ssram rstack(
//     .dout(mem_dout), //output [15:0] dout
//     .di(mem_din), //input [15:0] di
//     .wad(mem_din_addr), //input [3:0] wad
//     .rad(mem_dout_addr), //input [3:0] rad
//     .wre(we), //input wre
//     .clk(clk) //input clk
// );
// `endif
// /* END */

endmodule
