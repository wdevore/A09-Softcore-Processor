// --------------------------------------------------------------------------
// Test bench
// --------------------------------------------------------------------------
`timescale 1ns/1ps

`define VCD_OUTPUT "/media/RAMDisk/pc_tb.vcd"

module pc_tb;
   parameter Data_WIDTH = 16;                 // data width
   parameter WordByte_Size = 1;
   
   // Test bench Signals
   // Outputs
   wire [Data_WIDTH-1:0] DOut_TB;          // Output from PC

   // Inputs
   reg Reset_TB;
   reg LD_TB;
   reg Inc_TB;
   reg [Data_WIDTH-1:0] DIn_TB;

   reg Clock_TB;

   // -------------------------------------------
   // Device under test
   // -------------------------------------------
   ProgramCounter #(.DATA_WIDTH(Data_WIDTH), .WORD_SIZE(WordByte_Size)) dut
   (
      .clk_i(Clock_TB),
      .reset_ni(Reset_TB),
      .ld_ni(LD_TB),
      .inc_ni(Inc_TB),
      .data_i(DIn_TB),
      .data_o(DOut_TB)
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

      Reset_TB = 1'b1;  // Disable reset
      DIn_TB = {Data_WIDTH{1'b0}};  // DIn = 0
      LD_TB = 1'b1;     // Disable load
      Inc_TB = 1'b1;    // Disable counting
   end

   always begin
      // ------------------------------------
      // Reset first
      // ------------------------------------
      @(posedge Clock_TB);
      Reset_TB = 1'b0;  // Enable reset
      DIn_TB = {Data_WIDTH{1'b0}};  // DIn can be any value
      LD_TB = 1'b1;     // Disable load

      @(negedge Clock_TB);
      #10;
      $display("%d <-- Marker", $stime);

      if (DOut_TB !== 16'h0000) begin
         $display("%d %m: ERROR - (0) PC output incorrect (%h).", $stime, DOut_TB);
         $finish;
      end

      // ------------------------------------
      // Load
      // ------------------------------------
      @(posedge Clock_TB);
      Reset_TB = 1'b1;  // Disable reset
      DIn_TB = 16'h00A0;  // Set Address to 0x00A0
      LD_TB = 1'b0;     // Enable load

      @(negedge Clock_TB);
      #10  // Wait for data

      if (DOut_TB !== 16'h00A0) begin
         $display("%d %m: ERROR - (1) PC output incorrect (%h).", $stime, DOut_TB);
         $finish;
      end

      // ------------------------------------
      // Reset
      // ------------------------------------
      @(posedge Clock_TB);
      Reset_TB = 1'b0;  // Enable reset
      LD_TB = 1'b1;     // Disable load

      @(negedge Clock_TB);
      #10  // Wait for data

      if (DOut_TB !== 16'h0000) begin
         $display("%d %m: ERROR - (2) PC output incorrect (%h).", $stime, DOut_TB);
         $finish;
      end

      // ------------------------------------
      // Increment
      // ------------------------------------
      @(posedge Clock_TB);
      Reset_TB = 1'b1;  // Disable reset
      LD_TB = 1'b1;     // Disable load
      Inc_TB = 1'b0;    // Enable counting

      @(negedge Clock_TB);
      #10  // Wait for data

      if (DOut_TB !== 16'h0001) begin
         $display("%d %m: ERROR - (3) PC output incorrect (%h).", $stime, DOut_TB);
         $finish;
      end

      // ------------------------------------
      // Increment
      // ------------------------------------
      @(negedge Clock_TB);
      #10  // Wait for data

      if (DOut_TB !== 16'h0002) begin
         $display("%d %m: ERROR - (4) PC output incorrect (%h).", $stime, DOut_TB);
         $finish;
      end

      // ------------------------------------
      // Increment
      // ------------------------------------
      @(negedge Clock_TB);
      #10  // Wait for data

      if (DOut_TB !== 16'h0003) begin
         $display("%d %m: ERROR - (5) PC output incorrect (%h).", $stime, DOut_TB);
         $finish;
      end

      // ------------------------------------
      // Simulation duration
      // ------------------------------------
      #50 $display("%d %m: Testbench simulation PASSED.", $stime);
      $finish;
   end
endmodule
