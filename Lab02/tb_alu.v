`timescale 1ns / 1ps

module tb_alu;

    // Testbench registers to drive inputs into the ALU.
    reg [7:0] DATA1;
    reg [7:0] DATA2;
    reg [2:0] SELECT;

    // Wire to observe the output from the ALU.
    wire [7:0] RESULT;

    // Instantiate the Unit Under Test (UUT).
    alu uut (
        .DATA1(DATA1),
        .DATA2(DATA2),
        .RESULT(RESULT),
        .SELECT(SELECT)
    );

    initial begin
        // GTKWave configuration: Generates the VCD file for timing visualization.
        $dumpfile("alu_waveform.vcd"); 
        $dumpvars(0, tb_alu);          

        // Monitor prints variable states to the console dynamically upon change.
        $monitor("Time: %0t | SELECT: %b | DATA1: %d | DATA2: %d | RESULT: %d", 
                 $time, SELECT, DATA1, DATA2, RESULT);

        // System Initialization
        DATA1 = 8'd0;
        DATA2 = 8'd0;
        SELECT = 3'b000;
        #10; // 10 ns interval to allow propagation

        // ---------------------------------------------------------
        // State 000: FORWARD
        // Expectation: RESULT = 25 after 1 time unit delay.
        // ---------------------------------------------------------
        DATA1 = 8'd10; 
        DATA2 = 8'd25; 
        SELECT = 3'b000;
        #10; 

        // ---------------------------------------------------------
        // State 001: ADD
        // Expectation: RESULT = 35 after 2 time units delay.
        // ---------------------------------------------------------
        DATA1 = 8'd10; 
        DATA2 = 8'd25; 
        SELECT = 3'b001;
        #10;

        // ---------------------------------------------------------
        // State 010: AND
        // Expectation: RESULT = 160 (10100000 in binary) after 1 time unit delay.
        // ---------------------------------------------------------
        DATA1 = 8'b11110000; 
        DATA2 = 8'b10101010; 
        SELECT = 3'b010;
        #10;

        // ---------------------------------------------------------
        // State 011: OR
        // Expectation: RESULT = 255 (11111111 in binary) after 1 time unit delay.
        // ---------------------------------------------------------
        DATA1 = 8'b11110000; 
        DATA2 = 8'b00001111; 
        SELECT = 3'b011;
        #10;

        // ---------------------------------------------------------
        // States 1XX: Reserved
        // Expectation: RESULT = 0 immediately (handled by default case).
        // ---------------------------------------------------------
        DATA1 = 8'd100; 
        DATA2 = 8'd100; 
        SELECT = 3'b100; 
        #5;
        
        SELECT = 3'b111; 
        #10;

        // Terminate simulation run.
        $finish;
    end
endmodule