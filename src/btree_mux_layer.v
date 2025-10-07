/*
    Binary tree mux layer (INPUT_COUNT X INPUT_COUNT/2) (read gpu)
*/

module btree_mux_layer
#(
    parameter INPUT_COUNT = 64,
    parameter INPUT_WIDTH = 6
)
(
    input wire [INPUT_COUNT-1:0] flags_in, // mux control
    input wire [INPUT_WIDTH-1:0] data_in [INPUT_COUNT-1:0], // mux data

    output reg [INPUT_COUNT/2-1:0] flags_out, // any control?
    output reg [INPUT_WIDTH-1:0] data_out [INPUT_COUNT/2-1:0] // mux output
);

localparam OUT_COUNT = INPUT_COUNT / 2;

always @(*) begin
    for (integer i = 0; i < OUT_COUNT; i++) begin
        data_out[i] = flags_in[i*2+1] ? data_in[i*2+1] : data_in[i*2];
        flags_out[i] = flags_in[i*2+1] | flags_in[i*2];
    end
end

endmodule
