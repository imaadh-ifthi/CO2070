// ALU  implementation for Lab 4.5
// Extended ISA version from Lab 4
// Handles forward, add, and, or operations 
// Added support for shift/rotate (sll, srl, sra, ror) and multply instructions
// Includes a ZERO flag output for  beq/bne evaluation

// Forward unit - passes data2 through without modifications
// utilized for mov and loadi instructions.
module forward_unit(input [7:0] data2, output reg [7:0] out);
    always @(*) #1 out = data2; // 1 unit delay
endmodule

// Adder unit - Requires 2 time units delay for computation
// Also handles subtraction operations  through 2's complement
module add_unit(input [7:0] data1, input [7:0] data2, output reg [7:0] out);
    always @(*) #2 out = data1 + data2;
endmodule

// AND unit with 1 time unit delay
module and_unit(input [7:0] data1, input [7:0] data2, output reg [7:0] out);
    always @(*) #1 out = data1 & data2;
endmodule

    // OR - similar to the and unit but perfroms bitwise OR
module or_unit(input [7:0] data1, input [7:0] data2, output reg [7:0] out);
    always @(*) #1 out = data1 | data2;
endmodule


// Main ALU module that  instantiates all functional units
// The SELECT signal determines the  operation:
// 000=forward, 001=add, 010=and, 011=or 
// 100=shift/rotate, 101=multiply
//
// ZERO output flag: Asserted to 1 when the add_unit result is zero.
// This is used for beq/bne branch evaluations. 
// For branches, the control unit executes a subtraction, 
// so equal register values result in a zero output.
module alu (DATA1, DATA2, RESULT, SELECT, ZERO, SHIFT_MODE);
    input [7:0] DATA1, DATA2;   // two 8 bit inputs
    input [2:0] SELECT;          // operation selector
    output reg [7:0] RESULT;
    output ZERO;                 // zero flag for beq/bne
    input [1:0] SHIFT_MODE;     // NEW: 00=SLL, 01=SRL, 10=SRA, 11=ROR

    // outputs from each functional unit
    wire [7:0] fwd_out, add_out, and_out, or_out;
    wire [7:0] shift_out;        // NEW: from barrel shifter
    wire [7:0] mult_out;         // NEW: from multiplier

    // all units run in parallel, we just pick the one we need
    forward_unit f1(DATA2, fwd_out);
    add_unit     a1(DATA1, DATA2, add_out);
    and_unit     an1(DATA1, DATA2, and_out);
    or_unit      o1(DATA1, DATA2, or_out);

    // NEW: shift/rotate unit - one unit handles sll, srl, sra, ror
    // SHIFT_MODE tells it which flavor of shift to do
    // DATA1 = value to shift, DATA2 = shift amount
    shift_unit   s1(DATA1, DATA2, SHIFT_MODE, shift_out);

    // NEW: multiplier unit - array multiplier, no * operator used
    // DATA1 * DATA2, lower 8 bits only
    mult_unit    m1(DATA1, DATA2, mult_out);

    // ZERO flag: Set to high when the adder output is zero
    // The adder output is evaluated because beq/bne instructions 
    // utilize subtraction to determine equality.
    assign ZERO = (add_out == 8'b00000000) ? 1'b1 : 1'b0;

    // mux - picks the right result
    always @(*) begin
        case(SELECT)
            3'b000: RESULT = fwd_out;    // forward
            3'b001: RESULT = add_out;    // add
            3'b010: RESULT = and_out;    // and
            3'b011: RESULT = or_out;     // or
            3'b100: RESULT = shift_out;  // NEW: shift/rotate (sll, srl, sra, ror)
            3'b101: RESULT = mult_out;   // NEW: multiply
            default: RESULT = 8'b00000000; // default case to prevent latch  inference
        endcase
    end
endmodule
