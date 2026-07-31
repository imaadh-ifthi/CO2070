`timescale 1ns/100ps

module forward_unit(
    input [7:0] DATA2, //8 bit value numbered from 7 to 0
    output reg [7:0] OUT
);
    always@(DATA2) begin // This execute whenever DATA2 changes
        #1 OUT = DATA2; // Assign DATA2 into OUT in 1 time unit
    end
endmodule