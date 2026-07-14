module spi_master(
    input wire clk,
    input wire reset,

    // cpu memory interface
    input  wire [1:0]  mem_addr,
    input  wire [15:0] mem_din,
    input  wire        mem_din_we,
    output reg  [15:0] mem_dout,

    // cpu resume
    output reg resume,

    // SPI
    input  wire              spi_miso,
    output reg               spi_clk,
    output wire              spi_cs,
    output wire              spi_mosi
);

// Programmed registers
reg [15:0] clk_div; // r/w, add=0
reg        cs;      // r/w, add=1
reg [7:0]  tx_data; // r/w, add=2
reg [7:0]  rx_data; // r,   add=3


// Clock enable logic
reg [15:0] counter     = '0;
reg        enable      = 1'b0;
reg        half_enable = 1'b0;

wire enable_new      = (counter == clk_div - 1);
wire half_enable_new = (counter == ((clk_div >> 1) - 1)) | enable_new;

reg  [2:0] bit_sended_counter;
// state
localparam IDLE  = 2'd0;
localparam WRITE = 2'd1;
reg   [1:0] state;
logic [1:0] state_new;

wire [15:0] counter_new = state != IDLE ? (enable_new ? 0 : counter + 1) : counter;

always_comb begin
    casez ({state, mem_din_we && mem_addr == 2, enable, bit_sended_counter == 7})
        5'b00_1??: state_new = WRITE;
        5'b01_?11: state_new = IDLE;
        default:   state_new = state;
    endcase
end

wire resume_new = enable && bit_sended_counter == 7;

wire [2:0] bit_sended_counter_new = ((state == WRITE) && enable) ? bit_sended_counter + 1 : bit_sended_counter;

wire spi_clk_new = (half_enable && state != IDLE) ? ~spi_clk : spi_clk;

// Write enable to registers
wire we = (state == IDLE) && mem_din_we;

wire [7:0] tx_data_new_work = ((state == WRITE) && enable) ? {tx_data[6:0], tx_data[7]} : tx_data;

wire [15:0] clk_div_new = we && mem_addr == 0 ? mem_din      : clk_div;
wire [15:0] cs_new      = we && mem_addr == 1 ? mem_din[7:0] : cs;
wire [15:0] tx_data_new = we && mem_addr == 2 ? mem_din[7:0] : tx_data_new_work;


wire [7:0] rx_data_new = ((state == WRITE) && enable) ? {rx_data[6:0], spi_miso} : rx_data;


logic [15:0] mem_dout_new;

always_comb begin
    case (mem_addr)
        0:       mem_dout_new = clk_div;
        1:       mem_dout_new = {15'b0, cs};
        2:       mem_dout_new = {8'b0, tx_data};
        3:       mem_dout_new = {8'b0, rx_data};
        default: mem_dout_new = 16'b0;
    endcase
end

assign spi_cs = cs;
assign spi_mosi = tx_data[7];


always_ff @(posedge clk) begin
    if (reset) begin
        state <= IDLE;
        mem_dout <= '0;
        counter <= '0;
        spi_clk <= '0;
        enable <= '0;
        half_enable <= '0;

        clk_div <= 500;
        cs <= 1;
        tx_data <= '0;
        rx_data <= '0;
        bit_sended_counter <= '0;
        spi_clk <= '0;
        resume <= '0;
    end else begin
        mem_dout <= mem_dout_new;
        counter <= counter;
        spi_clk <= spi_clk_new;
        enable      <= enable_new;
        half_enable <= half_enable_new;
        state <= state_new;

        clk_div <= clk_div_new;
        cs <= cs_new;
        tx_data <= tx_data_new;
        rx_data <= rx_data_new;
        bit_sended_counter <= bit_sended_counter_new;
        spi_clk <= spi_clk_new;
        counter <= counter_new;
        resume <= resume_new;
    end
end

endmodule
