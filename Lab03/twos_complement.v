module twos_complement(
    input [7:0] IN,
    output reg [7:0] OUT
);

    // Computes the 2's complement (~value + 1)
    // Used for SUB instruction
    // Latency: #1 time unit
    always @(IN) begin
        #1 OUT = ~IN + 8'd1;
    end

endmodule
