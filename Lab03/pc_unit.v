module pc_unit(
    output reg [31:0] PC,
    input CLK,
    input RESET
);

    wire [31:0] PC_NEXT;

    // PC + 4 Adder
    // Latency: #1 time unit, works in parallel with instruction memory read
    assign #1 PC_NEXT = PC + 32'd4;

    // PC Update Logic (Synchronous, on positive clock edge)
    // Delay: #1 time unit for PC write
    always @(posedge CLK) begin
        if (RESET) begin
            #1 PC = 32'd0;         // Reset PC to address 0
        end else begin
            #1 PC = PC_NEXT;       // Advance to next instruction
        end
    end

endmodule
