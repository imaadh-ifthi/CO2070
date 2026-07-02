# Lab 4.5 - Extended ISA Report

## 1. Overview

This report documents the extension of the Lab 4 processor to support **6 additional instructions**:
`mult`, `sll`, `srl`, `sra`, `ror`, and `bne`.

All new functional units are implemented **without simple Verilog operators** — the multiplier uses an array of AND gates and adder trees (no `*`), and the barrel shifter uses mux layers with bit concatenation (no `<<`, `>>`, `>>>`).

---

## 2. Instruction Encodings

All instructions use the existing 32-bit format:

```
[31:24]  [23:16]  [15:8]  [7:0]
OPCODE   RD/OFF   RT      RS/IMM
```

### 2.1 Opcode Table (Complete ISA)

| Opcode | Hex  | Instruction | Format                  | Description                          |
|--------|------|-------------|-------------------------|--------------------------------------|
| 00000000 | 0x00 | `loadi` | `loadi rd, imm`        | Load immediate into register         |
| 00000001 | 0x01 | `mov`   | `mov rd, rt`           | Copy register to register            |
| 00000010 | 0x02 | `add`   | `add rd, rt, rs`       | Add two registers                    |
| 00000011 | 0x03 | `sub`   | `sub rd, rt, rs`       | Subtract two registers               |
| 00000100 | 0x04 | `and`   | `and rd, rt, rs`       | Bitwise AND                          |
| 00000101 | 0x05 | `or`    | `or rd, rt, rs`        | Bitwise OR                           |
| 00000110 | 0x06 | `j`     | `j offset`             | Unconditional jump                   |
| 00000111 | 0x07 | `beq`   | `beq offset, rt, rs`   | Branch if equal                      |
| **00001000** | **0x08** | **`mult`** | **`mult rd, rt, rs`** | **Multiply two registers**       |
| **00001001** | **0x09** | **`sll`**  | **`sll rd, rt, imm`** | **Shift left logical**           |
| **00001010** | **0x0A** | **`srl`**  | **`srl rd, rt, imm`** | **Shift right logical**          |
| **00001011** | **0x0B** | **`sra`**  | **`sra rd, rt, imm`** | **Shift right arithmetic**       |
| **00001100** | **0x0C** | **`ror`**  | **`ror rd, rt, imm`** | **Rotate right**                 |
| **00001101** | **0x0D** | **`bne`**  | **`bne offset, rt, rs`** | **Branch if not equal**       |

### 2.2 Field Descriptions for New Instructions

**`mult rd, rt, rs`** — Register-register multiply
- `rd` [23:16]: Destination register (lower 3 bits)
- `rt` [15:8]: First source register (lower 3 bits)
- `rs` [7:0]: Second source register (lower 3 bits)
- Result: `reg[rd] = reg[rt] × reg[rs]` (lower 8 bits of product)

**`sll/srl/sra/ror rd, rt, imm`** — Register-immediate shift/rotate
- `rd` [23:16]: Destination register (lower 3 bits)
- `rt` [15:8]: Source register to shift (lower 3 bits)
- `imm` [7:0]: Shift amount (lower 3 bits used, range 0–7)
- Result varies by operation (see Section 4)

**`bne offset, rt, rs`** — Conditional branch
- `offset` [23:16]: Signed branch offset (instruction count)
- `rt` [15:8]: First comparison register (lower 3 bits)
- `rs` [7:0]: Second comparison register (lower 3 bits)
- Branches to `PC+4 + (sign_extend(offset) × 4)` if `reg[rt] ≠ reg[rs]`

---

## 3. ALUOP Assignments

The 3-bit ALUOP signal selects between functional units inside the ALU:

| ALUOP | Functional Unit     | Instructions Using It         |
|-------|---------------------|-------------------------------|
| `000` | Forward Unit        | `loadi`, `mov`                |
| `001` | Add Unit            | `add`, `sub`, `beq`, `bne`    |
| `010` | AND Unit            | `and`                         |
| `011` | OR Unit             | `or`                          |
| **`100`** | **Shift/Rotate Unit** | **`sll`, `srl`, `sra`, `ror`** |
| **`101`** | **Multiply Unit**   | **`mult`**                    |
| `110` | *(unused)*          | —                             |
| `111` | *(unused)*          | —                             |

### 3.1 Hardware Sharing Strategy

The 4 shift/rotate instructions (`sll`, `srl`, `sra`, `ror`) all share a **single barrel shifter** functional unit (ALUOP `100`). The specific operation is selected by a 2-bit `SHIFT_MODE` control signal:

| SHIFT_MODE | Operation | Fill Behavior |
|------------|-----------|---------------|
| `00` | SLL (Shift Left Logical)      | Fill vacated LSBs with 0 |
| `01` | SRL (Shift Right Logical)     | Fill vacated MSBs with 0 |
| `10` | SRA (Shift Right Arithmetic)  | Fill vacated MSBs with sign bit |
| `11` | ROR (Rotate Right)            | Wrap bits from LSB to MSB |

This allows 4 operations to share one ALUOP code, keeping the 3-bit ALUOP constraint satisfied.

---

## 4. New Functional Units

### 4.1 Multiply Unit (`mult_unit.v`)

**Architecture:** 8-bit array multiplier using shift-and-add

**Implementation:**
1. **Partial Product Generation**: 8 partial products created using AND gates. Each partial product `pp[i]` = `data1 AND {8{data2[i]}}`.
2. **Positional Shifting**: Each partial product is shifted left by its position using **bit concatenation** (not the `<<` operator). E.g., `pp1` shifted left by 1 = `{pp1[6:0], 1'b0}`.
3. **Adder Tree**: Partial products are summed using a 3-level binary adder tree for efficient addition.

Only the lower 8 bits of the 16-bit product are kept (upper bits overflow and are discarded).

**Latency:** `#3` time units

### 4.2 Barrel Shifter/Rotator (`shift_unit.v`)

**Architecture:** 3-layer barrel shifter using multiplexer-based design

**Implementation:**
- **Layer 0**: Conditionally shifts by 1 position (controlled by `shift_amount[0]`)
- **Layer 1**: Conditionally shifts by 2 positions (controlled by `shift_amount[1]`)
- **Layer 2**: Conditionally shifts by 4 positions (controlled by `shift_amount[2]`)

Each layer uses a `case` statement on `SHIFT_MODE` to determine the fill behavior. Shifting is implemented using **bit slicing and concatenation** (e.g., `{data[6:0], 1'b0}` for SLL by 1), not Verilog shift operators.

Only the lower 3 bits of the shift amount are used (supports shifts of 0–7 positions).

**Latency:** `#2` time units

---

## 5. Control Signal Changes

### 5.1 New Control Signals

| Signal | Width | Source | Purpose |
|--------|-------|--------|---------|
| `SHIFT_MODE[1:0]` | 2 bits | Control Unit → ALU | Selects shift operation type |
| `BRANCH_NEQ` | 1 bit | Control Unit → CPU | Asserted for `bne` instruction |

### 5.2 Control Signal Values per New Instruction

| Instruction | ALUOP | MUX_IMM_SEL | MUX_COMP_SEL | WRITEENABLE | SHIFT_MODE | BRANCH_NEQ | JUMP | BRANCH |
|-------------|-------|-------------|--------------|-------------|------------|------------|------|--------|
| `mult`      | `101` | 0 | 0 | 1 | `xx` | 0 | 0 | 0 |
| `sll`       | `100` | 1 | 0 | 1 | `00` | 0 | 0 | 0 |
| `srl`       | `100` | 1 | 0 | 1 | `01` | 0 | 0 | 0 |
| `sra`       | `100` | 1 | 0 | 1 | `10` | 0 | 0 | 0 |
| `ror`       | `100` | 1 | 0 | 1 | `11` | 0 | 0 | 0 |
| `bne`       | `001` | 0 | 1 | 0 | `xx` | 1 | 0 | 0 |

---

## 6. Datapath Changes

### 6.1 Updated PC_SELECT Logic

```
// Original (Lab 4):
PC_SELECT = JUMP | (BRANCH & ZERO)

// Updated (Lab 4.5):
PC_SELECT = JUMP | (BRANCH & ZERO) | (BRANCH_NEQ & ~ZERO)
```

The `bne` instruction uses the same subtract-and-check-zero mechanism as `beq`, but branches when the ZERO flag is **not** asserted (i.e., the operands are **not** equal).

### 6.2 Updated ALU

The ALU output multiplexer is extended from 4 entries to 6:

```
case(SELECT)
    3'b000: RESULT = fwd_out;    // forward
    3'b001: RESULT = add_out;    // add
    3'b010: RESULT = and_out;    // and
    3'b011: RESULT = or_out;     // or
    3'b100: RESULT = shift_out;  // NEW: shift/rotate
    3'b101: RESULT = mult_out;   // NEW: multiply
endcase
```

The `SHIFT_MODE` signal passes through the CPU from the control unit to the ALU's barrel shifter.

### 6.3 Datapath Diagram (Signal Flow for New Instructions)

```
mult rd, rt, rs:
  READREG1=RT → REGOUT1 → ALU.DATA1 ─┐
  READREG2=RS → REGOUT2 → [comp_mux(0)] → [imm_mux(0)] → ALU.DATA2 ─┤
                                              ALUOP=101 → mult_unit → RESULT → reg[rd]

sll/srl/sra/ror rd, rt, imm:
  READREG1=RT → REGOUT1 → ALU.DATA1 ─┐
  IMMEDIATE=imm → [imm_mux(1)] → ALU.DATA2 ─┤
                    ALUOP=100, SHIFT_MODE → shift_unit → RESULT → reg[rd]

bne offset, rt, rs:
  READREG1=RT → REGOUT1 → ALU.DATA1 ─┐
  READREG2=RS → REGOUT2 → [comp_mux(1)] → [imm_mux(0)] → ALU.DATA2 ─┤
                              (2's comp)     ALUOP=001 → add_unit → ZERO flag
                                             BRANCH_NEQ & ~ZERO → PC_SELECT
```

---

## 7. Timing Analysis

**Clock period: 8 time units** (unchanged from Lab 4)

### 7.1 Component Latencies

| Component | Latency | Notes |
|-----------|---------|-------|
| PC update | #1 | `PC = PC_NEXT` or `PC = TARGET` |
| Instruction Memory | #2 | Read 4 bytes |
| Control Unit (Decode) | #1 | Decode opcode, set control signals |
| Register File Read | #2 | Asynchronous read |
| 2's Complement | #1 | Bit inversion + add 1 |
| Forward Unit | #1 | Pass-through |
| Add Unit | #2 | 8-bit addition |
| AND/OR Unit | #1 | Bitwise operation |
| **Shift/Rotate Unit** | **#2** | **3-layer barrel shifter** |
| **Multiply Unit** | **#3** | **Array multiplier with adder tree** |
| Branch Target Adder | #2 | 32-bit addition |

### 7.2 Critical Path Analysis

**Key insight:** Decode (#1) and Register Read (#2) happen **in parallel** because `READREG1` and `READREG2` are assigned combinationally (zero delay) from the instruction bits, while the control unit decode takes #1.

| Instruction | Critical Path | Total |
|-------------|--------------|-------|
| `mult` | PC(#1) → Mem(#2) → max(Decode(#1), RegRead(#2)) → Mult(#3) | 1+2+2+3 = **8** ✅ |
| `sll/srl/sra/ror` | PC(#1) → Mem(#2) → max(Decode(#1), RegRead(#2)) → Shift(#2) | 1+2+2+2 = **7** ✅ |
| `bne` | PC(#1) → Mem(#2) → max(Decode(#1), RegRead(#2)) → 2sComp(#1) → Add(#2) | 1+2+2+1+2 = **8** ✅ |

All instructions complete within 8 time units. No clock period increase required.

```
Time:    0    1    2    3    4    5    6    7    8
         |    |    |    |    |    |    |    |    |
mult:    [PC ] [Instr Memory ] [Reg ] [Multiply    ]
                               [Dec ]
                                          ↑ Result ready at t=8

shift:   [PC ] [Instr Memory ] [Reg ] [Shift  ]
                               [Dec ]
                                     ↑ Result ready at t=7

bne:     [PC ] [Instr Memory ] [Reg ] [2s ] [Add   ]
                               [Dec ]
                                               ↑ ZERO ready at t=8
```

---

## 8. Verification

### 8.1 Test Program

The testbench (`cpu_tb.v`) contains 13 test phases. Phases 1–6 test the original Lab 4 instructions. Phases 7–13 test the new Lab 4.5 instructions:

| Phase | Instruction | Test | Expected Result |
|-------|-------------|------|-----------------|
| 7 | `mult` | `mult r2, r0, r1` (r0=5, r1=7) | r2 = 35 |
| 8 | `sll` | `sll r4, r3, 2` (r3=5=00000101) | r4 = 20 (00010100) |
| 9 | `srl` | `srl r5, r3, 3` (r3=0xA0=10100000) | r5 = 20 (00010100) |
| 10 | `sra` | `sra r6, r3, 3` (r3=0xA0=10100000) | r6 = 244 (11110100) |
| 11 | `ror` | `ror r7, r3, 2` (r3=0x05=00000101) | r7 = 65 (01000001) |
| 12 | `bne` taken | `bne 0x01, r0, r1` (r0=5, r1=7) | Skips PC+4, lands at PC+8 |
| 13 | `bne` not-taken | `bne 0x01, r0, r1` (r0=42, r1=42) | Falls through to PC+4 |

### 8.2 Simulation Results

All register values match expected values:

```
r0 = 42  (0x2A) ✓ - bne test setup
r1 = 42  (0x2A) ✓ - mov'd from r0
r2 = 35  (0x23) ✓ - mult 5×7
r3 = 187 (0xBB) ✓ - bne not-taken proof
r4 = 20  (0x14) ✓ - sll 5<<2
r5 = 20  (0x14) ✓ - srl 0xA0>>3
r6 = 244 (0xF4) ✓ - sra 0xA0>>>3
r7 = 65  (0x41) ✓ - ror 0x05 by 2
```

---

## 9. Files

| File | Status | Description |
|------|--------|-------------|
| `mult_unit.v` | **New** | 8-bit array multiplier (AND gates + adder tree) |
| `shift_unit.v` | **New** | 8-bit barrel shifter/rotator (mux-based, 4 modes) |
| `alu.v` | Modified | Integrated mult_unit and shift_unit, expanded output mux |
| `control_unit.v` | Modified | Added 6 new opcodes, SHIFT_MODE and BRANCH_NEQ outputs |
| `cpu.v` | Modified | Wired SHIFT_MODE and BRANCH_NEQ, updated PC_SELECT logic |
| `cpu_tb.v` | Modified | Added test phases 7–13 for all new instructions |
| `reg_file.v` | Unchanged | — |
| `pc_unit.v` | Unchanged | — |
| `twos_complement.v` | Unchanged | — |
| `mux_2x1_8bit.v` | Unchanged | — |
