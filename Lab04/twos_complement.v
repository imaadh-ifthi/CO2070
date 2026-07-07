// 2s complement unit
// flips the bits and adds 1 to negate the value
// we need this for subtraction (a - b = a + (~b + 1))
// why didn't we just make a subtractor module?? whatever.

module twos_complement(
    input [7:0] IN,
    output reg [7:0] OUT
);

    // #1 delay for the complement operation
    always @(IN) begin
        #1 OUT = ~IN + 8'd1;
    end

endmodule
