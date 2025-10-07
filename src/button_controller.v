module button_controller
#(
    parameter BUTTON_COUNT = 6,
    parameter BUTTON_ADDR = 7802,
    parameter ADDR_WIDTH = 13
)
(
    input wire clk,
    input wire reset,
    input wire copy_start,

    input wire [BUTTON_COUNT-1:0] buttons_in,

    output reg mem_dout_we,
    output wire [ADDR_WIDTH-1:0] mem_dout_addr,
    output reg [15:0] mem_dout
);

wire buttons_data [BUTTON_COUNT-1:0];

generate
genvar i;
for (i = 0; i < BUTTON_COUNT; i = i + 1) begin
    button_handler button(
        .clk(clk),
        .reset(reset),
        .button_in(buttons_in[i]),
        .button_out(buttons_data[i])
    );
end
endgenerate

reg [ADDR_WIDTH-1:0] addr;
reg [ADDR_WIDTH-1:0] addr_new;

assign mem_dout_addr = addr;

reg state;
reg state_new; // logic

localparam WAIT = 1'b0;
localparam COPY = 1'b1;

always @(*) begin
    case ({state, copy_start, addr == BUTTON_ADDR + BUTTON_COUNT - 1})
        {WAIT, 1'b1, 1'b0}: state_new = COPY;
        {COPY, 1'b0, 1'b1}: state_new = WAIT;
        {COPY, 1'b0, 1'b0}: state_new = COPY;
        default: state_new = WAIT;
    endcase
end

always @(*) begin
    case ({state, copy_start, addr == BUTTON_ADDR + BUTTON_COUNT - 1})
        {WAIT, 2'b00},
        {WAIT, 2'b01},
        {WAIT, 2'b10},
        {COPY, 2'b01}: addr_new = addr;
        default: addr_new = addr + 1;
    endcase
end

always @(*) begin
    mem_dout = {16{buttons_data[addr - BUTTON_ADDR]}};
end

always @(*) begin
    case (state)
        WAIT: mem_dout_we = 1'b0;
        COPY: mem_dout_we = 1'b1; 
    endcase
end

always @(posedge clk) begin
    if (reset) begin
        state <= WAIT;
        addr <= BUTTON_ADDR;
    end else begin
        addr <= addr_new;
        state <= state_new;
    end
end

initial begin
    state <= WAIT;
    addr <= BUTTON_ADDR;
end

endmodule
