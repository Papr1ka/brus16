module control_core(
    input wire clk,
    input wire reset,

    output reg game_core_reset,  // Reset game core
    output reg control_core_sel, // Connect control core to game core memory 

    input  wire [15:0] buttons,

    // Control core memory bus
    output wire [15:0] mem_dout_addr,
    output wire [15:0] mem_dout,
    output wire [15:0] mem_dout_we,

    // SPI SD card
    output wire spi_clk_sd,
    output wire spi_mosi_sd,
    input  wire spi_miso_sd,
    output wire spi_cs_sd,

    // UART
    input  wire uart_rx,
    output wire uart_tx
);

/*
    Memory mapping:

    (For UART loader)
    [0-8192):      control core program memory
    [8192-16384):  control core data memory

    (For control core)
    [16384-24576): game core program memory
    [24576-32768): game core data memory
    65528:         DS2 combined buttons (j0 | j1)
    65529:         game core reset
    65530:         connect control core to game core memory
    65531:         SPI clk_div
    65532:         SPI cs
    65533:         SPI txdata
    65534:         SPI rxdata
    65535:         UART txdata
*/

localparam BUTTONS_ADDR   = 65528;
localparam RESET_REG_ADDR = 65529;
localparam SEL_REG_ADDR   = 65530;

localparam SPI_ADDR_START = 65531;
localparam SPI_ADDR_END   = 65534;
localparam UART_ADDR = 65535;

reg  [15:0] cpu_mem_addr_delayed;

// UART loader outputs
wire        uart_cfg_reset;
wire        uart_cfg_we;
wire [15:0] uart_cfg_addr;
wire [15:0] uart_cfg_data;

wire control_core_sys_reset = reset | uart_cfg_reset;

/* ------------------------------ memory buses ------------------------------ */

/* Program memory buses */
wire [15:0] program_memory_addr_bus_0;
wire [15:0] program_memory_data_bus_0;

wire [15:0] program_memory_addr_bus_1;
wire        program_memory_write_we_bus_1;
wire [15:0] program_memory_write_data_bus_1;

/* Data memory buses, cpu port */
wire [15:0] data_memory_addr_bus_0;
wire [15:0] data_memory_read_data_bus_0;
wire        data_memory_write_we_bus_0;
wire [15:0] data_memory_write_data_bus_0;

/* Data memory buses, uart loader port */
wire [15:0] data_memory_addr_bus_1;
wire        data_memory_write_we_bus_1;
wire [15:0] data_memory_write_data_bus_1;

/* SPI dout */
wire [15:0] spi_dout;

wire [15:0] cpu_mem_din = (cpu_mem_addr_delayed >= SPI_ADDR_START && cpu_mem_addr_delayed <= SPI_ADDR_END) ? spi_dout : 
                            cpu_mem_addr_delayed == BUTTONS_ADDR                                           ? buttons :
                            data_memory_read_data_bus_0;

/* ----------------------------------- ROM CPU ---------------------------------- */

wire resume_spi;
wire resume_uart;
wire cpu_resume = resume_spi | resume_uart;

/* cpu output buses for data memory */
wire        cpu_mem_dout_we;
wire [15:0] cpu_mem_addr;
wire [15:0] cpu_mem_dout;

cpu #(
    .CODE_ADDR_WIDTH(10),
    .DATA_ADDR_WIDTH(16),
    .FP(512)
)
cpu(
    .clk(clk),
    .resume(cpu_resume),
    .reset(control_core_sys_reset),
    .code_addr(program_memory_addr_bus_0),
    .instruction(program_memory_data_bus_0),
    .mem_addr(cpu_mem_addr),
    .mem_din(cpu_mem_din),
    .mem_dout_we(cpu_mem_dout_we),
    .mem_dout(cpu_mem_dout)
);

assign mem_dout      = cpu_mem_dout;
assign mem_dout_addr = cpu_mem_addr;
assign mem_dout_we   = cpu_mem_dout_we;

/* --------------------------------- SD card SPI master ---------------------------------- */

/*
    ADDR    DESCRIPTION  
    65531   clk_div, r/w
    65532   cs,      r/w
    65533   tx_data, r/w
    65534   rx_data, r
*/

wire [15:0] spi_addr    = (cpu_mem_addr - SPI_ADDR_START);
wire        is_spi_addr = (cpu_mem_addr >= SPI_ADDR_START) && (cpu_mem_addr <= SPI_ADDR_END);

spi_master spi_master_sd (
    .clk(clk),
    .reset(control_core_sys_reset),

    .mem_addr(spi_addr),
    .mem_din(cpu_mem_dout),
    .mem_din_we(cpu_mem_dout_we && is_spi_addr),
    .mem_dout(spi_dout),

    .resume(resume_spi),

    .spi_clk(spi_clk_sd),
    .spi_mosi(spi_mosi_sd),
    .spi_miso(spi_miso_sd),
    .spi_cs(spi_cs_sd)
);

/* --------------------------------- UART ---------------------------------- */

/*
    ADDR    DESCRIPTION  
    65535   w=tx_data/r=busy 
*/

wire [15:0] uart_dout;
wire        is_uart_addr = cpu_mem_addr == UART_ADDR;

uart uart (
    .clk(clk),
    .reset(control_core_sys_reset),

    .mem_din(cpu_mem_dout),
    .mem_din_we(cpu_mem_dout_we && is_uart_addr),
    .mem_dout(uart_dout),

    .resume(resume_uart),
    .uart_tx(uart_tx)
);

/* ------------------------------- UART Loader ----------------------------- */

uart_loader uart_loader(
    .clk(clk),
    .reset(reset),
    .uart_rx(uart_rx),
    .cfg_addr(uart_cfg_addr),
    .cfg_data(uart_cfg_data),
    .cfg_we(uart_cfg_we),
    .cfg_reset(uart_cfg_reset)
);

/* ------------------------------- data memory ----------------------------- */

/* Data memory buses, cpu port */
assign data_memory_addr_bus_0       = cpu_mem_addr;
assign data_memory_write_we_bus_0   = cpu_mem_dout_we && cpu_mem_addr < 512;
assign data_memory_write_data_bus_0 = cpu_mem_dout;

/* Data memory buses, uart loader port */
assign data_memory_addr_bus_1       = uart_cfg_addr[12:0];
assign data_memory_write_we_bus_1   = uart_cfg_we && (uart_cfg_addr >= 8192 && uart_cfg_addr < 16384);
assign data_memory_write_data_bus_1 = uart_cfg_data;

data_memory #(
    .WIDTH(9),
    .SIZE(512),
    .ROM_CORE(1)
)
data_memory(
    .clk(clk),

    .mem_addr_0(data_memory_addr_bus_0),
    .mem_dout_0(data_memory_read_data_bus_0),
    .mem_we_0(data_memory_write_we_bus_0),
    .mem_din_0(data_memory_write_data_bus_0),

    .mem_addr_1(data_memory_addr_bus_1),
    .mem_we_1(data_memory_write_we_bus_1),
    .mem_din_1(data_memory_write_data_bus_1)
);


/* ----------------------------- program memory ----------------------------- */

assign program_memory_addr_bus_1       = uart_cfg_addr[12:0];
assign program_memory_write_we_bus_1   = uart_cfg_we && uart_cfg_addr < 8192;
assign program_memory_write_data_bus_1 = uart_cfg_data;

program_memory #(
    .WIDTH(10),
    .SIZE(1024),
    .ROM_CORE(1)
)
program_memory(
    .clk(clk),
    .mem_dout_addr(program_memory_addr_bus_0),
    .mem_dout(program_memory_data_bus_0),

    .mem_din_addr(program_memory_addr_bus_1),
    .mem_din(program_memory_write_data_bus_1),
    .mem_din_we(program_memory_write_we_bus_1)
);

wire game_core_reset_new  = (cpu_mem_addr == RESET_REG_ADDR) && cpu_mem_dout_we ? cpu_mem_dout[0] : game_core_reset;
wire control_core_sel_new = (cpu_mem_addr == SEL_REG_ADDR)   && cpu_mem_dout_we ? cpu_mem_dout[0] : control_core_sel;

always_ff @(posedge clk) begin
    if (reset) begin
        cpu_mem_addr_delayed <= '0;
        game_core_reset      <= '0;
        control_core_sel     <= '0;
    end else begin
        cpu_mem_addr_delayed <= cpu_mem_addr;
        game_core_reset      <= game_core_reset_new;
        control_core_sel     <= control_core_sel_new;
    end
end


endmodule
