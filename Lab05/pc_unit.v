// Program  counter module - Lab 4
// Maintains the current execution address.
// Increments by 4 each cycle as the instructions are 4 bytes  long.
//
// Updated to accept PC_SELECT and BRANCH_JUMP_TARGET allowing  j and beq
// instructions to redirect the program  counter to a new target address.
// PC_SELECT = 0 -> Sequential execution (PC = PC + 4)
// PC_SELECT = 1 -> Branch/jump taken (PC = BRANCH_JUMP_TARGET)
// 
// PC_NEXT (= PC + 4) is provided as an  output for the CPU's
// branch/jump target calculation logic.

module pc_unit(
    output reg [31:0] PC,
    output wire [31:0] PC_NEXT,   // NEW: PC+4, used by branch target adder
    input [31:0] BRANCH_JUMP_TARGET, // NEW: target address for branches/jumps
    input PC_SELECT,              // NEW: 0=PC+4, 1=branch/jump target
    input BUSYWAIT,               // NEW: stall signal from memory
    input CLK,
    input RESET
);

    // calculate next PC value, #1 delay
    // this runs in parallel with the instruction memory read
    assign #1 PC_NEXT = PC + 32'd4;

    // Update PC on the  clock edge
    // If PC_SELECT is high, load the branch/jump target instead of PC+4
    always @(posedge CLK) begin
        #1; // Evaluate control signals after 1 time unit delay to resolve simulation race conditions.
        if (RESET) begin
            PC = 32'd0;                     // Reset PC to 0
        end else if (!BUSYWAIT) begin       // Stall execution if BUSYWAIT is high
            if (PC_SELECT) begin
                PC = BRANCH_JUMP_TARGET;     // Update PC to branch/jump target
            end else begin
                PC = PC_NEXT;                // Sequential execution
            end
        end
    end

endmodule
