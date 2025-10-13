/*
    1*READ 1*WRITE return stack
    intended to be implemented as distributed ram
    small in size
    async read, sync write
*/

module rstack
#(
    parameter WIDTH = 13,
    parameter SIZE = 8192,
    parameter DATA_WIDTH = 16
)
(
    input wire clk,

    // read
    input wire [WIDTH-1:0] mem_dout_addr,
    output wire [DATA_WIDTH-1:0] mem_dout,
    
    // write
    input wire we,
    input wire [WIDTH-1:0] mem_din_addr,
    input wire [DATA_WIDTH-1:0] mem_din
);

reg [DATA_WIDTH-1:0] data [SIZE-1:0];

always @(posedge clk) begin
    if (we) begin
        data[mem_din_addr] <= mem_din;
    end
end

assign mem_dout = data[mem_dout_addr]; // async read

initial begin
    for (integer i = 0; i < SIZE; i = i + 1) begin
        data[i] = DATA_WIDTH'(0);
    end
end


endmodule
