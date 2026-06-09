module mux_2x1_8bit(
    input [7:0] IN0,
    input [7:0] IN1,
    input SEL,
    output reg [7:0] OUT
);

    // Assumption: MUX has negligible delay
    always @(*) begin
        case (SEL)
            1'b0: OUT = IN0;
            1'b1: OUT = IN1;
        endcase
    end

endmodule
