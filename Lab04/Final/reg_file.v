// register file module
// 8 registers each 8 bits wide
// can read 2 regs at the same time (async) and write 1 (sync)

module reg_file (IN, OUT1, OUT2, INADDRESS, OUT1ADDRESS, OUT2ADDRESS, WRITE, CLK, RESET);

    input [7:0] IN;               // data to write

    // 3 bit addresses cos we only have 8 regs (2^3 = 8)
    input [2:0] INADDRESS;        // write destination
    input [2:0] OUT1ADDRESS;      // first read address
    input [2:0] OUT2ADDRESS;      // second read address

    input WRITE;    // write enable signal
    input CLK;
    input RESET;    // resets all regs to 0 (synchronous)

    // two output ports so we can read two registers at once
    output [7:0] OUT1;
    output [7:0] OUT2;

    // the register array itself
    reg [7:0] registers [7:0];

    integer i;  // need this for the reset loop. verilog loops are weird

    // async reads with #2 delay
    // updates whenever the address changes or when a register gets written
    assign #2 OUT1 = registers[OUT1ADDRESS];
    assign #2 OUT2 = registers[OUT2ADDRESS];

    // sync write/reset on positive edge
    // reset comes first if both are high
    always @(posedge CLK) begin

        if (RESET) begin
            #1;
            for (i = 0; i < 8; i = i + 1) begin
                registers[i] <= 8'b00000000;
            end
        end

        else if (WRITE) begin
            #1 registers[INADDRESS] <= IN;  // write with delay
        end

    end

endmodule
