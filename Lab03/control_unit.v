module control_unit(
    input [31:0] INSTRUCTION,
    output reg [2:0] READREG1,
    output reg [2:0] READREG2,
    output reg [2:0] WRITEREG,
    output reg WRITEENABLE,
    output reg [2:0] ALUOP,
    output reg MUX_IMM_SEL,
    output reg MUX_COMP_SEL,
    output reg [7:0] IMMEDIATE
);

    wire [7:0] OPCODE;
    wire [7:0] RD_IMM;
    wire [7:0] RT;
    wire [7:0] RS_IMM;

    assign OPCODE  = INSTRUCTION[31:24];
    assign RD_IMM  = INSTRUCTION[23:16];
    assign RT      = INSTRUCTION[15:8];
    assign RS_IMM  = INSTRUCTION[7:0];

    // Instruction Decode & Control Signal Generation
    // Decode delay: #1 time unit
    always @(INSTRUCTION) begin
        #1;  // Instruction decode delay
        
        // Default values for control signals
        WRITEENABLE = 1'b0;
        MUX_IMM_SEL = 1'b0;
        MUX_COMP_SEL = 1'b0;
        ALUOP = 3'b000;
        IMMEDIATE = RS_IMM;
        
        // Extract register addresses from instruction fields
        WRITEREG = RD_IMM[2:0];   // Destination register
        READREG1 = RT[2:0];        // Source register 1
        READREG2 = RS_IMM[2:0];    // Source register 2
        
        case (OPCODE)
            // LOADI
            8'b00000000: begin
                ALUOP = 3'b000;         // FORWARD operation
                MUX_IMM_SEL = 1'b1;     // Select immediate value
                MUX_COMP_SEL = 1'b0;    
                WRITEENABLE = 1'b1;      
                IMMEDIATE = RS_IMM;      
            end
            
            // MOV
            8'b00000001: begin
                ALUOP = 3'b000;         // FORWARD operation
                MUX_IMM_SEL = 1'b0;     
                MUX_COMP_SEL = 1'b0;    
                WRITEENABLE = 1'b1;      
                READREG2 = RT[2:0];      // Read the source register (RT)
            end
            
            // ADD
            8'b00000010: begin
                ALUOP = 3'b001;         // ADD operation
                MUX_IMM_SEL = 1'b0;     
                MUX_COMP_SEL = 1'b0;    
                WRITEENABLE = 1'b1;      
            end
            
            // SUB
            8'b00000011: begin
                ALUOP = 3'b001;         // ADD operation (add with 2's complement)
                MUX_IMM_SEL = 1'b0;     
                MUX_COMP_SEL = 1'b1;    // Select 2's complement of RS
                WRITEENABLE = 1'b1;      
            end
            
            // AND
            8'b00000100: begin
                ALUOP = 3'b010;         // AND operation
                MUX_IMM_SEL = 1'b0;     
                MUX_COMP_SEL = 1'b0;    
                WRITEENABLE = 1'b1;      
            end
            
            // OR
            8'b00000101: begin
                ALUOP = 3'b011;         // OR operation
                MUX_IMM_SEL = 1'b0;     
                MUX_COMP_SEL = 1'b0;    
                WRITEENABLE = 1'b1;      
            end
            
            default: begin
                WRITEENABLE = 1'b0;
            end
        endcase
    end

endmodule
