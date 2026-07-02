// CPU Testbench 
// Validates the 8-instruction ISA implementation: LOADI, MOV, ADD, SUB, AND, OR, J, BEQ.
// Configured with a clock period of 8 time units (duty cycle toggles every 4 units).
// Ensures correct propagation through all multiplexers and ALU states.

`include "cpu.v"
`include "alu.v"
`include "reg_file.v"
`include "control_unit.v"
`include "mux_2x1_8bit.v"
`include "pc_unit.v"
`include "twos_complement.v"

module cpu_tb;

    reg CLK, RESET;
    wire [31:0] PC;
    wire [31:0] INSTRUCTION;

    reg [7:0] instr_mem [0:1023];  // instr memory 1024 bytes

    // Instruction Memory Fetch Simulation
    // Emulates a read latency of #2 time units.
    // Opcodes: LOADI=0x00 | MOV=0x01 | ADD=0x02 | SUB=0x03 | AND=0x04 | OR=0x05 | J=0x06 | BEQ=0x07
    // Instruction Formatting: {OPCODE[31:24], RD/OFFSET[23:16], RT[15:8], RS/IMM[7:0]}
    assign #2 INSTRUCTION = {instr_mem[PC[31:0]+3], instr_mem[PC[31:0]+2], 
                              instr_mem[PC[31:0]+1], instr_mem[PC[31:0]]};

    initial begin

        // Phase 1: Register File Initialization

        // PC=0: loadi r0, 5
        {instr_mem[10'd3],  instr_mem[10'd2],  instr_mem[10'd1],  instr_mem[10'd0]}   = 32'b00000000_00000000_00000000_00000101;

        // PC=4: loadi r1, 10
        {instr_mem[10'd7],  instr_mem[10'd6],  instr_mem[10'd5],  instr_mem[10'd4]}   = 32'b00000000_00000001_00000000_00001010;

        //PC=8: loadi r2, 5    (same as r0 for beq test later)
        {instr_mem[10'd11], instr_mem[10'd10], instr_mem[10'd9],  instr_mem[10'd8]}   = 32'b00000000_00000010_00000000_00000101;

        // PC=12: add r3, r0, r1  -> r3 = 15
        {instr_mem[10'd15], instr_mem[10'd14], instr_mem[10'd13], instr_mem[10'd12]}  = 32'b00000010_00000011_00000000_00000001;


        // Phase 2: Unconditional Forward Jump Resolution
        // PC=16: J 0x02 | Computed Target Address = 20 + (2 * 4) = 28
        {instr_mem[10'd19], instr_mem[10'd18], instr_mem[10'd17], instr_mem[10'd16]}  = 32'b00000110_00000010_00000000_00000000;

        // PC=20: loadi r4, 0xAA  -> skipped
        {instr_mem[10'd23], instr_mem[10'd22], instr_mem[10'd21], instr_mem[10'd20]}  = 32'b00000000_00000100_00000000_10101010;

        // PC=24: LOADI r5, 0xBB (Intended to be bypassed during execution)
        // Validates sequential instruction bypass.
        {instr_mem[10'd27], instr_mem[10'd26], instr_mem[10'd25], instr_mem[10'd24]}  = 32'b00000000_00000101_00000000_10111011;

        // PC=28: loadi r4, 0x11    jump should land here, r4=0x11
        {instr_mem[10'd31], instr_mem[10'd30], instr_mem[10'd29], instr_mem[10'd28]}  = 32'b00000000_00000100_00000000_00010001;

        // phase 3 - beq taken  (r0==r2 so it should branch)
        // PC=32: beq 0x01, r0, r2   target=36+1*4=40
        {instr_mem[10'd35], instr_mem[10'd34], instr_mem[10'd33], instr_mem[10'd32]}  = 32'b00000111_00000001_00000000_00000010;

        //PC=36: loadi r5, 0xDD  -> skipped by beq
        {instr_mem[10'd39], instr_mem[10'd38], instr_mem[10'd37], instr_mem[10'd36]}  = 32'b00000000_00000101_00000000_11011101;

        // PC=40: loadi r5, 0x22  beq lands here, r5 shld be 0x22
        {instr_mem[10'd43], instr_mem[10'd42], instr_mem[10'd41], instr_mem[10'd40]}  = 32'b00000000_00000101_00000000_00100010;

        //phase 4 - beq NOT taken (r0 != r1, shouldnt branch)
        // PC=44: beq 0x01, r0, r1 -> fall thru
        {instr_mem[10'd47], instr_mem[10'd46], instr_mem[10'd45], instr_mem[10'd44]}  = 32'b00000111_00000001_00000000_00000001;

        // PC=48: loadi r6, 0x33   this should execute, r6=0x33
        {instr_mem[10'd51], instr_mem[10'd50], instr_mem[10'd49], instr_mem[10'd48]}  = 32'b00000000_00000110_00000000_00110011;

        // phase 5 - another jump fwd
        //PC=52: j 0x02    target=56+2*4=64
        {instr_mem[10'd55], instr_mem[10'd54], instr_mem[10'd53], instr_mem[10'd52]}  = 32'b00000110_00000010_00000000_00000000;

        // PC=56: loadi r7, 0xEE -> skipped
        {instr_mem[10'd59], instr_mem[10'd58], instr_mem[10'd57], instr_mem[10'd56]}  = 32'b00000000_00000111_00000000_11101110;

        //PC=60: loadi r7, 0xFF -> skipped
        {instr_mem[10'd63], instr_mem[10'd62], instr_mem[10'd61], instr_mem[10'd60]}  = 32'b00000000_00000111_00000000_11111111;

        // PC=64: loadi r7, 0x44  lands here
        {instr_mem[10'd67], instr_mem[10'd66], instr_mem[10'd65], instr_mem[10'd64]}  = 32'b00000000_00000111_00000000_01000100;

        // Phase 6: Iterative Backward Branching Loop
        // Validates conditional flow control by decrementing r0 iteratively from 3 to 0.
        //  PC=68: LOADI r0, 3      (Loop Iterator initialization)
        //  PC=72: LOADI r1, 1      (Decrement Step magnitude)
        //  PC=76: LOADI r2, 0      (Zero-value reference for BEQ validation)
        //  PC=80: SUB r0, r0, r1   (r0--)
        //  PC=84: BEQ r0, r2       (Branch evaluation: if r0==0, bypass loop jump)
        //  PC=88: J 0xFD           (Unconditional branch to PC=80; 0xFD = -3 signed displacement)
        //  PC=92: LOADI r3, 0x77   (Execution sentinel marking loop termination)
        // Validates robust boundary conditions for backward branching.

        // PC=68: loadi r0, 3
        {instr_mem[10'd71], instr_mem[10'd70], instr_mem[10'd69], instr_mem[10'd68]}  = 32'b00000000_00000000_00000000_00000011;

        //PC=72: loadi r1, 1
        {instr_mem[10'd75], instr_mem[10'd74], instr_mem[10'd73], instr_mem[10'd72]}  = 32'b00000000_00000001_00000000_00000001;

        // PC=76: loadi r2, 0
        {instr_mem[10'd79], instr_mem[10'd78], instr_mem[10'd77], instr_mem[10'd76]}  = 32'b00000000_00000010_00000000_00000000;

        //PC=80: sub r0, r0, r1  -> r0 = r0-1
        {instr_mem[10'd83], instr_mem[10'd82], instr_mem[10'd81], instr_mem[10'd80]}  = 32'b00000011_00000000_00000000_00000001;

        // PC=84: beq 0x01, r0, r2  if r0==0 go to 92
        {instr_mem[10'd87], instr_mem[10'd86], instr_mem[10'd85], instr_mem[10'd84]}  = 32'b00000111_00000001_00000000_00000010;

        // PC=88: j 0xFD  jump back to 80  (0xFD = -3 signed)
        {instr_mem[10'd91], instr_mem[10'd90], instr_mem[10'd89], instr_mem[10'd88]}  = 32'b00000110_11111101_00000000_00000000;

        // PC=92: loadi r3, 0x77   loop exited if we get here
        {instr_mem[10'd95], instr_mem[10'd94], instr_mem[10'd93], instr_mem[10'd92]}  = 32'b00000000_00000011_00000000_01110111;

        //PC=96: sub r4, r4, r4  -> r4=0
        {instr_mem[10'd99], instr_mem[10'd98], instr_mem[10'd97], instr_mem[10'd96]}  = 32'b00000011_00000100_00000100_00000100;
    end

    cpu mycpu(PC, INSTRUCTION, CLK, RESET);

    initial begin
        $dumpfile("cpu_wavedata.vcd");
        $dumpvars(0, cpu_tb);
        // have to explicitly dump each reg or they dont show in gtkwave
        $dumpvars(0, mycpu.myreg.registers[0]);
        $dumpvars(0, mycpu.myreg.registers[1]);
        $dumpvars(0, mycpu.myreg.registers[2]);
        $dumpvars(0, mycpu.myreg.registers[3]);
        $dumpvars(0, mycpu.myreg.registers[4]);
        $dumpvars(0, mycpu.myreg.registers[5]);
        $dumpvars(0, mycpu.myreg.registers[6]);
        $dumpvars(0, mycpu.myreg.registers[7]);
        
        CLK = 1'b0;
        RESET = 1'b0;
        
        // reset
        #1 RESET = 1'b1;
        #10 RESET = 1'b0;

        // expected final: r0=0 r1=1 r2=0 r3=0x77 r4=0 r5=0x22 r6=0x33 r7=0x44
        
        // Halt simulation subsequent to sufficient clock cycles for full trace completion.
        // Allocates sufficient buffer time for delayed signal propagation.
        #700;

        $display("\n========================================");
        $display("FINAL REGISTER VALUES:");
        $display("========================================");
        $display("r0 = %0d (0x%02h) [expected: 0]", 
                 mycpu.myreg.registers[0], mycpu.myreg.registers[0]);
        $display("r1 = %0d (0x%02h) [expected: 1]", 
                 mycpu.myreg.registers[1], mycpu.myreg.registers[1]);
        $display("r2 = %0d (0x%02h) [expected: 0]", 
                 mycpu.myreg.registers[2], mycpu.myreg.registers[2]);
        $display("r3 = %0d (0x%02h) [expected: 119 (0x77)]", 
                 mycpu.myreg.registers[3], mycpu.myreg.registers[3]);
        $display("r4 = %0d (0x%02h) [expected: 0]", 
                 mycpu.myreg.registers[4], mycpu.myreg.registers[4]);
        $display("r5 = %0d (0x%02h) [expected: 34 (0x22)]", 
                 mycpu.myreg.registers[5], mycpu.myreg.registers[5]);
        $display("r6 = %0d (0x%02h) [expected: 51 (0x33)]", 
                 mycpu.myreg.registers[6], mycpu.myreg.registers[6]);
        $display("r7 = %0d (0x%02h) [expected: 68 (0x44)]", 
                 mycpu.myreg.registers[7], mycpu.myreg.registers[7]);
        $display("========================================\n");

        $finish;
    end

    // clk gen, period 8
    always
        #4 CLK = ~CLK;

    // monitor - shows all the importnat signals
    initial begin
        $monitor("Time=%0t | CLK=%b RESET=%b | PC=%0d | OPCODE=%b | RD=%0d RT=%0d RS=%0d | ALUOP=%b WE=%b | JUMP=%b BRANCH=%b ZERO=%b PC_SEL=%b | ALURES=%0d | TARGET=%0d",
                 $time, CLK, RESET, PC, 
                 mycpu.mycontrol.OPCODE, mycpu.WRITEREG, mycpu.READREG1, mycpu.READREG2,
                 mycpu.ALUOP, mycpu.WRITEENABLE,
                 mycpu.JUMP, mycpu.BRANCH, mycpu.ZERO, mycpu.PC_SELECT,
                 mycpu.ALURESULT, mycpu.BRANCH_JUMP_TARGET);
    end

endmodule
