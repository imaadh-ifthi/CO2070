# CPU Testing Guide (Lab 7: Instruction Cache and System Integration)

## Prerequisites
Before running these commands, ensure you have modified `i_mem_for_icache.v` to load the generated memory file instead of using the hardcoded array. Add the following line inside its `initial` block:
`$readmemb("instr_mem.mem", memory_array);`

## Commands to Run in Order

cd "/Users/nithikanb/Library/Mobile Documents/com~apple~CloudDocs/Pera E22/Academic/Semester 4 - Computer Engineering/CO2070 - Computer Architecture/Labs/lab07"

1. **Compile the Assembler (if not already done)**
   ```bash
   gcc CO2070Assembler.c -o CO2070Assembler

```

2. **Generate instruction memory from assembly**
Run the following command to execute the comprehensive system test (Factorial calculation):
```bash
# Test: Complex Program Execution (Factorial of 5)
./generate_memory_image.sh factorial.s

```


3. **Compile the Verilog design**
Note: This now includes both data cache modules and the newly created instruction cache modules (`icache.v` and `i_mem_for_icache.v`).
```bash
iverilog -o cpu_sim cpu_tb.v cpu.v reg_file.v alu.v add_unit.v and_unit.v or_unit.v forward_unit.v shift_unit.v mult_unit.v dcache.v dmem_for_dcache.v icache.v imem_for_icache.v

```


4. **Run the simulation**
```bash
./cpu_sim

```


5. **View waveform in surfer**
```bash
surfer cpu_wavedata.vcd

```



## Signals to Analyze in Surfer

After opening the waveform, add and monitor these signals to verify your entire memory hierarchy behavior:

### System & CPU Basics

* `cpu_tb.CLK` (Clock signal)
* `cpu_tb.RESET` (System reset)
* `cpu_tb.PC` (Program Counter, verify stalling behavior during cache misses)
* `cpu_tb.INSTRUCTION` (The 32-bit instruction successfully fetched)
* `cpu_tb.mycpu.opcode` (Current Instruction Opcode)
* `cpu_tb.CPU_BUSYWAIT` (Master stall signal holding the CPU)

### Instruction Cache

* `cpu_tb.my_icache.hit` (Instruction Cache Hit Signal)
* `cpu_tb.my_icache.state` (iCache FSM State: 0 is IDLE, 1 is MEM_READ)
* `cpu_tb.icache_busywait` (Stall signal sent from iCache to CPU)
* `cpu_tb.imem_busywait` (Stall signal sent from Instruction Memory to iCache during the 80-cycle fetch)
* `cpu_tb.my_icache.mem_address` (Block Address being fetched from Instruction Memory)

### Data Cache

* `cpu_tb.my_dcache.hit` (Data Cache Hit Signal)
* `cpu_tb.my_dcache.state` (dCache FSM State)
* `cpu_tb.dcache_busywait` (Stall signal sent from dCache to CPU)
* `cpu_tb.mem_busywait` (Stall signal sent from Data Memory to dCache)

### Registers

* `cpu_tb.mycpu.my_registers.registers` (Array to view internal register states. For the factorial program, monitor register 1 for 'n', register 2 for the running total, and register 0 at the very end to verify the final 0x78 result).


# Waveform Markers and Signal Statuses

## 1. Initial iCache Miss (Fetching Setup Code)

- **Timestamp:** `0 ps` to `~660,000 ps`

### Signal Statuses to Identify
- `PC [31:0]` is stuck at `00000000`
- `my_icache.hit` = `0`
- `my_icache.state` = `1` *(MEM_READ state)*
- `icache_busywait` = `1` *(CPU is stalled)*

---

## 2. iCache Hits (Executing Setup Code)

- **Timestamp:** `~660,000 ps`

### Signal Statuses to Identify
- `my_icache.hit` spikes to `1`
- `icache_busywait` drops to `0`
- `PC [31:0]` advances quickly (`04` → `08` → `0c`)

---

## 3. iCache Miss (Fetching the Loop)

- **Timestamp:** `~660,000 ps` to `~1,320,000 ps`

### Signal Statuses to Identify
- `PC [31:0]` is stuck at `00000010` *(Start of Block 1)*
- `my_icache.hit` = `0`
- `my_icache.state` = `1`
- `icache_busywait` = `1`

---

## 4. iCache Hits (High-Speed Loop Execution)

- **Timestamp:** `~1,320,000 ps`

### Signal Statuses to Identify
- `my_icache.hit` repeatedly spikes to `1` *(several green lines clustered together)*
- `icache_busywait` stays mostly `0`
- `PC [31:0]` rapidly cycles between `10`, `14`, `18`, and `1c`

---

## 5. iCache Miss (Fetching the Exit Code)

- **Timestamp:** `~1,320,000 ps` to `~1,980,000 ps`

### Signal Statuses to Identify
- `PC [31:0]` is stuck at `00000020` *(Start of Block 2)*
- `my_icache.hit` = `0`
- `my_icache.state` = `1`
- `icache_busywait` = `1`

---

## 6. dCache Stall (`swi` Memory Write)

- **Timestamp:** `~2,000,000 ps` to `~2,600,000 ps`

### Signal Statuses to Identify
- `my_dcache.state` jumps to `1`
- `dcache_busywait` = `1` *(Data cache is now stalling the CPU, not the instruction cache)*
- `cpu_tb.mem_busywait` = `1` *(Main memory is processing the write)*

---

## 7. Final Result Captured

- **Timestamp:** `~2,660,000 ps`

### Signal Statuses to Identify
- `[0] [7:0]` changes from `00` to `78` *(Verification that `5! = 120` was calculated correctly)*