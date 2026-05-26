# RISC-V Assembly Lab
# E Numbers : E22151, E22056
# Names : M.I.M. Imaadh, P.G.D.D. Chandrawansha
# Description: 

.data
# Initialize the array with 5 sample integers
array:  .word 12, 7, 4, 15, 8   
length: .word 5                 

.text
.globl _start

_start:
    la   t0, array      # t0 = base address of the array
    lw   t1, length     # t1 = length of the array (5)
    li   t2, 0          # t2 = loop counter (i = 0)

# ---------------------------------------------------------
# YOUR CODE GOES HERE:
# Write the logic to iterate through the array.
# Check if each element is even or odd using 'andi'.
# Apply the addition or subtraction, and store it back.

loop_start:
    beq t2, t1, done #exit condition: if i == length, program is complete

    lw t3, 0(t0) #Load current array element into reg t3

    andi t4, t3, 1 #t4 = 1 if odd, 0 if even
    beq t4, zero, is_even # if t4 = 0, jump to is_even label

    is_odd:
        addi t3, t3, -5
        j store_result
    is_even:
        addi t3, t3, 10

    store_result:
        sw t3, 0(t0) #store value back to the same memory spot
    
        addi t2, t2, 1 #increment loop counter
    
        addi t0,t0, 4 #move the array pointer to the next element
        
    j loop_start #jump back to the top of the loop
# ---------------------------------------------------------

done:
    nop                 # Jump here when the array processing is complete