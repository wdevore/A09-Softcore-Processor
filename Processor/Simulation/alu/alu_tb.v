// --------------------------------------------------------------------------
// Test bench
// Article on Overflow and Carry:
// http://teaching.idallen.com/dat2343/10f/notes/040_overflow.txt#:~:text=A%20math%20result%20can%20overflow,the%20ALU%20%22overflow%22%20flag.&text=The%20rules%20for%20turning%20on,significant%20(leftmost)%20bits%20added.
// --------------------------------------------------------------------------
`timescale 1ns/10ps

`define VCD_OUTPUT "/media/RAMDisk/alu_tb.vcd"

module alu_tb;
   parameter WIDTH = 16;                 // data width
   
   wire [WIDTH-1:0] OY_TB;         // Output result
   wire [3:0] OFlags_TB;           // Flags output

   // Inputs
   reg [3:0] IFlags_TB;            // Flags input
   reg [WIDTH-1:0] IA_TB, IB_TB;   // A,B register inputs
   reg [3:0] FuncOp_TB;            // ALU function to perform

   // -------------------------------------------
   // Test bench clock
   // -------------------------------------------
   reg Clock_TB;
   initial begin
      Clock_TB <= 1'b0;
   end
 
   // The clock runs until the sim finishes. 200ns cycle
   always begin
      #100 Clock_TB = ~Clock_TB;
   end
 
   // -------------------------------------------
   // Device under test
   // -------------------------------------------
   ALU #(.DataWidth(WIDTH)) dut(
      .flags_i(IFlags_TB),
      .a_i(IA_TB),
      .b_i(IB_TB),
      .func_op_i(FuncOp_TB),
      .y_o(OY_TB),
      .flags_o(OFlags_TB)
      );

   // -------------------------------------------
   // Configure starting sim states
   // -------------------------------------------
   initial begin
      $dumpfile(`VCD_OUTPUT);
      $dumpvars;  // Save waveforms to vcd file
      
      $display("%d %m: Starting testbench simulation...", $stime);
   end

   `include "../../Modules/constants.v"

   always begin
      `ifdef SIMULATE_ADD
            $display("%d Simulating ADD operation", $stime);
            `include "add_op.v"
      `endif
      `ifdef SIMULATE_SUB
            $display("%d Simulating SUB operation", $stime);
            `include "sub_op.v"
      `endif
      #100 $finish;
   end

endmodule
