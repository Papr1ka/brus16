/*
    1*READ 1*WRITE sync memory
    intended to be implemented as block ram
    sync read, sync write
*/
module bsram
#(
    parameter WIDTH = 13,
    parameter SIZE = 8192
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
);

reg [15:0] data [SIZE-1:0];

always @(posedge clk) begin
    if (we) begin
        data[mem_din_addr] <= mem_din;
    end
    mem_dout <= data[mem_dout_addr];
end

initial begin
    for (integer i = 0; i < SIZE; i = i + 1) begin
        data[i] = 16'b0;
    end
end


endmodule
