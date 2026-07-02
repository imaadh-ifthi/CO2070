

// Handles FORWARD, ADD, AND, and OR operations.
// Added ZERO output flag for BEQ support.

// Forward Unit: Propagates DATA2 with a 1 time unit transmission latency.
// Utilized for MOV and LOADI instructions.
module forward_unit(input [7:0] data2, output reg [7:0] out);
    always @(*) #1 out = data2; // 1 unit delay
endmodule

// Add Unit: Performs 8-bit integer addition with a 2-time-unit propagation delay.
// This unit also facilitates subtraction, provided the subtrahend is 
// converted to its two's complement representation prior to evaluation.
// Relies on a prior Two's Complement conversion for subtraction logic.
module add_unit(input [7:0] data1, input [7:0] data2, output reg [7:0] out);
    always @(*) #2 out = data1 + data2;
endmodule

// AND Unit: Executes bitwise AND operation with a 1-time-unit delay.
// Implements fundamental logical conjunction.
module and_unit(input [7:0] data1, input [7:0] data2, output reg [7:0] out);
    always @(*) #1 out = data1 & data2;
endmodule

// OR Unit: Executes bitwise OR operation. Same latency as AND.
module or_unit(input [7:0] data1, input [7:0] data2, output reg [7:0] out);
    always @(*) #1 out = data1 | data2;
endmodule


// Arithmetic Logic Unit (ALU) Top-Level Module
// The SELECT signal multiplexes the output of the corresponding functional unit.
// 000: FORWARD | 001: ADD | 010: AND | 011: OR
//
// ZERO Output: Asserted (HIGH) when the ADD_UNIT output resolves to zero.
// This flag is essential for the BEQ instruction. The control unit
// configures the datapath for subtraction; if the operands are equal,
// the adder yields zero, driving the ZERO flag high.
// Requires precise alignment with Control Unit subtraction signals.
module alu (DATA1, DATA2, RESULT, SELECT, ZERO);
    input [7:0] DATA1, DATA2;   // two 8 bit inputs
    input [2:0] SELECT;          // operation selector
    output reg [7:0] RESULT;
    output ZERO;                 // NEW: zero flag for beq

    // outputs from each functional unit
    wire [7:0] fwd_out, add_out, and_out, or_out;

    // All functional units are instantiated and execute concurrently. Multiplexing is handled downstream.
    forward_unit f1(DATA2, fwd_out);
    add_unit     a1(DATA1, DATA2, add_out);
    and_unit     an1(DATA1, DATA2, and_out);
    or_unit      o1(DATA1, DATA2, or_out);

    // ZERO flag generation: Evaluates to high exclusively when the adder output is zero.
    // This targets the adder specifically because BEQ relies on a subtraction operation.
    // Zero indicates operand equality during a subtraction.
    assign ZERO = (add_out == 8'b00000000) ? 1'b1 : 1'b0;

    // Output Multiplexer: Routes the selected functional unit result to the ALU output.
    always @(*) begin
        case(SELECT)
            3'b000: RESULT = fwd_out;   // forward
            3'b001: RESULT = add_out;   // add
            3'b010: RESULT = and_out;   // and
            3'b011: RESULT = or_out;    // or
            default: RESULT = 8'b00000000; // shouldnt get here but just in case, don't want latches
        endcase
    end
endmodule
