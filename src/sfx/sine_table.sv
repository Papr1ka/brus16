module sine_table
#(
    parameter WIDTH = 10,
    parameter SIZE  = 1024
)
(
    input  wire             clk,
    // read
    input  wire [WIDTH-1:0] mem_dout_addr,
    output reg  [15:0]      mem_dout
);

reg [15:0] data [SIZE-1:0];

always_ff @(posedge clk) begin
    mem_dout <= data[mem_dout_addr];
end

initial begin
`ifdef SIM
    $readmemh("./firm/sine.hex", data);
`endif
`ifndef SIM
    $readmemh("../firm/sine.hex", data);
`endif
end

endmodule
