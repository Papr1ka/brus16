`timescale 1ns / 1ps

module tb_uart_tx;
    reg         clk;
    reg         reset;
    reg  [15:0] mem_din;
    reg         mem_din_we;
    wire [15:0] mem_dout;
    wire        resume;
    wire        tx;

    uart dut (
        .clk(clk),
        .reset(reset),
        .mem_din(mem_din),
        .mem_din_we(mem_din_we),
        .mem_dout(mem_dout),
        .resume(resume),
        .uart_tx(tx)
    );

    // Тактовый генератор 25.2 МГц
    always #20 clk = ~clk;

    // Параметры теста
    integer test_ok;
    reg [9:0] got;
    reg [9:0] expected_bits;  // ожидаемая последовательность: старт(0), 8 бит данных LSB first, стоп(1)
    integer   bit_idx;
    integer   wait_cnt;

    localparam CYCLE = 219;
    localparam HALF_CYCLE = CYCLE >> 1;

    initial begin
        $dumpfile("uart_tx.vcd");
        $dumpvars(0, tb_uart_tx);

        clk = 0;
        reset = 1;
        mem_din = 0;
        mem_din_we = 0;

        // Сброс
        #100 reset = 0;
        #40;

        // Отправим символ 'A' (0x41 = 01000001, сначала младший бит = 1)
        @(posedge clk);
        mem_din  = 8'd83;       // 'A'
        mem_din_we = 1;
        @(posedge clk);
        mem_din_we = 0;


        @(negedge tx);
        
        repeat(HALF_CYCLE) @(posedge clk);
        if (tx != 1'b0) begin
            $display("FAIL: expected 0 as start bit, got $b", tx);
        end

        expected_bits = {1'b0, 8'd83, 1'b1};
        
        for (integer i = 0; i < 10; i = i + 1) begin
            got <= {got[8:0], tx};
            if (i != 9) begin
                repeat(CYCLE) @(posedge clk);
            end
        end

        #1;

        if (expected_bits != got) begin
            $display("FAIL: GOT %b, EXPECTED %b", got, expected_bits);
        end else begin
            $display("PASS, DATA CORRECT");
        end

        // Ждём завершения передачи
        wait(resume);

        // Проверим, что модуль не занят
        @(posedge clk);
        #1;
        if ((mem_dout & 1) == 0)
            $display("PASS: передача завершена, busy=0");
        else
            $display("FAIL: busy не сброшен");
        

        #1000;

        // Отправим символ 'A' (0x41 = 01000001, сначала младший бит = 1)
        @(posedge clk);
        mem_din  = 8'd83;       // 'A'
        mem_din_we = 1;
        @(posedge clk);
        mem_din_we = 0;


        @(negedge tx);
        
        repeat(HALF_CYCLE) @(posedge clk);
        if (tx != 1'b0) begin
            $display("FAIL: expected 0 as start bit, got $b", tx);
        end

        expected_bits = {1'b0, 8'd83, 1'b1};
        
        for (integer i = 0; i < 10; i = i + 1) begin
            got <= {got[8:0], tx};
            if (i != 9) begin
                repeat(CYCLE) @(posedge clk);
            end
        end

        #1;

        if (expected_bits != got) begin
            $display("FAIL: GOT %b, EXPECTED %b", got, expected_bits);
        end else begin
            $display("PASS, DATA CORRECT");
        end

        // Ждём завершения передачи
        wait(resume);

        // Проверим, что модуль не занят
        @(posedge clk);
        #1;
        if ((mem_dout & 1) == 0)
            $display("PASS: передача завершена, busy=0");
        else
            $display("FAIL: busy не сброшен");

        #1000 $finish;
    end
endmodule
