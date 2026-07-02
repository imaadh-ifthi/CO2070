// Control Unit Instruction Decoder
// Orchestrates datapath operations by generating multiplexer and ALU control signals.
// Enforces combinatorial constraints to prevent synthesis errors.

module control_unit(
    input [31:0] INSTRUCTION,
    output wire [2:0] READREG1,
    output wire [2:0] READREG2,
    output reg [2:0] WRITEREG,
    output reg WRITEENABLE,
    output reg [2:0] ALUOP,
    output reg MUX_IMM_SEL,       // picks between reg value and immediate
    output reg MUX_COMP_SEL,      // picks between normal and 2s complement
    output reg [7:0] IMMEDIATE,
    output reg JUMP,              // NEW: asserted for j instruction
    output reg BRANCH,            // NEW: asserted for beq instruction
    output reg [7:0] OFFSET       // NEW: signed offset for branch/jump target calculation
);

    // Instruction Format Decomposition
    // Bitwise slicing based on instruction architecture specifications.
    wire [7:0] OPCODE;
    wire [7:0] RD_IMM;
    wire [7:0] RT;
    wire [7:0] RS_IMM;

    assign OPCODE  = INSTRUCTION[31:24];  // top 8 bits
    assign RD_IMM  = INSTRUCTION[23:16];  // destination reg OR offset (for j/beq)
    assign RT      = INSTRUCTION[15:8];   // source reg 1
    assign RS_IMM  = INSTRUCTION[7:0];    // source reg 2 OR immediate

    // Combinational extraction of register source addresses. 0 delay latency.
    // Facilitates concurrent instruction decoding and register file read operations.
    // Ensures timing closure for register fetch cycles.
    assign READREG1 = RT[2:0];
    assign READREG2 = (OPCODE == 8'b00000001) ? RT[2:0] : RS_IMM[2:0]; // mov uses RT for source

    // decode the instruction whenever it changes
    always @(INSTRUCTION) begin
        #1;  // decode delay

        // Initialize default control signal states to prevent inferred latches.
        // Failure to declare defaults will induce inferred latches during synthesis.
        WRITEENABLE  = 1'b0;
        MUX_IMM_SEL  = 1'b0;
        MUX_COMP_SEL = 1'b0;
        ALUOP        = 3'b000;
        IMMEDIATE    = RS_IMM;
        JUMP         = 1'b0;       // NEW: default no jump
        BRANCH       = 1'b0;       // NEW: default no branch
        OFFSET       = RD_IMM;     // NEW: offset comes from bits[23:16]
        
        // get the write register address from the instruction
        WRITEREG  = RD_IMM[2:0];
        
        case (OPCODE)
            // LOADI: Load Immediate Instruction
            // opcode = 0x00
            8'b00000000: begin
                ALUOP        = 3'b000;   // forward thru alu
                MUX_IMM_SEL  = 1'b1;     // use immediate value
                MUX_COMP_SEL = 1'b0;    
                WRITEENABLE  = 1'b1;      
                IMMEDIATE    = RS_IMM;    // the value to load
            end
            
            // mov - copy one register to another
            // opcode = 0x01
            8'b00000001: begin
                ALUOP        = 3'b000;   // forward
                MUX_IMM_SEL  = 1'b0;     
                MUX_COMP_SEL = 1'b0;    
                WRITEENABLE  = 1'b1;      
            end
            
            // add
            // opcode = 0x02
            8'b00000010: begin
                ALUOP        = 3'b001;
                MUX_IMM_SEL  = 1'b0;     
                MUX_COMP_SEL = 1'b0;    
                WRITEENABLE  = 1'b1;      
            end
            
            // SUB: Subtraction Instruction (Evaluated via Two's Complement Addition)
            // opcode = 0x03.
            8'b00000011: begin
                ALUOP        = 3'b001;   // still uses the adder
                MUX_IMM_SEL  = 1'b0;     
                MUX_COMP_SEL = 1'b1;     // flip to 2s complement
                WRITEENABLE  = 1'b1;      
            end
            
            // and
            // opcode = 0x04
            8'b00000100: begin
                ALUOP        = 3'b010;
                MUX_IMM_SEL  = 1'b0;     
                MUX_COMP_SEL = 1'b0;    
                WRITEENABLE  = 1'b1;      
            end
            
            // or
            // opcode = 0x05
            8'b00000101: begin
                ALUOP        = 3'b011;
                MUX_IMM_SEL  = 1'b0;     
                MUX_COMP_SEL = 1'b0;    
                WRITEENABLE  = 1'b1;      
            end

            // Includes absolute jumping and conditional branching.

            // j (jump) - unconditional jump
            // opcode = 0x06
            // Format: j offset  (offset is in bits[23:16], treated as signed)
            // Jumps to PC_NEXT + (offset * 4), where PC_NEXT = PC + 4
            // Bits[15:0] are ignored (wasted bits smh)
            8'b00000110: begin
                JUMP         = 1'b1;     // signal the PC to jump
                BRANCH       = 1'b0;     // not a conditional branch
                WRITEENABLE  = 1'b0;     // dont write to any register
                OFFSET       = RD_IMM;   // jump offset from bits[23:16]
            end

            // beq - conditional branch
            // opcode = 0x07
            // Format: beq offset, rt, rs
            // If reg[rt] == reg[rs], branch to PC_NEXT + (offset * 4)
            // We use subtract (rt - rs) and check if result is zero
            8'b00000111: begin
                BRANCH       = 1'b1;     // this is a conditional branch
                JUMP         = 1'b0;     // not an unconditional jump
                ALUOP        = 3'b001;   // use adder (for subtract)
                MUX_IMM_SEL  = 1'b0;     // use register value (not immediate)
                MUX_COMP_SEL = 1'b1;     // 2s complement for subtraction
                WRITEENABLE  = 1'b0;     // dont write to any register
                OFFSET       = RD_IMM;   // branch offset from bits[23:16]
            end
            
            // Unrecognized Opcode Exception Handler
            // Prevents unhandled state transitions.
            default: begin
                WRITEENABLE = 1'b0;
            end
        endcase
    end

endmodule
