`timescale 1ns/100ps

module reg_file (IN, OUT1, OUT2, INADDRESS, OUT1ADDRESS, OUT2ADDRESS, WRITE, CLK, RESET);
    input [7:0] IN; // 8 bit input data
    input [2:0] INADDRESS, OUT1ADDRESS, OUT2ADDRESS; //3 bit addresses for reg selection
  input WRITE, CLK, RESET; // control signals for write, clock and reset
    output [7:0] OUT1, OUT2; //8 bit outputs from selected registers

	reg [7:0] registers [0:7]; // array of 8 registers, each 8-bit wide
    integer i; //loop variable for reset operation

    assign #2 OUT1 = registers[OUT1ADDRESS]; //read reg at OUT1ADDRESS after 2 time units delay
    assign #2 OUT2 = registers[OUT2ADDRESS]; //read reg at out2address after 2 time units delay
	always @(posedge CLK) begin // execute on rising edge of clock
      
        if (RESET) begin // reset is active high
            #1; // wait 1 time unit before clearing registers
            for (i = 0; i < 8; i = i + 1) begin
                registers[i] = 8'b00000000; //set each reg value to 0
            end
        end 
        else if (WRITE) begin //write is active high
            #1 registers[INADDRESS] = IN; // after 1 time unit store input data into selected reg
        end
        
    end

endmodule