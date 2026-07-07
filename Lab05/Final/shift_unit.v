// Barrel Shifter / Rotator module - Lab 4.5
// Implements SLL, SRL, SRA, and ROR operations in a single functional unit
// to optimize hardware utilization.
//
// NO shift operators used (<<, >>, >>> are all banned)
// instead uses 3 layers of muxes (barrel shifter architecture):
//   Layer 0: conditionally shift by 1  (based on shift_amount[0])
//   Layer 1: conditionally shift by 2  (based on shift_amount[1])
//   Layer 2: conditionally shift by 4  (based on shift_amount[2])
//
// MODE encoding:
//   00 = SLL (logical shift left)  - fill with 0s from right
//   01 = SRL (logical shift right) - fill with 0s from left
//   10 = SRA (arithmetic shift right) - fill with sign bit from left
//   11 = ROR (rotate right) - wrap bits around
//
// LATENCY: #2 time units (3 mux layrs  execute within limits)
//
// Only utilizes the lower 3 bits of the shift amount (0-7 positions).
// Shifts greater than 7 will wrap  around.

module shift_unit(
    input [7:0] data1,       // value to shift/rotate
    input [7:0] data2,       // shift amount (lower 3 bits used)
    input [1:0] mode,        // 00=SLL, 01=SRL, 10=SRA, 11=ROR
    output reg [7:0] out
);

    wire [2:0] amt = data2[2:0];  // only need 3 bits for 8-bit shifts

    // intermediate stage results
    reg [7:0] stage0, stage1;

    always @(*) begin
        #2;  // 2 time unit delay for the barrel shifter

        // -------------------------------------------------------
        // STAGE 0: conditionally shift by 1 (if amt[0] == 1)
        // -------------------------------------------------------
        if (amt[0]) begin
            case (mode)
                2'b00: stage0 = {data1[6:0], 1'b0};         // SLL 1: slide left, fill right with 0
                2'b01: stage0 = {1'b0, data1[7:1]};         // SRL 1: slide right, fill left with 0
                2'b10: stage0 = {data1[7], data1[7:1]};     // SRA 1: slide right, fill left with sign bit
                2'b11: stage0 = {data1[0], data1[7:1]};     // ROR 1: bit that falls off the right goes to the left
            endcase
        end else begin
            stage0 = data1;  // no shift this stage
        end

        // -------------------------------------------------------
        // STAGE 1: conditionally shift by 2 (if amt[1] == 1)
        // -------------------------------------------------------
        if (amt[1]) begin
            case (mode)
                2'b00: stage1 = {stage0[5:0], 2'b00};              // SLL 2
                2'b01: stage1 = {2'b00, stage0[7:2]};              // SRL 2
                2'b10: stage1 = {{2{stage0[7]}}, stage0[7:2]};     // SRA 2: replicate sign bit twice
                2'b11: stage1 = {stage0[1:0], stage0[7:2]};        // ROR 2: bottom 2 bits wrap to top
            endcase
        end else begin
            stage1 = stage0;
        end

        // -------------------------------------------------------
        // STAGE 2: conditionally shift by 4 (if amt[2] == 1)
        // this is the final stage, output goes directly to 'out'
        // -------------------------------------------------------
        if (amt[2]) begin
            case (mode)
                2'b00: out = {stage1[3:0], 4'b0000};               // SLL 4
                2'b01: out = {4'b0000, stage1[7:4]};               // SRL 4
                2'b10: out = {{4{stage1[7]}}, stage1[7:4]};        // SRA 4: replicate sign bit 4 times
                2'b11: out = {stage1[3:0], stage1[7:4]};           // ROR 4: bottom 4 bits wrap to top
            endcase
        end else begin
            out = stage1;  // no shift this stage, just pass through
        end
    end

endmodule
