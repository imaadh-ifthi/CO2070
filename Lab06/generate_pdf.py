import sys
from fpdf import FPDF

class PDF(FPDF):
    def header(self):
        self.set_font('Arial', 'B', 12)
        self.cell(0, 10, 'CO2070 Lab 6 Answers', 0, 1, 'C')

    def footer(self):
        self.set_y(-15)
        self.set_font('Arial', 'I', 8)
        self.cell(0, 10, f'Page {self.page_no()}', 0, 0, 'C')

pdf = PDF()
pdf.add_page()

pdf.set_font('Arial', 'B', 12)
pdf.cell(0, 10, '1. Cache Miss Handling & Write Policies', 0, 1)
pdf.set_font('Arial', '', 11)
text1 = (
    "Read Miss:\n"
    "When a read miss occurs, the cache controller checks the dirty bit of the existing block in the indexed cache line. "
    "If the block is dirty, a write-back is performed first, writing the modified block to the main memory. "
    "Then, the requested missing block is fetched from the main memory and placed into the cache, updating "
    "the valid bit to 1 and dirty bit to 0. Finally, the requested word is sent to the CPU.\n\n"
    "Write Miss:\n"
    "Similar to a read miss, if the existing block is dirty, it is written back to the main memory. "
    "The new missing block is then fetched from the main memory and allocated in the cache. "
    "Once the block is in the cache, the CPU's write access proceeds as a 'write-hit', modifying the specific "
    "word in the cache and setting the dirty bit to 1.\n\n"
    "Write Policies:\n"
    "- Write-Back: The cache is updated on a write, and the dirty bit is set. Main memory is only updated when "
    "the dirty block is evicted. This system implements a write-back policy.\n"
    "- Write-Through: Every write updates both the cache and the main memory simultaneously, ensuring memory is "
    "always up-to-date but incurring high memory traffic.\n\n"
    "Flowchart Process:\n"
    "1. CPU requests access -> 2. Check Tag & Valid bit.\n"
    "3. If Hit -> Serve request (read sends data, write modifies cache & sets dirty).\n"
    "4. If Miss -> Check Dirty bit of existing block.\n"
    "5. If Dirty == 1 -> Write-back existing block to memory.\n"
    "6. Fetch new block from memory -> Update cache (Valid=1, Dirty=0).\n"
    "7. Serve original request."
)
pdf.multi_cell(0, 7, text1)
pdf.ln(5)

pdf.set_font('Arial', 'B', 12)
pdf.cell(0, 10, '2. Cache Mapping Mechanism & Address Format', 0, 1)
pdf.set_font('Arial', '', 11)
text2 = (
    "The required cache mapping mechanism is Direct-Mapped Cache. Since the cache has 8 blocks and each block "
    "is 4 Bytes, the 8-bit memory address is partitioned as follows:\n"
    "- Offset: 2 bits (Bits 1:0) to select 1 of 4 bytes within a block.\n"
    "- Index: 3 bits (Bits 4:2) to select 1 of 8 blocks in the cache.\n"
    "- Tag: 3 bits (Bits 7:5) to identify the memory origin of the block.\n\n"
    "Bit Format:\n"
    "[ 7 | 6 | 5 ] [ 4 | 3 | 2 ] [ 1 | 0 ]\n"
    "    Tag          Index       Offset"
)
pdf.multi_cell(0, 7, text2)
pdf.ln(5)

pdf.set_font('Arial', 'B', 12)
pdf.cell(0, 10, '3. Cache Table Trace', 0, 1)
pdf.set_font('Arial', '', 11)
text3 = (
    "Final Cache State after the given instructions:\n"
    "Index 0:\n"
    "  - Valid: 1\n"
    "  - Dirty: 1\n"
    "  - Tag: 001 (binary for 1)\n"
    "  - Data: [Byte0=0x08, Byte1=0x00, Byte2=0x00, Byte3=0x00] (from memory address 0x20)\n\n"
    "Index 1:\n"
    "  - Valid: 1\n"
    "  - Dirty: 1\n"
    "  - Tag: 000 (binary for 0)\n"
    "  - Data: [Byte0=0x00, Byte1=0x00, Byte2=0x00, Byte3=0x08] (from memory address 0x07)\n\n"
    "Indices 2 through 7:\n"
    "  - Valid: 0\n"
    "  - Dirty: 0\n"
    "  - Tag: 000\n"
    "  - Data: [0x00, 0x00, 0x00, 0x00]\n"
)
pdf.multi_cell(0, 7, text3)
pdf.ln(5)

pdf.set_font('Arial', 'B', 12)
pdf.cell(0, 10, '4. FSM Skeleton Completion', 0, 1)
pdf.set_font('Arial', '', 11)
text4 = (
    "To complete the FSM flowchart image for the Cache Controller:\n"
    "1. Add a new state bubble named 'MEM_WRITE'.\n"
    "2. Draw an arrow from 'IDLE' to 'MEM_WRITE' with the condition: '(read=1 || write=1) && dirty=1 && hit=0'.\n"
    "3. Draw a self-looping arrow on 'MEM_WRITE' with the condition: 'mem_busy = 1'.\n"
    "4. Draw an arrow from 'MEM_WRITE' to 'MEM_READ' with the condition: 'mem_busy = 0'.\n"
    "5. Ensure the arrow from 'MEM_READ' back to 'IDLE' has the condition: 'mem_busy = 0'.\n"
    "6. Update the self-loop on 'IDLE' to also include the hit condition: '(read=0 && write=0) || hit=1'."
)
pdf.multi_cell(0, 7, text4)

pdf.output('groupXX_eYY_ZZZ.pdf')
