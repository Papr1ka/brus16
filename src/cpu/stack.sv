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
);

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

endmodule
