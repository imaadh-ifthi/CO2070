.data
# Matrix A (4x4, row-major)
A:  .word 1, 2, 3, 4
    .word 5, 6, 7, 8
    .word 9, 10, 11, 12
    .word 13, 14, 15, 16

# Matrix B (4x4, COLUMN-major)
# Transposed from the original layout
B:  .word 1, 0, 0, 0
    .word 2, 1, 0, 0
    .word 3, 2, 1, 0
    .word 4, 3, 2, 1

# Matrix C (4x4, initialized to 0)
C:  .word 0, 0, 0, 0
    .word 0, 0, 0, 0
    .word 0, 0, 0, 0
    .word 0, 0, 0, 0

.text
.globl _start

_start:
    la s0, A          
    la s1, B          
    la s2, C          
    li s3, 0          

loop_i:
    li s4, 0          
loop_j:
    li s6, 0          
    li s5, 0          
loop_k:
    # --- Load A[i][k] (Row-Major) ---
    slli t0, s3, 2    
    add  t0, t0, s5   
    slli t0, t0, 2    
    add  t0, s0, t0   
    lw   a0, 0(t0)    

    # --- Load B[k][j] (Column-Major) ---
    # Offset calculated as (j * 4) + k
    slli t1, s4, 2    # t1 = j * 4
    add  t1, t1, s5   # t1 = (j * 4) + k
    slli t1, t1, 2    # t1 = ((j * 4) + k) * 4
    add  t1, s1, t1   # t1 = baseB + offset
    lw   a1, 0(t1)    

    # --- Multiply ---
    mul  t2, a0, a1   
    add  s6, s6, t2   

    addi s5, s5, 1    
    li   t3, 4
    blt  s5, t3, loop_k

    # --- Store C[i][j] (Row-Major) ---
    slli t0, s3, 2    
    add  t0, t0, s4   
    slli t0, t0, 2    
    add  t0, s2, t0   
    sw   s6, 0(t0)    

    addi s4, s4, 1    
    li   t3, 4
    blt  s4, t3, loop_j

    addi s3, s3, 1    
    li   t3, 4
    blt  s3, t3, loop_i

# ---------------------------------------------------------
done:
    nop                 # Main program complete