module reg_file (IN, OUT1, OUT2, INADDRESS, OUT1ADDRESS, OUT2ADDRESS, WRITE, CLK, RESET);

    //Input Ports

    // 8 bit data input that we write into a register
    input [7:0] IN;

    //3 bit addresses to select which register to access
    input [2:0] INADDRESS; //register we write to
    input [2:0] OUT1ADDRESS; // register to read from for port 1
    input [2:0] OUT2ADDRESS; //register to read from for port 2

    //control signals
    input WRITE; // enables writing
    input CLK;
    input RESET; // clears all registers when high

    //Output ports
    // two 8 bit outputs to read two registers at the same time
    output [7:0] OUT1;
    output [7:0] OUT2;

    // the register file itself
    //8 registers each 8 bits wide
    reg [7:0] registers [7:0];

    integer i; // for the reset loop

    // Asynchronous reading
    // outputs update whenever address changes, no need to wait for clock
    // #2 is the read delay
    assign #2 OUT1 = registers[OUT1ADDRESS];
    assign #2 OUT2 = registers[OUT2ADDRESS];

    //synchronous write and reset
    // runs on rising edge of clock only
    // reset takes priority over write
    always @(posedge CLK) begin

        if (RESET) begin
            // clear all registers to zero
            #1;
            for (i = 0; i < 8; i = i + 1) begin
                registers[i] <= 8'b00000000;
            end
        end

        else if (WRITE) begin
            // write IN to the register at INADDRESS
            #1 registers[INADDRESS] <= IN;
        end

    end

endmodule