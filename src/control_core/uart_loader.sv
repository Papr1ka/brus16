module uart_loader
#(
    parameter integer FCLK = 25200000,
    parameter integer BAUDRATE = 115200
)
(
    input             clk,
    input             reset,
    input             uart_rx,
    output reg [15:0] cfg_addr,
    output reg [15:0] cfg_data,
    output reg        cfg_we,
    output reg        cfg_reset
);

reg [31:0] rxstate;
reg[7:0] rxdata;
reg upd_reg;

always @(posedge clk) begin
    if (reset) begin
        rxstate   <= '0;
        rxdata    <= '0;
        upd_reg   <= '0;
    end else begin
        case (rxstate)
            0 : if (uart_rx == 1'b0) rxstate <= 1;
            3 * FCLK / 2 / BAUDRATE : begin rxdata[0] <= uart_rx; rxstate <= rxstate + 1; end 
            5 * FCLK / 2 / BAUDRATE : begin rxdata[1] <= uart_rx; rxstate <= rxstate + 1; end 
            7 * FCLK / 2 / BAUDRATE : begin rxdata[2] <= uart_rx; rxstate <= rxstate + 1; end 
            9 * FCLK / 2 / BAUDRATE : begin rxdata[3] <= uart_rx; rxstate <= rxstate + 1; end 
            11 * FCLK / 2 / BAUDRATE : begin rxdata[4] <= uart_rx; rxstate <= rxstate + 1; end 
            13 * FCLK / 2 / BAUDRATE : begin rxdata[5] <= uart_rx; rxstate <= rxstate + 1; end 
            15 * FCLK / 2 / BAUDRATE : begin rxdata[6] <= uart_rx; rxstate <= rxstate + 1; end 
            17 * FCLK / 2 / BAUDRATE : begin rxdata[7] <= uart_rx; rxstate <= rxstate + 1; end 
            19 * FCLK / 2 / BAUDRATE : begin upd_reg <= 1; rxstate <= rxstate + 1; end 
            (19 * FCLK / 2 / BAUDRATE) + 1 : begin upd_reg <= 0; rxstate <= 0; end 
            default: rxstate <= rxstate + 1;
        endcase
    end
end

always @(posedge clk) begin
    if (reset) begin
        cfg_addr  <= '0;
        cfg_data  <= '0;
        cfg_we    <= '0;
        cfg_reset <= '0;
    end else if (upd_reg) begin
        case (rxdata[7:4])
            // data  
            4'b0000 : cfg_data[3:0] <= rxdata[3:0]; 
            4'b0001 : cfg_data[7:4] <= rxdata[3:0]; 
            4'b0010 : cfg_data[11:8] <= rxdata[3:0]; 
            4'b0011 : cfg_data[15:12] <= rxdata[3:0];
            // addr
            4'b1010 : cfg_addr[3:0] <= rxdata[3:0];   // A 
            4'b1011 : cfg_addr[7:4] <= rxdata[3:0];   // B 
            4'b1100 : cfg_addr[11:8] <= rxdata[3:0];  // C
            4'b1101 : cfg_addr[15:12] <= rxdata[3:0]; // D
            // config bits
            4'b1111 : begin 
                      cfg_we <= rxdata[0];
                      cfg_reset <= rxdata[1];
            end
        endcase
    end
end

endmodule
