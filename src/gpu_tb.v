`timescale 1ps/1ps

module gpu_tb;

reg clk;
reg reset;
reg we;
reg idle;
reg [15:0] x_coord;
reg [15:0] y_coord;
reg [15:0] mem_din;
wire [15:0] color;

always #1 clk = ~clk;

reg[15:0] garbage;
// rom for test
example_rom_gpu rom(
    .clk(clk),
    .addr_a(16'b0),
    .dout_a(garbage),
    .we_b(1'b0),
    .addr_b(16'b0),
    .din_b(16'b0)
);

gpu gpu(
    .pixel_clk(clk),
    .reset(reset),
    .we(we),
    .idle(idle),
    .x_coord(x_coord),
    .y_coord(y_coord),
    .mem_din(mem_din),
    .color(color)
);

always @(posedge clk) begin
    x_coord <= x_coord + 1;
    if (x_coord == 799) begin
        if (y_coord == 799) begin
            y_coord <= 0;
        end else begin
            y_coord <= y_coord + 1;
        end
        x_coord <= 0;
    end
end

initial begin
    // $monitor ("[$monitor] time=%0t clk=%0b reset=%0b state=%0d copy_state=%0d collisions=0b%0b rect_idx=%0d color=0x%0h rect_counter=%0d mem_din=%0d we=0b%0b", $time, clk, reset, gpu.state, gpu.copy_state, gpu.collisions, gpu.rect_idx, gpu.color, gpu.rect_color, mem_din, we);
    $monitor("[$monitor] time=%0t clk=%0b we=%0b mem_din=0b%b rect_idx=%d color=0x%h state=0b%b copy_state=%d rect_counter=%d x=%d y=%d collisions=0b%b", $time, clk, we, mem_din, gpu.rect_idx, color, gpu.state, gpu.copy_state, gpu.rect_counter, x_coord, y_coord, gpu.collisions);
    clk = 1;
    idle = 0;
    reset = 1;
    #1;
    reset = 0;
    #1;
    we = 1;
    #2;
    for (integer i = 0; i < 384; i++)
    begin
        mem_din = rom.ram[i];
        $display("we = %0b", we);
        #2;
    end
    we = 0;
    #1;
    for (integer i = 0; i < 64; i++)
    begin
        $display("idx=%d x=%d y=%d x+width=%d y+height=%d color=0x%h", i, gpu.rect_left[i], gpu.rect_top[i], gpu.rect_right[i], gpu.rect_bottom[i], gpu.rect_color[i]);
    end

    x_coord = 0;
    y_coord = 0;
    #1000;
    // for (integer i = 784; i < 1024; i++) begin
    //     $display("ram[%d] = 0x%0h", i, dual_ram.ram[10'(i)]);
    // end


    $finish;
end

endmodule
