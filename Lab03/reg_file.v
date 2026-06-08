// CO2070 Computer Architecture - Lab 2 Part 2
// Module: 8x8 Register File
// 8 registers, each 8 bits wide
// Two asynchronous read ports, one synchronous write port
// Synchronous reset clears all registers

module reg_file (IN, OUT1, OUT2, INADDRESS, OUT1ADDRESS, OUT2ADDRESS, WRITE, CLK, RESET);

    // ============================================================
    // Port Declarations
    // ============================================================

    // 8-bit data input for writing into a register
    input [7:0] IN;

    // 3-bit addresses to select which register to access
    input [2:0] INADDRESS;    // register to write to (destination)
    input [2:0] OUT1ADDRESS;  // register to read from for port 1
    input [2:0] OUT2ADDRESS;  // register to read from for port 2

    // Control signals
    input WRITE;   // enables writing when high
    input CLK;     // clock signal
    input RESET;   // clears all registers when high (synchronous)

    // Two 8-bit output ports to read two registers simultaneously
    output [7:0] OUT1;
    output [7:0] OUT2;

    // ============================================================
    // Register File Storage
    // ============================================================
    // 8 registers, each 8 bits wide
    reg [7:0] registers [7:0];

    integer i; // loop variable for reset

    // ============================================================
    // Asynchronous Read
    // ============================================================
    // Outputs update whenever address or register content changes
    // #2 is the read delay (2 time units)
    assign #2 OUT1 = registers[OUT1ADDRESS];
    assign #2 OUT2 = registers[OUT2ADDRESS];

    // ============================================================
    // Synchronous Write and Reset (on positive clock edge)
    // ============================================================
    // Reset takes priority over write
    always @(posedge CLK) begin

        if (RESET) begin
            // Clear all 8 registers to zero
            #1;
            for (i = 0; i < 8; i = i + 1) begin
                registers[i] <= 8'b00000000;
            end
        end

        else if (WRITE) begin
            // Write IN to the register at INADDRESS after #1 delay
            #1 registers[INADDRESS] <= IN;
        end

    end

endmodule
