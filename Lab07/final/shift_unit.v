`timescale 1ns/100ps

module shift_unit (
    input [7:0] DATA,      //the value we want to shift
	input [7:0] SHIFT_AMT, //How many times to shift (comes from the immediate value)
	input [1:0] SHIFT_TYPE, //2-bit switch: 00=sll, 01=srl, 10=sra, 11=ror
  output reg [7:0] OUT
);
  // we only care about the last 3 bits for shifting an 8-bit number (0 to 7 shifts max)
    wire [2:0] amt = SHIFT_AMT[2:0];
    //temporary wires to hold the results of all four possible operations
	reg [7:0] left_result;
    reg [7:0] right_result;
    reg [7:0] arith_result;
    reg [7:0] ror_result;

	// sll (logical left) - fill empty spots on the right with 0s
    always @(*) begin
      case(amt)
          3'd0: left_result = DATA;
          3'd1: left_result = {DATA[6:0], 1'b0};
          3'd2: left_result = {DATA[5:0], 2'b00};
            3'd3: left_result = {DATA[4:0], 3'b000};
            3'd4: left_result = {DATA[3:0], 4'b0000};
            3'd5: left_result = {DATA[2:0], 5'b00000};
            3'd6: left_result = {DATA[1:0], 6'b000000};
	        3'd7: left_result = {DATA[0], 7'b0000000};
        endcase
    end

  //srl (logical right) - fill empty spots on the left with 0s
  always @(*) begin
        case(amt)
            3'd0: right_result = DATA;
            3'd1: right_result = {1'b0, DATA[7:1]};
          3'd2: right_result = {2'b00, DATA[7:2]};
          3'd3: right_result = {3'b000, DATA[7:3]};
            3'd4: right_result = {4'b0000, DATA[7:4]};
	        3'd5: right_result = {5'b00000, DATA[7:5]};
            3'd6: right_result = {6'b000000, DATA[7:6]};
            3'd7: right_result = {7'b0000000, DATA[7:7]};
      endcase
	end

	//SRA (Arithmetic Right) - Duplicate the sign bit (DATA[7]) to preserve negatives
    always @(*) begin
        case(amt)
            3'd0: arith_result = DATA;
          3'd1: arith_result = {DATA[7], DATA[7:1]};
            3'd2: arith_result = {{2{DATA[7]}}, DATA[7:2]};
	        3'd3: arith_result = {{3{DATA[7]}}, DATA[7:3]};
            3'd4: arith_result = {{4{DATA[7]}}, DATA[7:4]};
            3'd5: arith_result = {{5{DATA[7]}}, DATA[7:5]};
            3'd6: arith_result = {{6{DATA[7]}}, DATA[7:6]};
          3'd7: arith_result = {{7{DATA[7]}}, DATA[7:7]};
        endcase
  end
    // ror (rotate right) - bits that fall off the right wrap around to the left
    always @(*) begin
      case(amt)
	        3'd0: ror_result = DATA;
          3'd1: ror_result = {DATA[0], DATA[7:1]};
            3'd2: ror_result = {DATA[1:0], DATA[7:2]};
	        3'd3: ror_result = {DATA[2:0], DATA[7:3]};
            3'd4: ror_result = {DATA[3:0], DATA[7:4]};
            3'd5: ror_result = {DATA[4:0], DATA[7:5]};
            3'd6: ror_result = {DATA[5:0], DATA[7:6]};
	        3'd7: ror_result = {DATA[6:0], DATA[7:7]};
      endcase
    end
  //finally, look at the 2-bit switch and pick the right answer
    // we add a standard 1 time unit delay here to simulate hardware latency
    always @(*) begin
        case(SHIFT_TYPE)
          2'b00: #1 OUT = left_result;
	        2'b01: #1 OUT = right_result;
            2'b10: #1 OUT = arith_result;
            2'b11: #1 OUT = ror_result;
        endcase
    end

endmodule