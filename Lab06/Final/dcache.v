`timescale 1ns/100ps

/*
Module  : Data Cache 
Author  : Group XX
Date    : 

Description	:
Data Cache for CO2070 Lab 6.
*/

module dcache (
    input clock,
    input reset,
    input read,
    input write,
    input [7:0] address,
    input [7:0] writedata,
    output [7:0] readdata,
    output reg busywait,
    
    // memory signals
    output reg mem_read,
    output reg mem_write,
    output reg [5:0] mem_address,
    output reg [31:0] mem_writedata,
    input [31:0] mem_readdata,
    input mem_busywait
);

    // Cache memory arrays (8 blocks)
    // - valid_array: Tracks if the block contains actual data
    // - dirty_array: Tracks if the block has been modified (Write-back policy)
    // - tag_array: Stores the upper bits of the address for matching
    // - data_array: Stores the actual 32-bit (4-Byte) block of data
    reg valid_array [7:0];
    reg dirty_array [7:0];
    reg [2:0] tag_array [7:0];
    reg [31:0] data_array [7:0];

    // Address splitting
    // Since block size is 4 Bytes, 2 bits are needed for offset (address[1:0])
    // Since there are 8 blocks, 3 bits are needed for index (address[4:2])
    // The remaining 3 bits act as the tag (address[7:5])
    wire [1:0] offset = address[1:0];
    wire [2:0] index = address[4:2];
    wire [2:0] tag = address[7:5];

    // Combinational reads with artificial indexing latency of #1
    // Extracts the valid bit, dirty bit, tag, and full 32-bit block asynchronously corresponding to the index
    wire valid_out, dirty_out;
    wire [2:0] tag_out;
    wire [31:0] block_out;
    
    assign #1 valid_out = valid_array[index];
    assign #1 dirty_out = dirty_array[index];
    assign #1 tag_out = tag_array[index];
    assign #1 block_out = data_array[index];

    // Tag comparison with artificial latency of #0.9
    wire tag_match;
    assign #0.9 tag_match = (tag_out == tag) ? 1 : 0;
    
    // Hit detection
    wire hit;
    assign hit = tag_match && valid_out;

    // Data word selection for read-hit with latency of #1
    reg [7:0] readdata_reg;
    always @(block_out, offset) begin
        #1;
        case(offset)
            2'b00: readdata_reg = block_out[7:0];
            2'b01: readdata_reg = block_out[15:8];
            2'b10: readdata_reg = block_out[23:16];
            2'b11: readdata_reg = block_out[31:24];
        endcase
    end
    assign readdata = readdata_reg;

    /* Cache Controller FSM Start */
    // The FSM handles cache misses. 
    // IDLE: Serving hits. If miss occurs, check dirty bit to determine next state.
    // MEM_READ: Fetching new block from Data Memory.
    // MEM_WRITE: Writing modified (dirty) block back to Data Memory before eviction (Write-back).
    parameter IDLE = 3'b000, MEM_READ = 3'b001, MEM_WRITE = 3'b010;
    reg [2:0] state, next_state;

    // busywait logic
    always @(*) begin
        if (state == IDLE) begin
            // Assert busywait when read or write is active and it's a miss
            if ((read || write) && !hit)
                busywait = 1;
            else
                busywait = 0;
        end else begin
            // FSM holds busywait high until miss is resolved
            busywait = 1;
        end
    end

    // Next state logic
    always @(*) begin
        case(state)
            IDLE: begin
                if ((read || write) && !hit) begin
                    if (dirty_out && valid_out)
                        next_state = MEM_WRITE;
                    else
                        next_state = MEM_READ;
                end else begin
                    next_state = IDLE;
                end
            end
            MEM_WRITE: begin
                // wait until memory de-asserts busywait
                if (!mem_busywait)
                    next_state = MEM_READ;
                else
                    next_state = MEM_WRITE;
            end
            MEM_READ: begin
                // wait until memory de-asserts busywait
                if (!mem_busywait)
                    next_state = IDLE;
                else
                    next_state = MEM_READ;
            end
            default: next_state = IDLE;
        endcase
    end

    // Output logic
    always @(*) begin
        mem_read = 0;
        mem_write = 0;
        mem_address = 6'b0;
        mem_writedata = 32'b0;

        case(state)
            MEM_READ: begin
                mem_read = 1;
                mem_address = {tag, index};
                mem_writedata = 32'dx;
            end
            MEM_WRITE: begin
                mem_write = 1;
                mem_address = {tag_out, index};
                mem_writedata = block_out;
            end
        endcase
    end

    // Sequential logic for state transitioning and cache updating
    integer i;
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            for (i = 0; i < 8; i = i + 1) begin
                valid_array[i] <= 0;
                dirty_array[i] <= 0;
                tag_array[i] <= 0;
                data_array[i] <= 0;
            end
        end else begin
            state <= next_state;
            
            // Write to cache upon fetch completion
            if (state == MEM_READ && !mem_busywait) begin
                #1;
                data_array[index] <= mem_readdata;
                tag_array[index] <= tag;
                valid_array[index] <= 1;
                dirty_array[index] <= 0;
            end
            
            // Write-hit logic
            // "cache controller can write the data at the positive edge of the clock (at the start of the next clock cycle)"
            // The hit is resolved in #1.9 time units, so it writes on the next clock edge without stalling
            if (state == IDLE && write && hit) begin
                #1; // Artificial latency for writing to the cache
                case(offset)
                    2'b00: data_array[index][7:0]   <= writedata;
                    2'b01: data_array[index][15:8]  <= writedata;
                    2'b10: data_array[index][23:16] <= writedata;
                    2'b11: data_array[index][31:24] <= writedata;
                endcase
                dirty_array[index] <= 1;
            end
        end
    end

endmodule
