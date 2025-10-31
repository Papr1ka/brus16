/*
    GPU receiver fsm
    Receives data from rect_copy_controller, slave
    When all data has been processed, sends finish
*/

`include "constants.svh"


module gpu_receiver_fsm
(
    input  wire                          clk,
    input  wire                          reset,
    
    // from rect_copy_controller
    input  wire  [15:0]                  din,           // data from rect_copy controller
    input  wire  [2:0]                   state,
    input  wire  [9:0]                   coord_generator,
    input  wire  [3:0]                   rect_counter,
    input  wire  [1:0]                   batch_counter,
    input  wire                          batch_completed,

    // gpu memory interface
    output logic [1:0]                   mem_select,   // to which memory to write
    
    output wire  [9:0]                   mem_din_addr,
    input  wire  [63:0]                  mem_din,

    output wire                          we,
    output wire  [9:0]                   dout_addr,
    output reg   [63:0]                  dout,         // data to write
    output reg                           finish        // spike signal, when all rects are processed
);

localparam WAIT_FOR_START = 3'd0;
localparam READ_X = 3'd1;
localparam READ_WIDTH = 3'd2;
localparam READ_Y = 3'd3;
localparam READ_HEIGHT = 3'd4;
localparam READ_COLOR = 3'd5;

// shift registers (3 tacts)
reg [2:0][3:0] rect_counter_delay;
reg [2:0][9:0] coord_generator_delay;
reg [2:0][2:0] state_delay;
reg [2:0][1:0] batch_counter_delay;
reg [2:0]      batch_completed_delay;

assign we = batch_completed_delay[2];
assign mem_din_addr = coord_generator_delay[0];

logic [63:0] dout_new;
wire  finish_new = (state_delay[2] == READ_COLOR) && dout_addr == 63;

// address calculation
logic [9:0] addr_sm_right;
assign dout_addr = coord_generator_delay[2] + addr_sm_right;

always_comb begin
    case ({state_delay[2] == READ_COLOR, batch_counter_delay[2]})
        {1'b1, 2'd0}: addr_sm_right = 10'd0;
        {1'b1, 2'd1}: addr_sm_right = 10'd16;
        {1'b1, 2'd2}: addr_sm_right = 10'd32;
        {1'b1, 2'd3}: addr_sm_right = 10'd48;
        default:      addr_sm_right = 10'd0;
    endcase
end

// general purpose buffer (coords | colors)
wire [15:0] buffer [15:0];

gpu_buffer #(
    .ADDR_WIDTH(4),
    .SIZE(16),
    .DATA_WIDTH(16)
)
gpu_buffer(
    .clk(clk),
    .we(~batch_completed_delay[2]),
    .mem_din_addr(rect_counter_delay[2]),
    .mem_din(din),
    .dout(buffer)
);

wire  [15:0] collisions;                // batch
reg   [15:0] collisions_buffer;         // batch delayed
logic [63:0] collisions_buffer_aligned; // batch delayed, aligned to 64 bit
logic [63:0] mem_din_aligned;           // mem_din with 1 on unprocessed bits
                                        // processed collisions
wire  [63:0] collisions_updated = mem_din_aligned & collisions_buffer_aligned;

wire left_or_top = (state_delay[0] == READ_X) || (state_delay[0] == READ_Y);

always_comb begin
    case ({((state_delay[2] == READ_X) || (state_delay[2] == READ_Y)), batch_counter_delay[2]})
        {1'b1, 2'd0}: mem_din_aligned = {64{1'b1}};
        {1'b1, 2'd1}: mem_din_aligned = {{48{1'b1}}, mem_din[15:0]};
        {1'b1, 2'd2}: mem_din_aligned = {{32{1'b1}}, mem_din[31:0]};
        {1'b1, 2'd3}: mem_din_aligned = {{16{1'b1}}, mem_din[47:0]};
        default:      mem_din_aligned = mem_din;
    endcase
end

always_comb begin
    case (batch_counter_delay[2])
        2'd0:    collisions_buffer_aligned = {{48{1'b1}}, collisions_buffer};
        2'd1:    collisions_buffer_aligned = {{32{1'b1}}, collisions_buffer, {16{1'b1}}};
        2'd2:    collisions_buffer_aligned = {{16{1'b1}}, collisions_buffer, {32{1'b1}}};
        2'd3:    collisions_buffer_aligned = {collisions_buffer, {48{1'b1}}};
        default: collisions_buffer_aligned = {64{1'b1}};
    endcase
end

always_comb begin
    case (state_delay[2])
        READ_X,
        READ_WIDTH:  mem_select = 2'd0; // xs
        READ_Y,
        READ_HEIGHT: mem_select = 2'd1; // ys
        default:     mem_select = 2'd2; // colors
    endcase
end

always_comb begin
    case (state_delay[2])
        READ_COLOR: dout_new = {{48{1'b0}}, buffer[coord_generator_delay[1][3:0]]};
        default:    dout_new = collisions_updated;
    endcase
end

// 10-bit comparators for each value in buffer (abs clamped coords)
generate
    genvar i;
    for (i = 0; i < 16; i++) begin
        wire [9:0] comp_left  = left_or_top ? buffer[i][9:0]           : coord_generator_delay[0];
        wire [9:0] comp_right = left_or_top ? coord_generator_delay[0] : buffer[i][9:0];
        comparator #(
            .COORD_WIDTH(10)
        )
        comp(
            .left(comp_left),
            .right(comp_right),
            .equal(!left_or_top),
            .collision(collisions[i])
        );
    end
endgenerate

always_ff @(posedge clk) begin
    if (reset) begin
        dout                  <= '0;
        collisions_buffer     <= '0;
        rect_counter_delay    <= '0;
        coord_generator_delay <= '0;
        batch_counter_delay   <= '0;
        batch_completed_delay <= '0;
        state_delay           <= '0;
        finish                <= '0;
    end else begin
        dout                       <= dout_new;
        collisions_buffer          <= collisions;
        rect_counter_delay[2:0]    <= {rect_counter_delay[1:0],    rect_counter};
        coord_generator_delay[2:0] <= {coord_generator_delay[1:0], coord_generator};
        batch_counter_delay[2:0]   <= {batch_counter_delay[1:0],   batch_counter};
        batch_completed_delay[2:0] <= {batch_completed_delay[1:0], batch_completed};
        state_delay[2:0]           <= {state_delay[1:0], state};
        finish                     <= finish_new;
    end
end

endmodule
