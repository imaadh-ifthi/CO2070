# Performance Comparison Report: Cache vs Cache-less System

## 1. Architecture Overview
**Cache-less System (Lab 5):**
The CPU directly interfaced with the Data Memory. Every memory access (read or write) incurred a constant delay of `#28` time units, causing the CPU to stall for a significant number of cycles on every memory instruction (`lwd`, `lwi`, `swd`, `swi`).

**Cache System (Lab 6):**
A Data Cache module was introduced between the CPU and the Data Memory. The memory now operates on 4-Byte blocks with an increased latency of `#40` time units. The cache exploits the principle of locality to serve frequent accesses rapidly.
- **Hit Latency:** `#1.9` time units for read hits, well within the `#2` limit, allowing the CPU to proceed without stalling. Write hits execute in 1 clock cycle without stalling the CPU.
- **Miss Latency:** Incurs a read-miss penalty (fetching a 4-Byte block from memory) or write-miss penalty (writing back dirty blocks and fetching new blocks). The latency involves the `#40` time units for memory access plus the `#1` cache update time.

## 2. Performance Analysis
The test program (`cpu_tb.v`) includes multiple instructions, loops, and data memory accesses.

**Without Cache:**
Every single `swi`, `swd`, `lwi`, and `lwd` instruction stalls the pipeline. If a program iterates through an array of data, each iteration pays the `#28` latency penalty repeatedly.

**With Cache:**
1. **Compulsory Misses:** The first time a block is accessed, the CPU experiences a miss penalty of memory read. For a 4-byte block, this brings 4 words into the cache at once.
2. **Subsequent Hits:** Subsequent accesses to the same word or adjacent words within the 4-byte block result in a cache hit. The hit is resolved in `#1.9` time units asynchronously, meaning the `BUSYWAIT` signal drops early, and the CPU does not stall *at all*.
3. **Write-back Efficiency:** By using a write-back policy, consecutive writes to the same block (e.g., updating a variable in memory) only modify the cache. The expensive `#40` write to memory is deferred until the block is evicted, drastically reducing write traffic.

## 3. Conclusion
The memory hierarchy with the Data Cache significantly accelerates program execution, especially for programs with high spatial and temporal locality. Despite the increased raw memory latency (`#40` vs `#28`), the cache reduces the *average memory access time* (AMAT) substantially since hits incur zero CPU stall cycles. This optimization achieves the objective of "making the common case fast" and highlights the critical role of caches in modern computer architecture.
