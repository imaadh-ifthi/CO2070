// testbench for the cpu - lab 4
// tests all 8 instructions: loadi, mov, add, sub, and, or, j, beq
// clock period = 8 time units (toggle every 4)
//
// TIMING ANALYSIS:
//   The beq instruction has the longest critical path:
//     PC update (#1) -> Instr memory (#2) -> Reg read (#2) -> 2's comp (#1) -> ALU (#2) = 8 time units
//     Decode (#1) happens in parallel with Reg read
//   Therefore the clock period can be 8.
//   before the next clock edge. (With period=8, ZERO flag wasn't ready in time.)
//
// TEST PROGRAM SUMMARY:
//   Phase 1: Basic arithmetic to set up register values
//   Phase 2: Jump forward test (skip over instructions)
//   Phase 3: beq taken test (branch when registers are equal)
//   Phase 4: beq not-taken test (no branch when registers differ)
//   Phase 5: Another jump forward test
//   Phase 6: Backward loop using beq + j (decrement counter from 3 to 0)

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
    // #2 delay for memory read (simulates real memory latency)
    assign #2 INSTRUCTION = {instr_mem[PC[31:0]+3], instr_mem[PC[31:0]+2], 
                              instr_mem[PC[31:0]+1], instr_mem[PC[31:0]]};

    // opcode reference:
    //   loadi = 0x00, mov = 0x01, add = 0x02, sub = 0x03
    //   and   = 0x04, or  = 0x05, j   = 0x06, beq = 0x07
    // instruction format: {opcode[31:24], rd/offset[23:16], rt[15:8], rs/imm[7:0]}

    initial begin
        // ============================================================
        // LOAD THE TEST PROGRAM INTO INSTRUCTION MEMORY
        // ============================================================

        // ---------------------------------------------------------
        // PHASE 1: Setup - load values into registers for later tests
        // ---------------------------------------------------------

        // PC=0: loadi r0, 5       -> r0 = 5
        {instr_mem[10'd3],  instr_mem[10'd2],  instr_mem[10'd1],  instr_mem[10'd0]}   = 32'b00000000_00000000_00000000_00000101;

        // PC=4: loadi r1, 10      -> r1 = 10
        {instr_mem[10'd7],  instr_mem[10'd6],  instr_mem[10'd5],  instr_mem[10'd4]}   = 32'b00000000_00000001_00000000_00001010;

        // PC=8: loadi r2, 5       -> r2 = 5 (same as r0, used in beq taken test)
        {instr_mem[10'd11], instr_mem[10'd10], instr_mem[10'd9],  instr_mem[10'd8]}   = 32'b00000000_00000010_00000000_00000101;

        // PC=12: add r3, r0, r1   -> r3 = 5 + 10 = 15
        {instr_mem[10'd15], instr_mem[10'd14], instr_mem[10'd13], instr_mem[10'd12]}  = 32'b00000010_00000011_00000000_00000001;

        // ---------------------------------------------------------
        // PHASE 2: Test j (jump forward)
        // PC=16: j 0x02 -> skip 2 instructions
        //   PC_NEXT = 20, target = 20 + 2*4 = 28
        //   Instructions at PC=20 and PC=24 should be SKIPPED
        // ---------------------------------------------------------

        // PC=16: j 0x02           -> jump forward by 2
        {instr_mem[10'd19], instr_mem[10'd18], instr_mem[10'd17], instr_mem[10'd16]}  = 32'b00000110_00000010_00000000_00000000;

        // PC=20: loadi r4, 0xAA   -> SHOULD BE SKIPPED by jump
        {instr_mem[10'd23], instr_mem[10'd22], instr_mem[10'd21], instr_mem[10'd20]}  = 32'b00000000_00000100_00000000_10101010;

        // PC=24: loadi r5, 0xBB   -> SHOULD ALSO BE SKIPPED by jump
        {instr_mem[10'd27], instr_mem[10'd26], instr_mem[10'd25], instr_mem[10'd24]}  = 32'b00000000_00000101_00000000_10111011;

        // PC=28: loadi r4, 0x11   -> SHOULD EXECUTE (jump lands here)
        // Verification: if jump works, r4=0x11. If not, r4=0xAA
        {instr_mem[10'd31], instr_mem[10'd30], instr_mem[10'd29], instr_mem[10'd28]}  = 32'b00000000_00000100_00000000_00010001;

        // ---------------------------------------------------------
        // PHASE 3: Test beq (branch TAKEN) - registers are equal
        // r0 = 5, r2 = 5 -> equal, branch should be taken
        // PC=32: beq 0x01, r0, r2
        //   PC_NEXT = 36, target = 36 + 1*4 = 40
        //   Instruction at PC=36 should be SKIPPED
        // ---------------------------------------------------------

        // PC=32: beq 0x01, r0, r2 -> branch forward 1 (r0==r2, take it)
        {instr_mem[10'd35], instr_mem[10'd34], instr_mem[10'd33], instr_mem[10'd32]}  = 32'b00000111_00000001_00000000_00000010;

        // PC=36: loadi r5, 0xDD   -> SHOULD BE SKIPPED (beq taken)
        {instr_mem[10'd39], instr_mem[10'd38], instr_mem[10'd37], instr_mem[10'd36]}  = 32'b00000000_00000101_00000000_11011101;

        // PC=40: loadi r5, 0x22   -> SHOULD EXECUTE (beq lands here)
        // Verification: if beq taken works, r5=0x22. If not, r5=0xDD
        {instr_mem[10'd43], instr_mem[10'd42], instr_mem[10'd41], instr_mem[10'd40]}  = 32'b00000000_00000101_00000000_00100010;

        // ---------------------------------------------------------
        // PHASE 4: Test beq (branch NOT TAKEN) - registers differ
        // r0 = 5, r1 = 10 -> NOT equal, branch should NOT be taken
        // PC=44: beq 0x01, r0, r1
        //   r0 != r1, so PC should go to 48 (fall through)
        // ---------------------------------------------------------

        // PC=44: beq 0x01, r0, r1 -> should NOT branch (r0 != r1)
        {instr_mem[10'd47], instr_mem[10'd46], instr_mem[10'd45], instr_mem[10'd44]}  = 32'b00000111_00000001_00000000_00000001;

        // PC=48: loadi r6, 0x33   -> SHOULD EXECUTE (beq NOT taken, falls through)
        // Verification: if beq not-taken works, r6=0x33. If wrongly taken, r6=0
        {instr_mem[10'd51], instr_mem[10'd50], instr_mem[10'd49], instr_mem[10'd48]}  = 32'b00000000_00000110_00000000_00110011;

        // ---------------------------------------------------------
        // PHASE 5: Another j (jump forward) test
        // PC=52: j 0x02 -> skip 2 instructions
        //   PC_NEXT = 56, target = 56 + 2*4 = 64
        // ---------------------------------------------------------

        // PC=52: j 0x02           -> jump forward by 2
        {instr_mem[10'd55], instr_mem[10'd54], instr_mem[10'd53], instr_mem[10'd52]}  = 32'b00000110_00000010_00000000_00000000;

        // PC=56: loadi r7, 0xEE   -> SHOULD BE SKIPPED by jump
        {instr_mem[10'd59], instr_mem[10'd58], instr_mem[10'd57], instr_mem[10'd56]}  = 32'b00000000_00000111_00000000_11101110;

        // PC=60: loadi r7, 0xFF   -> SHOULD BE SKIPPED by jump
        {instr_mem[10'd63], instr_mem[10'd62], instr_mem[10'd61], instr_mem[10'd60]}  = 32'b00000000_00000111_00000000_11111111;

        // PC=64: loadi r7, 0x44   -> SHOULD EXECUTE (jump lands here)
        // Verification: if jump works, r7=0x44. If not, r7=0xEE or 0xFF
        {instr_mem[10'd67], instr_mem[10'd66], instr_mem[10'd65], instr_mem[10'd64]}  = 32'b00000000_00000111_00000000_01000100;

        // ---------------------------------------------------------
        // PHASE 6: Backward branch loop test
        //   Uses beq + j to create a counting loop
        //   Loop body: decrement r0 from 3 to 0, then exit
        //
        //   PC=68: loadi r0, 3    -> loop counter (3 iterations)
        //   PC=72: loadi r1, 1    -> decrement step value
        //   PC=76: loadi r2, 0    -> comparison target (zero)
        //   PC=80: sub r0, r0, r1 -> r0 = r0 - 1
        //   PC=84: beq 0x01, r0, r2 -> if r0==0, skip next (-> PC=92)
        //   PC=88: j 0xFD         -> jump back 3 (-> PC=80)
        //          PC_NEXT=92, target=92+(-3)*4=80
        //   PC=92: loadi r3, 0x77 -> loop exit marker
        // ---------------------------------------------------------

        // PC=68: loadi r0, 3       -> loop counter = 3
        {instr_mem[10'd71], instr_mem[10'd70], instr_mem[10'd69], instr_mem[10'd68]}  = 32'b00000000_00000000_00000000_00000011;

        // PC=72: loadi r1, 1       -> decrement step = 1
        {instr_mem[10'd75], instr_mem[10'd74], instr_mem[10'd73], instr_mem[10'd72]}  = 32'b00000000_00000001_00000000_00000001;

        // PC=76: loadi r2, 0       -> comparison value = 0
        {instr_mem[10'd79], instr_mem[10'd78], instr_mem[10'd77], instr_mem[10'd76]}  = 32'b00000000_00000010_00000000_00000000;

        // PC=80: sub r0, r0, r1    -> r0 = r0 - 1
        {instr_mem[10'd83], instr_mem[10'd82], instr_mem[10'd81], instr_mem[10'd80]}  = 32'b00000011_00000000_00000000_00000001;

        // PC=84: beq 0x01, r0, r2  -> if r0 == 0, branch to PC=92 (skip the jump)
        //   PC_NEXT=88, target = 88 + 1*4 = 92
        {instr_mem[10'd87], instr_mem[10'd86], instr_mem[10'd85], instr_mem[10'd84]}  = 32'b00000111_00000001_00000000_00000010;

        // PC=88: j 0xFD            -> jump back to PC=80 (loop back)
        //   PC_NEXT=92, target = 92 + (-3)*4 = 92-12 = 80
        //   0xFD = -3 in signed 8-bit (11111101)
        {instr_mem[10'd91], instr_mem[10'd90], instr_mem[10'd89], instr_mem[10'd88]}  = 32'b00000110_11111101_00000000_00000000;

        // PC=92: loadi r3, 0x77    -> proves loop exited successfully
        //   r0 should be 0, r3 should become 0x77
        {instr_mem[10'd95], instr_mem[10'd94], instr_mem[10'd93], instr_mem[10'd92]}  = 32'b00000000_00000011_00000000_01110111;

        // PC=96: sub r4, r4, r4    -> r4 = 0 (self-subtract for cleanup)
        {instr_mem[10'd99], instr_mem[10'd98], instr_mem[10'd97], instr_mem[10'd96]}  = 32'b00000011_00000100_00000100_00000100;
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

        // ============================================================
        // EXPECTED FINAL REGISTER VALUES:
        // ============================================================
        // r0 = 0   (0x00) - loop counter decremented to 0
        // r1 = 1   (0x01) - loop step value
        // r2 = 0   (0x00) - loop comparison target
        // r3 = 119 (0x77) - proves loop exit happened
        // r4 = 0   (0x00) - self-subtracted at end
        // r5 = 34  (0x22) - proves beq taken worked
        // r6 = 51  (0x33) - proves beq not-taken worked
        // r7 = 68  (0x44) - proves jump forward worked
        // ============================================================
        
        // let it run long enough for all phases including the loop
        // ~30 instruction cycles at 10 time units each = 300, giving extra margin
        // putting 700 just to be safe 
        #700;

        // print final register values for verification
        $display("\n========================================");
        $display("FINAL REGISTER VALUES:");
        $display("========================================");
        $display("r0 = %0d (0x%02h) [expected: 0 (0x00) - loop counter finished]", 
                 mycpu.myreg.registers[0], mycpu.myreg.registers[0]);
        $display("r1 = %0d (0x%02h) [expected: 1 (0x01) - loop step]", 
                 mycpu.myreg.registers[1], mycpu.myreg.registers[1]);
        $display("r2 = %0d (0x%02h) [expected: 0 (0x00) - loop zero target]", 
                 mycpu.myreg.registers[2], mycpu.myreg.registers[2]);
        $display("r3 = %0d (0x%02h) [expected: 119 (0x77) - loop exit marker]", 
                 mycpu.myreg.registers[3], mycpu.myreg.registers[3]);
        $display("r4 = %0d (0x%02h) [expected: 0 (0x00) - self-subtracted]", 
                 mycpu.myreg.registers[4], mycpu.myreg.registers[4]);
        $display("r5 = %0d (0x%02h) [expected: 34 (0x22) - beq taken proof]", 
                 mycpu.myreg.registers[5], mycpu.myreg.registers[5]);
        $display("r6 = %0d (0x%02h) [expected: 51 (0x33) - beq not-taken proof]", 
                 mycpu.myreg.registers[6], mycpu.myreg.registers[6]);
        $display("r7 = %0d (0x%02h) [expected: 68 (0x44) - jump forward proof]", 
                 mycpu.myreg.registers[7], mycpu.myreg.registers[7]);
        $display("========================================\n");

        $finish;
    end

    // clock gen - flip every 4 time units = period of 8
    // Period is 8 because decode and reg read are now in parallel
    always
        #4 CLK = ~CLK;

    // monitor for debugging - shows all important signals including new flow control ones
    initial begin
        $monitor("Time=%0t | CLK=%b RESET=%b | PC=%0d | OPCODE=%b | RD=%0d RT=%0d RS=%0d | ALUOP=%b WE=%b | JUMP=%b BRANCH=%b ZERO=%b PC_SEL=%b | ALURES=%0d | TARGET=%0d",
                 $time, CLK, RESET, PC, 
                 mycpu.mycontrol.OPCODE, mycpu.WRITEREG, mycpu.READREG1, mycpu.READREG2,
                 mycpu.ALUOP, mycpu.WRITEENABLE,
                 mycpu.JUMP, mycpu.BRANCH, mycpu.ZERO, mycpu.PC_SELECT,
                 mycpu.ALURESULT, mycpu.BRANCH_JUMP_TARGET);
    end

endmodule
