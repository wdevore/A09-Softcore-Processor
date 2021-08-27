`default_nettype none

// --------------------------------------------------------------------------
// Standard program counter with Auto-increment, Load and reset_i.
// --------------------------------------------------------------------------

module ProgramCounter
#(
    parameter DATA_WIDTH = 16,
    parameter WORD_SIZE = 1)
(
    input wire clk_i,
    input wire reset_ni,                 // Active Low
    input wire ld_ni,                    // Load: Active Low
    input wire inc_ni,                   // Increment: Active Low
    input wire [DATA_WIDTH-1:0] data_i,  // Input
    output reg [DATA_WIDTH-1:0] data_o   // Output
);

always @(negedge clk_i) begin
    if (~reset_ni)
        data_o <= {DATA_WIDTH{1'b0}};
    else if (~ld_ni)
        data_o <= data_i;
    else if (~inc_ni)
        data_o <= data_o + WORD_SIZE;
    else
        data_o <= data_o;
end

endmodule
