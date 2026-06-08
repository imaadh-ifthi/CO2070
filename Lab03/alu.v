
// Module: 8-bit ALU with functional units
// Supports FORWARD (mov/loadi), ADD (add/sub), AND, OR


// Functional Units

// FORWARD unit: passes DATA2 through (used for mov, loadi)
// Latency: #1 time unit
module forward_unit(input [7:0] data2, output reg [7:0] out);
    always @(*) #1 out = data2;
endmodule

// ADD unit: adds DATA1 + DATA2 (used for add, sub via 2's complement)
// Latency: #2 time units
module add_unit(input [7:0] data1, input [7:0] data2, output reg [7:0] out);
    always @(*) #2 out = data1 + data2;
endmodule

// AND unit: bitwise AND of DATA1 & DATA2
// Latency: #1 time unit
module and_unit(input [7:0] data1, input [7:0] data2, output reg [7:0] out);
    always @(*) #1 out = data1 & data2;
endmodule

// OR unit: bitwise OR of DATA1 | DATA2
// Latency: #1 time unit
module or_unit(input [7:0] data1, input [7:0] data2, output reg [7:0] out);
    always @(*) #1 out = data1 | data2;
endmodule


// Top-Level ALU Module

// SELECT encoding:
//   3'b000 -> FORWARD (passes DATA2 through)
//   3'b001 -> ADD     (DATA1 + DATA2)
//   3'b010 -> AND     (DATA1 & DATA2)
//   3'b011 -> OR      (DATA1 | DATA2)
module alu (DATA1, DATA2, RESULT, SELECT); //receives 2, 8 bit numebers for inputs
    input [7:0] DATA1, DATA2;
    input [2:0] SELECT;                    //receives a 3 bit number for the operation
    output reg [7:0] RESULT;

    // Wires to connect functional unit outputs
    wire [7:0] fwd_out, add_out, and_out, or_out;

    // Instantiate all functional units (they operate in parallel)
    forward_unit f1(DATA2, fwd_out);
    add_unit     a1(DATA1, DATA2, add_out);
    and_unit     an1(DATA1, DATA2, and_out);
    or_unit      o1(DATA1, DATA2, or_out);

    // MUX to select the appropriate result based on SELECT signal
    always @(*) begin
        case(SELECT)
            3'b000: RESULT = fwd_out;   // FORWARD
            3'b001: RESULT = add_out;   // ADD
            3'b010: RESULT = and_out;   // AND
            3'b011: RESULT = or_out;    // OR
            default: RESULT = 8'b00000000; 
        endcase
    end
endmodule
