module cpu_tb(
    input wire clk,
    input wire reset,
    input wire resume
);

parameter CODE_WIDTH = 13;
parameter DATA_WIDTH = 13;

wire [CODE_WIDTH-1:0] code_addr;
wire [15:0] instr;

wire cpu_mem_dout_we;
wire [DATA_WIDTH-1:0] cpu_mem_dout_addr;
wire [15:0] cpu_mem_dout;

wire [DATA_WIDTH-1:0] cpu_mem_din_addr;
wire [15:0] cpu_mem_din;

cpu cpu(
    .clk(clk),
    .resume(resume),
    .reset(reset),
    .code_addr(code_addr),
    .instruction(instr),
    .mem_din_addr(cpu_mem_din_addr),
    .mem_din(cpu_mem_din),
    .mem_dout_we(cpu_mem_dout_we),
    .mem_dout_addr(cpu_mem_dout_addr),
    .mem_dout(cpu_mem_dout)
);

bsram memory(
    .clk(clk),
    .mem_dout_addr(cpu_mem_din_addr),
    .mem_dout(cpu_mem_din),

    .we(cpu_mem_dout_we),
    .mem_din_addr(cpu_mem_dout_addr),
    .mem_din(cpu_mem_dout)
);

/* verilator lint_off PINMISSING */
bsram program_memory(
    .clk(clk),
    .mem_dout_addr(code_addr),
    .mem_dout(instr)
);
/* verilator lint_on PINMISSING */

endmodule
