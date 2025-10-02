module priority_encoder64
(
    input pixel_clk,
    input wire [63:0] to_encode,
    output reg [5:0] encoded
);

always @(posedge pixel_clk) begin
    encoded <= 6'b0;
    for (integer i = 0; i < 64; i++) begin
        if (to_encode[i]) begin
            encoded <= 6'(i);
        end
    end
end

endmodule
