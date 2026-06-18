
// ok alu for the cpu lab 4.5. praying this works 
// (upgraded from lab 4, extended ISA edition)
// handles forward, add, and, or operations (original)
// NEW: also handles shift/rotate (sll, srl, sra, ror) and multiply (mult)
// ZERO output flag for beq/bne support

// forward unit - literally just passes data2 through lmao
// used for mov and loadi. feels kinda redundant but whatever
module forward_unit(input [7:0] data2, output reg [7:0] out);
    always @(*) #1 out = data2; // 1 unit delay
endmodule

// adder - takes 2 time units cos addition is slower ugh
// also handles subtraction since we do 2s complement before this
// (pls dont ask me how 2s comp works I just copied it from lab 2)
module add_unit(input [7:0] data1, input [7:0] data2, output reg [7:0] out);
    always @(*) #2 out = data1 + data2;
endmodule

// AND gate, 1 time unit delay
// simple enough even I can't mess this up
module and_unit(input [7:0] data1, input [7:0] data2, output reg [7:0] out);
    always @(*) #1 out = data1 & data2;
endmodule

// OR - same as and but OR lol
module or_unit(input [7:0] data1, input [7:0] data2, output reg [7:0] out);
    always @(*) #1 out = data1 | data2;
endmodule


// the actual ALU module that ties everything together finally
// select signal picks which operation result we want
// 000 = forward, 001 = add, 010 = and, 011 = or (hope I memorized this right for the viva)
// NEW: 100 = shift/rotate, 101 = multiply
//
// ZERO output: asserted (1) when the add_unit output is zero.
// used by the beq/bne instructions. For beq/bne, the control unit
// sets up a subtract so if the two
// register values are equal, the add result will be zero and
// ZERO will be high. took me 3 hours to debug this part smh
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

    // ZERO flag: high when the adder output is all zeros
    // We check the adder output specifically because beq/bne use
    // subtract. if it's 0 they are equal. big brain moment.
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
            default: RESULT = 8'b00000000; // shouldnt get here but just in case, don't want latches
        endcase
    end
endmodule
