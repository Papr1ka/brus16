// `include "~/dev/brus16/src/defs.vh"

/*
    CPU
    works in a single cycle

    after work, WAIT cmd sets the wait flag, frozing computations
    after resule, cmd continues work, setting wait flag to 0
*/

`define CODE_WIDTH 13
`define DATA_WIDTH 13

`define JMP 2'd0
`define JZ 2'd1
`define CALL 2'd2
`define PUSH_ADDR 2'd3

`define ADD 5'd0
`define SUB 5'd1
`define MUL 5'd2
`define AND 5'd3
`define OR 5'd4
`define XOR 5'd5
`define SHL 5'd6
`define SHR 5'd7
`define SHRA 5'd8
`define EQ 5'd9
`define NEQ 5'd10
`define LT 5'd11
`define LE 5'd12
`define GT 5'd13
`define GE 5'd14
`define LTU 5'd15
`define LOAD 5'd16
`define STORE 5'd17
`define LOCALS 5'd18
`define SET_FP 5'd19
`define ICALL 5'd20
`define RET 5'd21
`define PUSH_INT 5'd22
`define PUSH_MR 5'd23
`define POP 5'd24
`define WAIT 5'd25


module cpu
#(
    parameter CODE_WIDTH = `CODE_WIDTH,
    parameter DATA_WIDTH = `DATA_WIDTH,
    parameter STACK_DEPTH = 6,
    parameter RSTACK_DEPTH = 5
)
(
    input wire clk,
    input wire reset, // reset cpu, start from scratch
    input wire resume, // continue work after wait

    output wire [CODE_WIDTH-1:0] code_addr, // pc (what instruction to fetch)
    input wire [15:0] instruction, // instruction from program memory

    output wire [DATA_WIDTH-1:0] mem_din_addr, // data mem, read address
    input wire [15:0] mem_din, // data mem, data

    output wire mem_dout_we, // write enable to data mem
    output wire [DATA_WIDTH-1:0] mem_dout_addr, // data mem, write address
    output wire [15:0] mem_dout // data mem, write data
);

/*
    data stack
*/
reg [STACK_DEPTH-1:0] sp; // stack pointer (pointing to stack_top)
reg [STACK_DEPTH-1:0] sp_new; // (logic)

wire [STACK_DEPTH-1:0] sp_plus_1 = sp + 1;
wire [STACK_DEPTH-1:0] sp_minus_1 = sp - 1;

wire [15:0] stack_top; // top element of stack
reg [15:0] stack_top_new; // (logic)
wire [15:0] stack_pre_top; // (top - 1) element of stack

reg write_to_stack; // sp_new (logic) write enable to stack

stack #(
    .WIDTH(STACK_DEPTH),
    .SIZE(1 << STACK_DEPTH)
)
stack(
    .clk(clk),

    .mem_dout_addr0(sp),
    .mem_dout0(stack_top),

    .mem_dout_addr1(sp - 1),
    .mem_dout1(stack_pre_top),

    .we(write_to_stack),
    .mem_din_addr(sp_new),
    .mem_din(stack_top_new)
);

/*
    return stack
*/

reg [RSTACK_DEPTH-1:0] rsp; // return stack pointer (pointing to rstack_top)
reg [RSTACK_DEPTH-1:0] rsp_new; // (logic)

reg [`CODE_WIDTH-1:0] rstack_top; // top element of return stack
reg [`CODE_WIDTH-1:0] rstack_top_new; // (logic)

reg write_to_rstack; // sp_new(logic) write enable to return stack

dsram #(
    .WIDTH(RSTACK_DEPTH),
    .SIZE(1 << RSTACK_DEPTH),
    .DATA_WIDTH(`CODE_WIDTH)
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

F1 = [('F', 1), ('OP', 2), ('IMM', 13)]
    JMP, JZ, CALL, PUSH_ADDR
F2 = [('F', 1), ('OP', 5), ('I', 1), ('SIMM', 9)]
    Other
*/
wire [15:0] instr = reset ? 19456 : instruction; // 19456 = SET_FP 0 = NOP

wire cmd_type = instr[15]; // format 1 or format 2

wire [4:0] opcode = instr[14:10];
wire mode = instr[9]; // use immediate if mode else from stack
wire [15:0] instr_simm9 = {{7{instr[8]}}, instr[8:0]};
wire [15:0] instr_imm13 = {3'b0, instr[12:0]};

reg [CODE_WIDTH-1:0] pc; // program counter
reg [DATA_WIDTH-1:0] fp; // frame pointer
reg [CODE_WIDTH-1:0] pc_new; // (logic)
reg [DATA_WIDTH-1:0] fp_new; // (logic)

reg wait_flag;
reg wait_flag_new; // logic

assign code_addr = pc_new;
wire [`CODE_WIDTH-1:0] pc_plus_1 = pc + 1;

wire [12:0] mem_abs_addr = mode ? fp + instr_simm9[12:0] : stack_top[12:0];
assign mem_dout_we = (!cmd_type && opcode == `STORE) ? 1'b1 : 1'b0;
assign mem_dout = mode ? stack_top : stack_pre_top;
assign mem_dout_addr = mem_abs_addr;

assign mem_din_addr = mem_abs_addr;
// alu

wire [15:0] alu_out;

wire [15:0] alu_x = mode ? stack_top : stack_pre_top;
wire [15:0] alu_y = mode ? instr_simm9 : stack_top;

wire is_alu = !cmd_type && opcode < `LOAD;

alu alu(
    .opcode(opcode),
    .a(alu_x),
    .b(alu_y),
    .out(alu_out)
);

/*
    logic
*/

// all pc logic
always @(*) begin
    casez ({cmd_type, opcode, wait_flag, resume})
        8'b?_??_???_?_1: pc_new = pc_plus_1;
        8'b?_??_???_1_0: pc_new = pc;
        {1'b0, `WAIT, 2'b0}: pc_new = pc;
        8'b1_00_???_0_0: pc_new = instr_imm13[12:0]; // JMP
        8'b1_01_???_0_0: pc_new = (~|stack_top) ? instr_imm13[12:0] : pc_plus_1; // JZ
        8'b1_10_???_0_0: pc_new = instr_imm13[12:0]; // CALL
        {1'b0, `RET, 2'b0}: pc_new = rstack_top;
        default: pc_new = pc_plus_1;
    endcase
end

// all fp logic
always @(*) begin
    // compute all return stack logic
    case ({cmd_type, opcode})
        {1'b0, `LOCALS}: fp_new = fp - instr_simm9[DATA_WIDTH-1:0];
        {1'b0, `RET}: fp_new = fp + instr_simm9[DATA_WIDTH-1:0];
        {1'b0, `SET_FP}: fp_new = stack_top[DATA_WIDTH-1:0];
        default: fp_new = fp;
    endcase
end

// all return stack logic
always @(*) begin
    casez ({cmd_type, opcode})
        6'b1_10_???, // CALL
        {1'b0, `ICALL}: rstack_top_new = pc_plus_1;
        default: rstack_top_new = rstack_top;
    endcase
end

always @(*) begin
    casez ({cmd_type, opcode})
        6'b1_10_???, // CALL
        {1'b0, `ICALL}: rsp_new = rsp + 1;
        {1'b0, `RET}: rsp_new = rsp - 1;
        default: rsp_new = rsp;
    endcase
end

always @(*) begin
    casez ({cmd_type, opcode})
        6'b1_10_???, // CALL
        {1'b0, `ICALL}: write_to_rstack = 1'b1;
        default: write_to_rstack = 1'b0;
    endcase
end

// all stack logic
always @(*) begin
    casez ({cmd_type, is_alu, opcode})
        {2'b00, `LOAD}: sp_new = mode ? sp : sp_minus_1;

        {2'b00, `STORE}: sp_new = mode ? sp_minus_1 : sp - 2;

        7'b01?????: sp_new = mode ? sp : sp_minus_1; // format 1 + alu + any
        {2'b00, `SET_FP}: sp_new = sp_minus_1;
        {2'b00, `ICALL}: sp_new = sp_minus_1;
        {2'b00, `POP}: sp_new = sp_minus_1;
        {7'b10_01_???}: sp_new = sp_minus_1; // JZ

        {2'b00, `PUSH_INT}: sp_new = sp_plus_1;
        {2'b00, `PUSH_MR}: sp_new = sp_plus_1;
        7'b10_11_???: sp_new = sp_plus_1; // PUSH_ADDR

        default: sp_new = sp; // LOCALS, RET, WAIT, JMP, CALL, ANY
    endcase
end

always @(*) begin
    casez ({cmd_type, is_alu, opcode})
        7'b01?????: stack_top_new = alu_out; // format 1 + alu + any
        {2'b00, `PUSH_INT}: stack_top_new = instr_simm9;
        {2'b00, `PUSH_MR}: stack_top_new = mem_din;
        7'b10_11_???: stack_top_new = instr_imm13; // PUSH_ADDR
        default: stack_top_new = stack_top;
    endcase
end

always @(*) begin
    casez ({cmd_type, is_alu, opcode})
        7'b01?????: write_to_stack = 1'b1; // format 1 + alu + any
        {2'b00, `PUSH_INT}: write_to_stack = 1'b1;
        {2'b00, `PUSH_MR}: write_to_stack = 1'b1;
        7'b10_11_???: write_to_stack = 1'b1; // PUSH_ADDR
        default: write_to_stack = 1'b0;
    endcase
end

always @(*) begin
    casez({cmd_type, opcode, resume})
        {1'b0, `WAIT, 1'b0}: wait_flag_new = 1'b1;
        {7'b?_?????_1}: wait_flag_new = 1'b0;
        default: wait_flag_new = wait_flag;
    endcase
end

// calculation logic
always @(posedge clk) begin
    if (reset) begin
        pc <= (CODE_WIDTH)'(13'b1111111111111);
        sp <= (STACK_DEPTH)'(0);
        rsp <= (RSTACK_DEPTH)'(0);
        fp <= (DATA_WIDTH)'(0);
        wait_flag <= 1'b0;
    end else begin
        pc <= pc_new;
        sp <= sp_new;
        rsp <= rsp_new;
        fp <= fp_new;
        wait_flag <= wait_flag_new;
    end
end

initial begin
    pc = (CODE_WIDTH)'(0);
    sp = (STACK_DEPTH)'(0);
    rsp = (RSTACK_DEPTH)'(0);
    fp = (DATA_WIDTH)'(0);
    wait_flag = 1'b0;
end

endmodule
