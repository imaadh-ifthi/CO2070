// ok alu for the cpu lab 4. 
// (upgraded from lab 3 finally)
// handles forward, add, and, or operations
// NEW: added ZERO output flag for beq support cuz why not

// forward unit - literally just passes data2 through lmao
// used for mov and loadi.
module forward_unit(input [7:0] data2, output reg [7:0] out);
    always @(*) #1 out = data2; // 1 unit delay
endmodule

// adder - takes 2 time units cos addition is slower ugh
// also handles subtraction since we do 2s complement before this
module add_unit(input [7:0] data1, input [7:0] data2, output reg [7:0] out);
    always @(*) #2 out = data1 + data2;
endmodule

// AND gate, 1 time unit delay
module and_unit(input [7:0] data1, input [7:0] data2, output reg [7:0] out);
    always @(*) #1 out = data1 & data2;
endmodule

// OR - same as and but OR 
module or_unit(input [7:0] data1, input [7:0] data2, output reg [7:0] out);
    always @(*) #1 out = data1 | data2;
endmodule


// the actual ALU module that ties everything together finally
// select signal picks which operation result we want
//
// ZERO output: asserted (1) when the add_unit output is zero.
// used by the beq instruction. For beq, the control unit
// sets up a subtract so if the two
// register values are equal, the add result will be zero and
// ZERO will be high. 
module alu (DATA1, DATA2, RESULT, SELECT, ZERO);
    input [7:0] DATA1, DATA2;   // two 8 bit inputs
    input [2:0] SELECT;          // operation selector
    output reg [7:0] RESULT;
    output ZERO;                 // NEW: zero flag for beq

    // outputs from each functional unit
    wire [7:0] fwd_out, add_out, and_out, or_out;

    // all units run in parallel, we just pick the one we need
    forward_unit f1(DATA2, fwd_out);
    add_unit     a1(DATA1, DATA2, add_out);
    and_unit     an1(DATA1, DATA2, and_out);
    or_unit      o1(DATA1, DATA2, or_out);

    // ZERO flag: high when the adder output is all zeros
    // We check the adder output specifically because beq uses
    // subtract. if it's 0 they are equal. 
    assign ZERO = (add_out == 8'b00000000) ? 1'b1 : 1'b0;

    // mux - picks the right result
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
