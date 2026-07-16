`timescale 1ns/100ps
// CPU Testbench - Lab 4.5
// Tests all 14 instructions: loadi, mov, add, sub, and, or, j, beq,
//                            mult, sll, srl, sra, ror, bne
// Clock  period is set to 8 time units (toggle every 4)
// TIMING ANALYSIS:
//   The beq/bne instructions have the longest critical path:
//     PC update (#1) -> Instr memory (#2) -> Reg read (#2) -> 2's comp (#1) -> ALU (#2) = 8 time units
//     BUT decode (#1) happens in parallel with Reg read (#2), so actual = 1+2+2+2 = 7
//     (beq/bne add 2's comp which is also parallel with decode)
//
//   New instruction critical paths (decode || reg read):
//     mult: PC(#1) -> Mem(#2) -> max(Decode(#1), RegRead(#2)) -> Mult(#3) = 1+2+2+3 = 8 
//     sll/srl/sra/ror: PC(#1) -> Mem(#2) -> max(Decode(#1), RegRead(#2)) -> Shift(#2) = 1+2+2+2 = 7 
//     bne: same as beq = 8 
//   All instructions fit  within the 8 time units limit.
//
// TEST PROGRAM SUMMARY:
//   Phase 1: Basic arithmetic to set up register values
//   Phase 2: Jump forward test (skip over instructions)
//   Phase 3: beq taken test (branch when registers are equal)
//   Phase 4: beq not-taken test (no branch when registers differ)
//   Phase 5: Another jump forward test
//   Phase 6: Backward loop using beq + j (decrement counter from 3 to 0)
//   Phase 7: Multiply test (mult)
//   Phase 8: Shift left logical test (sll)
//   Phase 9: Shift right logical test (srl)
//   Phase 10: Shift right arithmetic test (sra)
//   Phase 11: Rotate right test (ror)
//   Phase 12: bne taken test (branch when NOT equal)
//   Phase 13: bne not-taken test (no branch when equal)

`include "cpu.v"
`include "alu.v"
`include "reg_file.v"
`include "control_unit.v"
`include "mux_2x1_8bit.v"
`include "pc_unit.v"
`include "twos_complement.v"
`include "mult_unit.v"
`include "shift_unit.v"
`include "data_memory.v"
`include "dcache.v"

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
    //   mult  = 0x08, sll = 0x09, srl = 0x0A, sra = 0x0B
    //   ror   = 0x0C, bne = 0x0D
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

        // PC=92: loadi r3, 0x77    -> Validates that loop exited successfully
        //   r0 should be 0, r3 should become 0x77
        {instr_mem[10'd95], instr_mem[10'd94], instr_mem[10'd93], instr_mem[10'd92]}  = 32'b00000000_00000011_00000000_01110111;

        // PC=96: sub r4, r4, r4    -> r4 = 0 (self-subtract for cleanup)
        {instr_mem[10'd99], instr_mem[10'd98], instr_mem[10'd97], instr_mem[10'd96]}  = 32'b00000011_00000100_00000100_00000100;

        // ============================================================
        // EXTENDED ISA TESTS - LAB 4.5
        // ============================================================

        // ---------------------------------------------------------
        // PHASE 7: Multiply test
        //   r0 = 5, r1 = 7, mult r2, r0, r1 -> r2 = 35
        // ---------------------------------------------------------

        // PC=100: loadi r0, 5      -> r0 = 5
        {instr_mem[10'd103], instr_mem[10'd102], instr_mem[10'd101], instr_mem[10'd100]} = 32'b00000000_00000000_00000000_00000101;

        // PC=104: loadi r1, 7      -> r1 = 7
        {instr_mem[10'd107], instr_mem[10'd106], instr_mem[10'd105], instr_mem[10'd104]} = 32'b00000000_00000001_00000000_00000111;

        // PC=108: mult r2, r0, r1  -> r2 = 5 * 7 = 35
        //   ALUOP=101, DATA1=reg[0]=5, DATA2=reg[1]=7
        {instr_mem[10'd111], instr_mem[10'd110], instr_mem[10'd109], instr_mem[10'd108]} = 32'b00001000_00000010_00000000_00000001;

        // ---------------------------------------------------------
        // PHASE 8: Shift Left Logical (SLL) test
        //   r3 = 5 (00000101), sll r4, r3, 2 -> 00010100 = 20
        // ---------------------------------------------------------

        // PC=112: loadi r3, 0x05   -> r3 = 5 (00000101)
        {instr_mem[10'd115], instr_mem[10'd114], instr_mem[10'd113], instr_mem[10'd112]} = 32'b00000000_00000011_00000000_00000101;

        // PC=116: sll r4, r3, 2    -> r4 = 00010100 = 20
        //   ALUOP=100, SHIFT_MODE=00, DATA1=reg[3]=5, DATA2=imm=2
        {instr_mem[10'd119], instr_mem[10'd118], instr_mem[10'd117], instr_mem[10'd116]} = 32'b00001001_00000100_00000011_00000010;

        // ---------------------------------------------------------
        // PHASE 9: Shift Right Logical (SRL) test
        //   r3 = 0xA0 (10100000), srl r5, r3, 3 -> 00010100 = 20
        // ---------------------------------------------------------

        // PC=120: loadi r3, 0xA0   -> r3 = 160 (10100000)
        {instr_mem[10'd123], instr_mem[10'd122], instr_mem[10'd121], instr_mem[10'd120]} = 32'b00000000_00000011_00000000_10100000;

        // PC=124: srl r5, r3, 3    -> r5 = 00010100 = 20
        //   ALUOP=100, SHIFT_MODE=01, DATA1=reg[3]=0xA0, DATA2=imm=3
        //   10100000 >> 3 = 00010100 (fill with 0s from left)
        {instr_mem[10'd127], instr_mem[10'd126], instr_mem[10'd125], instr_mem[10'd124]} = 32'b00001010_00000101_00000011_00000011;

        // ---------------------------------------------------------
        // PHASE 10: Shift Right Arithmetic (SRA) test
        //   r3 = 0xA0 (10100000, negative in signed), sra r6, r3, 3
        //   -> 11110100 = 0xF4 = 244 (sign bit preserved!)
        //   this is different from SRL because the sign bit fills in from the left
        // ---------------------------------------------------------

        // PC=128: sra r6, r3, 3    -> r6 = 11110100 = 0xF4 = 244
        //   ALUOP=100, SHIFT_MODE=10, DATA1=reg[3]=0xA0, DATA2=imm=3
        {instr_mem[10'd131], instr_mem[10'd130], instr_mem[10'd129], instr_mem[10'd128]} = 32'b00001011_00000110_00000011_00000011;

        // ---------------------------------------------------------
        // PHASE 11: Rotate Right (ROR) test
        //   r3 = 0x05 (00000101), ror r7, r3, 2 -> 01000001 = 0x41 = 65
        //   bits that fall off the right wrap around to the left:
        //   00000101 rotate right 2 = 01|000001 (the '01' wraps to MSB side)
        // ---------------------------------------------------------

        // PC=132: loadi r3, 0x05   -> r3 = 5 (00000101)
        {instr_mem[10'd135], instr_mem[10'd134], instr_mem[10'd133], instr_mem[10'd132]} = 32'b00000000_00000011_00000000_00000101;

        // PC=136: ror r7, r3, 2    -> r7 = 01000001 = 0x41 = 65
        //   ALUOP=100, SHIFT_MODE=11, DATA1=reg[3]=0x05, DATA2=imm=2
        {instr_mem[10'd139], instr_mem[10'd138], instr_mem[10'd137], instr_mem[10'd136]} = 32'b00001100_00000111_00000011_00000010;

        // ---------------------------------------------------------
        // PHASE 12: bne TAKEN test (branch when NOT equal)
        //   r0 = 5, r1 = 7 -> NOT equal, branch should be TAKEN
        //   PC=140: bne 0x01, r0, r1  -> branch forward 1 (skip PC=144)
        //   PC_NEXT=144, target = 144 + 1*4 = 148
        // ---------------------------------------------------------

        // PC=140: bne 0x01, r0, r1 -> branch taken (r0=5 != r1=7)
        {instr_mem[10'd143], instr_mem[10'd142], instr_mem[10'd141], instr_mem[10'd140]} = 32'b00001101_00000001_00000000_00000001;

        // PC=144: loadi r3, 0xDD   -> SHOULD BE SKIPPED (bne taken)
        {instr_mem[10'd147], instr_mem[10'd146], instr_mem[10'd145], instr_mem[10'd144]} = 32'b00000000_00000011_00000000_11011101;

        // PC=148: loadi r3, 0xAA   -> SHOULD EXECUTE (bne lands here)
        //   Verification: if bne taken works, r3=0xAA. If not, r3=0xDD
        {instr_mem[10'd151], instr_mem[10'd150], instr_mem[10'd149], instr_mem[10'd148]} = 32'b00000000_00000011_00000000_10101010;

        // ---------------------------------------------------------
        // PHASE 13: bne NOT TAKEN test (no branch when equal)
        //   Load same value into r0 and r1, then bne should NOT branch
        // ---------------------------------------------------------

        // PC=152: loadi r0, 42     -> r0 = 42
        {instr_mem[10'd155], instr_mem[10'd154], instr_mem[10'd153], instr_mem[10'd152]} = 32'b00000000_00000000_00000000_00101010;

        // PC=156: mov r1, r0       -> r1 = r0 = 42
        {instr_mem[10'd159], instr_mem[10'd158], instr_mem[10'd157], instr_mem[10'd156]} = 32'b00000001_00000001_00000000_00000000;

        // PC=160: bne 0x01, r0, r1 -> should NOT branch (r0=42 == r1=42)
        {instr_mem[10'd163], instr_mem[10'd162], instr_mem[10'd161], instr_mem[10'd160]} = 32'b00001101_00000001_00000000_00000001;

        // PC=164: loadi r3, 0xBB   -> SHOULD EXECUTE (bne NOT taken, falls through)
        //   Verification: if bne not-taken works, r3=0xBB. If wrongly taken, r3=0xAA
        {instr_mem[10'd167], instr_mem[10'd166], instr_mem[10'd165], instr_mem[10'd164]} = 32'b00000000_00000011_00000000_10111011;

        // ============================================================
        // PHASE 14: Data Memory Tests (Lab 5)
        // ============================================================
        // PC=168: swi r7, 16      -> mem[16] = r7 = 65
        {instr_mem[10'd171], instr_mem[10'd170], instr_mem[10'd169], instr_mem[10'd168]} = 32'b00010001_00000000_00000111_00010000;
        
        // PC=172: swd r6, r0      -> mem[r0(42)] = r6 = 244
        {instr_mem[10'd175], instr_mem[10'd174], instr_mem[10'd173], instr_mem[10'd172]} = 32'b00010000_00000000_00000110_00000000;
        
        // PC=176: lwi r1, 16      -> r1 = mem[16] = 65
        {instr_mem[10'd179], instr_mem[10'd178], instr_mem[10'd177], instr_mem[10'd176]} = 32'b00001111_00000001_00000000_00010000;
        
        // PC=180: lwd r2, r0      -> r2 = mem[r0(42)] = 244
        {instr_mem[10'd183], instr_mem[10'd182], instr_mem[10'd181], instr_mem[10'd180]} = 32'b00001110_00000010_00000000_00000000;
    end

    // memory interface wires
    wire MEM_READ, MEM_WRITE, BUSYWAIT;
    wire [7:0] MEM_ADDRESS, MEM_WRITEDATA, MEM_READDATA;

    // cache-to-memory wires
    wire mem_read, mem_write, mem_busywait;
    wire [5:0] mem_address;
    wire [31:0] mem_writedata, mem_readdata;

    // instantiate the cpu
    cpu mycpu(PC, INSTRUCTION, CLK, RESET, MEM_READ, MEM_WRITE, MEM_ADDRESS, MEM_WRITEDATA, MEM_READDATA, BUSYWAIT);

    // instantiate the data cache
    // The cache acts as an intermediary, capturing CPU memory requests and either returning
    // data instantly (Hit) or stalling the CPU while fetching from Main Memory (Miss).
    dcache mycache(
        .clock(CLK),
        .reset(RESET),
        .read(MEM_READ),
        .write(MEM_WRITE),
        .address(MEM_ADDRESS),
        .writedata(MEM_WRITEDATA),
        .readdata(MEM_READDATA),
        .busywait(BUSYWAIT),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .mem_address(mem_address),
        .mem_writedata(mem_writedata),
        .mem_readdata(mem_readdata),
        .mem_busywait(mem_busywait)
    );

    // instantiate the data memory
    data_memory mymem(
        .clock(CLK),
        .reset(RESET),
        .read(mem_read),
        .write(mem_write),
        .address(mem_address),
        .writedata(mem_writedata),
        .readdata(mem_readdata),
        .busywait(mem_busywait)
    );

    // simulation setup
    initial begin
        // dump waveforms for gtkwave  analysis
        $dumpfile("cpu_wavedata.vcd");
        $dumpvars(0, cpu_tb);
        // Explicitly dump each register 
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
        // EXPECTED FINAL REGISTER VALUES (after ALL phases):
        // ============================================================
        // r0 = 42  (0x2A) - loaded in phase 13 setup
        // r1 = 65  (0x41) - loaded from memory via lwi (was 42)
        // r2 = 244 (0xF4) - loaded from memory via lwd (was 35)
        // r3 = 187 (0xBB) - proves bne not-taken worked
        // r4 = 20  (0x14) - sll result (5 << 2)
        // r5 = 20  (0x14) - srl result (0xA0 >> 3)
        // r6 = 244 (0xF4) - sra result (0xA0 >>> 3, sign-extended)
        // r7 = 65  (0x41) - ror result (0x05 rotated right by 2)
        // ============================================================
        
        // let it run long enough for all phases including the loop + new tests
        // memory accesses stall the CPU for 5 cycles each
        #2000;

        // print final register values for verification
        $display("\n========================================");
        $display("FINAL REGISTER VALUES:");
        $display("========================================");
        $display("r0 = %0d (0x%02h) [expected: 42 (0x2A) - bne test setup]", 
                 mycpu.myreg.registers[0], mycpu.myreg.registers[0]);
        $display("r1 = %0d (0x%02h) [expected: 65 (0x41) - loaded from mem]", 
                 mycpu.myreg.registers[1], mycpu.myreg.registers[1]);
        $display("r2 = %0d (0x%02h) [expected: 244 (0xF4) - loaded from mem]", 
                 mycpu.myreg.registers[2], mycpu.myreg.registers[2]);
        $display("r3 = %0d (0x%02h) [expected: 187 (0xBB) - bne not-taken proof]", 
                 mycpu.myreg.registers[3], mycpu.myreg.registers[3]);
        $display("r4 = %0d (0x%02h) [expected: 20 (0x14) - sll 5<<2]", 
                 mycpu.myreg.registers[4], mycpu.myreg.registers[4]);
        $display("r5 = %0d (0x%02h) [expected: 20 (0x14) - srl 0xA0>>3]", 
                 mycpu.myreg.registers[5], mycpu.myreg.registers[5]);
        $display("r6 = %0d (0x%02h) [expected: 244 (0xF4) - sra 0xA0>>>3]", 
                 mycpu.myreg.registers[6], mycpu.myreg.registers[6]);
        $display("r7 = %0d (0x%02h) [expected: 65 (0x41) - ror 0x05 by 2]", 
                 mycpu.myreg.registers[7], mycpu.myreg.registers[7]);
        $display("========================================\n");

        $finish;
    end

    // clock gen - flip every 4 time units = period of 8
    // Period is 8 because decode and reg read are now in parallel
    always
        #4 CLK = ~CLK;

    // monitor for debugging - shows all important signals including new ones
    initial begin
        $monitor("Time=%0t | CLK=%b RESET=%b | PC=%0d | OPCODE=%b | RD=%0d RT=%0d RS=%0d | ALUOP=%b WE=%b | JUMP=%b BRANCH=%b BNE=%b ZERO=%b PC_SEL=%b | SHIFT_MODE=%b | ALURES=%0d | TARGET=%0d",
                 $time, CLK, RESET, PC, 
                 mycpu.mycontrol.OPCODE, mycpu.WRITEREG, mycpu.READREG1, mycpu.READREG2,
                 mycpu.ALUOP, mycpu.WRITEENABLE,
                 mycpu.JUMP, mycpu.BRANCH, mycpu.BRANCH_NEQ, mycpu.ZERO, mycpu.PC_SELECT,
                 mycpu.SHIFT_MODE,
                 mycpu.ALURESULT, mycpu.BRANCH_JUMP_TARGET);
    end

endmodule
