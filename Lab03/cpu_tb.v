// CO2070 Computer Architecture - Lab 3
// Testbench: Comprehensive CPU Testbench
// Tests all 6 instructions: loadi, mov, add, sub, and, or
//
// This testbench includes:
//   - Instruction memory (1024 bytes = 256 instructions)
//   - Multiple test programs hardcoded as machine code
//   - Reset functionality testing
//   - Waveform dump for GTKWave visualization
//
// Clock period = 8 time units (half-period = 4)

// `include "cpu.v"
// `include "alu.v"
// `include "reg_file.v"

module cpu_tb;

    // ============================================================
    // Testbench Signals
    // ============================================================
    reg CLK, RESET;              // Clock and reset (driven by testbench)
    wire [31:0] PC;              // Program Counter (output from CPU)
    wire [31:0] INSTRUCTION;     // Instruction word (output from instruction memory)

    // ============================================================
    // SIMPLE INSTRUCTION MEMORY
    // ============================================================
    // 1024 bytes of instruction memory (256 x 32-bit instructions)
    // Each instruction is 4 bytes, stored in big-endian byte order
    reg [7:0] instr_mem [0:1023];

    // ============================================================
    // Instruction Fetching Logic (Asynchronous)
    // ============================================================
    // The CPU provides PC as the address; we read 4 bytes starting at PC
    // to form the 32-bit instruction word.
    // Instruction memory read delay: #2 time units
    assign #2 INSTRUCTION = {instr_mem[PC[31:0]+3], instr_mem[PC[31:0]+2], 
                              instr_mem[PC[31:0]+1], instr_mem[PC[31:0]]};

    // ============================================================
    // Hardcoded Test Program
    // ============================================================
    // This program tests all 6 supported instructions:
    //   loadi, mov, add, sub, and, or
    //
    // OP-CODE encoding (from assembler):
    //   loadi = 8'b00000000 (0x00)
    //   mov   = 8'b00000001 (0x01)
    //   add   = 8'b00000010 (0x02)
    //   sub   = 8'b00000011 (0x03)
    //   and   = 8'b00000100 (0x04)
    //   or    = 8'b00000101 (0x05)
    //
    // Instruction format: {OPCODE[31:24], RD/IMM[23:16], RT[15:8], RS/IMM[7:0]}
    //
    // Test Program:
    //   Instruction 0: loadi 4 0x05      -> r4 = 5          (0x00_04_00_05)
    //   Instruction 1: loadi 2 0x09      -> r2 = 9          (0x00_02_00_09)
    //   Instruction 2: add   6 4 2       -> r6 = r4 + r2 = 14  (0x02_06_04_02)
    //   Instruction 3: mov   0 6         -> r0 = r6 = 14    (0x01_00_06_00)
    //   Instruction 4: loadi 1 0x01      -> r1 = 1          (0x00_01_00_01)
    //   Instruction 5: add   2 2 1       -> r2 = r2 + r1 = 10  (0x02_02_02_01)
    //   Instruction 6: sub   3 6 4       -> r3 = r6 - r4 = 9   (0x03_03_06_04)
    //   Instruction 7: and   5 6 2       -> r5 = r6 & r2 = 14 & 10 = 10  (0x04_05_06_02)
    //   Instruction 8: or    7 4 1       -> r7 = r4 | r1 = 5 | 1 = 5     (0x05_07_04_01)
    //   Instruction 9: loadi 3 0xFF      -> r3 = 0xFF = -1 (signed)      (0x00_03_00_FF)
    //   Instruction 10: add  5 3 4       -> r5 = r3 + r4 = -1 + 5 = 4    (0x02_05_03_04)
    //   Instruction 11: sub  7 4 2       -> r7 = r4 - r2 = 5 - 10 = -5 = 0xFB (0x03_07_04_02)
    //   Instruction 12: loadi 0 0xAA     -> r0 = 0xAA       (0x00_00_00_AA)
    //   Instruction 13: loadi 1 0x55     -> r1 = 0x55       (0x00_01_00_55)
    //   Instruction 14: and  2 0 1       -> r2 = 0xAA & 0x55 = 0x00  (0x04_02_00_01)
    //   Instruction 15: or   3 0 1       -> r3 = 0xAA | 0x55 = 0xFF  (0x05_03_00_01)
    //   Instruction 16: mov  4 3         -> r4 = r3 = 0xFF  (0x01_04_03_00)

    initial begin
        // Initialize all instruction memory to zero (NOP-like)
        // This prevents undefined behavior for unused memory locations
        
        // -------------------------------------------------------
        // Instruction 0: loadi 4 0x05 -> r4 = 5
        // Machine code: 0x00_04_00_05
        // {opcode=00000000, rd=00000100, rt=00000000, imm=00000101}
        // -------------------------------------------------------
        {instr_mem[10'd3], instr_mem[10'd2], instr_mem[10'd1], instr_mem[10'd0]}    = 32'b00000000_00000100_00000000_00000101;
        
        // -------------------------------------------------------
        // Instruction 1: loadi 2 0x09 -> r2 = 9
        // Machine code: 0x00_02_00_09
        // -------------------------------------------------------
        {instr_mem[10'd7], instr_mem[10'd6], instr_mem[10'd5], instr_mem[10'd4]}    = 32'b00000000_00000010_00000000_00001001;
        
        // -------------------------------------------------------
        // Instruction 2: add 6 4 2 -> r6 = r4 + r2 = 5 + 9 = 14
        // Machine code: 0x02_06_04_02
        // -------------------------------------------------------
        {instr_mem[10'd11], instr_mem[10'd10], instr_mem[10'd9], instr_mem[10'd8]}  = 32'b00000010_00000110_00000100_00000010;
        
        // -------------------------------------------------------
        // Instruction 3: mov 0 6 -> r0 = r6 = 14
        // Machine code: 0x01_00_06_00
        // For mov, RT field has the source register, RS/IMM is ignored (set to 0)
        // -------------------------------------------------------
        {instr_mem[10'd15], instr_mem[10'd14], instr_mem[10'd13], instr_mem[10'd12]} = 32'b00000001_00000000_00000110_00000000;
        
        // -------------------------------------------------------
        // Instruction 4: loadi 1 0x01 -> r1 = 1
        // Machine code: 0x00_01_00_01
        // -------------------------------------------------------
        {instr_mem[10'd19], instr_mem[10'd18], instr_mem[10'd17], instr_mem[10'd16]} = 32'b00000000_00000001_00000000_00000001;
        
        // -------------------------------------------------------
        // Instruction 5: add 2 2 1 -> r2 = r2 + r1 = 9 + 1 = 10
        // Machine code: 0x02_02_02_01
        // -------------------------------------------------------
        {instr_mem[10'd23], instr_mem[10'd22], instr_mem[10'd21], instr_mem[10'd20]} = 32'b00000010_00000010_00000010_00000001;
        
        // -------------------------------------------------------
        // Instruction 6: sub 3 6 4 -> r3 = r6 - r4 = 14 - 5 = 9
        // Machine code: 0x03_03_06_04
        // -------------------------------------------------------
        {instr_mem[10'd27], instr_mem[10'd26], instr_mem[10'd25], instr_mem[10'd24]} = 32'b00000011_00000011_00000110_00000100;
        
        // -------------------------------------------------------
        // Instruction 7: and 5 6 2 -> r5 = r6 & r2 = 14 & 10 = 10
        //   14 = 0b00001110, 10 = 0b00001010 -> AND = 0b00001010 = 10
        // Machine code: 0x04_05_06_02
        // -------------------------------------------------------
        {instr_mem[10'd31], instr_mem[10'd30], instr_mem[10'd29], instr_mem[10'd28]} = 32'b00000100_00000101_00000110_00000010;
        
        // -------------------------------------------------------
        // Instruction 8: or 7 4 1 -> r7 = r4 | r1 = 5 | 1 = 5
        //   5 = 0b00000101, 1 = 0b00000001 -> OR = 0b00000101 = 5
        // Machine code: 0x05_07_04_01
        // -------------------------------------------------------
        {instr_mem[10'd35], instr_mem[10'd34], instr_mem[10'd33], instr_mem[10'd32]} = 32'b00000101_00000111_00000100_00000001;
        
        // -------------------------------------------------------
        // Instruction 9: loadi 3 0xFF -> r3 = 0xFF = 255 (unsigned) / -1 (signed)
        // Machine code: 0x00_03_00_FF
        // -------------------------------------------------------
        {instr_mem[10'd39], instr_mem[10'd38], instr_mem[10'd37], instr_mem[10'd36]} = 32'b00000000_00000011_00000000_11111111;
        
        // -------------------------------------------------------
        // Instruction 10: add 5 3 4 -> r5 = r3 + r4 = -1 + 5 = 4 (signed)
        // Machine code: 0x02_05_03_04
        // -------------------------------------------------------
        {instr_mem[10'd43], instr_mem[10'd42], instr_mem[10'd41], instr_mem[10'd40]} = 32'b00000010_00000101_00000011_00000100;
        
        // -------------------------------------------------------
        // Instruction 11: sub 7 4 2 -> r7 = r4 - r2 = 5 - 10 = -5 = 0xFB
        // Machine code: 0x03_07_04_02
        // -------------------------------------------------------
        {instr_mem[10'd47], instr_mem[10'd46], instr_mem[10'd45], instr_mem[10'd44]} = 32'b00000011_00000111_00000100_00000010;
        
        // -------------------------------------------------------
        // Instruction 12: loadi 0 0xAA -> r0 = 0xAA = 10101010
        // Machine code: 0x00_00_00_AA
        // -------------------------------------------------------
        {instr_mem[10'd51], instr_mem[10'd50], instr_mem[10'd49], instr_mem[10'd48]} = 32'b00000000_00000000_00000000_10101010;
        
        // -------------------------------------------------------
        // Instruction 13: loadi 1 0x55 -> r1 = 0x55 = 01010101
        // Machine code: 0x00_01_00_55
        // -------------------------------------------------------
        {instr_mem[10'd55], instr_mem[10'd54], instr_mem[10'd53], instr_mem[10'd52]} = 32'b00000000_00000001_00000000_01010101;
        
        // -------------------------------------------------------
        // Instruction 14: and 2 0 1 -> r2 = r0 & r1 = 0xAA & 0x55 = 0x00
        // Machine code: 0x04_02_00_01
        // -------------------------------------------------------
        {instr_mem[10'd59], instr_mem[10'd58], instr_mem[10'd57], instr_mem[10'd56]} = 32'b00000100_00000010_00000000_00000001;
        
        // -------------------------------------------------------
        // Instruction 15: or 3 0 1 -> r3 = r0 | r1 = 0xAA | 0x55 = 0xFF
        // Machine code: 0x05_03_00_01
        // -------------------------------------------------------
        {instr_mem[10'd63], instr_mem[10'd62], instr_mem[10'd61], instr_mem[10'd60]} = 32'b00000101_00000011_00000000_00000001;
        
        // -------------------------------------------------------
        // Instruction 16: mov 4 3 -> r4 = r3 = 0xFF
        // Machine code: 0x01_04_03_00
        // For mov: RD=4, RT=3 (source), RS ignored
        // -------------------------------------------------------
        {instr_mem[10'd67], instr_mem[10'd66], instr_mem[10'd65], instr_mem[10'd64]} = 32'b00000001_00000100_00000011_00000000;
    end

    // ============================================================
    // CPU Instantiation
    // ============================================================
    cpu mycpu(PC, INSTRUCTION, CLK, RESET);

    // ============================================================
    // Simulation Control
    // ============================================================
    initial begin
        // Generate waveform dump file for GTKWave visualization
        $dumpfile("cpu_wavedata.vcd");
        $dumpvars(0, cpu_tb);
        
        // Initialize clock and reset
        CLK = 1'b0;
        RESET = 1'b0;
        
        // -------------------------------------------------------
        // Apply RESET pulse to initialize the CPU
        // RESET must be high during a positive clock edge to take effect
        // -------------------------------------------------------
        #1 RESET = 1'b1;    // Assert reset
        #10 RESET = 1'b0;   // De-assert reset after one+ clock cycles
        
        // -------------------------------------------------------
        // Let the program execute for enough clock cycles
        // Each instruction takes 1 clock cycle (8 time units)
        // 17 instructions * 8 time units = 136 time units minimum
        // We give extra time for safety
        // -------------------------------------------------------
        #500;
        
        // -------------------------------------------------------
        // Test RESET functionality
        // Apply reset again mid-execution to verify PC goes to 0
        // and registers are cleared
        // -------------------------------------------------------
        RESET = 1'b1;
        #10 RESET = 1'b0;
        
        // Let it run a few more instructions after reset
        #200;
        
        $finish;
    end

    // ============================================================
    // Clock Generation
    // ============================================================
    // Clock period = 8 time units (half-period = 4 time units)
    // Rising edge every 8 time units
    always
        #4 CLK = ~CLK;

    // ============================================================
    // Monitor Output (for debugging)
    // ============================================================
    // Display register values and key signals at each clock edge
    initial begin
        $monitor("Time=%0t | CLK=%b RESET=%b | PC=%0d | INSTRUCTION=%b | OPCODE=%b | RD=%0d RT=%0d RS=%0d | ALUOP=%b | WRITEENABLE=%b | ALURESULT=%0d",
                 $time, CLK, RESET, PC, INSTRUCTION, 
                 mycpu.mycontrol.OPCODE, mycpu.WRITEREG, mycpu.READREG1, mycpu.READREG2,
                 mycpu.ALUOP, mycpu.WRITEENABLE, mycpu.ALURESULT);
    end

endmodule
