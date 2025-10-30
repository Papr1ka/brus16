/*
    binary tree of mux-es
    64x1 (6 layers) (read gpu introduction)
*/

`include "constants.svh"

module btree_mux
#(
    parameter INPUT_COUNT = `RECT_COUNT,
    parameter INPUT_WIDTH = `RECT_COUNT_WIDTH
)
(
    input   wire                    clk,
    input   wire [INPUT_COUNT-1:0]  flags_in,                   // mux controls
    // input   wire [INPUT_WIDTH-1:0]  data_in [INPUT_COUNT-1:0],  // mux data
    output  wire                    flag_out,                   // any mux control ?
    output  wire [INPUT_WIDTH-1:0]  data_out                    // mux output
);

// layer1 64x32

// wire [INPUT_WIDTH-1:0]      layer1_data [INPUT_COUNT/2-1:0];
// wire [INPUT_COUNT/2-1:0]    layer1_flags;

// btree_mux_layer #(
//     .INPUT_COUNT(INPUT_COUNT),
//     .INPUT_WIDTH(INPUT_WIDTH)
// )
// layer1(
//     .flags_in(flags_in),
//     .data_in(data_in),
//     .flags_out(layer1_flags),
//     .data_out(layer1_data)
// );

// // layer2 32x16

// wire [INPUT_WIDTH-1:0]      layer2_data [INPUT_COUNT/4-1:0];
// wire [INPUT_COUNT/4-1:0]    layer2_flags;

// btree_mux_layer #(
//     .INPUT_COUNT(INPUT_COUNT/2),
//     .INPUT_WIDTH(INPUT_WIDTH)
// )
// layer2(
//     .flags_in(layer1_flags),
//     .data_in(layer1_data),
//     .flags_out(layer2_flags),
//     .data_out(layer2_data)
// );

// // layer3 16x8

// wire [INPUT_WIDTH-1:0]      layer3_data [INPUT_COUNT/8-1:0];
// wire [INPUT_COUNT/8-1:0]    layer3_flags;

// btree_mux_layer #(
//     .INPUT_COUNT(INPUT_COUNT/4),
//     .INPUT_WIDTH(INPUT_WIDTH)
// )
// layer3(
//     .flags_in(layer2_flags),
//     .data_in(layer2_data),
//     .flags_out(layer3_flags),
//     .data_out(layer3_data)
// );

wire [5:0] flags;
wire [5:0] rom_dout [5:0];
btree_rom rom0(
    .dout({rom_dout[0], flags[0]}), //output [5:0] dout
    .clk(clk), //input clk
    .oce(1'b1), //input oce
    .ce(1'b1), //input ce
    .reset(1'b0), //input reset
    .ad(flags_in[63:53]) //input [10:0] ad
);

btree_rom rom1(
    .dout({rom_dout[1], flags[1]}), //output [5:0] dout
    .clk(clk), //input clk
    .oce(1'b1), //input oce
    .ce(1'b1), //input ce
    .reset(1'b0), //input reset
    .ad(flags_in[52:42]) //input [10:0] ad
);

btree_rom rom2(
    .dout({rom_dout[2], flags[2]}), //output [5:0] dout
    .clk(clk), //input clk
    .oce(1'b1), //input oce
    .ce(1'b1), //input ce
    .reset(1'b0), //input reset
    .ad(flags_in[41:31]) //input [10:0] ad
);

btree_rom rom3(
    .dout({rom_dout[3], flags[3]}), //output [5:0] dout
    .clk(clk), //input clk
    .oce(1'b1), //input oce
    .ce(1'b1), //input ce
    .reset(1'b0), //input reset
    .ad(flags_in[30:20]) //input [10:0] ad
);

btree_rom rom4(
    .dout({rom_dout[4], flags[4]}), //output [5:0] dout
    .clk(clk), //input clk
    .oce(1'b1), //input oce
    .ce(1'b1), //input ce
    .reset(1'b0), //input reset
    .ad(flags_in[19:9]) //input [10:0] ad
);

btree_rom rom5(
    .dout({rom_dout[5], flags[5]}), //output [5:0] dout
    .clk(clk), //input clk
    .oce(1'b1), //input oce
    .ce(1'b1), //input ce
    .reset(1'b0), //input reset
    .ad(flags_in[8:0]) //input [10:0] ad
);



// layer4 8x4

wire [INPUT_WIDTH-1:0]  layer4_data [3:0];
wire [3:0]              layer4_flags;
assign layer4_data[0] = '0;
assign layer4_flags[0] = '0;

btree_mux_layer #(
    .INPUT_COUNT(6),
    .INPUT_WIDTH(INPUT_WIDTH)
)
layer4(
    .flags_in(flags),
    .data_in(rom_dout),
    .flags_out(layer4_flags[3:1]),
    .data_out(layer4_data[3:1])
);

// layer5 4x2

wire [INPUT_WIDTH-1:0]      layer5_data [1:0];
wire [1:0]   layer5_flags;

btree_mux_layer #(
    .INPUT_COUNT(4),
    .INPUT_WIDTH(INPUT_WIDTH)
)
layer5(
    .flags_in(layer4_flags),
    .data_in(layer4_data),
    .flags_out(layer5_flags),
    .data_out(layer5_data)
);

// layer6 2x1

wire [INPUT_WIDTH-1:0]      layer6_data [INPUT_COUNT/64-1:0];
wire [INPUT_COUNT/64-1:0]   layer6_flags;

btree_mux_layer #(
    .INPUT_COUNT(INPUT_COUNT/32),
    .INPUT_WIDTH(INPUT_WIDTH)
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
