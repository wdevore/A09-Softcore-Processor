`default_nettype none

// --------------------------------------------------------------------------
// Register file 
// --------------------------------------------------------------------------

module RegisterFile
#(
    parameter DATA_WIDTH = 16,
    parameter WORDS = 8,
    parameter SELECT_SIZE = 3)   // 3bits = 8 = WORDS
(
    input wire clk_i,
    input wire reg_we_i,
    input wire [DATA_WIDTH-1:0] data_i,        // Data input
    // Destination reg write, Write = Active Low
    input wire [SELECT_SIZE-1:0] reg_dst_i,    // Reg destination select
    input wire [SELECT_SIZE-1:0] reg_src1_i,   // Source #1 select
    input wire [SELECT_SIZE-1:0] reg_src2_i,   // Source #2 select
    output wire [DATA_WIDTH-1:0] src1_o,       // Source 1 output
    output wire [DATA_WIDTH-1:0] src2_o        // Source 2 output
);

// The Registers
reg [DATA_WIDTH-1:0] bank [(1<<WORDS)-1:0];

// An alternative is to sync the outputs. This is Async
// See: "Digital Systems Design Using Verilog by Charles Roth, Lizy K. John, Byeong Kil Lee 2016 MIPS CPU"
// Dual port write
always @(negedge clk_i) begin
    if (~reg_we_i) begin
        bank[reg_dst_i] <= data_i;

        `ifdef SIMULATE
            $display("%d Write Reg File DIn: %h, Reg: ", $stime, data_i, reg_dst_i);
        `endif
    end
end

// Source outputs
assign src1_o = bank[reg_src1_i];
assign src2_o = bank[reg_src2_i];

endmodule
