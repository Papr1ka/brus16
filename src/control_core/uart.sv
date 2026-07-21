module uart(
    input wire         clk,
    input wire         reset,

    // r/w memory interface
    input  wire [15:0] mem_din,
    input  wire        mem_din_we,
    output reg  [15:0] mem_dout,

    // cpu resume
    output reg         resume,

    // UART
    output reg         uart_tx
);

localparam CLK_DIV = 219;

localparam IDLE = 0;
localparam TR_END = 10;
reg   [3:0] state_counter;

wire work = state_counter != IDLE;
wire we = (state_counter == IDLE) && mem_din_we;


reg  [15:0] counter;
wire        counter_end = (counter == CLK_DIV - 1);
wire [15:0] counter_new = work ? (counter_end ? 0 : counter + 1) : counter;
wire        enable      = work && counter_end;

logic [3:0] state_counter_new;

wire transaction_start = we; // write to txdata register
wire transaction_end   = enable && state_counter == TR_END;

always_comb begin
    casez ({transaction_start, transaction_end, enable})
        3'b10?:   state_counter_new = state_counter + 1;
        3'b01?:   state_counter_new = IDLE;
        3'b001:   state_counter_new = state_counter + 1;
        default:  state_counter_new = state_counter;
    endcase
end

// Programmable registers
reg [9:0] tx_data; // start + data byte + end

wire [7:0] din_reversed = {mem_din[0], mem_din[1], mem_din[2], mem_din[3],
                           mem_din[4], mem_din[5], mem_din[6], mem_din[7]};

wire [9:0] tx_data_work_new = (enable) ? {tx_data[8:0], tx_data[9]} : tx_data;
wire [9:0] tx_data_new      = we       ? {1'b0, din_reversed, 1'b1} : tx_data_work_new;


// read logic
wire [15:0] mem_dout_new = (state_counter_new != IDLE); // busy flag

wire uart_tx_new = work ? tx_data[9] : 1'b1;

wire resume_new = transaction_end;

always_ff @(posedge clk) begin
    if (reset) begin
        state_counter <= IDLE;
        counter <= '0;
        tx_data <= '0;
        resume <= '0;
        mem_dout <= '0;
        uart_tx <= '1;
    end else begin
        state_counter <= state_counter_new;
        counter <= counter_new;
        tx_data <= tx_data_new;
        resume <= resume_new;
        mem_dout <= mem_dout_new;
        uart_tx <= uart_tx_new;
    end
end

endmodule
