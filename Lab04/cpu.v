// top level CPU module - connects everything together
// LAB 4: upgraded to support j and beq flow control instructions
// supports: add, sub, and, or, mov, loadi, j, beq
// (I am losing my mind over all these wires)
//
// ARCHITECTURE OVERVIEW (lab 4 additions):
//   The offset from the instruction (bits[23:16]) is sign-extended to 32 bits,
//   then left-shifted by 2 (i.e. multiplied by 4) to convert from an instruction
//   count offset to a byte offset. This shifted offset is added to PC_NEXT (PC+4)
//   by a dedicated branch/jump target adder with #2 latency, running in parallel
//   with the ALU. 
//   if that makes no sense, don't worry, I don't get it either tbh
//
//   For j:   PC_SELECT = 1 unconditionally -> PC = PC+4 + (offset << 2)
//   For beq: PC_SELECT = (BRANCH & ZERO)   -> PC = PC+4 + (offset << 2) only if equal
//
//   A 32-bit mux_2x1 selects between PC+4 (normal) and the branch/jump target.

module cpu(PC, INSTRUCTION, CLK, RESET);

    // ports
    output wire [31:0] PC;       // program counter output
    input [31:0] INSTRUCTION;    // instruction from memory
    input CLK;
    input RESET;

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
    wire JUMP;                   // NEW: unconditional jump signal
    wire BRANCH;                 // NEW: conditional branch signal
    wire [7:0] OFFSET;           // NEW: signed offset from instruction

    // -------------------------------------------------------
    // Internal data wires
    // -------------------------------------------------------
    wire [7:0] REGOUT1;          // value from reg port 1
    wire [7:0] REGOUT2;          // value from reg port 2
    wire [7:0] ALURESULT;        // output of alu
    wire ZERO;                   // NEW: zero flag from alu (for beq)
    wire [7:0] TWOS_COMP_OUT;    // negated value for subtraction
    wire [7:0] MUX_COMP_RESULT;  // after complement mux
    wire [7:0] MUX_IMM_RESULT;   // after immediate mux, goes into alu

    // -------------------------------------------------------
    // NEW: Branch/Jump target calculation wires
    // -------------------------------------------------------
    wire [31:0] PC_NEXT;                 // PC + 4 (from pc_unit)
    wire [31:0] OFFSET_SIGN_EXTENDED;    // offset sign-extended to 32 bits
    wire [31:0] OFFSET_SHIFTED;          // offset << 2 (multiply by 4)
    wire [31:0] BRANCH_JUMP_TARGET;      // final target = PC+4 + shifted offset
    wire PC_SELECT;                      // 0=sequential, 1=take branch/jump

    // -------------------------------------------------------
    // Sign-extend the 8-bit offset to 32 bits
    // The offset is treated as a signed (2's complement) value
    // so negative offsets (backward branches) work correctly.
    // e.g. 0xFE (-2) becomes 0xFFFFFFFE. pretty neat trick
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
    // PC_SELECT logic:
    //   - For j:   JUMP = 1, so PC_SELECT = 1 (always take the jump)
    //   - For beq: BRANCH = 1 and ZERO must be 1 for the branch to be taken
    //   - For all other instructions: PC_SELECT = 0 (sequential)
    //   I spent way too long trying to figure out this one line
    // -------------------------------------------------------
    assign PC_SELECT = JUMP | (BRANCH & ZERO);

    // -------------------------------------------------------
    // Program Counter (upgraded)
    // Now receives PC_SELECT and BRANCH_JUMP_TARGET
    // -------------------------------------------------------
    pc_unit mypc(
        .PC(PC),
        .PC_NEXT(PC_NEXT),                   // NEW: output for target adder
        .BRANCH_JUMP_TARGET(BRANCH_JUMP_TARGET), // NEW: target address
        .PC_SELECT(PC_SELECT),               // NEW: 0=PC+4, 1=target
        .CLK(CLK),
        .RESET(RESET)
    );

    // -------------------------------------------------------
    // Control unit - decodes instruction and sets all control signals
    // (upgraded with JUMP, BRANCH, OFFSET outputs)
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
        .JUMP(JUMP),                         // NEW
        .BRANCH(BRANCH),                     // NEW
        .OFFSET(OFFSET)                      // NEW
    );

    // -------------------------------------------------------
    // 2s complement for subtraction (and beq comparison)
    // thank god I don't have to write this from scratch
    // -------------------------------------------------------
    twos_complement mytwoscomp(
        .IN(REGOUT2),
        .OUT(TWOS_COMP_OUT)
    );

    // -------------------------------------------------------
    // Mux: choose between normal value or 2s complement
    // sub and beq set this to 1, everything else uses 0
    // -------------------------------------------------------
    mux_2x1_8bit mux_comp(
        .IN0(REGOUT2),
        .IN1(TWOS_COMP_OUT),
        .SEL(MUX_COMP_SEL),
        .OUT(MUX_COMP_RESULT)
    );

    // -------------------------------------------------------
    // Mux: choose between register value or immediate
    // loadi uses immediate, everything else uses register
    // -------------------------------------------------------
    mux_2x1_8bit mux_imm(
        .IN0(MUX_COMP_RESULT),
        .IN1(IMMEDIATE),
        .SEL(MUX_IMM_SEL),
        .OUT(MUX_IMM_RESULT)
    );

    // -------------------------------------------------------
    // ALU - does the actual computation
    // (upgraded with ZERO flag output)
    // -------------------------------------------------------
    alu myalu(
        .DATA1(REGOUT1),
        .DATA2(MUX_IMM_RESULT),
        .RESULT(ALURESULT),
        .SELECT(ALUOP),
        .ZERO(ZERO)                          // NEW: zero flag for beq
    );

    // -------------------------------------------------------
    // Register file - stores all 8 registers
    // ALU result gets written back here
    // -------------------------------------------------------
    reg_file myreg(
        .IN(ALURESULT),
        .OUT1(REGOUT1),
        .OUT2(REGOUT2),
        .INADDRESS(WRITEREG),
        .OUT1ADDRESS(READREG1),
        .OUT2ADDRESS(READREG2),
        .WRITE(WRITEENABLE),
        .CLK(CLK),
        .RESET(RESET)
    );

endmodule
