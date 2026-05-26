// Functional Units
module forward_unit(input [7:0] data2, output reg [7:0] out);
    always @(*) #1 out = data2;
endmodule

module add_unit(input [7:0] data1, input [7:0] data2, output reg [7:0] out);
    always @(*) #2 out = data1 + data2;
endmodule

module and_unit(input [7:0] data1, input [7:0] data2, output reg [7:0] out);
    always @(*) #1 out = data1 & data2;
endmodule

module or_unit(input [7:0] data1, input [7:0] data2, output reg [7:0] out);
    always @(*) #1 out = data1 | data2;
endmodule

// Top-Level ALU Module
module alu (DATA1, DATA2, RESULT, SELECT);
    input [7:0] DATA1, DATA2;
    input [2:0] SELECT;
    output reg [7:0] RESULT;

    wire [7:0] fwd_out, add_out, and_out, or_out;

    forward_unit f1(DATA2, fwd_out);
    add_unit     a1(DATA1, DATA2, add_out);
    and_unit     an1(DATA1, DATA2, and_out);
    or_unit      o1(DATA1, DATA2, or_out);

    always @(*) begin
        case(SELECT)
            3'b000: RESULT = fwd_out;
            3'b001: RESULT = add_out;
            3'b010: RESULT = and_out;
            3'b011: RESULT = or_out;
            default: RESULT = 8'b00000000; 
        endcase
    end
endmodule