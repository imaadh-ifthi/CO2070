// Top  level CPU module  that connects all components
// LAB 4: Added support for  j and beq instructions
// LAB 4.5: Extended ISA with mult, sll, srl, sra, ror, and bne 
// supported operations: add, sub, and, or, mov, loadi, j, beq, mult, sll, srl, sra, ror, bne
//
// ARCHITECTURE OVERVIEW (lab 4 additions):
//   The instruction offset (bits[23:16]) is sign extended to 32-bits,
//   and then left shifted by 2 (multiplying by 4) to  convert it from an instruction
//   count offset to a byte offset. The shifted offset is then added to PC_NEXT (PC+4)
//   using a dedicated target adder with #2  delay, which runs parallel
//   with the ALU. 
//   this ensures the proper timing behaviour for  the system
//
//   For j:   PC_SELECT = 1 unconditionally -> PC = PC+4 + (offset << 2)
//   For beq: PC_SELECT = (BRANCH & ZERO)   -> PC = PC+4 + (offset << 2) only if equal
//   For bne: PC_SELECT = (BRANCH_NEQ & ~ZERO) -> PC = PC+4 + (offset << 2) only if NOT equal
//
//   A 32-bit mux_2x1 selects between PC+4 (normal) and the branch/jump target.
//
// LAB 4.5 ADDITIONS:
//   - SHIFT_MODE[1:0]: control signal from CU to ALU's barrel shifter
//     selects between SLL(00), SRL(01), SRA(10), ROR(11)
//   - BRANCH_NEQ: new branch signal for bne (branch if not equal)
//     PC_SELECT logic updated to handle both beq and bne

module cpu(PC, INSTRUCTION, CLK, RESET, MEM_READ, MEM_WRITE, MEM_ADDRESS, MEM_WRITEDATA, MEM_READDATA, BUSYWAIT);

    // ports
    output wire [31:0] PC;       // program counter output
    input [31:0] INSTRUCTION;    // instruction from memory
    input CLK;
    input RESET;
    
    // NEW: Memory interface ports
    output wire MEM_READ;
    output wire MEM_WRITE;
    output wire [7:0] MEM_ADDRESS;
    output wire [7:0] MEM_WRITEDATA;
    input [7:0] MEM_READDATA;
    input BUSYWAIT;

    // -------------------------------------------------------
    // Control signals from the control unit
    // -------------------------------------------------------
    wire [2:0] READREG1;         // which reg to read (port 1)
    wire [2:0] READREG2;         // which reg to read (port 2)
    wire [2:0] WRITEREG;         // which reg to write to
    wire WRITEENABLE;
    wire [2:0] ALUOP;            // tells alu what operation to do
    wire MUX_IMM_SEL;            // 0=register, 1=immediate
    wire MUX_COMP_SEL;           // 0=normal, 1=2s complement (for sub)
    wire [7:0] IMMEDIATE;
    wire JUMP;                   // unconditional jump signal
    wire BRANCH;                 // conditional branch signal (beq)
    wire [7:0] OFFSET;           // signed offset from instruction
    wire [1:0] SHIFT_MODE;      // NEW: shift mode for barrel shifter
    wire BRANCH_NEQ;             // NEW: conditional branch signal (bne)

    // -------------------------------------------------------
    // Memory control signals
    // -------------------------------------------------------
    wire READ_MEM;               // memory read enable
    wire WRITE_MEM;              // memory write enable
    wire MUX_MEM_SEL;            // 0=ALU result, 1=memory data

    // -------------------------------------------------------
    // Internal data wires
    // -------------------------------------------------------
    wire [7:0] REGOUT1;          // value from reg port 1
    wire [7:0] REGOUT2;          // value from reg port 2
    wire [7:0] ALURESULT;        // output of alu
    wire ZERO;                   // zero flag from alu (for beq/bne)
    wire [7:0] TWOS_COMP_OUT;    // negated value for subtraction
    wire [7:0] MUX_COMP_RESULT;  // after complement mux
    wire [7:0] MUX_IMM_RESULT;   // after immediate mux, goes into alu

    wire [7:0] REG_IN_DATA;      // final data to write to register file

    // -------------------------------------------------------
    // Memory Interface Assignments
    // -------------------------------------------------------
    assign MEM_READ = READ_MEM;
    assign MEM_WRITE = WRITE_MEM;
    assign MEM_ADDRESS = ALURESULT;
    assign MEM_WRITEDATA = REGOUT1;

    // -------------------------------------------------------
    // Branch/Jump target calculation wires
    // -------------------------------------------------------
    wire [31:0] PC_NEXT;                 // PC + 4 (from pc_unit)
    wire [31:0] OFFSET_SIGN_EXTENDED;    // offset sign-extended to 32 bits
    wire [31:0] OFFSET_SHIFTED;          // offset << 2 (multiply by 4)
    wire [31:0] BRANCH_JUMP_TARGET;      // final target = PC+4 + shifted offset
    wire PC_SELECT;                      // 0=sequential, 1=take branch/jump

    // -------------------------------------------------------
    // Sign extened the 8-bit offset to 32 bits.
    // the offset is treated as a 2's complement signed value
    // to allow backward branching (negative offsets) to function  properly.
    // -------------------------------------------------------
    assign OFFSET_SIGN_EXTENDED = {{24{OFFSET[7]}}, OFFSET};

    // -------------------------------------------------------
    // Left-shift by 2 to convert instruction offset to byte offset
    // (each instruction is 4 bytes, so offset 2 = 8 bytes)
    // -------------------------------------------------------
    assign OFFSET_SHIFTED = OFFSET_SIGN_EXTENDED << 2;

    // -------------------------------------------------------
    // Branch/jump target adder with #2 delay
    // Runs in parallel with the ALU
    // Computes: target = PC_NEXT + (sign_extended_offset << 2)
    // -------------------------------------------------------
    assign #2 BRANCH_JUMP_TARGET = PC_NEXT + OFFSET_SHIFTED;

    // -------------------------------------------------------
    // PC_SELECT logic  implementation:
    //   - For j: JUMP = 1, PC_SELECT = 1 (unconditional jump)
    //   - For beq: BRANCH = 1 and ZERO = 1 to take the branch
    //   - For bne: BRANCH_NEQ = 1 and ZERO = 0 to take the  branch
    //   - For other instructions: PC_SELECT = 0 (sequential execution)
    //   UPDATE: Logic has been extended  to include the bne instruction
    // -------------------------------------------------------
    assign PC_SELECT = JUMP | (BRANCH & ZERO) | (BRANCH_NEQ & ~ZERO);

    // -------------------------------------------------------
    // Program  Counter (Modified)
    // Updated to recieve PC_SELECT and BRANCH_JUMP_TARGET inputs
    // -------------------------------------------------------
    pc_unit mypc(
        .PC(PC),
        .PC_NEXT(PC_NEXT),                   // output for target adder
        .BRANCH_JUMP_TARGET(BRANCH_JUMP_TARGET), // target address
        .PC_SELECT(PC_SELECT),               // 0=PC+4, 1=target
        .BUSYWAIT(BUSYWAIT),                 // stall signal
        .CLK(CLK),
        .RESET(RESET)
    );

    // -------------------------------------------------------
    // Control unit module - decodes instructions and genarates control signals
    // (Updated to include SHIFT_MODE and BRANCH_NEQ for lab 4.5)
    // -------------------------------------------------------
    control_unit mycontrol(
        .INSTRUCTION(INSTRUCTION),
        .READREG1(READREG1),
        .READREG2(READREG2),
        .WRITEREG(WRITEREG),
        .WRITEENABLE(WRITEENABLE),
        .ALUOP(ALUOP),
        .MUX_IMM_SEL(MUX_IMM_SEL),
        .MUX_COMP_SEL(MUX_COMP_SEL),
        .IMMEDIATE(IMMEDIATE),
        .JUMP(JUMP),
        .BRANCH(BRANCH),
        .OFFSET(OFFSET),
        .SHIFT_MODE(SHIFT_MODE),             // NEW: shift mode for barrel shifter
        .BRANCH_NEQ(BRANCH_NEQ),             // NEW: bne branch signal
        .READ_MEM(READ_MEM),
        .WRITE_MEM(WRITE_MEM),
        .MUX_MEM_SEL(MUX_MEM_SEL)
    );

    // -------------------------------------------------------
    // 2s complement conversion for  subtraction and beq/bne operations
    // -------------------------------------------------------
    twos_complement mytwoscomp(
        .IN(REGOUT2),
        .OUT(TWOS_COMP_OUT)
    );

    // -------------------------------------------------------
    // Mux: choose between normal value or 2s complement
    // sub, beq, and bne set this to 1, everything else uses 0
    // -------------------------------------------------------
    mux_2x1_8bit mux_comp(
        .IN0(REGOUT2),
        .IN1(TWOS_COMP_OUT),
        .SEL(MUX_COMP_SEL),
        .OUT(MUX_COMP_RESULT)
    );

    // -------------------------------------------------------
    // Mux: choose between register value or immediate
    // loadi and shift instructions use immediate, everything else uses register
    // -------------------------------------------------------
    mux_2x1_8bit mux_imm(
        .IN0(MUX_COMP_RESULT),
        .IN1(IMMEDIATE),
        .SEL(MUX_IMM_SEL),
        .OUT(MUX_IMM_RESULT)
    );

    // -------------------------------------------------------
    // ALU - does the actual computation
    // (upgraded with SHIFT_MODE input for barrel shifter)
    // -------------------------------------------------------
    alu myalu(
        .DATA1(REGOUT1),
        .DATA2(MUX_IMM_RESULT),
        .RESULT(ALURESULT),
        .SELECT(ALUOP),
        .ZERO(ZERO),
        .SHIFT_MODE(SHIFT_MODE)              // NEW: shift mode passthrough
    );

    // -------------------------------------------------------
    // Mux: choose between ALU result and Memory data
    // -------------------------------------------------------
    mux_2x1_8bit mux_mem_reg(
        .IN0(ALURESULT),
        .IN1(MEM_READDATA),
        .SEL(MUX_MEM_SEL),
        .OUT(REG_IN_DATA)
    );

    // -------------------------------------------------------
    // Register file - contains all 8 registers
    // REG_IN_DATA is written  back to this module.
    // Writing is disabled  if the BUSYWAIT signal is active
    // -------------------------------------------------------
    wire REG_WRITE_ENABLE = WRITEENABLE & ~BUSYWAIT;
    
    reg_file myreg(
        .IN(REG_IN_DATA),
        .OUT1(REGOUT1),
        .OUT2(REGOUT2),
        .INADDRESS(WRITEREG),
        .OUT1ADDRESS(READREG1),
        .OUT2ADDRESS(READREG2),
        .WRITE(REG_WRITE_ENABLE),
        .CLK(CLK),
        .RESET(RESET)
    );

endmodule
