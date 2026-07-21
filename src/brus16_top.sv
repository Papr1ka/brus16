/*
    Brus 16 top module
*/

`include "constants.svh"


module brus16_top #(
    parameter CODE_ADDR_WIDTH     = `CODE_ADDR_WIDTH,
    parameter DATA_ADDR_WIDTH     = `DATA_ADDR_WIDTH,
    parameter DEFAULT_COLOR       = `DEFAULT_COLOR,
    parameter BUTTON_COUNT        = `KEY_NUM,
    parameter BUTTON_ADDR         = `KEY_MEM,
    parameter COORD_WIDTH         = `COORD_WIDTH,
    parameter RESET_COUNTER_WIDTH = `RESET_COUNTER_WIDTH,
    parameter DS2_CLK_RATIO       = `DS2_CLK_RATIO
)
(
    input wire clk,

// DUALSHOCK 2 controllers
`ifndef DISABLE_CONTROLLERS
    output     joystick_clk_0,
    output     joystick_mosi_0,
    input      joystick_miso_0,
    output reg joystick_cs_0,
    
    output     joystick_clk_1,
    output     joystick_mosi_1,
    input      joystick_miso_1,
    output reg joystick_cs_1,
`endif

`ifdef SIM
    output wire        hsync_out,
    output wire        vsync_out,
    output wire [15:0] rgb_out,
    input  wire [15:0] buttons_in,
    output wire [15:0] sample_out,
    output wire        audio_clk_out,
`endif
    // Control core SPI SD card
    output wire spi_clk_sd,
    output wire spi_mosi_sd,
    input  wire spi_miso_sd,
    output wire spi_cs_sd,

    // Control core UART
    input  wire uart_rx,
    output wire uart_tx,

    output wire [3:0]  hdmi_tx_n,
    output wire [3:0]  hdmi_tx_p
);

reg [4:0][2:0]   dvh_delay;  // shift register (delay)
reg [2:0]        dvh;        // vsync, display_on_reg, hsync
reg [15:0]       rgb_reg;

// Control core outputs
wire        control_core_sel;
wire        game_core_reset;
wire [15:0] control_core_mem_dout_addr;
wire [15:0] control_core_mem_dout;
wire        control_core_mem_dout_we;

`ifdef SIM
assign hsync_out = dvh_delay[4][0];
assign vsync_out = dvh_delay[4][1];
assign rgb_out = rgb_reg;
`endif


/* ----------------------------------- PLL ---------------------------------- */

wire system_clk; // clk for the whole system, 25.2 MHz
wire vga_x5;     // system_clk x5 (126 MHz) (for HDMI)
wire lock;       // PLL lock

pll_generic pll_generic(
    .clk(clk),
    .system_clk(system_clk),
    .vga_x5(vga_x5),
    .lock(lock)
);


/* ------------------------------ Global reset ------------------------------ */

reg [RESET_COUNTER_WIDTH-1:0] reset_counter = RESET_COUNTER_WIDTH'(0);
reg was_reset = 1'b0;

reg reset         = 1'b0;
reg reset_osers_0 = 1'b0;
reg reset_osers_1 = 1'b0;

always_ff @(posedge system_clk) begin
    reset_counter <= reset_counter + 1;
    if (reset_counter == {RESET_COUNTER_WIDTH{1'b1}}) begin
        was_reset <= 1'b1;
    end else begin
        was_reset <= was_reset;
    end
    reset <= ~lock | ~was_reset;
end


always_ff @(posedge vga_x5 or posedge reset) begin
    if (reset) begin
        reset_osers_0 <= 1'b0;
        reset_osers_1 <= 1'b0;    
    end else begin
        reset_osers_0 <= reset;
        reset_osers_1 <= reset_osers_0;
    end
end

/* ------------------------------- VGA 640x480 ------------------------------ */

// vga_controller starts at hpos=5, hdmi has it's own logic, starts at hpos=0
// gpu has a delay of 5 clocks
// when hdmi hpos=5 (cx signal), gpu will produce rgb_8_8_8 for (hpos=5)

wire [9:0] hpos;
wire [9:0] vpos;
wire display_on;
wire hsync;
wire vsync;

vga_controller vga_controller(
    .clk(system_clk),
    .reset(reset),

    .hsync(hsync),
    .vsync(vsync),

    .display_on(display_on),
    .hpos(hpos),
    .vpos(vpos)
);


/* ----------------------------- Main controller ---------------------------- */
wire [1:0] peripheral_sel; // which peripheral must be connected to data memory port 1

// spike signals
wire cpu_pulse;
wire gpu_pulse;
wire rc_controller_pulse;
wire button_controller_pulse;
wire sfx_controller_pulse;

brus16_controller brus16_controller(
    .clk(system_clk),
    .reset(reset),
    .vpos(vpos),

    .peripheral_sel(peripheral_sel),
    .cpu_pulse(cpu_pulse),
    .gpu_pulse(gpu_pulse),
    .rc_controller_pulse(rc_controller_pulse),
    .button_controller_pulse(button_controller_pulse),
    .sfx_controller_pulse(sfx_controller_pulse)
);


/* -------------------------- buttons logic ------------------------- */
wire                       bc_mem_dout_we;
wire [DATA_ADDR_WIDTH-1:0] bc_mem_dout_addr;
wire [15:0]                bc_mem_dout;
wire [15:0]                buttons;

buttons_top buttons_top(
    .clk(system_clk),
    .reset(reset),
    .copy_start(button_controller_pulse),
    .bc_reset_pulse(cpu_pulse),

`ifndef DISABLE_CONTROLLERS
    // joystick 0
    .joystick_clk_0(joystick_clk_0),
    .joystick_mosi_0(joystick_mosi_0),
    .joystick_miso_0(joystick_miso_0),
    .joystick_cs_0(joystick_cs_0),
    // joystick 1
    .joystick_clk_1(joystick_clk_1),
    .joystick_mosi_1(joystick_mosi_1),
    .joystick_miso_1(joystick_miso_1),
    .joystick_cs_1(joystick_cs_1),
`endif

    .buttons(buttons),
    // data memory interface
    .mem_dout_we(bc_mem_dout_we),
    .mem_dout_addr(bc_mem_dout_addr),
    .mem_dout(bc_mem_dout)
);


/* ------------------------------ memory buses ------------------------------ */

/* Program memory buses */
wire [CODE_ADDR_WIDTH-1:0] program_memory_addr_bus_0;
wire [15:0]                program_memory_data_bus_0;

wire [CODE_ADDR_WIDTH-1:0] program_memory_addr_bus_1;
wire                       program_memory_write_we_bus_1;
wire [15:0]                program_memory_write_data_bus_1;

/* Data memory buses, cpu port */
wire [DATA_ADDR_WIDTH-1:0] data_memory_addr_bus_0;
wire [15:0]                data_memory_read_data_bus_0;
wire                       data_memory_write_we_bus_0;
wire [15:0]                data_memory_write_data_bus_0;

/* Data memory buses, peripheral port */
wire [DATA_ADDR_WIDTH-1:0] data_memory_addr_bus_1;
wire [15:0]                data_memory_read_data_bus_1;
wire                       data_memory_write_we_bus_1;
wire [15:0]                data_memory_write_data_bus_1;


/* --------------------------------- game cpu --------------------------------- */

/* cpu output buses for data memory */
wire                       cpu_mem_dout_we;
wire [DATA_ADDR_WIDTH-1:0] cpu_mem_addr;
wire [15:0]                cpu_mem_dout;

/*
    cpu reset:
    set to 1 instantly
    set to 0 only after cpu_pulse to ensure a sufficient clock cycle reserve before vsync
*/

reg   cpu_reset = 1'b1;
logic cpu_reset_new;

always_comb begin
    casez ({cpu_reset, reset | game_core_reset, cpu_pulse})
        3'b100:  cpu_reset_new = cpu_reset;
        3'b101:  cpu_reset_new = 1'b0;
        3'b01?:  cpu_reset_new = 1'b1;
        default: cpu_reset_new = reset | game_core_reset;
    endcase
end

always_ff @(posedge system_clk) begin
    cpu_reset <= cpu_reset_new;
end

cpu cpu(
    .clk(system_clk),
    .resume(cpu_pulse),
    .reset(cpu_reset),
    .code_addr(program_memory_addr_bus_0),
    .instruction(program_memory_data_bus_0),
    .mem_addr(cpu_mem_addr),
    .mem_din(data_memory_read_data_bus_0),
    .mem_dout_we(cpu_mem_dout_we),
    .mem_dout(cpu_mem_dout)
);


/* ------------------------------- control core ----------------------------- */

control_core control_core(
    .clk(system_clk),
    .reset(reset),

    .game_core_reset(game_core_reset),
    .control_core_sel(control_core_sel),
    
    .buttons(buttons),

    .mem_dout_addr(control_core_mem_dout_addr),
    .mem_dout(control_core_mem_dout),
    .mem_dout_we(control_core_mem_dout_we),

    .spi_clk_sd(spi_clk_sd),
    .spi_mosi_sd(spi_mosi_sd),
    .spi_miso_sd(spi_miso_sd),
    .spi_cs_sd(spi_cs_sd),

    .uart_rx(uart_rx),
    .uart_tx(uart_tx)
);

/* ---------------------------------- sfx ----------------------------------  */

wire [DATA_ADDR_WIDTH-1:0] sfx_read_addr; // data memory read addr
wire                       audio_clk;     // audio clk, 44100 Hz
wire [15:0]                sample;        // current audio sample

sfx_top sfx_top(
    .clk(system_clk),
    .reset(reset),
    .copy(peripheral_sel == 2'd2),
    .copy_pulse(sfx_controller_pulse),
    
    // data memory interface
    .mem_din_addr(sfx_read_addr),
    .mem_din(data_memory_read_data_bus_1),

    .sample_out(sample),
    .audio_clk(audio_clk)
);

`ifdef SIM
assign sample_out    = sample;
assign audio_clk_out = audio_clk;
`endif


/* ----------------------------------- gpu ---------------------------------- */
wire [15:0]                gpu_rgb; // 5 clocks delayed rgb 5 6 5
wire [15:0]                rgb = control_core_sel ? DEFAULT_COLOR : gpu_rgb;
wire [DATA_ADDR_WIDTH-1:0] rc_controller_mem_din_addr;


gpu_top gpu_top(
    .clk(system_clk),
    .reset(reset),
    .peripheral_sel(peripheral_sel),
    .rc_controller_pulse(rc_controller_pulse),
    .gpu_pulse(gpu_pulse),

    .mem_din_addr(rc_controller_mem_din_addr),
    .mem_din(data_memory_read_data_bus_1),

    .hpos(hpos),
    .vpos(vpos),
    .display_on(dvh_delay[4][2]),
    
    .rgb(gpu_rgb)
);


/* ---------------------------------- HDMI ---------------------------------- */

`ifndef SIM
// rgb 5 6 5 decode
wire [23:0] rgb_8_8_8 = {
    rgb_reg[15:11], rgb_reg[15:13],
    rgb_reg[10:5], rgb_reg[10:9],
    rgb_reg[4:0], rgb_reg[4:2]
};

wire [2:0] tmds;
wire       tmds_clock;

ELVDS_OBUF OBUFDS_clock(.I(tmds_clock), .O(hdmi_tx_p[3]), .OB(hdmi_tx_n[3]));
ELVDS_OBUF OBUFDS_r(.I(tmds[2]), .O(hdmi_tx_p[2]), .OB(hdmi_tx_n[2]));
ELVDS_OBUF OBUFDS_g(.I(tmds[1]), .O(hdmi_tx_p[1]), .OB(hdmi_tx_n[1]));
ELVDS_OBUF OBUFDS_b(.I(tmds[0]), .O(hdmi_tx_p[0]), .OB(hdmi_tx_n[0]));

// left and right channel
wire [15:0] dual_channel [1:0] = {sample, sample};

hdmi #(
    .VIDEO_REFRESH_RATE(60),
    .VENDOR_NAME({"Brus-16", 8'd0})
) hdmi (
    .clk_pixel_x5(vga_x5),
    .clk_pixel(system_clk),
    .clk_audio(audio_clk),
    .reset(reset),
    .reset_osers(reset_osers_1),
    .rgb(rgb_8_8_8),
    .audio_sample_word(dual_channel),
    .tmds(tmds),
    .tmds_clock(tmds_clock)
);
`endif


/* ------------------------------- data memory ------------------------------ */

wire control_core_addr_to_data_memory = (control_core_mem_dout_addr >= 24576 && control_core_mem_dout_addr < 32768);
wire control_core_we_to_data_memory   = control_core_mem_dout_we && control_core_addr_to_data_memory;

/* Data memory buses, cpu port */
assign data_memory_addr_bus_0       = control_core_sel ? control_core_mem_dout_addr[12:0] : cpu_mem_addr;
assign data_memory_write_we_bus_0   = control_core_sel ? control_core_we_to_data_memory   : cpu_mem_dout_we;
assign data_memory_write_data_bus_0 = control_core_sel ? control_core_mem_dout            : cpu_mem_dout;

/* Data memory buses, peripheral port */

/*
0 => rect copy controller
1 => button_controller
2 => sfx_controller
3 => no write
*/

assign data_memory_addr_bus_1       = peripheral_sel == 2'd0 ? rc_controller_mem_din_addr :
                                      peripheral_sel == 2'd1 ? bc_mem_dout_addr :
                                      peripheral_sel == 2'd2 ? sfx_read_addr :
                                      rc_controller_mem_din_addr;

assign data_memory_write_data_bus_1 = peripheral_sel == 2'd0 ? 16'b0 :
                                      peripheral_sel == 2'd1 ? bc_mem_dout :
                                      peripheral_sel == 2'd2 ? 16'b0 :
                                      16'b0;

assign data_memory_write_we_bus_1   = peripheral_sel == 2'd0 ? 1'b0 :
                                      peripheral_sel == 2'd1 ? bc_mem_dout_we :
                                      peripheral_sel == 2'd2 ? 1'b0 :
                                      1'b0;

data_memory data_memory(
    .clk(system_clk),

    .mem_addr_0(data_memory_addr_bus_0),
    .mem_dout_0(data_memory_read_data_bus_0),
    .mem_we_0(data_memory_write_we_bus_0),
    .mem_din_0(data_memory_write_data_bus_0),

    .mem_addr_1(data_memory_addr_bus_1),
    .mem_dout_1(data_memory_read_data_bus_1),
    .mem_we_1(data_memory_write_we_bus_1),
    .mem_din_1(data_memory_write_data_bus_1)
);


/* ----------------------------- program memory ----------------------------- */

wire control_core_addr_to_program_memory = (control_core_mem_dout_addr >= 16384 && control_core_mem_dout_addr < 24576);
wire control_core_we_to_program_memory   = control_core_mem_dout_we && control_core_addr_to_program_memory;

assign program_memory_addr_bus_1 = control_core_mem_dout_addr[12:0];
assign program_memory_write_we_bus_1 = control_core_we_to_program_memory;
assign program_memory_write_data_bus_1 = control_core_mem_dout;

program_memory program_memory(
    .clk(system_clk),
    // read port
    .mem_dout_addr(program_memory_addr_bus_0),
    .mem_dout(program_memory_data_bus_0),

    // write port
    .mem_din_addr(program_memory_addr_bus_1),
    .mem_din(program_memory_write_data_bus_1),
    .mem_din_we(program_memory_write_we_bus_1)
);


/* ----------------------------- SEQUENTIAL LOGIC ----------------------------- */

always_ff @(posedge system_clk) begin
    if (reset) begin
        rgb_reg            <= 16'b0;
        dvh                <= 3'b0;
        dvh_delay          <= '0;
    end else begin
        rgb_reg            <= rgb;
        dvh                <= {display_on, vsync, hsync};
        dvh_delay          <= {dvh_delay[3:0], dvh};
    end
end

initial begin
    $dumpfile("dump.vcd");
    $dumpvars(1, control_core);
end

endmodule
