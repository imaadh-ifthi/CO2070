// testbench for the cpu
// tests all 6 instructions: loadi, mov, add, sub, and, or
// clock period = 8 time units

`include "cpu.v"
`include "alu.v"
`include "reg_file.v"
`include "control_unit.v"
`include "mux_2x1_8bit.v"
`include "pc_unit.v"
`include "twos_complement.v"

module cpu_tb;

    // testbench signals
    reg CLK, RESET;
    wire [31:0] PC;
    wire [31:0] INSTRUCTION;

    // instruction memory - 1024 bytes total
    // each instruction is 32 bits = 4 bytes
    reg [7:0] instr_mem [0:1023];

    // instruction fetch - read 4 bytes from memory based on PC
    // #2 delay for memory read
    assign #2 INSTRUCTION = {instr_mem[PC[31:0]+3], instr_mem[PC[31:0]+2], 
                              instr_mem[PC[31:0]+1], instr_mem[PC[31:0]]};

    // opcode reference:
    //   loadi = 00, mov = 01, add = 02, sub = 03, and = 04, or = 05
    // format: {opcode, rd, rt, rs/imm}

    initial begin
        // load the test program into memory

        // loadi r4, 5
        {instr_mem[10'd3], instr_mem[10'd2], instr_mem[10'd1], instr_mem[10'd0]}    = 32'b00000000_00000100_00000000_00000101;
        
        // loadi r2, 9
        {instr_mem[10'd7], instr_mem[10'd6], instr_mem[10'd5], instr_mem[10'd4]}    = 32'b00000000_00000010_00000000_00001001;
        
        // add r6, r4, r2  -> should be 14
        {instr_mem[10'd11], instr_mem[10'd10], instr_mem[10'd9], instr_mem[10'd8]}  = 32'b00000010_00000110_00000100_00000010;
        
        // mov r0, r6  -> r0 should be 14 now
        {instr_mem[10'd15], instr_mem[10'd14], instr_mem[10'd13], instr_mem[10'd12]} = 32'b00000001_00000000_00000110_00000000;
        
        // loadi r1, 1
        {instr_mem[10'd19], instr_mem[10'd18], instr_mem[10'd17], instr_mem[10'd16]} = 32'b00000000_00000001_00000000_00000001;
        
        // add r2, r2, r1  -> 9+1 = 10
        {instr_mem[10'd23], instr_mem[10'd22], instr_mem[10'd21], instr_mem[10'd20]} = 32'b00000010_00000010_00000010_00000001;
        
        // sub r3, r6, r4  -> 14-5 = 9
        {instr_mem[10'd27], instr_mem[10'd26], instr_mem[10'd25], instr_mem[10'd24]} = 32'b00000011_00000011_00000110_00000100;
        
        // and r5, r6, r2  -> 14 & 10 = 10
        {instr_mem[10'd31], instr_mem[10'd30], instr_mem[10'd29], instr_mem[10'd28]} = 32'b00000100_00000101_00000110_00000010;
        
        // or r7, r4, r1  -> 5 | 1 = 5
        {instr_mem[10'd35], instr_mem[10'd34], instr_mem[10'd33], instr_mem[10'd32]} = 32'b00000101_00000111_00000100_00000001;
        
        // loadi r3, 0xFF  (thats -1 in signed)
        {instr_mem[10'd39], instr_mem[10'd38], instr_mem[10'd37], instr_mem[10'd36]} = 32'b00000000_00000011_00000000_11111111;
        
        // add r5, r3, r4  -> -1 + 5 = 4
        {instr_mem[10'd43], instr_mem[10'd42], instr_mem[10'd41], instr_mem[10'd40]} = 32'b00000010_00000101_00000011_00000100;
        
        // sub r7, r4, r2  -> 5 - 10 = -5 (0xFB)
        {instr_mem[10'd47], instr_mem[10'd46], instr_mem[10'd45], instr_mem[10'd44]} = 32'b00000011_00000111_00000100_00000010;
        
        // loadi r0, 0xAA  (10101010 in binary)
        {instr_mem[10'd51], instr_mem[10'd50], instr_mem[10'd49], instr_mem[10'd48]} = 32'b00000000_00000000_00000000_10101010;
        
        // loadi r1, 0x55  (01010101)
        {instr_mem[10'd55], instr_mem[10'd54], instr_mem[10'd53], instr_mem[10'd52]} = 32'b00000000_00000001_00000000_01010101;
        
        // and r2, r0, r1  -> 0xAA & 0x55 = 0x00 (no overlapping bits)
        {instr_mem[10'd59], instr_mem[10'd58], instr_mem[10'd57], instr_mem[10'd56]} = 32'b00000100_00000010_00000000_00000001;
        
        // or r3, r0, r1  -> 0xAA | 0x55 = 0xFF (all bits set)
        {instr_mem[10'd63], instr_mem[10'd62], instr_mem[10'd61], instr_mem[10'd60]} = 32'b00000101_00000011_00000000_00000001;
        
        // mov r4, r3  -> r4 gets 0xFF
        {instr_mem[10'd67], instr_mem[10'd66], instr_mem[10'd65], instr_mem[10'd64]} = 32'b00000001_00000100_00000011_00000000;
    end

    // instantiate the cpu
    cpu mycpu(PC, INSTRUCTION, CLK, RESET);

    // simulation setup
    initial begin
        // dump waveforms for gtkwave
        $dumpfile("cpu_wavedata.vcd");
        $dumpvars(0, cpu_tb);
        // need to explicitly dump each register or they wont show up
        $dumpvars(0, mycpu.myreg.registers[0]);
        $dumpvars(0, mycpu.myreg.registers[1]);
        $dumpvars(0, mycpu.myreg.registers[2]);
        $dumpvars(0, mycpu.myreg.registers[3]);
        $dumpvars(0, mycpu.myreg.registers[4]);
        $dumpvars(0, mycpu.myreg.registers[5]);
        $dumpvars(0, mycpu.myreg.registers[6]);
        $dumpvars(0, mycpu.myreg.registers[7]);
        
        // init
        CLK = 1'b0;
        RESET = 1'b0;
        
        // reset the cpu first
        #1 RESET = 1'b1;
        #10 RESET = 1'b0;
        
        // let it run for a while
        // 17 instructions * 8 time units each = ~136 but giving extra
        #500;
        
        // test reset mid-execution to make sure it actually works
        RESET = 1'b1;
        #10 RESET = 1'b0;
        
        // let it run a bit more after reset
        #200;
        
        $finish;
    end

    // clock gen - flip every 4 time units = period of 8
    always
        #4 CLK = ~CLK;

    // monitor for debugging - prints everything useful
    initial begin
        $monitor("Time=%0t | CLK=%b RESET=%b | PC=%0d | INSTRUCTION=%b | OPCODE=%b | RD=%0d RT=%0d RS=%0d | ALUOP=%b | WRITEENABLE=%b | ALURESULT=%0d",
                 $time, CLK, RESET, PC, INSTRUCTION, 
                 mycpu.mycontrol.OPCODE, mycpu.WRITEREG, mycpu.READREG1, mycpu.READREG2,
                 mycpu.ALUOP, mycpu.WRITEENABLE, mycpu.ALURESULT);
    end

endmodule
