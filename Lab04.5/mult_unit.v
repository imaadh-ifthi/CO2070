// 8-bit multiplier - lab 4.5
// implements multiplication WITHOUT using the * operator
// (because apparently that would be too easy)
//
// HOW IT WORKS:
//   Uses the shift-and-add method (array multiplier).
//   For each bit of data2, if the bit is 1, we add a shifted copy
//   of data1 to the result. The "shift" is done using concatenation
//   (not <<, as those operators  are restricted).
//
//   Example: 5 * 7 = 00000101 * 00000111
//     pp0 = 00000101 (data2[0]=1, shift 0)
//     pp1 = 00001010 (data2[1]=1, shift 1)
//     pp2 = 00010100 (data2[2]=1, shift 2)
//     pp3-7 = 0       (data2[3-7]=0)
//     sum  = 00100011 = 35 ✓ nice
//
//   Only keeps the lower 8 bits of the 16-bit product.
//   Overflow is ignored  for 8-bit results
//
// LATENCY: #3 time units (array multiplier is slower than a simple add)

module mult_unit(input [7:0] data1, input [7:0] data2, output reg [7:0] out);

    // -------------------------------------------------------
    // Step 1: Generate partial products using AND gates
    // Each partial product = data1 AND'd with one bit of data2
    // (replicate the bit 8 times so we can AND the whole byte)
    // -------------------------------------------------------
    wire [7:0] pp0 = {8{data2[0]}} & data1;
    wire [7:0] pp1 = {8{data2[1]}} & data1;
    wire [7:0] pp2 = {8{data2[2]}} & data1;
    wire [7:0] pp3 = {8{data2[3]}} & data1;
    wire [7:0] pp4 = {8{data2[4]}} & data1;
    wire [7:0] pp5 = {8{data2[5]}} & data1;
    wire [7:0] pp6 = {8{data2[6]}} & data1;
    wire [7:0] pp7 = {8{data2[7]}} & data1;

    // -------------------------------------------------------
    // Step 2: Shift each partial product left by its position
    // Using concatenation instead of << because << is banned
    // We only keep lower 8 bits (upper bits overflow and get dropped)
    // -------------------------------------------------------
    wire [7:0] spp0 = pp0;                         // pp0 << 0 (no shift)
    wire [7:0] spp1 = {pp1[6:0], 1'b0};            // pp1 << 1
    wire [7:0] spp2 = {pp2[5:0], 2'b00};           // pp2 << 2
    wire [7:0] spp3 = {pp3[4:0], 3'b000};          // pp3 << 3
    wire [7:0] spp4 = {pp4[3:0], 4'b0000};         // pp4 << 4
    wire [7:0] spp5 = {pp5[2:0], 5'b00000};        // pp5 << 5
    wire [7:0] spp6 = {pp6[1:0], 6'b000000};       // pp6 << 6
    wire [7:0] spp7 = {pp7[0],   7'b0000000};      // pp7 << 7

    // -------------------------------------------------------
    // Step 3: Sum all shifted partial products using an adder tree
    // Tree structure (pairs first, then pairs of pairs)
    // so it's like a tournament bracket but for addition
    // -------------------------------------------------------
    wire [7:0] sum_01   = spp0 + spp1;             // level 1
    wire [7:0] sum_23   = spp2 + spp3;
    wire [7:0] sum_45   = spp4 + spp5;
    wire [7:0] sum_67   = spp6 + spp7;

    wire [7:0] sum_0123 = sum_01 + sum_23;          // level 2
    wire [7:0] sum_4567 = sum_45 + sum_67;

    wire [7:0] product  = sum_0123 + sum_4567;      // level 3 (final)

    // output with #3 delay
    always @(*) #3 out = product;

endmodule
