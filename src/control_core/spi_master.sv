module spi_master(
    input wire         clk,
    input wire         reset,

    // r/w memory interface
    input  wire [1:0]  mem_addr,
    input  wire [15:0] mem_din,
    input  wire        mem_din_we,
    output reg  [15:0] mem_dout,

    // cpu resume
    output reg         resume,

    // SPI
    output reg         spi_clk,
    output wire        spi_mosi,
    input  wire        spi_miso,
    output wire        spi_cs
);

// Out SPI frequency = 1 / (2 * (clk_div + 1))

// Programmable registers
reg [15:0] clk_div; // r/w, add=0
reg        cs;      // r/w, add=1
reg [7:0]  tx_data; // r/w, add=2
reg [7:0]  rx_data; // r,   add=3


// State
localparam IDLE  = 1'd0;
localparam WRITE = 1'd1;
reg   state;
logic state_new;

// clocking logic will work
wire work = state != IDLE;
// Write enable to programmable registers
wire we = (state == IDLE) && mem_din_we;


// Clocking logic
reg [15:0] counter;

wire spi_clk_toggle  = work && counter == clk_div;
wire spi_clk_posedge = spi_clk_toggle && !spi_clk; // spi_clk posedge will be at next clk posedge
wire spi_clk_negedge = spi_clk_toggle &&  spi_clk; // spi_clk nededge will be at next clk posedge

// How many bits are sended
reg  [2:0] bits_sended_counter;
wire [2:0] bit_sended_counter_new = (spi_clk_negedge) ? bits_sended_counter + 1 : bits_sended_counter;

wire [15:0] counter_new = work ? (spi_clk_toggle ? 0 : counter + 1) : counter;

wire transaction_start = we && mem_addr == 2; // write to txdata register
wire transaction_end   = spi_clk_negedge && bits_sended_counter == 7;

always_comb begin
    case ({transaction_start, transaction_end})
        2'b10:   state_new = WRITE;
        2'b01:   state_new = IDLE;
        default: state_new = state;
    endcase
end

wire [7:0]  tx_data_work_new = (spi_clk_negedge) ? {tx_data[6:0], tx_data[7]} : tx_data;

wire [15:0] clk_div_new = we && mem_addr == 0 ? mem_din[0]   : clk_div;
wire        cs_new      = we && mem_addr == 1 ? mem_din[7:0] : cs;
wire [7:0]  tx_data_new = we && mem_addr == 2 ? mem_din[7:0] : tx_data_work_new;
wire [7:0]  rx_data_new      = (spi_clk_posedge) ? {rx_data[6:0], spi_miso}   : rx_data;

// read logic
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

assign spi_cs      = cs;
assign spi_mosi    = tx_data[7];
wire   spi_clk_new = spi_clk_toggle ? ~spi_clk : spi_clk;

always_ff @(posedge clk) begin
    if (reset) begin
        state               <= IDLE;
        counter             <= '0;
        bits_sended_counter <= '0;

        clk_div             <= '0;
        cs                  <= '1;
        tx_data             <= '0;
        rx_data             <= '0;

        mem_dout            <= '0;
        spi_clk             <= '0;
        resume              <= '0;

    end else begin
        state               <= state_new;
        counter             <= counter_new;
        bits_sended_counter <= bit_sended_counter_new;

        clk_div             <= clk_div_new;
        cs                  <= cs_new;
        tx_data             <= tx_data_new;
        rx_data             <= rx_data_new;

        mem_dout            <= mem_dout_new;
        spi_clk             <= spi_clk_new;
        resume              <= transaction_end;
    end
end

endmodule
