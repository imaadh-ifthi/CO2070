// program counter module
// just keeps track of where we are in the program
// increments by 4 each cycle (since each instruction is 4 bytes)

module pc_unit(
    output reg [31:0] PC,
    input CLK,
    input RESET
);

    wire [31:0] PC_NEXT;

    // calculate next PC value, #1 delay
    // this runs in parallel with the instruction memory read
    assign #1 PC_NEXT = PC + 32'd4;

    // update PC on clock edge
    always @(posedge CLK) begin
        if (RESET) begin
            #1 PC = 32'd0;         // go back to start
        end else begin
            #1 PC = PC_NEXT;       // move to next instruction
        end
    end

endmodule
