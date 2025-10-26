`include "constants.svh"


module gpu_receiver_fsm
#(
    parameter COORD_WIDTH       = `COORD_WIDTH,
    parameter RECT_COUNT_WIDTH  = `RECT_COUNT_WIDTH
)
(
    input  wire                          clk,
    input  wire                          reset,
    input  wire  [15:0]                  mem_din,      // data from rect_copy controller

    output wire                          finish,       // spike signal, when all rects are recieved
    output wire                          we_rect_lefts,
    output wire                          we_rect_tops,
    output wire                          we_rect_rights,
    output wire                          we_rect_bottoms,
    output wire                          we_rect_colors,
    output wire  [RECT_COUNT_WIDTH-1:0]  dout_addr,
    output logic [15:0]                  dout          // data to write to gpu_mem
);

reg     [2:0] copy_state;
logic   [2:0] copy_state_new;
localparam READ_START   = 3'b000;
localparam READ_X       = 3'b001;
localparam READ_Y       = 3'b010;
localparam READ_WIDTH   = 3'b011;
localparam READ_HEIGHT  = 3'b100;
localparam READ_COLOR   = 3'b101;

reg     [RECT_COUNT_WIDTH-1:0] rect_counter;
logic   [RECT_COUNT_WIDTH-1:0] rect_counter_new;


assign we_rect_lefts    = copy_state == READ_X;
assign we_rect_tops     = copy_state == READ_Y;
assign we_rect_rights   = copy_state == READ_WIDTH;
assign we_rect_bottoms  = copy_state == READ_HEIGHT;
assign we_rect_colors   = copy_state == READ_COLOR;
assign finish           = (rect_counter == {RECT_COUNT_WIDTH{1'b1}}) && (copy_state == READ_COLOR);
assign dout_addr        = rect_counter;

reg [15:0] rect_x1_true;
reg [15:0] rect_y1_true;

logic [COORD_WIDTH-1:0] rect_x1;
logic [COORD_WIDTH-1:0] rect_y1;
logic [COORD_WIDTH-1:0] rect_x2;
logic [COORD_WIDTH-1:0] rect_y2;

always_comb begin
    casez ({mem_din[15], $signed(mem_din[15:7]) >= 5}) // >= 640
        2'b1?:   rect_x1 = 0;
        2'b01:   rect_x1 = 640;
        default: rect_x1 = mem_din[9:0];
    endcase
end

always_comb begin
    casez ({mem_din[15], $signed(mem_din[15:5]) >= 15}) // >= 480
        2'b1?:   rect_y1 = 0;
        2'b01:   rect_y1 = 480;
        default: rect_y1 = mem_din[9:0];
    endcase
end

wire [15:0] rect_x2_true = rect_x1_true + mem_din;
wire [15:0] rect_y2_true = rect_y1_true + mem_din;

always_comb begin
    casez ({rect_x2_true[15], $signed(rect_x2_true[15:7]) >= 5}) // >= 640
        2'b1?:    rect_x2 = 0;
        2'b01:    rect_x2 = 640;
        default:  rect_x2 = rect_x2_true[9:0];
    endcase
end

always_comb begin
    casez ({rect_y2_true[15], $signed(rect_y2_true[15:5]) >= 15}) // >= 480
        2'b1?:   rect_y2 = 0;
        2'b01:   rect_y2 = 480;
        default: rect_y2 = rect_y2_true[9:0];
    endcase
end

always_comb begin
    case (copy_state)
        READ_START:  copy_state_new = READ_X;
        READ_X:      copy_state_new = READ_Y;
        READ_Y:      copy_state_new = READ_WIDTH;
        READ_WIDTH:  copy_state_new = READ_HEIGHT;
        READ_HEIGHT: copy_state_new = READ_COLOR;
        default:     copy_state_new = READ_START;
    endcase
end

always_comb begin
    case (copy_state)
        READ_COLOR: rect_counter_new = rect_counter + 1; // READ_COLOR
        default:    rect_counter_new = rect_counter;
    endcase
end

always_comb begin
    case (copy_state)
        READ_X:      dout = 16'(rect_x1);
        READ_Y:      dout = 16'(rect_y1);
        READ_WIDTH:  dout = 16'(rect_x2);
        READ_HEIGHT: dout = 16'(rect_y2);
        READ_COLOR:  dout = mem_din;
        default:     dout = 16'bx;
    endcase
end

always_ff @(posedge clk) begin
    if (reset) begin
        copy_state   <= READ_START;
        rect_counter <= RECT_COUNT_WIDTH'(0);
        rect_x1_true <= 16'b0;
        rect_y1_true <= 16'b0;
    end else begin
        copy_state   <= copy_state_new;
        rect_counter <= rect_counter_new;
        rect_x1_true <= we_rect_lefts ? mem_din : rect_x1_true;
        rect_y1_true <= we_rect_tops  ? mem_din : rect_y1_true;
    end
end

endmodule
