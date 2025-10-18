/*
    DMA Button controller
    Contains BUTTON_COUNT buttons, after copy_start, writes button values to memory
    It works in assumption that after copy_start, it is connected to the data memory 
*/

`include "constants.svh"


module button_controller
#(
    parameter BUTTON_COUNT = `KEY_NUM,
    parameter BUTTON_ADDR = `KEY_MEM,
    parameter ADDR_WIDTH = `DATA_ADDR_WIDTH,
    parameter BUTTON_COUNT_WIDTH = `KEY_NUM_WIDTH
)
(
    input wire clk,
    input wire reset, // reset button values
    input wire copy_start, // start copy button values?

    input wire [BUTTON_COUNT-1:0] buttons_in, // button async raw signals

    output reg mem_dout_we,
    output wire [ADDR_WIDTH-1:0] mem_dout_addr,
    output reg [15:0] mem_dout
);

localparam LAST_BUTTON_ADDR = ADDR_WIDTH'(BUTTON_ADDR + BUTTON_COUNT - 1);

wire buttons_data [BUTTON_COUNT-1:0];

generate
genvar i;
for (i = 0; i < BUTTON_COUNT; i = i + 1) begin
    button_handler button(
        .clk(clk),
        .reset(reset),
        .button_in(buttons_in[BUTTON_COUNT - 1 - i]),
        .button_out(buttons_data[i])
    );
end
endgenerate

reg [ADDR_WIDTH-1:0] addr;
logic [ADDR_WIDTH-1:0] addr_new;

assign mem_dout_addr = addr;

reg state;
logic state_new;

wire is_last_button_addr = addr == LAST_BUTTON_ADDR;

localparam WAIT = 1'b0;
localparam COPY = 1'b1;

always_comb begin
    case ({state, copy_start, is_last_button_addr})
        {WAIT, 1'b1, 1'b0}: state_new = COPY;
        {COPY, 1'b0, 1'b1}: state_new = WAIT;
        {COPY, 1'b0, 1'b0}: state_new = COPY;
        default: state_new = WAIT;
    endcase
end

always_comb begin
    case ({state, copy_start, is_last_button_addr})
        {WAIT, 2'b00},
        {WAIT, 2'b01},
        {WAIT, 2'b10},
        {COPY, 2'b01}: addr_new = addr;
        default: addr_new = addr + 1;
    endcase
end

always_comb begin
    mem_dout = {16{buttons_data[BUTTON_COUNT_WIDTH'(addr - BUTTON_ADDR)]}};
end

always_comb begin
    case (state)
        WAIT: mem_dout_we = 1'b0;
        COPY: mem_dout_we = 1'b1;
    endcase
end

always_ff @(posedge clk) begin
    if (reset) begin
        state <= WAIT;
        addr <= ADDR_WIDTH'(BUTTON_ADDR);
    end else begin
        addr <= addr_new;
        state <= state_new;
    end
end


endmodule
