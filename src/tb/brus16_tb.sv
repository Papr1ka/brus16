`timescale 100 ps /100 ps

module brus16_tb;

GSR GSR( .GSRI( 1'b1 ) );

reg clk = 1'b0;

brus16_top brus16_top(
    .clk(clk)
);

always #1 clk = ~clk;

endmodule
