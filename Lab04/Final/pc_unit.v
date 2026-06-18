// Program Counter (PC) Module
// Maintains the instruction memory address pointer.
// Auto-increments by 4 bytes per cycle to fetch the subsequent 32-bit instruction word.
//
// ENHANCEMENT: Integrates PC_SELECT and BRANCH_JUMP_TARGET inputs to facilitate
// non-sequential control flow operations (e.g., J and BEQ instructions).
// PC_SELECT = 0 -> Sequential execution path (PC = PC + 4)
// PC_SELECT = 1 -> Control flow branch/jump taken (PC = BRANCH_JUMP_TARGET)
// 
// PC_NEXT (PC + 4) is exposed as an external output to enable parallel
// target address computation 

module pc_unit(
    output reg [31:0] PC,
    output wire [31:0] PC_NEXT,   // NEW: PC+4, used by branch target adder
    input [31:0] BRANCH_JUMP_TARGET, // NEW: target address for branches/jumps
    input PC_SELECT,              // NEW: 0=PC+4, 1=branch/jump target
    input CLK,
    input RESET
);

    // Compute sequential PC address
    assign #1 PC_NEXT = PC + 32'd4;

    // Synchronous PC state update
    always @(posedge CLK) begin
        #1; 
        if (RESET) begin
            PC = 32'd0;                      // Reinitialize instruction pointer to boot vector 0x0.
        end else begin
            if (PC_SELECT) begin
                PC = BRANCH_JUMP_TARGET;     // Non-sequential control flow path taken.
            end else begin
                PC = PC_NEXT;                // Sequential instruction progression.
            end
        end
    end

endmodule
