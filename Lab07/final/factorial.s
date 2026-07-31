// Program: Factorial Calculation (5!)
// Description: Computes 5 * 4 * 3 * 2 * 1 and stores the result in memory.

loadi 1 0x05    // r1 = 5 (This is 'n')
loadi 2 0x01    // r2 = 1 (This holds the running factorial result)
loadi 3 0x01    // r3 = 1 (Constant used to decrement n)
loadi 4 0x00    // r4 = 0 (Constant used to check if n has reached zero)

// --- Loop Start ---
// Instruction Address: 16 (Word 4)
// Check if n == 0. If it is, jump 3 words forward to exit the loop.
beq 0x03 1 4    

// Multiply the running result by n
mult 2 2 1      // r2 = r2 * r1

// Decrement n by 1
sub 1 1 3       // r1 = r1 - 1

// Jump backwards to the start of the loop
// Offset is -4 words. Two's complement of 4 is 0xFC
j 0xFC          

// --- End of Loop ---
// Instruction Address: 32 (Word 8)
// Store the final calculated factorial (120 or 0x78) into Data Memory address 0x04
swi 2 0x04      

// Move result to r0 to signal completion in the waveform
mov 0 2