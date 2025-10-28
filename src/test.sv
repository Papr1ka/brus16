module test(
    input  wire [63:0] a,
    output wire [63:0] b
);

assign b = a & (-a);

endmodule
