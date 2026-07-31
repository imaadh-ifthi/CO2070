`timescale 1ns/100ps

// direct-mapped data cache implementation with a write-back policy
// this module sits between the cpu, which accesses data one word (byte) at a time,
// and the main mem, which accesses data in 4-byte blocks

module dcache (
  input clock,
    input reset,
    
    // cpu interface signals
    //These match the standard mem module the CPU is already used to talking to
    input read,
	input write,
    input [7:0] address,
    input [7:0] writedata,
	output reg [7:0] readdata,
    output reg busywait,
	
    //main mem interface signals
    // these communicate with the block-based mem module during a cache miss
  output reg mem_read,
    output reg mem_write,
	output reg [5:0] mem_address,       // only 6 bits because mem ignores the 2-bit offset
  output reg [31:0] mem_writedata,    //Sending a full 4-byte block
    input [31:0] mem_readdata,          // receiving a full 4-byte block
    input mem_busywait                  // stall sig from main mem
);

  // cache internal mem arrays
    //We need 8 entries for this specific direct-mapped configuration
    
    //tracks if the data in the block is actually valid or just startup noise
    reg valid_array [0:7];
    //Tracks if the CPU has written to this block without updating main mem
    reg dirty_array [0:7];
	// stores the upper 3 bits of the addr to verify we have the correct mem location
    reg [2:0] tag_array [0:7];
    
  // stores the actual 4-byte payload fetched from main mem
    reg [31:0] data_array [0:7];

  // addr decoding
    //The 8-bit CPU addr must be sliced to route the data correctly
  // the lowest 2 bits determine which specific byte in the 4-byte block the cpu wants
  wire [1:0] offset = address[1:0];
	
    // the next 3 bits determine which of the 8 cache lines to look at
    wire [2:0] index = address[4:2];
    
  // The top 3 bits are the tag used for validation
    wire [2:0] tag = address[7:5];

    //Wires to hold the data extracted from the arrays at the current index
  wire valid, dirty;
    wire [2:0] stored_tag;
    wire [31:0] stored_block;

    // async read from the cache arrays
  // when the cpu addr changes, the index changes, and these wires immediately update
    //we add a #1 delay to simulate the physical time it takes to read from sram
	assign #1 valid = valid_array[index];
    assign #1 dirty = dirty_array[index];
	assign #1 stored_tag = tag_array[index];
    assign #1 stored_block = data_array[index];

    //Tag comparison to check if the requested addr is actually in the cache
    // the physical comparator logic takes #0.9 time units to evaluate
    // Since it waits for the stored_tag extraction (#1), this evaluates at #1.9 total
    wire tag_match;
  assign #0.9 tag_match = (tag == stored_tag) ? 1'b1 : 1'b0;

    // a cache hit only occurs if the tag matches and the data is valid
	wire hit;
    assign hit = valid && tag_match;

    // Data selection multiplexer
  //the cpu only asked for 1 byte, but we extracted 4 bytes (32 bits)
    //this logic uses the offset to grab the correct 8-bit slice
    //This happens asynchronously and overlaps with the tag comparison
	wire [7:0] selected_word;
    assign #1 selected_word = (offset == 2'b00) ? stored_block[7:0] :
                            (offset == 2'b01) ? stored_block[15:8] :
                              (offset == 2'b10) ? stored_block[23:16] :
	                                              stored_block[31:24];

  //Route the selected byte to the CPU's readdata port
  always @(selected_word) begin
	    readdata = selected_word;
    end
    // sig detection
    // figure out if the cpu is trying to read or write, and immediately set busywait
    //This tells the CPU to pause its pipeline while we figure out if we have a hit or miss
  reg readaccess, writeaccess;
    always @(read, write) begin
	    busywait = (read || write) ? 1'b1 : 1'b0;
	    readaccess = (read && !write) ? 1'b1 : 1'b0;
        writeaccess = (!read && write) ? 1'b1 : 1'b0;
  end
  // HIT //

    // fast path for cache hits
	// If we have a hit, we drop the busywait sig at exactly #1.9 time units
  // this allows the cpu to resume before its #2 time unit deadline
    always @(hit, readaccess, writeaccess) begin
      if (hit && (readaccess || writeaccess)) begin
            busywait = 1'b0;
	    end
    end

  // sync write logic for Write-Hits
    // We write to the cache on the rising edge of the clock to maintain stability
    always @(posedge clock) begin
        if (hit && writeaccess) begin
            // simulate the delay of physically writing to the cache sram
            #1; 
	        //write the cpu's data byte into the correct offset position within the block
            case (offset)
                2'b00: data_array[index][7:0] = writedata;
                2'b01: data_array[index][15:8] = writedata;
              2'b10: data_array[index][23:16] = writedata;
                2'b11: data_array[index][31:24] = writedata;
            endcase
            
	        //mark the block as dirty because it no longer matches main mem
	        // ensure valid is 1 just in case it wasn't already
            dirty_array[index] = 1'b1;
	        valid_array[index] = 1'b1;
        end
	end
	//miss //
	// Finite State Machine for Cache Miss Handling
    //This controls the multi-cycle process of talking to main mem
    
	//State definitions
    parameter IDLE = 2'b00, MEM_READ = 2'b01, MEM_WRITE = 2'b10;
    reg [1:0] state, next_state;

	// fsm next state logic
    //Decides where the state machine should go next based on current conditions
    always @(*) begin
        case(state)
            IDLE: begin
                //If the CPU requests mem but it's a miss, we must fetch it
              if ((readaccess || writeaccess) && !hit) begin
                    // if the current block in this slot is dirty, we can't just overwrite it
                    //We must write it back to mem first
                    if (dirty && valid)
                        next_state = MEM_WRITE; 
                  else
                      next_state = MEM_READ;  
              end else begin
                  next_state = IDLE;
                end
	        end
          //Clean Miss: IDLE -> MEM_READ (fetch new data) -> IDLE (done)
          // Dirty Miss: IDLE -> MEM_WRITE (save old data) -> MEM_READ (fetch new data) -> IDLE (done)

          MEM_READ: begin
              // stay in the read state until main mem drops its busywait sig
                if (!mem_busywait)
	                next_state = IDLE; 
                else
                    next_state = MEM_READ;
            end
          MEM_WRITE: begin
                //stay in the write state until mem finishes writing
              // once it finishes, we can finally proceed to fetch the block we actually want
                if (!mem_busywait)
                    next_state = MEM_READ; 
                else
                  next_state = MEM_WRITE;
	        end
	    endcase
    end
    //FSM State reg
  // updates the current state on every clock cycle
    always @(posedge clock) begin
        if (reset)
            //Force the FSM back to the default starting state
            //Using the non-blocking assignment (<=) ensures the physical reg is updated correctly
            state <= IDLE;
            
        else
            //If there is no reset, officially transition to the newly calculated state
	        state <= next_state;
	end

    //FSM Output Logic
  //Drives the control signals going out to main mem based on the current state
    always @(*) begin
      //Reset all control signals to zero by default to prevent accidental mem access
        mem_read = 0;
	    mem_write = 0;
        mem_address = 6'b0;
        mem_writedata = 32'b0;
        //(how the cache communicates with the main mem the exact moment a cache miss happens)
        case(state)
            IDLE: begin
                // We assert signals immediately in the IDLE state when a miss is detected
                // so that main mem can start working on the very next positive clock edge
	            if ((readaccess || writeaccess) && !hit) begin
                    if (dirty && valid) begin // dirty miss
                        mem_write = 1;
                        //Reconstruct the 6-bit block addr of the OLD data we are evicting
                        mem_address = {stored_tag, index};  // we are not sending the addr the cpu just asked for. we are sending the addr of the old data
	                    mem_writedata = stored_block;   // we send the actual 32-bit chunk of modified data to be saved
                    end else begin
                        mem_read = 1;
                        //construct the 6-bit block addr for the new data the cpu requested
	                    mem_address = {tag, index}; 
                  end
	            end
            end
            
            MEM_READ: begin
                //hold the read signals stable while waiting for mem
              mem_read = 1;
	            mem_address = {tag, index};
	        end
          
            MEM_WRITE: begin
	            //hold the write signals stable while waiting for mem
                mem_write = 1;
                mem_address = {stored_tag, index};
              mem_writedata = stored_block;
            end
        endcase
  end

    //update cache arrays after a successful mem fetch
  always @(posedge clock) begin
        // only trigger this when the mem fetch is fully complete
        if (state==MEM_READ && !mem_busywait) begin
          #1 ; //delay for sram write time
            
            // store the newly fetched 4-byte block
	        data_array[index] = mem_readdata;
          //Update the tag to reflect the new addr
            tag_array[index] = tag;
	        // mark the new data as valid and clean
            valid_array[index] = 1'b1;
	        dirty_array[index] = 0; 
        end
	end
    //sync Reset
    // clears out all cache arrays and resets the state machine on a system reset
    integer i;
  always @(posedge reset) begin
        if (reset) begin
            for (i=0; i<8; i=i+1) begin
	            valid_array[i] = 0;
                dirty_array[i] = 0;
                tag_array[i] = 0;
                data_array[i] = 0;
            end
            busywait = 0;
	        readaccess = 0;
            writeaccess = 0;
	        state = IDLE;
            next_state = IDLE;
        end
    end
endmodule