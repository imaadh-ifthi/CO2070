`timescale 1ns/100ps

// Design: 8-bit Combinational Multiplier (No '*' operator)

module mult_unit (
    input [7:0] DATA1,
    input [7:0] DATA2,
	output reg [7:0] RESULT
);

    //generate partial products
    // if the bit in data2 is 1, we take data1 and shift it left by that bit's position
	// if the bit is 0, the partial product is just 0
    //We manually slice and pad with zeros to avoid using the '<<' operator!
    wire [7:0] pp0 = DATA2[0] ? DATA1 : 8'd0; //something like -> if (data2[0] == 1) {data1} else {8'd0}
    wire [7:0] pp1 = DATA2[1] ? {DATA1[6:0], 1'b0} : 8'd0;
    wire [7:0] pp2 = DATA2[2] ? {DATA1[5:0], 2'b00} : 8'd0;
    wire [7:0] pp3 = DATA2[3] ? {DATA1[4:0], 3'b000} : 8'd0;
	wire [7:0] pp4 = DATA2[4] ? {DATA1[3:0], 4'b0000} : 8'd0;
    wire [7:0] pp5 = DATA2[5] ? {DATA1[2:0], 5'b00000} : 8'd0;
    wire [7:0] pp6 = DATA2[6] ? {DATA1[1:0], 6'b000000} : 8'd0;
    wire [7:0] pp7 = DATA2[7] ? {DATA1[0], 7'b0000000} : 8'd0;
    always @(*) begin
	    //add all partial products together
        // We assign a 2 time unit delay because this is a heavy hardware operation
        #2 RESULT = pp0 + pp1 + pp2 + pp3 + pp4 + pp5 + pp6 + pp7;
    end
endmodule