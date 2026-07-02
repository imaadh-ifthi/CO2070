// program counter module - lab 4 (upgraded)
// keeps track of where we are in the program
// increments by 4 each cycle cuz instructions are 4 bytes long. duh.
//
// NEW: accepts PC_SELECT and BRANCH_JUMP_TARGET so that j and beq
// instructions can redirect the program counter to a new address.
// PC_SELECT = 0 -> normal sequential execution (PC = PC + 4)
// PC_SELECT = 1 -> branch/jump taken (PC = BRANCH_JUMP_TARGET)
// 
// PC_NEXT (= PC + 4) is exposed as an output so the CPU's
// branch/jump target adder can use it. 
// why didn't I think of this earlier...

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

    // update PC on clock edge
    // if PC_SELECT is high, load the branch/jump target instead of PC+4
    always @(posedge CLK) begin
        #1; // evaluate control signals after 1 time unit (this hack fixed my simulation race condition bless up)
        if (RESET) begin
            PC = 32'd0;                     // go back to start on reset
        end else if (!BUSYWAIT) begin       // NEW: STALL if BUSYWAIT is high
            if (PC_SELECT) begin
                PC = BRANCH_JUMP_TARGET;     // NEW: take the branch/jump wheeee
            end else begin
                PC = PC_NEXT;                // normal: move to next instruction. boring.
            end
        end
    end

endmodule
