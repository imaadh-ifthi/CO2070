module tb_reg_file;

    // testbench signals
    //inputs are reg, outputs are wire
    reg [7:0] IN;
    reg [2:0] INADDRESS, OUT1ADDRESS, OUT2ADDRESS;
    reg WRITE, CLK, RESET;
    wire [7:0] OUT1, OUT2;

    //instantiate register file
    reg_file uut (
        .IN(IN),
        .OUT1(OUT1),
        .OUT2(OUT2),
        .INADDRESS(INADDRESS),
        .OUT1ADDRESS(OUT1ADDRESS),
        .OUT2ADDRESS(OUT2ADDRESS),
        .WRITE(WRITE),
        .CLK(CLK),
        .RESET(RESET)
    );

    // clock with period of 10
    always #5 CLK = ~CLK;

    initial begin

        //initialize signals
        CLK = 0;
        RESET = 0;
        WRITE = 0;
        IN = 8'b0;
        INADDRESS = 3'b0;
        OUT1ADDRESS = 3'b0;
        OUT2ADDRESS = 3'b0;

        // vcd dump for gtkwave
        $dumpfile("reg_file_tb.vcd");
        $dumpvars(0, tb_reg_file);
        // dump registers so we can actually see them
        $dumpvars(1, uut.registers[0], uut.registers[1],
                     uut.registers[2], uut.registers[3],
                     uut.registers[4], uut.registers[5],
                     uut.registers[6], uut.registers[7]);

        // test 1: Reset all registers
        //set reset high and wait for a clock edge
        $display("test 1: Asserting Reset");
        RESET = 1;
        #10;
        RESET = 0;

        // test 2: Write 0xAA to Register 2
        #10;
        $display("test 2: Writing 0xAA to Register 2");
        IN = 8'hAA;
        INADDRESS = 3'd2;
        WRITE = 1;
        #10; //wait for posedge
        WRITE = 0;

        // test 3: Write 0x55 to Register 5
        #10;
        $display("test 3: Writing 0x55 to Register 5");
        IN = 8'h55;
        INADDRESS = 3'd5;
        WRITE = 1;
        #10;
        WRITE = 0;

        // test 4: Read from Register 2 and Register 5
        // reading is async so it should update without clock
        #10;
        $display("test 4: Reading from Register 2 (OUT1) and Register 5 (OUT2)");
        OUT1ADDRESS = 3'd2;
        OUT2ADDRESS = 3'd5;
        #3; //need to wait more than the #2 read delay
        $display("  -> OUT1 = %h (expected: AA), OUT2 = %h (expected: 55)", OUT1, OUT2);

        // test 5: Overwrite Register 2 with 0xFF
        // check if OUT1 updates after we change the value
        #17;
        $display("test 5: Overwriting Register 2 with 0xFF");
        IN = 8'hFF;
        INADDRESS = 3'd2;
        WRITE = 1;
        #10;
        WRITE = 0;
        #3; // read delay
        $display("  -> OUT1 = %h (expected: FF after overwrite)", OUT1);

        //test 6: final reset to make sure everything clears
        #17;
        $display("test 6: Final Reset");
        RESET = 1;
        #10;
        RESET = 0;
        #3;
        $display("  -> OUT1 = %h (expected: 00), OUT2 = %h (expected: 00)", OUT1, OUT2);

        #20;
        $display("All tests completed.");
        $finish;
    end

    // monitor for debugging
    initial begin
        $monitor("t=%0d | CLK=%b RESET=%b WRITE=%b | IN=%h ADDR=%d | OUT1=%h (r%0d) OUT2=%h (r%0d)",
                 $time, CLK, RESET, WRITE, IN, INADDRESS, OUT1, OUT1ADDRESS, OUT2, OUT2ADDRESS);
    end

endmodule