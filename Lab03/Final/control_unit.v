// control unit - decodes instructions and generates control signals
// this is basically the brain of the cpu

module control_unit(
    input [31:0] INSTRUCTION,
    output reg [2:0] READREG1,
    output reg [2:0] READREG2,
    output reg [2:0] WRITEREG,
    output reg WRITEENABLE,
    output reg [2:0] ALUOP,
    output reg MUX_IMM_SEL,       // picks between reg value and immediate
    output reg MUX_COMP_SEL,      // picks between normal and 2s complement
    output reg [7:0] IMMEDIATE
);

    // break up the instruction into its fields
    wire [7:0] OPCODE;
    wire [7:0] RD_IMM;
    wire [7:0] RT;
    wire [7:0] RS_IMM;

    assign OPCODE  = INSTRUCTION[31:24];  // top 8 bits
    assign RD_IMM  = INSTRUCTION[23:16];
    assign RT      = INSTRUCTION[15:8];
    assign RS_IMM  = INSTRUCTION[7:0];    // bottom 8 bits

    // decode the instruction whenever it changes
    always @(INSTRUCTION) begin
        #1;  // decode delay

        // set defaults first so we dont forget anything
        WRITEENABLE = 1'b0;
        MUX_IMM_SEL = 1'b0;
        MUX_COMP_SEL = 1'b0;
        ALUOP = 3'b000;
        IMMEDIATE = RS_IMM;
        
        // get the register addresses from the instruction
        WRITEREG = RD_IMM[2:0];
        READREG1 = RT[2:0];
        READREG2 = RS_IMM[2:0];
        
        case (OPCODE)
            // loadi - load immediate value into register
            8'b00000000: begin
                ALUOP = 3'b000;         // forward thru alu
                MUX_IMM_SEL = 1'b1;     // use immediate value
                MUX_COMP_SEL = 1'b0;    
                WRITEENABLE = 1'b1;      
                IMMEDIATE = RS_IMM;      // the value to load
            end
            
            // mov - copy one register to another
            8'b00000001: begin
                ALUOP = 3'b000;         // forward
                MUX_IMM_SEL = 1'b0;     
                MUX_COMP_SEL = 1'b0;    
                WRITEENABLE = 1'b1;      
                READREG2 = RT[2:0];      // source is in RT field for mov
            end
            
            // add
            8'b00000010: begin
                ALUOP = 3'b001;
                MUX_IMM_SEL = 1'b0;     
                MUX_COMP_SEL = 1'b0;    
                WRITEENABLE = 1'b1;      
            end
            
            // sub - uses add with 2s complement trick
            8'b00000011: begin
                ALUOP = 3'b001;         // still uses the adder
                MUX_IMM_SEL = 1'b0;     
                MUX_COMP_SEL = 1'b1;    // flip to 2s complement
                WRITEENABLE = 1'b1;      
            end
            
            // and
            8'b00000100: begin
                ALUOP = 3'b010;
                MUX_IMM_SEL = 1'b0;     
                MUX_COMP_SEL = 1'b0;    
                WRITEENABLE = 1'b1;      
            end
            
            // or
            8'b00000101: begin
                ALUOP = 3'b011;
                MUX_IMM_SEL = 1'b0;     
                MUX_COMP_SEL = 1'b0;    
                WRITEENABLE = 1'b1;      
            end
            
            // unknown opcode, dont write anything
            default: begin
                WRITEENABLE = 1'b0;
            end
        endcase
    end

endmodule
