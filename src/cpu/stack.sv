/*
    2*READ 1*WRITE stack
    small in size
    async read, sync write
*/

`include "constants.svh"


module stack
#(
    parameter WIDTH = 5, // pointer width
    parameter SIZE  = 32
)
(
    input wire clk,

    // read 0
    input wire [WIDTH-1:0] mem_dout_addr0,
    output wire [15:0] mem_dout0,

    // read 1
    input wire [WIDTH-1:0] mem_dout_addr1,
    output wire [15:0] mem_dout1,
    
    // write
    input wire we,
    input wire [WIDTH-1:0] mem_din_addr,
    input wire [15:0] mem_din
) /* synthesis syn_ramstyle = "distributed_ram" */;

reg [15:0] data [SIZE-1:0];

always @(posedge clk) begin
    if (we) begin
        data[mem_din_addr] <= mem_din;
    end
end

assign mem_dout0 = data[mem_dout_addr0]; // async read port 0
assign mem_dout1 = data[mem_dout_addr1]; // async read port 1

/* ONLY FOR VERILATOR SIMULATION */
`ifdef SIM
initial begin
    for (integer i = 0; i < SIZE; i = i + 1) begin
        data[i] = 16'b0;
    end
end
`endif
/* END */


// /* GOWIN ONLY */
// `ifdef GOWIN
// wire [31:0] dout;
// assign mem_dout1 = dout[31:16];
// assign mem_dout0 = dout[15:0];

// stack_ssram stack(
//     .dout(dout), //output [31:0] dout
//     .wre(we), //input wre
//     .wad(mem_din_addr), //input [4:0] wad
//     .di({mem_din, 16'b0}), //input [31:0] di
//     .rad(mem_dout_addr1), //input [4:0] rad
//     .clk(clk) //input clk
// );
// `endif
// /* END */

endmodule
