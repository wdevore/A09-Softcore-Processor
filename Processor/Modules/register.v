`default_nettype none
`ifdef SIMULATE
`timescale 1ns/1ps
`endif

// --------------------------------------------------------------------------
// Standard register with Load and Reset.
// --------------------------------------------------------------------------

module Register
#(
    parameter DATA_WIDTH = 16)
(
    input wire clk_i,
    input wire reset_ni,                // Active Low
    input wire ld_ni,                   // Load: Active Low
    input wire [DATA_WIDTH-1:0] data_i, // Input
    output reg [DATA_WIDTH-1:0] data_o  // Output
);

// The register acts only the negative edge of the clock
always @(negedge clk_i) begin
    if (~reset_ni) begin
        `ifdef SIMULATE
            $display("%d Register reset", $stime);
        `endif
        data_o <= {DATA_WIDTH{1'b0}};
    end
    else if (~ld_ni) begin
        `ifdef SIMULATE
            $display("%d Register Load: (%b) %h", $stime, data_i, data_i);
        `endif
        data_o <= data_i;
    end
end

endmodule
