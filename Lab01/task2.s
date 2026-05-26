# RISC-V Assembly Lab
# E Numbers : E22151, E22056
# Names : M.I.M. Imaadh, P.G.D.D. Chandrawansha
# Description: 

.data
# Space to store the final calculated product
result: .word 0

.text
.globl _start

_start:
    # Load test values into a0 (multiplicand) and a1 (multiplier)
    # You can change these numbers to test different cases
    li   a0, 6        
    li   a1, 7        

    # Call the multiplication subroutine
    jal  ra, mymul

    # Store the returned result (in a0) into the data segment
    la   t0, result
    sw   a0, 0(t0)

done:
    j done               # Main program complete

# ---------------------------------------------------------
# Subroutine: mymul
# Arguments:
#   a0 = multiplicand
#   a1 = multiplier
# Returns:
#   a0 = product (a0 * a1)
# ---------------------------------------------------------
mymul:
li t0, 0 # t0 = sum


loop:
    beqz a1, mul_done # if no bits left in multiplier, finish
    andi t1, a1, 1  # t1 = LSB of multiplier
    beqz t1, mul_skip # if bit is 0, skip addition
    add t0, t0, a0 # product += multiplicand

mul_skip:
    slli a0, a0, 1 # shift multiplicand left by 1
    srli a1, a1, 1 # shift multiplier right by 1 
    j loop

mul_done:
    mv a0, t0 # return product in a0
    ret
# ---------------------------------------------------------
# YOUR CODE GOES HERE:
# ---------------------------------------------------------

