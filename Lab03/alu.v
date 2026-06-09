// 8-bit ALU for lab 3
// does mov, loadi, add, sub, and, or things

// gotta make a forward unit for mov and loadi instructions. 
// just passes data2 straight thru
// delay is #1
module forward_unit(input [7:0] data2, output reg [7:0] out);
    always @(*) #1 out = data2;
endmodule

// addition module. also used for sub (we do 2s complement in cpu module)
// this one takes 2 time units
module add_unit(input [7:0] data1, input [7:0] data2, output reg [7:0] out);
    always @(*) #2 out = data1 + data2;
endmodule

// bitwise AND. #1 delay
module and_unit(input [7:0] data1, input [7:0] data2, output reg [7:0] out);
    always @(*) #1 out = data1 & data2;
endmodule

// bitwise OR stuff. #1 delay
module or_unit(input [7:0] data1, input [7:0] data2, output reg [7:0] out);
    always @(*) #1 out = data1 | data2;
endmodule

// main alu module
// select codes:
// 000: forward
// 001: add
// 010: and
// 011: or
module alu (DATA1, DATA2, RESULT, SELECT); // 2 8-bit inputs
    input [7:0] DATA1, DATA2;
    input [2:0] SELECT;                    // 3 bit select signal
    output reg [7:0] RESULT;

    // wires for the module outputs
    wire [7:0] fwd_out, add_out, and_out, or_out;

    // run all of them at once bc why not
    forward_unit f1(DATA2, fwd_out);
    add_unit     a1(DATA1, DATA2, add_out);
    and_unit     an1(DATA1, DATA2, and_out);
    or_unit      o1(DATA1, DATA2, or_out);

    // mux to pick the right answer
    always @(*) begin
        case(SELECT)
            3'b000: RESULT = fwd_out;   // forward
            3'b001: RESULT = add_out;   // add
            3'b010: RESULT = and_out;   // and
            3'b011: RESULT = or_out;    // or
            default: RESULT = 8'b00000000; // just zero it out if something goes wrong
        endcase
    end
endmodule
