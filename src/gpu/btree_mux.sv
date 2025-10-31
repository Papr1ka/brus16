/*
    binary tree of mux-es
    64x1 (6 layers)
*/

`include "constants.svh"

module btree_mux
#(
    parameter INPUT_COUNT = `RECT_COUNT,
    parameter INPUT_WIDTH = `RECT_COUNT_WIDTH
)
(
    input  wire                   clk,                       // needed for testing
    input  wire [INPUT_COUNT-1:0] flags_in,                  // mux controls
    input  wire [INPUT_WIDTH-1:0] data_in [INPUT_COUNT-1:0], // mux data
    output wire                   flag_out,                  // any mux control ?
    output wire [INPUT_WIDTH-1:0] data_out                   // mux output
);

// layer1 64x32

wire [INPUT_WIDTH-1:0]   layer1_data [INPUT_COUNT/2-1:0];
wire [INPUT_COUNT/2-1:0] layer1_flags;

btree_mux_layer layer1(
    .flags_in(flags_in),
    .data_in(data_in),
    .flags_out(layer1_flags),
    .data_out(layer1_data)
);

// layer2 32x16

wire [INPUT_WIDTH-1:0]   layer2_data [INPUT_COUNT/4-1:0];
wire [INPUT_COUNT/4-1:0] layer2_flags;

btree_mux_layer #(
    .INPUT_COUNT(INPUT_COUNT/2)
)
layer2(
    .flags_in(layer1_flags),
    .data_in(layer1_data),
    .flags_out(layer2_flags),
    .data_out(layer2_data)
);

// layer3 16x8

wire [INPUT_WIDTH-1:0]   layer3_data [INPUT_COUNT/8-1:0];
wire [INPUT_COUNT/8-1:0] layer3_flags;

btree_mux_layer #(
    .INPUT_COUNT(INPUT_COUNT/4)
)
layer3(
    .flags_in(layer2_flags),
    .data_in(layer2_data),
    .flags_out(layer3_flags),
    .data_out(layer3_data)
);

// layer4 8x4

wire [INPUT_WIDTH-1:0]   layer4_data [INPUT_COUNT/16-1:0];
wire [INPUT_COUNT/16-1:0] layer4_flags;

btree_mux_layer #(
    .INPUT_COUNT(INPUT_COUNT/8)
)
layer4(
    .flags_in(layer3_flags),
    .data_in(layer3_data),
    .flags_out(layer4_flags),
    .data_out(layer4_data)
);

// layer5 4x2

wire [INPUT_WIDTH-1:0]    layer5_data [INPUT_COUNT/32-1:0];
wire [INPUT_COUNT/32-1:0] layer5_flags;

btree_mux_layer #(
    .INPUT_COUNT(INPUT_COUNT/16)
)
layer5(
    .flags_in(layer4_flags),
    .data_in(layer4_data),
    .flags_out(layer5_flags),
    .data_out(layer5_data)
);

// layer6 2x1

wire [INPUT_WIDTH-1:0]    layer6_data [INPUT_COUNT/64-1:0];
wire [INPUT_COUNT/64-1:0] layer6_flags;

btree_mux_layer #(
    .INPUT_COUNT(INPUT_COUNT/32)
)
layer6(
    .flags_in(layer5_flags),
    .data_in(layer5_data),
    .flags_out(layer6_flags),
    .data_out(layer6_data)
);

assign data_out = layer6_data[0];
assign flag_out = layer6_flags[0];

endmodule
