`timescale 1ns/100ps

//design: direct-mapped inst cache
//architecture: 128 bytes total, 16-byte blocks (8 entries)

module icache (
    input clock,
    input reset,
    // cpu interface
    input [9:0] pc,                 //10-bit addr from CPU Program Counter
    output reg [31:0] instruction,  // 4-Byte inst word sent to CPU
    output reg busywait,            // stall sig sent to cpu
  
	//mem interface
	output reg mem_read,            //read enable sent to inst mem
    output reg [5:0] mem_address,   // 6-bit block addr sent to inst mem
    input [127:0] mem_readdata,     //16-Byte block fetched from inst mem
  input mem_busywait              // stall sig from inst mem
);

  //Cache Storage Arrays (8 blocks)
    reg valid_array [0:7];
    reg [2:0] tag_array [0:7];
    reg [127:0] data_array [0:7];   // 16-byte data block per entry
	// addr decoding
  //cpu word addr is 10 bits where lsbs (bits 1 and 0) are always 00
    wire [1:0] offset = pc[3:2];    // word selection within the 16-byte block
    wire [2:0] index  = pc[6:4];    //cache entry mapping
    wire [2:0] tag    = pc[9:7];    //Tag comparison

	//async extraction (includes #1 time unit latency)
  wire valid;
    wire [2:0] stored_tag;
    wire [127:0] stored_block;

	assign #1 valid = valid_array[index];
	assign #1 stored_tag = tag_array[index];
    assign #1 stored_block = data_array[index];
    // async tag comparison (includes #0.9 time unit latency)
	wire tag_match;
    assign #0.9 tag_match = (tag==stored_tag) ? 1'b1 : 1'b0;
    // Hit Detection
    wire hit;
    assign hit = valid && tag_match;
    //word selection for read hits (includes #1 latency parallel to tag compare)
    wire [31:0] selected_word;
  assign #1 selected_word = (offset == 2'b00) ? stored_block[31:0]   :
                              (offset==2'b01) ? stored_block[63:32]  :
                              (offset == 2'b10) ? stored_block[95:64]  :
                                                stored_block[127:96];
    // forward the selected word to the cpu
    always @(selected_word) begin
        instruction = selected_word;
	end

    /* --------------------------------------
       CPU Stall Control
  -------------------------------------- */

    //detect a new inst fetch request
    //Immediately stall the CPU until the cache lookup completes
    always @(pc) begin
	    busywait = 1'b1;
        // Wait for cache indexing (#1) and tag comparison (#0.9)
	    #1.9;
        //de-assert busywait immediately on a cache hit
        if (hit) begin
	        busywait = 1'b0;
        end
  end
	// de-assert busywait after a cache miss is serviced
  // 'hit' becomes high once the fetched block is written into the cache
    always @(hit) begin
	    if (hit) begin
            busywait = 1'b0;
	    end
	end

    /* --------------------------------------
     CACHE MISS HANDLING (FSM)
    -------------------------------------- */

    //FSM States
    parameter IDLE = 0, MEM_READ = 1;
  reg state, next_state;
    // next state logic
    always @(*) begin
	    case(state)
            IDLE: begin
                //Cache miss detected
                if (!hit)
                    next_state = MEM_READ;
              else
                    next_state = IDLE;
          end

            MEM_READ: begin
	            if (!mem_busywait)
                  next_state = IDLE; // fetch completed
                else
	                next_state = MEM_READ;
            end
        endcase
    end

    //state reg update
    always @(posedge clock) begin
        if (reset)
            state <= IDLE;
        else
          state <= next_state;
	end

  //mem control sig logic
    always @(*) begin
        // Default outputs
        mem_read = 0;
        mem_address = 6'b0;
        // initiate a mem read on a cache miss
        if (state==IDLE && !hit) begin
            mem_read = 1'b1;
            mem_address = {tag, index};
        end

	    //continue asserting mem read while waiting for the block
      else if (state == MEM_READ) begin
            mem_read = 1;
	        mem_address = {tag, index};
	    end
    end

    //Cache Write-In after mem Fetch
  always @(posedge clock) begin
	    if (state==MEM_READ && !mem_busywait) begin
            #1; //artificial latency for writing into cache arrays

            // Update cache entry with the fetched mem block
	        data_array[index] = mem_readdata;
	        // Store corresponding tag
	        tag_array[index] = tag;

          // Mark the cache entry as valid
            valid_array[index] = 1;
      end
  end
    // initialization and reset handling
    integer i;
  always @(posedge reset) begin
        if (reset) begin

            //Invalidate all cache entries
            for (i = 0; i < 8; i = i + 1) begin
                valid_array[i] = 1'b0;
                tag_array[i] = 3'b0;
              data_array[i] = 128'b0;
            end

	        //reset cpu interface signals
	        busywait = 0;
            //Reset FSM
            state = IDLE;
            next_state = IDLE;
	    end
  end

endmodule