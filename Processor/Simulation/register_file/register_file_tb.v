`default_nettype none

// --------------------------------------------------------------------------
// Test bench
// --------------------------------------------------------------------------
`timescale 1ns/1ps

`define VCD_OUTPUT "/media/RAMDisk/register_file_tb.vcd"

module register_file_tb;
   parameter Data_WIDTH = 16;                 // data width
   parameter SelectSize = 3;
   
   // Test bench Signals
   // Outputs
   wire [Data_WIDTH-1:0] SRC1_TB;
   wire [Data_WIDTH-1:0] SRC2_TB;

   // Inputs
   reg REG_WE_TB;
   reg [Data_WIDTH-1:0] DIn_TB;
   reg [SelectSize-1:0] REG_Dst_TB;
   reg [SelectSize-1:0] REG_Src1_TB;
   reg [SelectSize-1:0] REG_Src2_TB;

   reg Clock_TB;

   // -------------------------------------------
   // Device under test
   // -------------------------------------------
   RegisterFile #(.DataWidth(Data_WIDTH)) dut
   (
      .clk_i(Clock_TB),
      .reg_we_i(REG_WE_TB),
      .data_i(DIn_TB),
      .reg_dst_i(REG_Dst_TB),
      .reg_src1_i(REG_Src1_TB),
      .reg_src2_i(REG_Src2_TB),
      .src1_o(SRC1_TB),
      .src2_o(SRC2_TB)
   );

   // -------------------------------------------
   // Test bench clock - not really need for this TB
   // -------------------------------------------
   initial begin
      Clock_TB <= 1'b0;
   end

   // The clock runs until the sim finishes. #100 = 200ns clock cycle
   always begin
      #100 Clock_TB = ~Clock_TB;
   end

   // -------------------------------------------
   // Configure starting sim states
   // -------------------------------------------
   initial begin
      $dumpfile(`VCD_OUTPUT);
      $dumpvars;  // Save waveforms to vcd file
      
      $display("%d %m: Starting testbench simulation...", $stime);

      REG_WE_TB = 1'b1;  // Disable Register write
      DIn_TB = {Data_WIDTH{1'b0}};  // DIn = 0
      REG_Dst_TB = 3'b000;      // Default to reg 0
      REG_Src1_TB = 3'b000;     // Default to reg 0
      REG_Src2_TB = 3'b000;     // Default to reg 0
   end

   always begin
      // ------------------------------------
      // Load Reg 0 <- 0x00A0
      // ------------------------------------
      @(posedge Clock_TB);
      REG_WE_TB = 1'b0;  // Enable writing
      DIn_TB = 16'h00A0;  // Write 0x00A0
      REG_Dst_TB = 3'b000;    // Select Reg 0 as destination
      REG_Src1_TB = 3'b000;   // (Assertion) Reg 0 as Src #1 for reading

      @(negedge Clock_TB);
      #10  // Wait for data
      $display("%d <-- Marker", $stime);

      if (SRC1_TB !== 16'h00A0) begin
         $display("%d %m: ERROR - Src #1 output incorrect (%h).", $stime, SRC1_TB);
         $finish;
      end

      @(posedge Clock_TB);
      REG_WE_TB = 1'b1;  // Disable writing
      @(negedge Clock_TB);

      // ------------------------------------
      // Load Reg 1 <- 0x000A
      // ------------------------------------
      @(posedge Clock_TB);
      REG_WE_TB = 1'b0;  // Enable writing
      DIn_TB = 16'h000A;  // Write 0x000A
      REG_Dst_TB = 3'b001;    // Select Reg 1 as destination
      REG_Src1_TB = 3'b001;   // Set output reg 1 as Src #1

      @(negedge Clock_TB);
      #10  // Wait for data
      $display("%d <-- Marker", $stime);

      if (SRC1_TB !== 16'h000A) begin
         $display("%d %m: ERROR(2) - Src #1 output incorrect (%h).", $stime, SRC1_TB);
         $finish;
      end

      @(posedge Clock_TB);
      REG_WE_TB = 1'b1;  // Disable writing
      @(negedge Clock_TB);

      // ------------------------------------
      // Read Reg 0
      // ------------------------------------
      @(posedge Clock_TB);
      REG_Src1_TB = 3'b000;   // reg 0 as Src #1

      @(negedge Clock_TB);
      #10  // Wait for data
      $display("%d <-- Marker", $stime);

      if (SRC1_TB !== 16'h00A0) begin
         $display("%d %m: ERROR(3) - Read Src #1 output incorrect (%h).", $stime, SRC1_TB);
         $finish;
      end

      // ------------------------------------
      // Simulation duration
      // ------------------------------------
      #50 $display("%d %m: Testbench simulation Finished.", $stime);
      $finish;
   end
endmodule
