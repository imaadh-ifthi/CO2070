`timescale 1ns/100ps

module or_unit (
    input [7:0] DATA1, // 8 bit input 1 into DATA1
    input [7:0] DATA2, //8 bit input 2 into data2
    output reg [7:0] OUT
);
    always @(DATA1 or DATA2) begin // whenever both data1 or data2 changes, execute
      #1 OUT = DATA1 | DATA2; // Assign DATA1 OR DATA2 into OUT in 1 time unit
    end

endmodule