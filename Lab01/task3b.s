
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
    la s0, A            # s0 = Base address of A
    la s1, B            # s1 = Base address of B
    la s2, C            # s2 = Base address of C

    li s3, 0    # s3 = i = 0 (Outer loop: Rows of A)
loop_i:
    li t6, 4
    bge s3, t6, done

    li s4, 0    # s4 = j = 0 (Middle loop: Cols of B)
loop_j:
    li t6, 4
    bge s4, t6, next_i

    li s6, 0            # s6 = running sum for C[i][j]

    li s5, 0 # s5 = k = 0 (Inner loop: Dot product)
loop_k:
    li t6, 4
    bge s5, t6, store_c

    # Calculate A[i][k] Address 
    slli t0, s3, 2  # t0 = i * 4
    add  t0, t0, s5 # t0 = (i * 4) + k
    slli t0, t0, 2  # t0 = ((i * 4) + k) * 4 bytes
    add  t0, s0, t0 # t0 = exact address
    lw   a0, 0(t0)  # Load A[i][k]

    # Calculate B[k][j] Address
    slli t1, s5, 2  # t1 = k * 4
    add  t1, t1, s4     # t1 = (k * 4) + j
    slli t1, t1, 2  # t1 = ((k * 4) + j) * 4 bytes
    add  t1, s1, t1 # t1 = exact address
    lw   a1, 0(t1)      # Load B[k][j]

    mul  t3, a0, a1 # t3 = A[i][k] * B[k][j]
    add  s6, s6, t3 # sum += t3

    addi s5, s5, 1      # k++
    j loop_k

store_c:
    #Calculate C[i][j] Address and Store
    slli t2, s3, 2      # t2 = i * 4
    add  t2, t2, s4     # t2 = (i * 4) + j
    slli t2, t2, 2      # t2 = ((i * 4) + j) * 4 bytes
    add  t2, s2, t2     # t2 = exact address
    sw   s6, 0(t2)      # Store sum

    addi s4, s4, 1      # j++
    j loop_j

next_i:
    addi s3, s3, 1      # i++
    j loop_i

done:
    nop                 # Halt