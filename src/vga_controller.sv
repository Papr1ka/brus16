module vga_controller(
    input wire clk,
    input wire reset,
    
    output reg hsync,
    output reg vsync,
    output reg display_on,
    output reg [9:0] hpos,
    output reg [9:0] vpos
);
    /* verilator lint_off UNUSEDPARAM */
    // 640X480 VGA sync parameters
    localparam LEFT_PORCH		= 	48;
    localparam ACTIVE_WIDTH		= 	640;
    localparam RIGHT_PORCH		= 	16;
    localparam HORIZONTAL_SYNC	=	96;
    localparam TOTAL_WIDTH		=	800;
    
    localparam TOP_PORCH		= 	33;
    localparam ACTIVE_HEIGHT	= 	480;
    localparam BOTTOM_PORCH		= 	10;
    localparam VERTICAL_SYNC	=	2;
    localparam TOTAL_HEIGHT		=	525;
    /* verilator lint_on PINMISSING */
    // next state regs
    reg hsync_next;
    reg vsync_next;
    reg [9:0] hpos_next;
    reg [9:0] vpos_next;
    reg display_on_next;
    
    // sequential logic
    always @(posedge clk) begin
        if (reset) begin
            hsync <= 0;
            vsync <= 0;
            hpos <= 0;
            vpos <= 0;
            display_on <= 0;
        end else begin
            hsync <= hsync_next;
            vsync <= vsync_next;
            hpos <= hpos_next;
            vpos <= vpos_next;
            display_on <= display_on_next;
        end
    end
    
    // combinational logic
    always @(*) begin
        hsync_next = hpos >= RIGHT_PORCH + ACTIVE_WIDTH && 
                      hpos < RIGHT_PORCH + ACTIVE_WIDTH + HORIZONTAL_SYNC;
        vsync_next = vpos >= TOP_PORCH + ACTIVE_HEIGHT && 
                      vpos < TOP_PORCH + ACTIVE_HEIGHT + VERTICAL_SYNC;
        
        
        if (hpos == TOTAL_WIDTH - 1) begin
            hpos_next = 0;
            if (vpos == TOTAL_HEIGHT - 1)
                vpos_next = 0;
            else
                vpos_next = vpos + 1;
        end else begin
            hpos_next = hpos + 1;
            vpos_next = vpos;
        end
        display_on_next = hpos < ACTIVE_WIDTH && vpos < ACTIVE_HEIGHT;
    end


endmodule
