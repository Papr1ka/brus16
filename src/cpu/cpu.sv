/*
    CPU
    works in a single cycle

    after work, WAIT cmd sets the wait flag, frozing computations
    after resume, cpu continues to work, setting wait flag to 0
*/

`include "constants.svh"


module cpu
#(
    parameter CODE_ADDR_WIDTH   = `CODE_ADDR_WIDTH,
    parameter DATA_ADDR_WIDTH   = `DATA_ADDR_WIDTH,
    parameter STACK_DEPTH       = `STACK_DEPTH,
    parameter RSTACK_DEPTH      = `RSTACK_DEPTH,
    parameter KEY_MEM           = `KEY_MEM
)
(
    input   wire                        clk,
    input   wire                        reset,          // reset cpu, start from scratch
    input   wire                        resume,         // continue work after wait

    // Input code bus
    output  wire [CODE_ADDR_WIDTH-1:0]  code_addr,      // pc (what instruction to fetch)
    input   wire [15:0]                 instruction,    // instruction from program memory

    // Input data bus
    output  wire [DATA_ADDR_WIDTH-1:0]  mem_din_addr,   // data mem, read address
    input   wire [15:0]                 mem_din,        // data mem, data

    // Output data bus
    output  wire                        mem_dout_we,    // write enable to data mem
    output  wire [DATA_ADDR_WIDTH-1:0]  mem_dout_addr,  // data mem, write address
    output  wire [15:0]                 mem_dout        // data mem, write data
);

/*
    Data stack
*/

reg     [STACK_DEPTH-1:0] sp;   // stack pointer (pointing to stack_top)
logic   [STACK_DEPTH-1:0] sp_new;

wire    [STACK_DEPTH-1:0] sp_plus_1  = sp + 1;
wire    [STACK_DEPTH-1:0] sp_minus_1 = sp - 1;

wire    [15:0] stack_top;       // top element of stack
logic   [15:0] stack_top_new;
wire    [15:0] stack_pre_top;   // stack[sp-1] element of stack

logic write_to_stack;           // write enable to stack

stack #(
    .WIDTH(STACK_DEPTH),
    .SIZE(1 << STACK_DEPTH)
)
stack(
    .clk(clk),

    .mem_dout_addr0(sp),
    .mem_dout0(stack_top),

    .mem_dout_addr1(sp_minus_1),
    .mem_dout1(stack_pre_top),

    .we(write_to_stack),
    .mem_din_addr(sp_new),
    .mem_din(stack_top_new)
);

/*
    Return stack
*/

reg     [RSTACK_DEPTH-1:0] rsp;             // return stack pointer (pointing to rstack_top)
logic   [RSTACK_DEPTH-1:0] rsp_new;

reg     [CODE_ADDR_WIDTH-1:0] rstack_top;   // top element of return stack
logic   [CODE_ADDR_WIDTH-1:0] rstack_top_new;

logic write_to_rstack;                      // write enable to return stack

rstack #(
    .WIDTH(RSTACK_DEPTH),
    .SIZE(1 << RSTACK_DEPTH),
    .DATA_WIDTH(CODE_ADDR_WIDTH)
)
rstack(
    .clk(clk),

    .mem_dout_addr(rsp),
    .mem_dout(rstack_top),

    .we(write_to_rstack),
    .mem_din_addr(rsp_new),
    .mem_din(rstack_top_new)
);

/*
    Command formats
    F1: [('F', 1), ('OP', 2), ('IMM', 13)]              JMP, JZ, CALL, PUSH_ADDR
    F2: [('F', 1), ('OP', 5), ('I', 1), ('SIMM', 9)]    Other
*/

wire [15:0] instr       = reset ? 18944 : instruction; // 18944 = LOCALS 0 (MODE 1) = NOP
wire [15:0] instr_simm9 = {{7{instr[8]}}, instr[8:0]};
wire [15:0] instr_imm13 = {3'b0, instr[12:0]};
wire [4:0]  opcode      = instr[14:10];

wire cmd_type   = instr[15];    // format 1 or format 2
wire mode       = instr[9];     // use immediate if mode else from stack


reg     [CODE_ADDR_WIDTH-1:0] pc;   // program counter
logic   [CODE_ADDR_WIDTH-1:0] pc_new;
wire    [CODE_ADDR_WIDTH-1:0] pc_plus_1 = pc + 1;
wire    [CODE_ADDR_WIDTH-1:0] pc_jz     = (~|stack_top) ? instr_imm13[12:0] : pc_plus_1;
reg     [DATA_ADDR_WIDTH-1:0] fp;   // frame pointer
logic   [DATA_ADDR_WIDTH-1:0] fp_new;
reg     wait_flag;
logic   wait_flag_new;


assign code_addr = pc_new;
wire [DATA_ADDR_WIDTH-1:0] mem_abs_addr =  (mode ?
                                            fp :
                                            stack_top[DATA_ADDR_WIDTH-1:0]
                                            ) + instr_simm9[DATA_ADDR_WIDTH-1:0];

assign mem_dout_we   = (!cmd_type && opcode == `STORE) ? 1'b1 : 1'b0;
assign mem_dout      = mode ? stack_top : stack_pre_top;
assign mem_dout_addr = mem_abs_addr;
assign mem_din_addr  = mem_abs_addr;

/*
    ALU
*/

wire [15:0] alu_x = mode ? stack_top : stack_pre_top;
wire [15:0] alu_y = mode ? instr_simm9 : stack_top;
wire [15:0] alu_out;

wire is_alu = !cmd_type && opcode < `LOAD;

alu alu(
    .opcode(opcode),
    .a(alu_x),
    .b(alu_y),
    .out(alu_out)
);

/*
    Combinational logic
*/

// PC logic
always_comb begin
    casez ({cmd_type, opcode, wait_flag, resume})
        8'b?_??_???_?_1:     pc_new = pc_plus_1;         // Resume
        8'b?_??_???_1_0,                                 // In wait state
        {1'b0, `WAIT, 2'b0}: pc_new = pc;                // Set wait
        8'b1_00_???_0_0,                                 // JMP
        8'b1_10_???_0_0:     pc_new = instr_imm13[12:0]; // CALL
        8'b1_01_???_0_0:     pc_new = pc_jz;             // JZ
        {1'b0, `RET, 2'b0}:  pc_new = rstack_top;        // RET
        default:             pc_new = pc_plus_1;
    endcase
end

// FP logic
always_comb begin
    case ({cmd_type, opcode})
        {1'b0, `LOCALS}: fp_new = fp - instr_simm9[DATA_ADDR_WIDTH-1:0];
        {1'b0, `RET}:    fp_new = fp + instr_simm9[DATA_ADDR_WIDTH-1:0];
        {1'b0, `SET_FP}: fp_new = stack_top[DATA_ADDR_WIDTH-1:0];
        default:         fp_new = fp;
    endcase
end

// Return stack logic
always_comb begin
    casez ({cmd_type, opcode})
        6'b1_10_???: rstack_top_new = pc_plus_1; // CALL
        default:     rstack_top_new = DATA_ADDR_WIDTH'('x);
    endcase
end

always_comb begin
    casez ({cmd_type, opcode})
        6'b1_10_???:  rsp_new = rsp + 1; // CALL
        {1'b0, `RET}: rsp_new = rsp - 1;
        default:      rsp_new = rsp;
    endcase
end

always_comb begin
    casez ({cmd_type, opcode})
        6'b1_10_???: write_to_rstack = 1'b1; // CALL
        default:     write_to_rstack = 1'b0;
    endcase
end

// Stack logic
always_comb begin
    casez ({cmd_type, is_alu, opcode})
        {2'b00, `LOAD},
        7'b01?????:         sp_new = mode ? sp : sp_minus_1;    // ALU
        {2'b00, `STORE}:    sp_new = mode ? sp_minus_1 : sp - 2;
        {2'b00, `SET_FP},
        {7'b10_01_???}:     sp_new = sp_minus_1;                // JZ
        {2'b00, `PUSH_INT},
        {2'b00, `PUSH_MR},
        7'b10_11_???:       sp_new = sp_plus_1;                 // PUSH_ADDR
        default:            sp_new = sp;                        // LOCALS, RET, WAIT, JMP, CALL, ANY
    endcase
end

always_comb begin
    casez ({cmd_type, is_alu, opcode})
        7'b01?????:         stack_top_new = alu_out;        // ALU
        {2'b00, `PUSH_INT}: stack_top_new = instr_simm9;
        {2'b00, `PUSH_MR}:  stack_top_new = mem_din;
        7'b10_11_???:       stack_top_new = instr_imm13;    // PUSH_ADDR
        default:            stack_top_new = 16'bx;
    endcase
end

always_comb begin
    casez ({cmd_type, is_alu, opcode})
        7'b01?????,                                 // ALU
        {2'b00, `PUSH_INT},
        {2'b00, `PUSH_MR},
        7'b10_11_???:       write_to_stack = 1'b1;  // PUSH_ADDR
        default:            write_to_stack = 1'b0;
    endcase
end

always_comb begin
    casez({cmd_type, opcode, resume})
        {1'b0, `WAIT, 1'b0}: wait_flag_new = 1'b1;
        {7'b?_?????_1}:      wait_flag_new = 1'b0;
        default:             wait_flag_new = wait_flag;
    endcase
end

// Sequential logic
always_ff @(posedge clk) begin
    if (reset) begin
        pc  <= {CODE_ADDR_WIDTH{1'b1}};
        sp  <= STACK_DEPTH'(0);
        rsp <= RSTACK_DEPTH'(0);
        fp  <= DATA_ADDR_WIDTH'(KEY_MEM);
        wait_flag <= 1'b0;
    end else begin
        pc  <= pc_new;
        sp  <= sp_new;
        rsp <= rsp_new;
        fp  <= fp_new;
        wait_flag <= wait_flag_new;
    end
end

endmodule
