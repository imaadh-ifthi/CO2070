// Standard timescale directive for simulation timing.
`timescale 1ns / 1ps
// -------------------------------------------------------------------------
// Functional Units
// Each operation is implemented as a separate module.
// Artificial delays are applied to simulate specific hardware latencies.
// -------------------------------------------------------------------------

module forward_unit(input [7:0] data2, output reg [7:0] out);
    // FORWARD unit sends DATA2 to output.
    // Required delay: #1 time unit.
    // Triggered asynchronously when data2 changes.
    always @(*) #1 out = data2;
endmodule

module add_unit(input [7:0] data1, input [7:0] data2, output reg [7:0] out);
    // ADD unit computes DATA1 + DATA2.
    // Required delay: #2 time units.
    always @(*) #2 out = data1 + data2;
endmodule

module and_unit(input [7:0] data1, input [7:0] data2, output reg [7:0] out);
    // AND unit performs bitwise AND on DATA1 and DATA2.
    // Required delay: #1 time unit.
    always @(*) #1 out = data1 & data2;
endmodule

module or_unit(input [7:0] data1, input [7:0] data2, output reg [7:0] out);
    // OR unit performs bitwise OR on DATA1 and DATA2.
    // Required delay: #1 time unit.
    always @(*) #1 out = data1 | data2;
endmodule

// -------------------------------------------------------------------------
// Top-Level ALU Module
// Integrates functional units and multiplexes the output.
// -------------------------------------------------------------------------

module alu (DATA1, DATA2, RESULT, SELECT);
    // Interfaces as defined in the specification.
    input [7:0] DATA1, DATA2;
    input [2:0] SELECT;
    output reg [7:0] RESULT;

    // Internal wires connecting functional unit outputs to the multiplexer.
    wire [7:0] fwd_out, add_out, and_out, or_out;

    // Instantiate functional units. All units compute in parallel.
    forward_unit f1(.data2(DATA2), .out(fwd_out));
    add_unit     a1(.data1(DATA1), .data2(DATA2), .out(add_out));
    and_unit     an1(.data1(DATA1), .data2(DATA2), .out(and_out));
    or_unit      o1(.data1(DATA1), .data2(DATA2), .out(or_out));

    // Multiplexer logic uses a case structure to select the output.
    always @(*) begin
        case(SELECT)
            3'b000: RESULT = fwd_out; // Supports loadi, mov
            3'b001: RESULT = add_out; // Supports add, sub
            3'b010: RESULT = and_out; // Supports and
            3'b011: RESULT = or_out;  // Supports or
            
            // Unused bit combinations of the SELECT port default to zero.
            // This prevents the synthesis of unintended latches.
            default: RESULT = 8'b00000000; 
        endcase
    end
endmodule