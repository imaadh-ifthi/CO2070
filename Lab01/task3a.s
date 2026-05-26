# RISC-V Assembly Lab
# E Numbers : E22151, E22056
# Names : M.I.M. Imaadh, P.G.D.D. Chandrawansha
# Description: 

.data
# Matrix A (4x4, row-major)
A:  .word 1, 2, 3, 4
    .word 5, 6, 7, 8
    .word 9, 10, 11, 12
    .word 13, 14, 15, 16

# Matrix B (4x4, row-major)
B:  .word 1, 2, 3, 4
    .word 0, 1, 2, 3
    .word 0, 0, 1, 2
    .word 0, 0, 0, 1

# Matrix C (4x4, initialized to 0)
C:  .word 0, 0, 0, 0
    .word 0, 0, 0, 0
    .word 0, 0, 0, 0
    .word 0, 0, 0, 0

.text
.globl _start

_start:
    la s0, A    #s0 = base address of A
    la s1, B    #s1 = base address of B
    la s2, C    #s2 = base address of C
    li s3, 0    #i = 0 (Row index)

loop_i:
    li s4, 0    #j = 0 (Col index)

loop_j:
    li s6, 0    #sum = 0
    li s5, 0    #k = 0

loop_k:
    # Load A[i][k]
    slli t0, s3, 2      #t0 = i*4
    add t0, t0, s5      #t0 = (i*4) + k
    slli t0, t0, 2      #t0 = ((i*4) + k) * 4
    add t0, s0, t0      #t0 = baseA + offset
    lw a0, 0(t0)        #a0 = A[i][k]

    # Load B[k][j]
    slli t1, s5, 2      #t1 = k*4
    add  t1, t1, s4     #t1 = (k*4) + j
    slli t1, t1, 2      #t1 = ((k*4) + j) * 4
    add  t1, s1, t1     #t1 = baseB + offset
    lw   a1, 0(t1)      #a1 = A[k][j]

    # Multiply
    jal ra, mymul
    add s6, s6, a0      #sum += 0

    addi s5, s5, 1      #k++
    li t2, 4
    blt s5, t2, loop_k

    # --- Store C[i][j] ---
    slli t0, s3, 2    # t0 = i * 4
    add  t0, t0, s4   # t0 = (i * 4) + j
    slli t0, t0, 2    # t0 = ((i * 4) + j) * 4
    add  t0, s2, t0   # t0 = baseC + offset
    sw   s6, 0(t0)    # C[i][j] = sum

    addi s4, s4, 1    # j++
    li   t2, 4
    blt  s4, t2, loop_j

    addi s3, s3, 1    # i++
    li   t2, 4
    blt  s3, t2, loop_i

    j done

    # Subroutine: mymul
mymul:
    li t0, 0          
loop_mul:
    beqz a1, mul_done 
    andi t1, a1, 1    
    beqz t1, mul_skip 
    add  t0, t0, a0   
mul_skip:
    slli a0, a0, 1    
    srli a1, a1, 1     
    j loop_mul
mul_done:
    mv a0, t0         
    ret

done:
    nop                 # Main program complete