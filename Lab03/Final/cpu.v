// top level CPU module - connects everything together
// supports: add, sub, and, or, mov, loadi

module cpu(PC, INSTRUCTION, CLK, RESET);

    // ports
    output wire [31:0] PC;       // program counter output
    input [31:0] INSTRUCTION;    // instruction from memory
    input CLK;
    input RESET;

    // wires from control unit
    wire [2:0] READREG1;         // which reg to read (port 1)
    wire [2:0] READREG2;         // which reg to read (port 2)
    wire [2:0] WRITEREG;         // which reg to write to
    wire WRITEENABLE;
    wire [2:0] ALUOP;            // tells alu what operation to do
    wire MUX_IMM_SEL;            // 0=register, 1=immediate
    wire MUX_COMP_SEL;           // 0=normal, 1=2s complement (for sub)
    wire [7:0] IMMEDIATE;

    // internal data wires
    wire [7:0] REGOUT1;          // value from reg port 1
    wire [7:0] REGOUT2;          // value from reg port 2
    wire [7:0] ALURESULT;        // output of alu
    wire [7:0] TWOS_COMP_OUT;    // negated value for subtraction
    wire [7:0] MUX_COMP_RESULT;  // after complement mux
    wire [7:0] MUX_IMM_RESULT;   // after immediate mux, goes into alu

    // program counter
    pc_unit mypc(
        .PC(PC),
        .CLK(CLK),
        .RESET(RESET)
    );

    // control unit - decodes instruction and sets all the control signals
    control_unit mycontrol(
        .INSTRUCTION(INSTRUCTION),
        .READREG1(READREG1),
        .READREG2(READREG2),
        .WRITEREG(WRITEREG),
        .WRITEENABLE(WRITEENABLE),
        .ALUOP(ALUOP),
        .MUX_IMM_SEL(MUX_IMM_SEL),
        .MUX_COMP_SEL(MUX_COMP_SEL),
        .IMMEDIATE(IMMEDIATE)
    );

    // 2s complement for subtraction
    twos_complement mytwoscomp(
        .IN(REGOUT2),
        .OUT(TWOS_COMP_OUT)
    );

    // mux to choose between normal value or 2s complement
    // sub sets this to 1, everything else uses 0
    mux_2x1_8bit mux_comp(
        .IN0(REGOUT2),
        .IN1(TWOS_COMP_OUT),
        .SEL(MUX_COMP_SEL),
        .OUT(MUX_COMP_RESULT)
    );

    // mux to choose between register value or immediate
    // loadi uses immediate, everything else uses register
    mux_2x1_8bit mux_imm(
        .IN0(MUX_COMP_RESULT),
        .IN1(IMMEDIATE),
        .SEL(MUX_IMM_SEL),
        .OUT(MUX_IMM_RESULT)
    );

    // alu does the actual computation
    alu myalu(
        .DATA1(REGOUT1),
        .DATA2(MUX_IMM_RESULT),
        .RESULT(ALURESULT),
        .SELECT(ALUOP)
    );

    // register file - stores all 8 registers
    // alu result gets written back here
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
