`timescale 1ns/100ps

module and_unit(
	input [7:0] DATA1, //8 bit input 1 into DATA1
	input [7:0] DATA2, //8 bit input 2 into data2
    output reg [7:0] OUT
);
    always @(DATA1 or DATA2) begin //Begin execute whenever DATA1 or DATA2 both changes
        #1 OUT = DATA1 & DATA2; //assign data1 and data2 into out in 1 time unit
    end

endmodule