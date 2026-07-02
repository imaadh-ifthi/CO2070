// Two's Complement Conversion Unit
// Performs bitwise inversion and subsequent addition of 1 to yield the arithmetic negation.
// Essential for implementing subtraction via the primary adder (A - B = A + (~B + 1)).
// Consolidates arithmetic hardware by reusing the primary adder.

module twos_complement(
    input [7:0] IN,
    output reg [7:0] OUT
);

    // Evaluate combinational logic with a 1-time-unit hardware latency simulation.
    always @(IN) begin
        #1 OUT = ~IN + 8'd1;
    end

endmodule
