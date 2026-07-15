`timescale 1ns / 1ps

module tb_spi_master;
    reg         clk;
    reg         reset;
    reg  [1:0]  mem_addr;
    reg  [15:0] mem_din;
    reg         mem_din_we;
    wire [15:0] mem_dout;
    wire        resume;
    reg         spi_miso;
    wire        spi_clk;
    wire        spi_cs;
    wire        spi_mosi;

    // Подключаем тестируемый модуль
    spi_master dut (
        .clk(clk),
        .reset(reset),
        .mem_addr(mem_addr),
        .mem_din(mem_din),
        .mem_din_we(mem_din_we),
        .mem_dout(mem_dout),
        .resume(resume),
        .spi_miso(spi_miso),
        .spi_clk(spi_clk),
        .spi_cs(spi_cs),
        .spi_mosi(spi_mosi)
    );

    // Тактовый генератор 25.2 МГц -> период ~40 нс
    always #20 clk = ~clk;

    // Модель ответа SPI-устройства (возвращает 0x5A)
    reg [7:0] miso_shift;
    reg [7:0] mosi_shift;
    always @(negedge spi_clk) begin
        if (!spi_cs) begin  // когда выбрано
            miso_shift <= {miso_shift[6:0], 1'b0};
            spi_miso <= miso_shift[6];
        end
    end

    always @(posedge spi_clk) begin
        if (!spi_cs) begin
            mosi_shift <= {mosi_shift[6:0], spi_mosi};
        end
    end

    initial begin
        localparam CLK_DIV = 16'd10;
        localparam MOSI = 8'd165;
        localparam MISO = 8'd90;

        $dumpfile("spi_master.vcd");
        $dumpvars(0, tb_spi_master);

        // Инициализация
        clk = 0;
        reset = 1;
        mem_addr = 2'b00;
        mem_din = 16'h0000;
        mem_din_we = 0;
        spi_miso = 0;
        miso_shift = MISO;  // устройство вернёт 90

        // Сброс
        #100 reset = 0;
        #100;

        // Установка делителя = 3 (SPI ~ 3.15 МГц при 25.2 МГц)
        @(posedge clk);
        mem_addr = 2'b00;  // регистр DIV
        mem_din  = CLK_DIV;
        mem_din_we = 1;
        @(posedge clk);
        mem_din_we = 0;

        // Опустить CS (регистр CTRL[0]=0)
        @(posedge clk);
        mem_addr = 2'b01;
        mem_din  = 16'h0000;
        mem_din_we = 1;
        @(posedge clk);
        mem_din_we = 0;

        // Записать байт для передачи (TXDATA) -> запустится SPI-обмен
        @(posedge clk);
        mem_addr = 2'b10;
        mem_din  = MOSI;
        mem_din_we = 1;
        @(posedge clk);
        mem_din_we = 0;

        // Ждём завершения передачи
        wait(resume);
        $display("Передача завершена, проверяем принятый байт");

        // Читаем регистр RXDATA (адрес 3)
        @(posedge clk);
        mem_addr = 2'b11;
        @(posedge clk);
        #1;
        if (mem_dout[7:0] == MISO)
            $display("PASS: принят байт 90");
        else
            $display("FAIL: принят байт %d, ожидался 90", mem_dout[7:0]);

        if (mosi_shift[7:0] == MOSI)
            $display("PASS: передан байт 165");
        else
            $display("FAIL: передан байт %d, ожидался 165", mosi_shift);
        
        @(posedge clk)
        // Опустить CS (регистр CTRL[0]=0)
        @(posedge clk);
        mem_addr = 2'b01;
        mem_din  = 16'h0001;
        mem_din_we = 1;
        @(posedge clk);
        mem_din_we = 0;
        #200;

        miso_shift = MISO;  // устройство вернёт 90
        // Опустить CS (регистр CTRL[0]=0)
        @(posedge clk);
        mem_addr = 2'b01;
        mem_din  = 16'h0000;
        mem_din_we = 1;
        @(posedge clk);
        mem_din_we = 0;

        // Записать байт для передачи (TXDATA) -> запустится SPI-обмен
        @(posedge clk);
        mem_addr = 2'b10;
        mem_din  = MOSI;
        mem_din_we = 1;
        @(posedge clk);
        mem_din_we = 0;

        // Ждём завершения передачи
        wait(resume);
        $display("Передача завершена, проверяем принятый байт");

        // Читаем регистр RXDATA (адрес 3)
        @(posedge clk);
        mem_addr = 2'b11;
        @(posedge clk);
        #1;
        if (mem_dout[7:0] == MISO)
            $display("PASS: принят байт 90");
        else
            $display("FAIL: принят байт %d, ожидался 90", mem_dout[7:0]);

        if (mosi_shift[7:0] == MOSI)
            $display("PASS: передан байт 165");
        else
            $display("FAIL: передан байт %d, ожидался 165", mosi_shift);

        #200;
        $finish;
    end
endmodule
