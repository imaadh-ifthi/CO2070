`timescale 1ns/100ps

module alu(DATA1, DATA2, RESULT, SELECT, ZERO, SHIFT_TYPE); 
    input [7:0] DATA1, DATA2; 
    input [2:0] SELECT; 
    input [1:0] SHIFT_TYPE; // 2-bit switch: 00=sll, 01=srl, 10=sra, 11=ror
	
    output reg [7:0] RESULT; 
    output ZERO;

  // Added the new mult_ans wire to hold the answer coming from the multiplier
  wire [7:0] fwd_ans, add_ans, and_ans, or_ans, shift_ans, mult_ans; 

    // Instantiate all the sub-modules
  forward_unit    my_fwd (DATA2, fwd_ans);
    add_unit        my_add (DATA1, DATA2, add_ans);
	and_unit        my_and (DATA1, DATA2, and_ans);
  or_unit         my_or (DATA1, DATA2, or_ans);
	// the upgraded shifter (handles all 4 shift types)
    shift_unit      my_shifter (DATA1, DATA2, SHIFT_TYPE, shift_ans); 
    // the brand new multiplier unit
	mult_unit       my_mult (DATA1, DATA2, mult_ans);

    //mux logic
    always @(*) begin 
	    case(SELECT)
	        3'b000: RESULT = fwd_ans; 
            3'b001: RESULT = add_ans; 
            3'b010: RESULT = and_ans; 
            3'b011: RESULT = or_ans;
            3'b100: RESULT = shift_ans; //opcode selects shifter
          3'b101: RESULT = mult_ans;  //Opcode selects multiplier
            default: RESULT = 8'b00000000;
      endcase
    end

    //Sets ZERO flag to 1 if result is exactly 0
    assign ZERO = (RESULT == 8'b00000000);
endmodule