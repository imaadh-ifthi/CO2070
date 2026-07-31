`timescale 1ns/100ps

module add_unit(
	input [7:0] DATA1, // 8 bit input 1 into data1
    input [7:0] DATA2, // 8 bit input 2 into DATA2
	output reg [7:0] OUT
);
  always @(DATA1 or DATA2) begin // execute whenever data1 or data2 both changes
	    #2 OUT = DATA1 + DATA2; //wait for 2 time units and then assign DATA1 + DATA2 into OUT
  end
endmodule