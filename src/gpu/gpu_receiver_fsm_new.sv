`include "constants.svh"


module gpu_receiver_fsm
#(
    parameter COORD_WIDTH       = `COORD_WIDTH,
    parameter RECT_COUNT_WIDTH  = `RECT_COUNT_WIDTH
)
(
    input  wire                          clk,
    input  wire                          reset,
    input  wire  [15:0]                  din,      // data from rect_copy controller
    input  wire  [2:0]                   state,
    input  wire  [9:0]                   coord_generator,
    input  wire  [3:0]                   rect_counter,
    input  wire  [1:0]                   batch_counter,
    input  wire                          batch_completed,

    output logic [1:0]                   mem_select,   // to which memory to write
    
    output wire  [9:0]                   mem_din_addr,
    input  wire  [63:0]                  mem_din,

    output wire                          we,
    output wire  [9:0]                   dout_addr,
    output logic [63:0]                  dout,         // data to write to gpu_mem
    output wire                          finish        // spike signal, when all rects are recieved
);

reg [2:0][3:0] rect_counter_delay;
reg [2:0][9:0] coord_generator_delay;
reg [2:0][2:0] state_delay;
reg [2:0][1:0] batch_counter_delay;
reg [2:0]      batch_completed_delay;


wire [9:0] buffer [15:0];
assign we = batch_completed_delay[2];

logic [63:0] dout_new;

assign mem_din_addr = coord_generator_delay[0];
assign dout_addr = coord_generator_delay[2];

localparam WAIT_FOR_START = 3'd0;
localparam READ_X = 3'd1;
localparam READ_WIDTH = 3'd2;
localparam READ_Y = 3'd3;
localparam READ_HEIGHT = 3'd4;
localparam READ_COLOR = 3'd5;

gpu_mem #(
    .ADDR_WIDTH(4),
    .SIZE(16),
    .DATA_WIDTH(10)
)
gpu_mem(
    .clk(clk),
    .we(~batch_completed_delay[2]),
    .mem_din_addr(rect_counter_delay[2]),
    .mem_din(din[9:0]),
    .dout(buffer)
);

wire  [15:0] collisions;
reg   [15:0] collisions_buffer;
logic [63:0] collisions_buffer_aligned;

wire left_or_top = state_delay[0] == READ_X || state_delay[0] == READ_Y;
wire [63:0] collisions_updated = mem_din | collisions_buffer_aligned;

always_comb begin
    case (batch_counter_delay[2])
        2'd0:    collisions_buffer_aligned = {{48{1'b0}}, collisions_buffer};
        2'd1:    collisions_buffer_aligned = {{32{1'b0}}, collisions_buffer, {16{1'b0}}};
        2'd2:    collisions_buffer_aligned = {{16{1'b0}}, collisions_buffer, {32{1'b0}}};
        2'd3:    collisions_buffer_aligned = {collisions_buffer, {48{1'b0}}};
        default: collisions_buffer_aligned = {64{1'b0}};
    endcase
end

always_comb begin
    case (state_delay[2])
        READ_X,
        READ_WIDTH:  mem_select = 2'd0;
        READ_Y,
        READ_HEIGHT: mem_select = 2'd1;
        default:     mem_select = 2'd2;
    endcase
end

always_comb begin
    case (state_delay[2])
        READ_COLOR: dout_new = {{48{1'b0}}, din};
        default:    dout_new = collisions_updated; 
    endcase
end

// Comparators for each rect
generate
    genvar i;
    for (i = 0; i < 16; i++) begin
        comparator #(.COORD_WIDTH(10)) comp(
            .left(left_or_top ? buffer[i] : coord_generator_delay[0]),
            .right(left_or_top ? coord_generator_delay[0] : buffer[i]),
            .equal(!left_or_top),
            .collision(collisions[i])
        );
    end
endgenerate

always_ff @(posedge clk) begin
    if (reset) begin
        dout <= '0;
        collisions_buffer <= '0;
        rect_counter_delay <= '0;
        coord_generator_delay <= '0;
        batch_counter_delay <= '0;
        batch_completed_delay <= '0;
        state_delay <= '0;
    end else begin
        dout <= dout_new;
        collisions_buffer <= collisions;
        rect_counter_delay[2:0]    <= {rect_counter_delay[1:0],    rect_counter};
        coord_generator_delay[2:0] <= {coord_generator_delay[1:0], coord_generator};
        batch_counter_delay[2:0]   <= {batch_counter_delay[1:0],   batch_counter};
        batch_completed_delay[2:0] <= {batch_completed_delay[1:0], batch_completed};
        state_delay[2:0] <= {state_delay[1:0], state};
    end
end

endmodule
