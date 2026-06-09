// lab 3 cpu testbench
// tests loadi, mov, add, sub, and, or

// basically simulating the instr memory here too
// 1024 bytes = 256 instructions max
// clock period is 8 

`include "cpu.v"
`include "alu.v"
`include "reg_file.v"

module cpu_tb;

    // testbench signals
    reg CLK, RESET;              
    wire [31:0] PC;              
    wire [31:0] INSTRUCTION;     

    // instruction mem 
    // 1024 bytes
    reg [7:0] instr_mem [0:1023];

    // fetch logic 
    // reading 4 bytes at a time based on PC
    // read delay is #2
    assign #2 INSTRUCTION = {instr_mem[PC[31:0]+3], instr_mem[PC[31:0]+2], 
                              instr_mem[PC[31:0]+1], instr_mem[PC[31:0]]};

    // hardcoded test program from the lab manual
    // opcodes:
    // loadi = 0x00
    // mov   = 0x01
    // add   = 0x02
    // sub   = 0x03
    // and   = 0x04
    // or    = 0x05

    initial begin
        // load instruction memory
        
        // inst 0: loadi r4, 5
        {instr_mem[10'd3], instr_mem[10'd2], instr_mem[10'd1], instr_mem[10'd0]}    = 32'b00000000_00000100_00000000_00000101;
        
        // inst 1: loadi r2, 9
        {instr_mem[10'd7], instr_mem[10'd6], instr_mem[10'd5], instr_mem[10'd4]}    = 32'b00000000_00000010_00000000_00001001;
        
        // inst 2: add r6, r4, r2
        {instr_mem[10'd11], instr_mem[10'd10], instr_mem[10'd9], instr_mem[10'd8]}  = 32'b00000010_00000110_00000100_00000010;
        
        // inst 3: mov r0, r6
        {instr_mem[10'd15], instr_mem[10'd14], instr_mem[10'd13], instr_mem[10'd12]} = 32'b00000001_00000000_00000110_00000000;
        
        // inst 4: loadi r1, 1
        {instr_mem[10'd19], instr_mem[10'd18], instr_mem[10'd17], instr_mem[10'd16]} = 32'b00000000_00000001_00000000_00000001;
        
        // inst 5: add r2, r2, r1
        {instr_mem[10'd23], instr_mem[10'd22], instr_mem[10'd21], instr_mem[10'd20]} = 32'b00000010_00000010_00000010_00000001;
        
        // inst 6: sub r3, r6, r4
        {instr_mem[10'd27], instr_mem[10'd26], instr_mem[10'd25], instr_mem[10'd24]} = 32'b00000011_00000011_00000110_00000100;
        
        // inst 7: and r5, r6, r2
        {instr_mem[10'd31], instr_mem[10'd30], instr_mem[10'd29], instr_mem[10'd28]} = 32'b00000100_00000101_00000110_00000010;
        
        // inst 8: or r7, r4, r1
        {instr_mem[10'd35], instr_mem[10'd34], instr_mem[10'd33], instr_mem[10'd32]} = 32'b00000101_00000111_00000100_00000001;
        
        // inst 9: loadi r3, -1
        {instr_mem[10'd39], instr_mem[10'd38], instr_mem[10'd37], instr_mem[10'd36]} = 32'b00000000_00000011_00000000_11111111;
        
        // inst 10: add r5, r3, r4
        {instr_mem[10'd43], instr_mem[10'd42], instr_mem[10'd41], instr_mem[10'd40]} = 32'b00000010_00000101_00000011_00000100;
        
        // inst 11: sub r7, r4, r2
        {instr_mem[10'd47], instr_mem[10'd46], instr_mem[10'd45], instr_mem[10'd44]} = 32'b00000011_00000111_00000100_00000010;
        
        // inst 12: loadi r0, 0xAA
        {instr_mem[10'd51], instr_mem[10'd50], instr_mem[10'd49], instr_mem[10'd48]} = 32'b00000000_00000000_00000000_10101010;
        
        // inst 13: loadi r1, 0x55
        {instr_mem[10'd55], instr_mem[10'd54], instr_mem[10'd53], instr_mem[10'd52]} = 32'b00000000_00000001_00000000_01010101;
        
        // inst 14: and r2, r0, r1
        {instr_mem[10'd59], instr_mem[10'd58], instr_mem[10'd57], instr_mem[10'd56]} = 32'b00000100_00000010_00000000_00000001;
        
        // inst 15: or r3, r0, r1
        {instr_mem[10'd63], instr_mem[10'd62], instr_mem[10'd61], instr_mem[10'd60]} = 32'b00000101_00000011_00000000_00000001;
        
        // inst 16: mov r4, r3
        {instr_mem[10'd67], instr_mem[10'd66], instr_mem[10'd65], instr_mem[10'd64]} = 32'b00000001_00000100_00000011_00000000;
    end

    // main cpu instance
    cpu mycpu(PC, INSTRUCTION, CLK, RESET);

    // sim stuff
    initial begin
        // dumping everything to vcd for gtkwave
        $dumpfile("cpu_wavedata.vcd");
        $dumpvars(0, cpu_tb);
        $dumpvars(0, mycpu.myreg.registers[0]);
        $dumpvars(0, mycpu.myreg.registers[1]);
        $dumpvars(0, mycpu.myreg.registers[2]);
        $dumpvars(0, mycpu.myreg.registers[3]);
        $dumpvars(0, mycpu.myreg.registers[4]);
        $dumpvars(0, mycpu.myreg.registers[5]);
        $dumpvars(0, mycpu.myreg.registers[6]);
        $dumpvars(0, mycpu.myreg.registers[7]);
        
        CLK = 1'b0;
        RESET = 1'b0;
        
        // kick off with a reset pulse
        #1 RESET = 1'b1;    
        #10 RESET = 1'b0;   
        
        // let it run for a bit
        // 17 insts * 8 units = 136, but let's give it 500 just to be safe
        #500;
        
        // test if reset actually works by throwing it mid-execution
        RESET = 1'b1;
        #10 RESET = 1'b0;
        
        // run a little more
        #200;
        
        $finish;
    end

    // clock generator - period is 8 so flip every 4
    always
        #4 CLK = ~CLK;

    // debug printout at each clock edge
    initial begin
        $monitor("Time=%0t | CLK=%b RESET=%b | PC=%0d | INSTRUCTION=%b | OPCODE=%b | RD=%0d RT=%0d RS=%0d | ALUOP=%b | WRITEENABLE=%b | ALURESULT=%0d",
                 $time, CLK, RESET, PC, INSTRUCTION, 
                 mycpu.OPCODE, mycpu.WRITEREG, mycpu.READREG1, mycpu.READREG2,
                 mycpu.ALUOP, mycpu.WRITEENABLE, mycpu.ALURESULT);
    end

endmodule
