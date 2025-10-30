module clamp(
    input  wire [15:0] coord;
    input  wire mode,
    output wire [9:0] clamped
);

wire [15:0] constant = (mode ? 16'd640 : 16'd480);
wire gte = $signed(coord >= constant);

always_comb begin
    casez ({coord[15], gte}) // >= 640
        2'b1?:    clamped = 0;
        2'b01:    clamped = constant[9:0];
        default:  clamped = coord[9:0];
    endcase
end

endmodule
