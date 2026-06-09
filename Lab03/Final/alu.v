
// alu for the cpu - lab 3
// handles forward, add, and, or operations

// forward unit - literally just passes data2 through
// used for mov and loadi
module forward_unit(input [7:0] data2, output reg [7:0] out);
    always @(*) #1 out = data2; // 1 unit delay
endmodule

// adder - takes 2 time units cos addition is slower i guess
// also handles subtraction since we do 2s complement before this
module add_unit(input [7:0] data1, input [7:0] data2, output reg [7:0] out);
    always @(*) #2 out = data1 + data2;
endmodule

// AND gate, 1 time unit delay
module and_unit(input [7:0] data1, input [7:0] data2, output reg [7:0] out);
    always @(*) #1 out = data1 & data2;
endmodule

// OR - same as and but OR lol
module or_unit(input [7:0] data1, input [7:0] data2, output reg [7:0] out);
    always @(*) #1 out = data1 | data2;
endmodule


// the actual ALU module that ties everything together
// select signal picks which operation result we want
// 000 = forward, 001 = add, 010 = and, 011 = or
module alu (DATA1, DATA2, RESULT, SELECT);
    input [7:0] DATA1, DATA2;   // two 8 bit inputs
    input [2:0] SELECT;          // operation selector
    output reg [7:0] RESULT;

    // outputs from each functional unit
    wire [7:0] fwd_out, add_out, and_out, or_out;

    // all units run in parallel, we just pick the one we need
    forward_unit f1(DATA2, fwd_out);
    add_unit     a1(DATA1, DATA2, add_out);
    and_unit     an1(DATA1, DATA2, and_out);
    or_unit      o1(DATA1, DATA2, or_out);

    // mux - picks the right result
    always @(*) begin
        case(SELECT)
            3'b000: RESULT = fwd_out;   // forward
            3'b001: RESULT = add_out;   // add
            3'b010: RESULT = and_out;   // and
            3'b011: RESULT = or_out;    // or
            default: RESULT = 8'b00000000; // shouldnt get here but just in case
        endcase
    end
endmodule
