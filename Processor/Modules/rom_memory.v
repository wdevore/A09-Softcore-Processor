`default_nettype none
`ifdef SIMULATE
`timescale 1ns/1ps
`endif

// --------------------------------------------------------------------------
// 256x16 BRAM memory
// ROM
// --------------------------------------------------------------------------
// The path to the data file is relative to the test bench (TB).
// If the TB is run from this directory then the path would be "ROM.dat"
// `define MEM_CONTENTS "ROM.dat"
// Otherwise it is relative to the TB.
`define ROM_PATH "../../roms/"
`define ROM_EXTENSION ".dat"
`define MEM_CONTENTS "Cylon"

module RomMemory
#(
    parameter WORDS = 8,    // 2^WORDS
    parameter DATA_WIDTH = 16)
(
    input wire clk_i,                         // neg-edge
    input wire [WORDS-1:0] address_i,    // Memory address_i
    output reg [DATA_WIDTH-1:0] data_o        // Memory register data output (ASync)
);

// Memory bank
reg [DATA_WIDTH-1:0] mem [0:(1<<WORDS)-1]; // The actual memory

// Debugging
`ifdef SIMULATE
integer index;
`endif
    
initial begin
    // Example of clearing remaining memory
    // for(index = 5; index < 20; index = index + 1)
    //     mem[index] = 16'h0000;

    // I can explicitly specify the start/end address_i in order to avoid the
    // warning: "WARNING: memory.v:23: $readmemh: Standard inconsistency, following 1364-2005."
    //     $readmemh (`MEM_CONTENTS, mem, 'h00, 'h04);
    `ifdef USE_ROM
        // NOTE:
        // `` - The double-backtick(``) is essentially a token delimiter.
        // It helps the compiler clearly differentiate between the Argument and
        // the rest of the string in the macro text.
        // See: https://www.systemverilog.io/macros

        // This only works with BRAM. It generally doesn't work with SPRAM constructs.
        $display("Using ROM: %s", `MEM_CONTENTS);
        $readmemh({`ROM_PATH, `MEM_CONTENTS, `ROM_EXTENSION}, mem);  // , 0, 6
    `elsif USE_STATIC
        mem[0] = 16'h00ff;       // Simple data for testing
        mem[1] = 16'h00f0;
        mem[2] = 16'h000f;
        mem[255] = 16'h0001;
    `endif

    `ifdef SIMULATE
        // Example of displaying contents
        $display("------- Top MEM contents ------");
        for(index = 0; index < 15; index = index + 1)
            $display("memory[%d] = %b <- %h", index[7:0], mem[index], mem[index]);

        // Display the vector data residing at the bottom of memory
        $display("------- Bottom MEM contents ------");
        for(index = 250; index < 256; index = index + 1)
            $display("memory[%d] = %b <- %h", index[7:0], mem[index], mem[index]);
    `endif
end

// --------------------------------
// ROM
// --------------------------------
always @(negedge clk_i) begin
    `ifdef SIMULATE
        $display("%d READ data at Addr(0x%h), Mem(0x%h), data_i(0x%h)", $stime, address_i, mem[address_i], data_i);
    `endif
    data_o <= mem[address_i];
end

endmodule

