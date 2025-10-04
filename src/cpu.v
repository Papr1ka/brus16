// `include "~/dev/brus16/src/defs.vh"

`define CODE_WIDTH 13
`define DATA_WIDTH 13

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
`define LT 5'd10
`define LTU 5'd11
`define LOAD 5'd12
`define STORE 5'd13
`define LEA 5'd14
`define SET_FP 5'd15
`define JMP 5'd16
`define JZ 5'd17
`define JNZ 5'd18
`define CALL 5'd19
`define RET 5'd20
`define PUSH_LO 5'd21
`define PUSH_HI 5'd22
`define POP 5'd23


module cpu
#(
    parameter CODE_WIDTH = `CODE_WIDTH,
    parameter DATA_WIDTH = `DATA_WIDTH,
    parameter STACK_DEPTH = 6,
    parameter RSTACK_DEPTH = 5
)
(
    input wire clk,
    input wire reset,

    output wire [CODE_WIDTH-1:0] code_addr, // pc (what instruction to fetch)
    input wire [15:0] instr, // instruction from program memory

    output wire [DATA_WIDTH-1:0] mem_din_addr, // data mem, read address
    input wire [15:0] mem_din, // data mem, data

    output reg mem_dout_we, // write enable to data mem
    output reg [DATA_WIDTH-1:0] mem_dout_addr, // data mem, write address
    output reg [15:0] mem_dout // data mem, write data
);

// data stack
/*
meaning:
    stack = [8, 7, 6, 5]
representation:
    stack=[0, 0, 8, 7, 6, 0, 0, 0] sp=4 stack_top=5 stack_pre_top=6

when push:
    current clock (execute):
        assign sp_new = sp + 1; // 4
        assign stack_top_new = instr_simm; // 4
        assign write_to_stack = 1'b1;
    clock +1 (writeback):
        (memory write) stack_top => stack // 5
        sp <= sp_new; // 4
        stack_top <= stack_top_new; // 4
        assign write_to_stack = 1'b0;
    clock +3 (next cycle)
        stack = [0, 0, 8, 7, 6, 5, 0, 0] sp = 5 stack_top=4 stack_pre_top=5

(old stack top will be written at sp=5,
new value will be stored at stack_top_register,
stack_pre_top will be syncronized automatically)

stack = [0, 0, 8, 7, 6, 5, 0, 0] sp = 5 stack_top=4 stack_pre_top=5

when pop:
    current clock (execute):
        assign sp_new = sp - 1; // 4
        assign stack_top_new = stack_pre_top; // 5
        assign write_to_stack <= 1'b0;
    clock +1 (writeback):
        sp <= sp_new; // 4
        stack_top <= stack_top_new; // 5
    clock +3 (next cycle)
        stack = [0, 0, 8, 7, 6, 5, 0, 0] sp = 4 stack_top=5 stack_pre_top=6

stack = [0, 0, 8, 7, 6, 5, 0, 0] sp = 4 stack_top=5 stack_pre_top=6

when double pop:
    current clock (execute):
        assign sp_new = sp - 1; // 3
        stack_top_new <= X; // doesn't matter
        write_to_stack <= 1'b0;
        stack_pre_top_to_top <= 1'b1;
        sp <= sp_new; // 3
    clock +1 (writeback):
        if (double_pop)
            assign sp_new = sp - 1 // 2
            assign stack_top_new = stack_pre_top
            double_pop <= 0
        else
        sp <= sp_new; // 2
        stack_top <= stack_top_new; // 6
    clock +2 (next cycle):
        stack = [0, 0, 8, 7, 6, 5, 0, 0] sp = 2 stack_top=7 stack_pre_top=8

rstack, rfpstack works the same
*/


reg [STACK_DEPTH-1:0] sp; // stack pointer (pointing to stack_top_prev)
reg [15:0] stack_top; // top element of stack

reg [STACK_DEPTH-1:0] sp_new; // (logic)
reg [STACK_DEPTH-1:0] sp_new_execute; // (logic)
reg [15:0] stack_top_new; // (logic)
wire [15:0] stack_pre_top; // (top - 1) element of stack
reg write_to_stack; //sp_new (logic) write enable to stack

// pre calculations
wire mode = instr[5]; // use immediate if mode else from stack
wire [STACK_DEPTH-1:0] sp0_mode = mode ? sp : sp - 1;
wire [STACK_DEPTH-1:0] sp1_mode = mode ? sp + 1 : sp;
wire [STACK_DEPTH-1:0] sp1_neg_mode = mode ? sp - 1 : sp - 2;

dsram #(
    .WIDTH(STACK_DEPTH),
    .SIZE(1 << STACK_DEPTH)
)
stack(
    .clk(clk),

    .mem_dout_addr(sp),
    .mem_dout(stack_pre_top),

    .we(write_to_stack),
    .mem_din_addr(sp + 1),
    .mem_din(stack_top_new) // was stack_top
);

// return stack (only for pc), rfpstack for fp's

reg [RSTACK_DEPTH-1:0] rsp; // return stack pointer
reg [`CODE_WIDTH-1:0] rstack_top; // top element of return stack

reg [RSTACK_DEPTH-1:0] rsp_new; // (logic)
reg [`CODE_WIDTH-1:0] rstack_top_new; // (logic)
wire [`CODE_WIDTH-1:0] rstack_pre_top; // (top - 1) element of return stack
reg write_to_rstack; // sp_new(logic) write enable to return stack

dsram #(
    .WIDTH(RSTACK_DEPTH),
    .SIZE(1 << RSTACK_DEPTH)
)
rstack(
    .clk(clk),

    .mem_dout_addr(rsp),
    .mem_dout(rstack_pre_top),

    .we(write_to_rstack),
    .mem_din_addr(rsp_new),
    .mem_din(16'(rstack_top))
);

// return frame pointer stack (only frame pointers)

reg [`DATA_WIDTH-1:0] rfpstack_top; // top element of return frame pointer stack
reg [`DATA_WIDTH-1:0] rfpstack_top_new; // logic
wire [`DATA_WIDTH-1:0] rfpstack_pre_top; // (top - 1) element of return frame pointer stack

dsram #(
    .WIDTH(RSTACK_DEPTH),
    .SIZE(1 << RSTACK_DEPTH)
)
rfpstack(
    .clk(clk),

    .mem_dout_addr(rsp),
    .mem_dout(rfpstack_pre_top),

    .we(write_to_rstack),
    .mem_din_addr(rsp_new),
    .mem_din(16'(rfpstack_top))
);

// 

wire [4:0] opcode = instr[4:0]; // opcode
wire [15:0] instr_simm = {{6{instr[15]}}, instr[15:6]};

reg [CODE_WIDTH-1:0] pc; // program counter
reg [DATA_WIDTH-1:0] fp; // frame pointer
reg [CODE_WIDTH-1:0] pc_new; // (logic)
reg [DATA_WIDTH-1:0] fp_new; // (logic)

assign code_addr = pc;

reg state; // cpu state

localparam FETCH_WRITEBACK = 1'b0;
localparam EXECUTE = 1'b1;

reg mem_to_stack; // need to write from memory to top of stack on fetch
reg mem_to_stack_new; // (logic)
reg stack_pre_top_to_top; // need to write stack (top - 1) to stack top on fetch
reg stack_pre_top_to_top_new; // (logic)

wire [`CODE_WIDTH-1:0] pc_plus_1 = pc + 1;

// pre-calculated address to access the data memory
wire [`DATA_WIDTH-1:0] abs_mem_addr = mode ? fp + DATA_WIDTH'(instr_simm) : DATA_WIDTH'(stack_top) + DATA_WIDTH'(instr_simm);

// pre-calculated address to access the program memory
wire [`CODE_WIDTH-1:0] abs_jump_addr = mode ? pc + CODE_WIDTH'(instr_simm) : CODE_WIDTH'(stack_top) + CODE_WIDTH'(instr_simm);


reg stack_top_on_mem;

reg mem_dout_we_new; // (logic)
reg [15:0] mem_dout_new; // (logic)

assign mem_din_addr = abs_mem_addr;

// alu

wire [15:0] alu_out;

wire [15:0] alu_x = mode ? stack_top : stack_pre_top;
wire [15:0] alu_y = mode ? instr_simm : stack_top;

alu alu(
    .opcode(opcode),
    .a(alu_x),
    .b(alu_y),
    .out(alu_out)
);


// state update logic
always @(posedge clk) begin
    if (!reset) begin
        case (state)
            FETCH_WRITEBACK: state <= EXECUTE;
            EXECUTE: state <= FETCH_WRITEBACK;
            default: state <= FETCH_WRITEBACK;
        endcase
    end
end

// all pc logic
always @(*) begin
    case (opcode)
        `JMP: pc_new = abs_jump_addr;
        `JZ: pc_new = (~|stack_top) ? abs_jump_addr : pc_plus_1;
        `JNZ: pc_new = (|stack_top) ? abs_jump_addr : pc_plus_1;
        `CALL: pc_new = abs_jump_addr;
        `RET: pc_new = rstack_top;
        default: pc_new = pc_plus_1;
    endcase
end

// all fp logic
always @(*) begin
    // compute all return stack logic
    case (opcode)
        `RET: fp_new = rfpstack_top;
        `SET_FP: fp_new = abs_mem_addr;
        default: fp_new = fp;
    endcase
end

// all return stack logic
always @(*) begin
    case (opcode)
        `CALL: rstack_top_new = pc + 1;
        `RET: rstack_top_new = rstack_pre_top;
        default: rstack_top_new = rstack_top;
    endcase
end

always @(*) begin
    case (opcode)
        `CALL: rfpstack_top_new = fp;
        `RET: rfpstack_top_new = rfpstack_pre_top;
        default: rfpstack_top_new = rfpstack_top;
    endcase
end

always @(*) begin
    case (opcode)
        `CALL: rsp_new = rsp + 1;
        `RET: rsp_new = rsp - 1;
        default: rsp_new = rsp;
    endcase
end

always @(*) begin
    case (opcode)
        `CALL: write_to_rstack = 1'b1;
        `RET: write_to_rstack = 1'b0;
        default: write_to_rstack = 1'b0;
    endcase
end

always @(*) begin
    case ({state, opcode})
        {FETCH_WRITEBACK, `STORE}: {mem_dout_we_new, mem_dout_new} = {1'b1, mode ? stack_top : stack_pre_top};
        default: mem_dout_we_new = 1'b0;
    endcase
end


// all stack logic
always @(*) begin
    case (opcode)
        `LOAD,
        `LEA: sp_new = sp1_mode;
        `STORE,
        `JZ,
        `JNZ: sp_new = sp - 1; // was sp1_neg_mode
        `ADD,
        `SUB,
        `MUL,
        `AND,
        `OR,
        `XOR,
        `SHL,
        `SHR,
        `SHRA,
        `EQ,
        `LT,
        `LTU,
        `SET_FP,
        `JMP,
        `CALL,
        `RET: sp_new = sp0_mode;
        `PUSH_LO,
        `PUSH_HI: sp_new = sp + 1;
        `POP: sp_new = sp - 1;
        default: sp_new = sp;
    endcase
end

always @(*) begin
    case ({mode, opcode})
        {1'b0, `STORE}: sp_new_execute = sp - 1;
        default: sp_new_execute = sp;
    endcase
end

always @(*) begin
    case ({state, opcode})
        {EXECUTE, `STORE}: stack_pre_top_to_top_new = 1'b1;
        {EXECUTE, `JZ}: stack_pre_top_to_top_new = 1'b1;
        {EXECUTE, `JNZ}: stack_pre_top_to_top_new = 1'b1;
        default: stack_pre_top_to_top_new = 1'b0;
    endcase
end

always @(*) begin
    case (opcode)
        `ADD,
        `SUB,
        `MUL,
        `AND,
        `OR,
        `XOR,
        `SHL,
        `SHR,
        `SHRA,
        `EQ,
        `LT,
        `LTU: stack_top_new = alu_out;
        `LOAD: stack_top_new = mem_din;
        `STORE,
        `JZ,
        `JNZ: stack_top_new = stack_pre_top;
        `LEA: stack_top_new = 16'(abs_mem_addr);
        `SET_FP,
        `JMP,
        `CALL,
        `RET: stack_top_new = mode ? stack_top : stack_pre_top;
        `PUSH_LO: stack_top_new = instr_simm;
        `PUSH_HI: stack_top_new = instr_simm << 6;
        `POP: stack_top_new = stack_pre_top;
        default: stack_top_new = stack_top;
    endcase
end

always @(*) begin
    case ({state, opcode})
        {EXECUTE, `LOAD}: write_to_stack = 1'b1; // was mode ? 1'b1 : 1'b0
        {EXECUTE, `PUSH_LO},
        {EXECUTE, `PUSH_HI}: write_to_stack = 1'b1;
        default: write_to_stack = 1'b0;
    endcase
end

always @(*) begin
    case ({state, opcode})
        {EXECUTE, `LOAD}: mem_to_stack_new = 1'b1;
        default: mem_to_stack_new = 1'b0;
    endcase
end

// calculation logic
always @(posedge clk) begin
    if (reset) begin
        state <= FETCH_WRITEBACK;
        pc <= (CODE_WIDTH)'(0);
        sp <= (STACK_DEPTH)'(0);
        rsp <= (RSTACK_DEPTH)'(0);
        fp <= (DATA_WIDTH)'(0);
        
        stack_top <= 16'b0;
        rstack_top <= (CODE_WIDTH)'(0);
        rfpstack_top <= (DATA_WIDTH)'(0);
    end else begin
        case (state)
            FETCH_WRITEBACK: begin
                if (mem_to_stack) begin
                    stack_top <= mem_din;
                end
                if (stack_pre_top_to_top) begin
                    stack_top <= stack_pre_top;
                end

                pc <= pc_new;
                sp <= sp_new;
                rsp <= rsp_new;
                fp <= fp_new;
                stack_top <= stack_top_new;
                rstack_top <= rstack_top_new;
                rfpstack_top <= rfpstack_top_new;


                // test
                mem_dout_addr <= abs_mem_addr;
                mem_dout_we <= mem_dout_we_new;
                mem_dout <= mem_dout_new;
            end
            EXECUTE: begin
                mem_dout_addr <= abs_mem_addr;
                mem_dout_we <= mem_dout_we_new;
                mem_dout <= mem_dout_new;

                sp <= sp_new_execute;
                mem_to_stack <= mem_to_stack_new;
                stack_pre_top_to_top <= stack_pre_top_to_top_new;

                if (opcode == `STORE && mode == 1'b0) begin
                    stack_top <= stack_top_new;
                end
                if (opcode == `JMP && mode == 1'b0) begin
                    stack_top <= stack_top_new;
                end
                if (opcode == `JNZ && mode == 1'b0) begin
                    stack_top <= stack_top_new;
                end

                if (opcode == `LOAD) begin
                    stack_top <= stack_top_new;
                end
            end
        endcase
    end
end

initial begin
    state = FETCH_WRITEBACK;
    pc = (CODE_WIDTH)'(0);
    sp = (STACK_DEPTH)'(0);
    rsp = (RSTACK_DEPTH)'(0);
    fp = (DATA_WIDTH)'(0);
    
    stack_top = 16'b0;
    rstack_top = (CODE_WIDTH)'(0);
    rfpstack_top = (DATA_WIDTH)'(0);
    
    mem_to_stack = 1'b0;
    stack_pre_top_to_top = 1'b0;
end

endmodule
