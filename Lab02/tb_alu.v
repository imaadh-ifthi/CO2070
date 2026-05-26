`timescale 1ns / 1ps

module tb_alu;

    reg [7:0] DATA1;
    reg [7:0] DATA2;
    reg [2:0] SELECT;
    wire [7:0] RESULT;

    alu uut (
        .DATA1(DATA1),
        .DATA2(DATA2),
        .RESULT(RESULT),
        .SELECT(SELECT)
    );

    initial begin
        // GTKWave Dump Setup
        $dumpfile("alu_waveform.vcd"); 
        $dumpvars(0, tb_alu);          

        // Monitor outputs to console
        $monitor("Time: %0t | SELECT: %b | DATA1: %d | DATA2: %d | RESULT: %d", 
                 $time, SELECT, DATA1, DATA2, RESULT);

        // Initialize Inputs
        DATA1 = 8'd0;
        DATA2 = 8'd0;
        SELECT = 3'b000;
        #10;

        // Test 1: FORWARD (SELECT = 000)
        DATA1 = 8'd10; 
        DATA2 = 8'd25; 
        SELECT = 3'b000;
        #10; 

        // Test 2: ADD (SELECT = 001)
        DATA1 = 8'd10; 
        DATA2 = 8'd25; 
        SELECT = 3'b001;
        #10;

        // Test 3: AND (SELECT = 010)
        DATA1 = 8'b11110000; 
        DATA2 = 8'b10101010; 
        SELECT = 3'b010;
        #10;

        // Test 4: OR (SELECT = 011)
        DATA1 = 8'b11110000; 
        DATA2 = 8'b00001111; 
        SELECT = 3'b011;
        #10;

        // Test 5: Reserved States (SELECT = 1XX)
        DATA1 = 8'd100; 
        DATA2 = 8'd100; 
        SELECT = 3'b100; 
        #5;
        
        SELECT = 3'b111; 
        #10;

        $finish;
    end
endmodule