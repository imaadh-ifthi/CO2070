// reg file for lab 2 part 2 (reusing for lab 3)
// 8x8 register file - 8 regs, 8 bits each
// 2 async read ports, 1 sync write port

module reg_file (IN, OUT1, OUT2, INADDRESS, OUT1ADDRESS, OUT2ADDRESS, WRITE, CLK, RESET);

    // data in port
    input [7:0] IN;

    // addresses (3 bits since we have 8 registers)
    input [2:0] INADDRESS;    // where to write to
    input [2:0] OUT1ADDRESS;  // read port 1
    input [2:0] OUT2ADDRESS;  // read port 2

    // control stuff
    input WRITE;   // write enable
    input CLK;     // clock
    input RESET;   // clears everything

    // outputs for reading
    output [7:0] OUT1;
    output [7:0] OUT2;

    // the actual registers array
    reg [7:0] registers [7:0];

    integer i; // for the loop below

    // read ports - async but with #2 delay as per lab manual
    assign #2 OUT1 = registers[OUT1ADDRESS];
    assign #2 OUT2 = registers[OUT2ADDRESS];

    // write and reset happen on posedge
    // reset has higher priority obviously
    always @(posedge CLK) begin

        if (RESET) begin
            // clear em all
            #1;
            for (i = 0; i < 8; i = i + 1) begin
                registers[i] <= 8'b00000000;
            end
        end

        else if (WRITE) begin
            // write input to the target register with #1 delay
            #1 registers[INADDRESS] <= IN;
        end

    end

endmodule
