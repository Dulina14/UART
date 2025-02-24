module UART_TX_tb;
    timeunit 1ns / 1ps;
    localparam  CLOCKS_PER_PULSE = 4,
                W_OUT            = 16,
                BITS_PER_WORD    = 8,
                PACKET_SIZE      = BITS_PER_WORD + 5,
                NUM_WORDS        = W_OUT / BITS_PER_WORD,
                CLK_PERIOD       = 10;

    logic clk = 0, rstn = 0, tx, s_valid = 0, s_ready;
    logic [NUM_WORDS - 1 : 0][BITS_PER_WORD - 1 : 0] s_data, rx_data,
    logic [BITS_PER_WORD - 1 : 0] rx_word;
    
    initial forever #(CLK_PERIOD / 2) clk <= !clk;

    AXI_Stream_to_UART_TX #(
        .CLOCKS_PER_PULSE(CLOCKS_PER_PULSE), .BITS_PER_WORD(BITS_PER_WORD),
        .PACKET_SIZE(PACKET_SIZE), .W_OUT(W_OUT))  dut(.*);

    // AXIS Driver
    initial begin
        $dumpfile(""dump.vcd); $dumpvars;
    end


endmodule