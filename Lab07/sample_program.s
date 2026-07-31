// Lab 4.5 Bonus Test Program - FULL 20 MARKS
// Testing mult, sll, srl, sra, ror, and bne

loadi 1 0x03    // r1 = 3
loadi 2 0x04    // r2 = 4
mult 3 1 2      // r3 = r1 * r2 (3 * 4 = 12, or 0x0C in hex)

loadi 4 0x80    // r4 = 10000000 in binary (-128 in decimal)
sra 5 4 0x02    // r5 = r4 shifted right arithmetically by 2. (Result: 0xE0)

// --- NEW ADDITIONS TO TEST REMAINING INSTRUCTIONS ---
loadi 6 0x0F    // r6 = 00001111 in binary (0x0F)
sll 7 6 0x04    // r7 = r6 shifted left by 4.   (Result: 11110000 or 0xF0)
srl 7 7 0x02    // r7 = r7 shifted right by 2.  (Result: 00111100 or 0x3C)
ror 7 7 0x03    // r7 = r7 rotated right by 3.  (Result: 10000111 or 0x87)
// ----------------------------------------------------

// Check if r3 (0x0C) and r5 (0xE0) are NOT equal. 
// They are not, so it will branch forward by 1 instruction (skipping the jump)
bne 0x01 3 5    

j 0xFD          // This jump will be safely skipped!

mov 0 3         // r0 = r3 (0x0C). Program finishes here.