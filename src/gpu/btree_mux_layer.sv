/*
    Binary tree mux layer (INPUT_COUNT X INPUT_COUNT/2) (read gpu)
*/

`include "constants.svh"


module btree_mux_layer
#(
    parameter INPUT_COUNT = `RECT_COUNT,
    parameter INPUT_WIDTH = `RECT_COUNT_WIDTH
)
(
    input wire [INPUT_COUNT-1:0] flags_in, // mux control
    input wire [INPUT_WIDTH-1:0] data_in [INPUT_COUNT-1:0], // mux data

    output logic [INPUT_COUNT/2-1:0] flags_out, // any control?
    output logic [INPUT_WIDTH-1:0] data_out [INPUT_COUNT/2-1:0] // mux output
);

localparam OUT_COUNT = INPUT_COUNT / 2;

always_comb begin
    for (integer i = 0; i < OUT_COUNT; i++) begin
        data_out[i] = flags_in[i*2+1] ? data_in[i*2+1] : data_in[i*2];
        flags_out[i] = flags_in[i*2+1] | flags_in[i*2];
    end
end

endmodule
