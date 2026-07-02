// CPU Top Level Module: Integrates Datapath and Control Path.
// Architecture upgraded to facilitate control flow instructions (J, BEQ).
// Supported Instruction Set Architecture (ISA): ADD, SUB, AND, OR, MOV, LOADI, J, BEQ.
// Implements a unified single-cycle datapath.

// ARCHITECTURE OVERVIEW:
//   The immediate offset field (bits [23:16]) undergoes sign-extension to 32 bits.
//   It is subsequently left-shifted by 2 to map the instruction-count displacement 
//   to a byte-address displacement. This adjusted offset is aggregated with PC_NEXT 
//   (PC+4) via a dedicated branch/jump adder.  Aligns memory word alignment with 
//   byte-addressable specifications.
//
//   Unconditional Jump (J):   PC_SELECT = 1 -> PC = PC+4 + (offset << 2)
//   Conditional Branch (BEQ): PC_SELECT = (BRANCH & ZERO) -> PC = PC+4 + (offset << 2)
//   A 32-bit multiplexer resolves the subsequent PC state between sequential execution and target addresses.

module cpu(PC, INSTRUCTION, CLK, RESET);
    // ports
    output wire [31:0] PC;       // program counter output
    input [31:0] INSTRUCTION;    // instruction from memory
    input CLK;
    input RESET;

    // Control signals from the control unit
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

    // Internal data wires
    wire [7:0] REGOUT1;          // value from reg port 1
    wire [7:0] REGOUT2;          // value from reg port 2
    wire [7:0] ALURESULT;        // output of alu
    wire ZERO;                   // NEW: zero flag from alu (for beq)
    wire [7:0] TWOS_COMP_OUT;    // negated value for subtraction
    wire [7:0] MUX_COMP_RESULT;  // after complement mux
    wire [7:0] MUX_IMM_RESULT;   // after immediate mux, goes into alu

    // Branch/Jump target calculation wires
    wire [31:0] PC_NEXT;                 // PC + 4 (from pc_unit)
    wire [31:0] OFFSET_SIGN_EXTENDED;    // offset sign-extended to 32 bits
    wire [31:0] OFFSET_SHIFTED;          // offset << 2 (multiply by 4)
    wire [31:0] BRANCH_JUMP_TARGET;      // final target = PC+4 + shifted offset
    wire PC_SELECT;                      // 0=sequential, 1=take branch/jump

    // Sign-extension of the 8-bit instruction offset to 32 bits.
    // The offset dictates a two's complement signed displacement,
    // accommodating bidirectional branch resolution.
    // e.g. 0xFE (-2) is sign-extended to 0xFFFFFFFE.
    assign OFFSET_SIGN_EXTENDED = {{24{OFFSET[7]}}, OFFSET};

    // Left-shift by 2 to convert instruction offset to byte offset
    // (each instruction is 4 bytes, so offset 2 = 8 bytes)
    assign OFFSET_SHIFTED = OFFSET_SIGN_EXTENDED << 2;

    // Branch/jump target adder with #2 delay
    // Runs in parallel with the ALU
    // Computes: target = PC_NEXT + (sign_extended_offset << 2)
    assign #2 BRANCH_JUMP_TARGET = PC_NEXT + OFFSET_SHIFTED;

    // Next-PC Multiplexer Control Logic (PC_SELECT):
    //   - JUMP (J): Asserts unconditionally (PC_SELECT = 1).
    //   - BEQ: Asserts contingently upon identical operands (BRANCH & ZERO).
    //   - Default: Proceeds sequentially (PC_SELECT = 0).
    //   Determines final target multiplexer routing.
    assign PC_SELECT = JUMP | (BRANCH & ZERO);

    // Program Counter (upgraded)
    // Now receives PC_SELECT and BRANCH_JUMP_TARGET
    pc_unit mypc(
        .PC(PC),
        .PC_NEXT(PC_NEXT),                   // NEW: output for target adder
        .BRANCH_JUMP_TARGET(BRANCH_JUMP_TARGET), // NEW: target address
        .PC_SELECT(PC_SELECT),               // NEW: 0=PC+4, 1=target
        .CLK(CLK),
        .RESET(RESET)
    );

    // Control unit - decodes instruction and sets all control signals
    // (upgraded with JUMP, BRANCH, OFFSET outputs)
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

    // Two's complement conversion unit for subtraction operations.
    // Modules reused from earlier architectural lab iterations.
    twos_complement mytwoscomp(
        .IN(REGOUT2),
        .OUT(TWOS_COMP_OUT)
    );

    // Mux: choose between normal value or 2s complement
    // sub and beq set this to 1, everything else uses 0
    mux_2x1_8bit mux_comp(
        .IN0(REGOUT2),
        .IN1(TWOS_COMP_OUT),
        .SEL(MUX_COMP_SEL),
        .OUT(MUX_COMP_RESULT)
    );

    // Mux: choose between register value or immediate
    // loadi uses immediate, everything else uses register
    mux_2x1_8bit mux_imm(
        .IN0(MUX_COMP_RESULT),
        .IN1(IMMEDIATE),
        .SEL(MUX_IMM_SEL),
        .OUT(MUX_IMM_RESULT)
    );

    // ALU - does the actual computation
    // (upgraded with ZERO flag output)
    alu myalu(
        .DATA1(REGOUT1),
        .DATA2(MUX_IMM_RESULT),
        .RESULT(ALURESULT),
        .SELECT(ALUOP),
        .ZERO(ZERO)                          // NEW: zero flag for beq
    );

    // Register file - stores all 8 registers
    // ALU result gets written back here
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
