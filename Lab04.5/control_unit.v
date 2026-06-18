// control unit - decodes instructions and generates control signals
// this is basically the brain of the cpu
// LAB 4: upgraded to support j and beq instructions (I hate branch instructions so much)
// LAB 4.5: extended ISA - added mult, sll, srl, sra, ror, bne
// if this doesnt compile im dropping out

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
    output reg JUMP,              // asserted for j instruction
    output reg BRANCH,            // asserted for beq instruction
    output reg [7:0] OFFSET,      // signed offset for branch/jump target calculation
    output reg [1:0] SHIFT_MODE,  // NEW: 00=SLL, 01=SRL, 10=SRA, 11=ROR
    output reg BRANCH_NEQ         // NEW: asserted for bne instruction
);

    // break up the instruction into its fields 
    // tbh I just guessed the bit numbers here, hope it's right
    wire [7:0] OPCODE;
    wire [7:0] RD_IMM;
    wire [7:0] RT;
    wire [7:0] RS_IMM;

    assign OPCODE  = INSTRUCTION[31:24];  // top 8 bits
    assign RD_IMM  = INSTRUCTION[23:16];  // destination reg OR offset (for j/beq/bne)
    assign RT      = INSTRUCTION[15:8];   // source reg 1
    assign RS_IMM  = INSTRUCTION[7:0];    // source reg 2 OR immediate

    // immediately extract register read addresses (0 delay)
    // this allows register file reading to happen in parallel with decode
    // TA said we needed this for timing but idk man it seems fine without it
    assign READREG1 = RT[2:0];
    assign READREG2 = (OPCODE == 8'b00000001) ? RT[2:0] : RS_IMM[2:0]; // mov uses RT for source

    // decode the instruction whenever it changes
    always @(INSTRUCTION) begin
        #1;  // decode delay

        // set defaults first so we dont forget anything 
        // forgetting defaults = latch = 0 on assignment = crying
        WRITEENABLE  = 1'b0;
        MUX_IMM_SEL  = 1'b0;
        MUX_COMP_SEL = 1'b0;
        ALUOP        = 3'b000;
        IMMEDIATE    = RS_IMM;
        JUMP         = 1'b0;       // default no jump
        BRANCH       = 1'b0;       // default no branch
        OFFSET       = RD_IMM;     // offset comes from bits[23:16]
        SHIFT_MODE   = 2'b00;     // NEW: default SLL (doesn't matter when not shifting)
        BRANCH_NEQ   = 1'b0;      // NEW: default no bne
        
        // get the write register address from the instruction
        WRITEREG  = RD_IMM[2:0];
        
        case (OPCODE)
            // loadi - load immediate value into register
            // opcode = 0x00 (free marks tbh)
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
            
            // sub - uses add with 2s complement trick
            // opcode = 0x03. bless whoever invented 2s complement
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

            // =============================================
            // INSTRUCTIONS FOR LAB 4 - FLOW CONTROL
            // (aka the part that kept me up till 4 am)
            // =============================================

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

            // beq (branch if equal) - conditional branch
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

            // =============================================
            // NEW INSTRUCTIONS FOR LAB 4.5 - EXTENDED ISA
            // (here we go again, more 1s and 0s to debug)
            // =============================================

            // mult (multiply) - multiply two register values
            // opcode = 0x08
            // Format: mult rd, rt, rs
            // reg[rd] = reg[rt] * reg[rs] (lower 8 bits of product)
            // Uses the array multiplier in the ALU (no * operator, built from AND + add)
            8'b00001000: begin
                ALUOP        = 3'b101;   // select multiply unit
                MUX_IMM_SEL  = 1'b0;     // use register value
                MUX_COMP_SEL = 1'b0;     // normal (no 2s complement)
                WRITEENABLE  = 1'b1;     // write result to rd
            end

            // sll (shift left logical) - shift register value left by immediate amount
            // opcode = 0x09
            // Format: sll rd, rt, imm
            // reg[rd] = reg[rt] << imm (fill with 0s from right)
            // shift amount is in bits[7:0], only lower 3 bits matter
            8'b00001001: begin
                ALUOP        = 3'b100;   // select shift unit
                SHIFT_MODE   = 2'b00;    // SLL mode
                MUX_IMM_SEL  = 1'b1;     // use immediate (shift amount)
                MUX_COMP_SEL = 1'b0;
                WRITEENABLE  = 1'b1;
            end

            // srl (shift right logical) - shift register value right, fill with 0s
            // opcode = 0x0A
            // Format: srl rd, rt, imm
            // reg[rd] = reg[rt] >> imm (fill with 0s from left)
            8'b00001010: begin
                ALUOP        = 3'b100;   // select shift unit (same as sll!)
                SHIFT_MODE   = 2'b01;    // SRL mode
                MUX_IMM_SEL  = 1'b1;     // use immediate (shift amount)
                MUX_COMP_SEL = 1'b0;
                WRITEENABLE  = 1'b1;
            end

            // sra (shift right arithmetic) - shift right, preserve sign bit
            // opcode = 0x0B
            // Format: sra rd, rt, imm
            // reg[rd] = reg[rt] >>> imm (fill with sign bit from left)
            // this is useful for signed division by powers of 2 apparently
            8'b00001011: begin
                ALUOP        = 3'b100;   // select shift unit
                SHIFT_MODE   = 2'b10;    // SRA mode
                MUX_IMM_SEL  = 1'b1;     // use immediate (shift amount)
                MUX_COMP_SEL = 1'b0;
                WRITEENABLE  = 1'b1;
            end

            // ror (rotate right) - rotate bits right, wrapping around
            // opcode = 0x0C
            // Format: ror rd, rt, imm
            // bits that fall off the right end come back on the left
            // kinda like a circular conveyor belt for bits lol
            8'b00001100: begin
                ALUOP        = 3'b100;   // select shift unit
                SHIFT_MODE   = 2'b11;    // ROR mode
                MUX_IMM_SEL  = 1'b1;     // use immediate (rotate amount)
                MUX_COMP_SEL = 1'b0;
                WRITEENABLE  = 1'b1;
            end

            // bne (branch if not equal) - conditional branch
            // opcode = 0x0D
            // Format: bne offset, rt, rs
            // If reg[rt] != reg[rs], branch to PC_NEXT + (offset * 4)
            // Same subtract trick as beq, but we check ~ZERO instead of ZERO
            8'b00001101: begin
                BRANCH_NEQ   = 1'b1;     // NEW: this is a bne branch
                BRANCH       = 1'b0;     // not a beq
                JUMP         = 1'b0;     // not a jump
                ALUOP        = 3'b001;   // use adder (for subtract)
                MUX_IMM_SEL  = 1'b0;     // use register value
                MUX_COMP_SEL = 1'b1;     // 2s complement for subtraction
                WRITEENABLE  = 1'b0;     // dont write to any register
                OFFSET       = RD_IMM;   // branch offset from bits[23:16]
            end
            
            // unknown opcode, dont write anything
            // just doing this so synthesis doesn't yell at me
            default: begin
                WRITEENABLE = 1'b0;
            end
        endcase
    end

endmodule
