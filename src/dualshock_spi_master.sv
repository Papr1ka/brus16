/*
    Dualshock 2 SPI controller
    Gets button values
    SPI clk:
        0: chip_select, data_valid <= 0;
        [TX_START, TX_START + TX_SIZE]: sends TX_DATA
        [RX_START, RX_START + RX_SIZE]: receives RX_DATA, stores to out registers
        last: chip_deselect, data_valid <= 1;
*/

module dualshock_spi_master #(
    // How many clk clocks to do one full spi_clk clock
    parameter CLK_RATIO = 750,

    parameter TX_START = 1,
    parameter TX_SIZE = 24,
    // 1h 0x42h 0h (lsb first)
    parameter TX_DATA = TX_SIZE'(24'b10000000_01000010_00000000),

    parameter RX_START = 25,
    parameter RX_SIZE = 16,

    parameter TRANSACTION_SIZE = (3 + 6) * 8 + 2
)
(
    input wire               clk,
    input wire               reset,

    // SPI
    input  wire              spi_miso,
    output reg               spi_clk,
    output reg               spi_cs,
    output reg               spi_mosi,

    // data from slave
    output reg               data_valid,
    output reg [RX_SIZE-1:0] rx_buffer
);

localparam TX_END = TX_START + TX_SIZE;
localparam RX_END = RX_START + RX_SIZE;
localparam TX_ADDR_WIDTH = $clog2(TX_SIZE);
localparam RX_ADDR_WIDTH = $clog2(RX_SIZE);

localparam COUNTER_WIDTH = $clog2(CLK_RATIO);
localparam STATE_WIDTH   = $clog2(TRANSACTION_SIZE);


// Clock enable logic
reg [COUNTER_WIDTH-1:0] counter     = '0;
reg                     enable      = 1'b0;
reg                     half_enable = 1'b0;

always_ff @(posedge clk) begin
    case ({counter == CLK_RATIO - 1, counter == CLK_RATIO / 2 - 1})
        2'b00:   {enable, half_enable} <= {1'b0, 1'b0};
        2'b10:   {enable, half_enable} <= {1'b1, 1'b1};
        2'b01:   {enable, half_enable} <= {1'b0, 1'b1};
        2'b11:   {enable, half_enable} <= {1'b1, 1'b1};
        default: {enable, half_enable} <= {1'b0, 1'b0};
    endcase
end

always_ff @(posedge clk) begin
    if (reset || counter == CLK_RATIO - 1)
        counter <= '0;
    else
        counter <= counter + 1; 
end


//   SPI logic

// SPI state
reg [STATE_WIDTH-1:0] spi_state = '0;
wire first_state = (spi_state == 0);
wire last_state  = (spi_state == TRANSACTION_SIZE - 1);

always_ff @(posedge clk) begin
    casez ({reset, enable, last_state})
        3'b1??,
        3'b011:  spi_state <= '0;
        3'b010:  spi_state <= spi_state + 1;
        default: spi_state <= spi_state; 
    endcase
end

// SPI chip select
always_ff @(posedge clk) begin
    casez ({reset, enable, first_state, spi_state == TRANSACTION_SIZE - 2})
        4'b1???: spi_cs <= reset;
        4'b0110: spi_cs <= 1'b0;
        4'b0101: spi_cs <= 1'b1;
        default: spi_cs <= spi_cs;
    endcase
end

// SPI data valid
always_ff @(posedge clk) begin
    casez ({reset, last_state, first_state})
        3'b1??,
        3'b001:  data_valid <= 1'b0;
        3'b010:  data_valid <= 1'b1;
        default: data_valid <= data_valid;
    endcase
end

// SPI clk
always_ff @(posedge clk) begin
    casez ({reset, spi_state != 0 && ~last_state, half_enable})
        3'b1??:  spi_clk <= 1'b0;
        3'b011:  spi_clk <= ~spi_clk;
        default: spi_clk <= spi_clk;
    endcase
end

// SPI mosi
always_ff @(posedge clk) begin
    if (spi_state >= TX_START && spi_state < TX_END)
        spi_mosi <= TX_DATA[TX_ADDR_WIDTH'(STATE_WIDTH'(TX_END - 1) - (spi_state))];
    else
        spi_mosi <= '0;
end

// SPI miso
always_ff @(posedge clk) begin
    if (enable) begin
        if (spi_state >= RX_START && spi_state < RX_END) begin
            rx_buffer[RX_ADDR_WIDTH'(STATE_WIDTH'(RX_END - 1) - (spi_state))] <= spi_miso;
        end
    end
end

endmodule
