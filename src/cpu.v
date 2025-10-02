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
    parameter DATA_WIDTH = `DATA_WIDTH
)
(
    input wire clk,
    input wire reset,

    output wire [CODE_WIDTH-1:0] code_addr, // pc (what instruction to fetch)
    input wire [15:0] instr, // instruction from program memory

    output reg [DATA_WIDTH-1:0] mem_din_addr, // data mem, read address
    input wire [15:0] mem_din, // data mem, data

    output reg mem_dout_we, // write enable to data mem
    output reg [DATA_WIDTH-1:0] mem_dout_addr, // data mem, write address
    output reg [15:0] mem_dout // data mem, write data
);

parameter STACK_DEPTH = 6;
parameter RSTACK_DEPTH = 5;

// data stack
/*
meaning:
    stack = [8, 7, 6, 5]
representation:
    stack=[0, 0, 8, 7, 6, 0, 0, 0] sp=4 stack_top=5 stack_pre_top=6

when push:
    current clock (execute):
        sp_new <= sp + 1; // 4
        stack_top_new <= instr_simm; // 4
        write_to_stack <= 1'b1;
    clock +1 (writeback):
        (memory write) stack_top => stack // 5
        sp <= sp_new; // 4
        stack_top <= stack_top_new; // 4
        write_to_stack <= 1'b0;
    clock +3 (next cycle)
        stack = [0, 0, 8, 7, 6, 5, 0, 0] sp = 5 stack_top=4 stack_pre_top=5

(old stack top will be written at sp=5,
new value will be stored at stack_top_register,
stack_pre_top will be syncronized automatically)

stack = [0, 0, 8, 7, 6, 5, 0, 0] sp = 5 stack_top=4 stack_pre_top=5

when pop:
    current clock (execute):
        sp_new <= sp - 1; // 4
        stack_top_new <= stack_pre_top; // 5
        write_to_stack <= 1'b0;
    clock +1 (writeback):
        sp <= sp_new; // 4
        stack_top <= stack_top_new; // 5
    clock +3 (next cycle)
        stack = [0, 0, 8, 7, 6, 5, 0, 0] sp = 4 stack_top=5 stack_pre_top=6

stack = [0, 0, 8, 7, 6, 5, 0, 0] sp = 4 stack_top=5 stack_pre_top=6

when double pop:
    current clock (execute):
        sp_new <= sp - 2; // 2
        sp <= sp - 1; // 3 (early change to move stack_pre_top to stack_top on clock + 2)
        stack_top_new <= stack_pre_top; // 6
        write_to_stack <= 1'b0;
        stack_pre_top_to_top <= 1'b1;
    clock +1 (writeback):
        sp <= sp_new; // 2
        stack_top <= stack_top_new; // 6
    clock +2 (fetch):
        (stack_pre_top = stack[3] on mem_din) // move
        stack_top <= stack_pre_top; // 7
        stack_pre_top <= 0;
    clock +3 (next cycle)
        stack = [0, 0, 8, 7, 6, 5, 0, 0] sp = 2 stack_top=7 stack_pre_top=8

rstack, rfpstack works the same
*/


reg [STACK_DEPTH-1:0] sp; // stack pointer (pointing to stack_top_prev)
reg [STACK_DEPTH-1:0] sp_new;
reg [15:0] stack_top; // top element of stack
reg [15:0] stack_top_new;
wire [15:0] stack_pre_top; // (top - 1) element of stack
reg write_to_stack; // write enable to stack

// pre calculations
wire mode = instr[5]; // use immediate if mode else from stack
wire [STACK_DEPTH-1:0] sp0_mode = mode ? sp : sp - 1;
wire [STACK_DEPTH-1:0] sp1_mode = mode ? sp + 1 : sp;
wire [STACK_DEPTH-1:0] sp1_neg_mode = mode ? sp - 1 : sp - 2;

bsram #(
    .WIDTH(STACK_DEPTH),
    .SIZE(1 << STACK_DEPTH)
)
stack(
    .clk(clk),

    .mem_dout_addr(sp),
    .mem_dout(stack_pre_top),

    .we(write_to_stack),
    .mem_din_addr(sp_new),
    .mem_din(stack_top)
);

// return stack (only for pc), rfpstack for fp's

reg [RSTACK_DEPTH-1:0] rsp; // return stack pointer
reg [RSTACK_DEPTH-1:0] rsp_new;

reg [`CODE_WIDTH-1:0] rstack_top; // top element of return stack
reg [`CODE_WIDTH-1:0] rstack_top_new;
wire [`CODE_WIDTH-1:0] rstack_pre_top; // (top - 1) element of return stack
reg write_to_rstack; // write enable to return stack

bsram #(
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
reg [`DATA_WIDTH-1:0] rfpstack_top_new;
wire [`DATA_WIDTH-1:0] rfpstack_pre_top; // (top - 1) element of return frame pointer stack

bsram #(
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
reg [CODE_WIDTH-1:0] pc_new;
reg [DATA_WIDTH-1:0] fp; // frame pointer

assign code_addr = pc;

reg [1:0] state; // cpu state

localparam FETCH = 0;
localparam EXECUTE = 1;
localparam WRITEBACK = 2;

reg mem_to_stack; // need to write from memory to top of stack on fetch
reg stack_pre_top_to_top; // need to write stack (top - 1) to stack top on fetch

wire is_alu_instr = opcode < `LOAD; // alu group of ISA?

wire [`CODE_WIDTH-1:0] pc_plus_1 = pc + 1;

// pre-calculated address to access the data memory
wire [`DATA_WIDTH-1:0] abs_mem_addr = mode ? fp + DATA_WIDTH'(instr_simm) : DATA_WIDTH'(stack_top) + DATA_WIDTH'(instr_simm);

// pre-calculated address to access the program memory
wire [`CODE_WIDTH-1:0] abs_jump_addr = mode ? pc + CODE_WIDTH'(instr_simm) : CODE_WIDTH'(stack_top) + CODE_WIDTH'(instr_simm);

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
            FETCH: state <= EXECUTE;
            EXECUTE: state <= WRITEBACK;
            WRITEBACK: state <= FETCH;
            default: state <= FETCH;
        endcase
    end
end

// calculation logic
always @(posedge clk) begin
    if (reset) begin
        state <= FETCH;
        pc <= (CODE_WIDTH)'(0);
        sp <= (STACK_DEPTH)'(0);
        rsp <= (RSTACK_DEPTH)'(0);
        fp <= (DATA_WIDTH)'(0);
        
        stack_top <= 16'b0;
        rstack_top <= (CODE_WIDTH)'(0);
        rfpstack_top <= (DATA_WIDTH)'(0);
        
        mem_to_stack <= 1'b0;
        stack_pre_top_to_top <= 1'b0;

        mem_dout_we <= 1'b0;
        write_to_stack <= 1'b0;
        write_to_rstack <= 1'b0;
    end else begin
        case (state)
            FETCH: begin
                if (mem_to_stack) begin
                    stack_top <= mem_din;
                    mem_to_stack <= 1'b0;
                end
                if (stack_pre_top_to_top) begin
                    stack_top <= stack_pre_top;
                    stack_pre_top_to_top <= 1'b0;
                end
            end
            WRITEBACK: begin
                pc <= pc_new;
                sp <= sp_new;
                rsp <= rsp_new;
                stack_top <= stack_top_new;
                rstack_top <= rstack_top_new;
                rfpstack_top <= rfpstack_top_new;
                
                mem_dout_we <= 1'b0;
                write_to_stack <= 1'b0;
                write_to_rstack <= 1'b0;
            end
            EXECUTE: begin

                // compute all pc logic
                case (opcode)
                    `JMP: begin
                        pc_new <= abs_jump_addr;
                    end
                    `JZ: begin
                        pc_new <= (~|stack_top) ? abs_jump_addr : pc_plus_1;
                    end
                    `JNZ: begin
                        pc_new <= (|stack_top) ? abs_jump_addr : pc_plus_1;
                    end
                    `CALL: begin
                        pc_new <= abs_jump_addr;
                    end
                    `RET: begin
                        pc_new <= rstack_top;
                    end
                    default: pc_new <= pc_plus_1;
                endcase

                // compute all return stack logic
                if (opcode == `RET) begin
                    fp <= rfpstack_top;
                end

                case (opcode)
                    `CALL: begin
                        rstack_top_new <= pc + 1;
                        rfpstack_top_new <= fp;
                        rsp_new <= rsp + 1;
                        write_to_rstack <= 1'b1;
                    end
                    `RET: begin
                        rstack_top_new <= rstack_pre_top;
                        rfpstack_top_new <= rfpstack_pre_top;
                        rsp_new <= rsp - 1;
                        write_to_rstack <= 1'b0;
                    end
                    default: begin
                        rstack_top_new <= rstack_top;
                        rfpstack_top_new <= rfpstack_top;
                        rsp_new <= rsp;
                        write_to_rstack <= 1'b0;
                    end
                endcase

                // stack logic
                if (is_alu_instr) begin
                    stack_top_new <= alu_out;
                    sp_new <= sp0_mode;
                    write_to_stack <= 1'b0;
                end else begin
                    case (opcode)
                        `LOAD: begin
                            sp_new <= sp1_mode;
                            stack_top_new <= stack_top;
                            write_to_stack <= mode ? 1'b1 : 1'b0;
                        end
                        `STORE, `JZ, `JNZ: begin
                            sp_new <= sp1_neg_mode;
                            stack_top_new <= stack_pre_top;
                            write_to_stack <= 1'b0;
                        end
                        `LEA: begin
                            sp_new <= sp1_mode;
                            stack_top_new <= 16'(abs_mem_addr);
                            write_to_stack <= 1'b0;
                        end
                        `SET_FP, `JMP, `CALL, `RET: begin
                            sp_new <= sp0_mode;
                            stack_top_new <= mode ? stack_top : stack_pre_top;
                            write_to_stack <= 1'b0;
                        end
                        `PUSH_LO: begin
                            sp_new <= sp + 1;
                            stack_top_new <= instr_simm;
                            write_to_stack <= 1'b1;
                        end
                        `PUSH_HI: begin
                            sp_new <= sp + 1;
                            stack_top_new <= instr_simm << 6;
                            write_to_stack <= 1'b1;
                        end
                        `POP: begin
                            sp_new <= sp - 1;
                            stack_top_new <= stack_pre_top;
                            write_to_stack <= 1'b0;
                        end
                        default: begin
                            sp_new <= sp;
                            stack_top_new <= stack_top;
                            write_to_stack <= 1'b0;
                        end
                    endcase
                end

                // instruction specific logic
                case (opcode)
                    `LOAD: begin
                        mem_din_addr <= abs_mem_addr;
                        mem_to_stack <= 1'b1;
                    end
                    `STORE: begin
                        mem_dout_addr <= abs_mem_addr;
                        mem_dout_we <= 1'b1;
                        mem_dout <= mode ? stack_top : stack_pre_top;
                        if (!mode) begin
                            sp <= sp - 1;
                        end
                        stack_pre_top_to_top <= 1'b1;
                    end
                    `JZ, `JNZ: begin
                        if (!mode) begin
                            sp <= sp - 1;
                        end
                        stack_pre_top_to_top <= 1'b1;
                    end
                    `SET_FP: begin
                        fp <= abs_mem_addr;
                    end
                endcase
            end
        endcase
    end
end

initial begin
    state = FETCH;
    pc = (CODE_WIDTH)'(0);
    sp = (STACK_DEPTH)'(0);
    rsp = (RSTACK_DEPTH)'(0);
    fp = (DATA_WIDTH)'(0);
    
    stack_top = 16'b0;
    rstack_top = (CODE_WIDTH)'(0);
    rfpstack_top = (DATA_WIDTH)'(0);
    
    mem_to_stack = 1'b0;
    stack_pre_top_to_top = 1'b0;

    mem_dout_we = 1'b0;
    write_to_stack = 1'b0;
    write_to_rstack = 1'b0;
end

endmodule
