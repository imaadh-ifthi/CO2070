`timescale 1ns/100ps
// computer architecture (co2070)
//Design: Testbench of Integrated CPU with inst & Data Caches

`include "cpu.v"
`include "alu.v"
`include "forward_unit.v"
`include "add_unit.v"
`include "and_unit.v"
`include "or_unit.v"
`include "shift_unit.v"
`include "mult_unit.v"
`include "reg_file.v"
`include "control_unit.v"
`include "mux_2x1_8bit.v"
`include "pc_unit.v"
`include "twos_complement.v"
`include "dmem_for_dcache.v"
`include "dcache.v"
`include "icache.v"
`include "imem_for_icache.v"

module cpu_tb;

    reg CLK, RESET;
    wire [31:0] PC;
    wire [31:0] INSTRUCTION;
    
    // master cpu stall sig
    wire CPU_BUSYWAIT;
    wire icache_busywait;
    wire dcache_busywait;
    
    // CPU stalls if EITHER the inst Cache OR Data Cache is busy
    assign CPU_BUSYWAIT = icache_busywait | dcache_busywait;

    // cpu data mem wires
    wire READ, WRITE;
    wire [7:0] ADDRESS, WRITEDATA, READDATA;

    /* -----
       CPU
       ----- */
    cpu mycpu(
        .PC(PC), 
        .INSTRUCTION(INSTRUCTION), 
        .CLK(CLK), 
        .RESET(RESET),
        .MEM_READDATA(READDATA),
        .BUSYWAIT(CPU_BUSYWAIT),
        .MEM_READ(READ),
        .MEM_WRITE(WRITE),
        .MEM_ADDRESS(ADDRESS),
        .MEM_WRITEDATA(WRITEDATA)
    );

    /* ----------------
       INSTRUCTION CACHE
       ---------------- */
    wire imem_read, imem_busywait;
    wire [5:0] imem_address;
    wire [127:0] imem_readdata;

    icache my_icache (
        .clock(CLK),
        .reset(RESET),
        .pc(PC[9:0]),
        .instruction(INSTRUCTION),
        .busywait(icache_busywait),
        .mem_read(imem_read),
        .mem_address(imem_address),
        .mem_readdata(imem_readdata),
        .mem_busywait(imem_busywait)
    );

    /* ----------------
       INSTRUCTION MEMORY
       ---------------- */
    instruction_memory my_inst_memory (
        .clock(CLK),
        .read(imem_read),
        .address(imem_address),
        .readinst(imem_readdata),
        .busywait(imem_busywait)
    );
    
    /* -----------
       DATA CACHE
       ----------- */
    wire mem_read, mem_write, mem_busywait;
    wire [5:0] mem_address;
    wire [31:0] mem_writedata, mem_readdata;
    
    dcache my_dcache (
        .clock(CLK),
        .reset(RESET),
        .read(READ),
        .write(WRITE),
        .address(ADDRESS),
        .writedata(WRITEDATA),
        .readdata(READDATA),
        .busywait(dcache_busywait),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .mem_address(mem_address),
        .mem_writedata(mem_writedata),
        .mem_readdata(mem_readdata),
        .mem_busywait(mem_busywait)
    );

    /* ----------------
       MAIN DATA MEMORY
       ---------------- */
    data_memory my_data_memory (
        .clock(CLK),
        .reset(RESET),
        .read(mem_read),
        .write(mem_write),
        .address(mem_address),
        .writedata(mem_writedata),
        .readdata(mem_readdata),
        .busywait(mem_busywait)
    );

    initial begin
        $dumpfile("cpu_wavedata.vcd");
        $dumpvars(0, cpu_tb);
        //explicitly dump all registers
        $dumpvars(0, mycpu.myreg.registers[0]);
        $dumpvars(0, mycpu.myreg.registers[1]);
        $dumpvars(0, mycpu.myreg.registers[2]);
        $dumpvars(0, mycpu.myreg.registers[3]);
        $dumpvars(0, mycpu.myreg.registers[4]);
        $dumpvars(0, mycpu.myreg.registers[5]);
        $dumpvars(0, mycpu.myreg.registers[6]);
        $dumpvars(0, mycpu.myreg.registers[7]);
        
        // Initial setup
        CLK = 1'b0;
        RESET = 1'b0;
        #1;
        RESET = 1'b1;
        #5; 
        RESET = 1'b0;

        // extended simulation time heavily to account for complex programs and massive mem fetch cycles
        #8000 
        $finish;
    end
  
    always
        #4 CLK = ~CLK;
        
endmodule