`default_nettype none

// --------------------------------------------------------------------------
// Test bench
// --------------------------------------------------------------------------
`timescale 1ns/1ps

`define VCD_OUTPUT "/media/RAMDisk/manual_tb.vcd"

module manual_tb;
   localparam DATA_WIDTH = 8;
   localparam PC_SELECT_SIZE = 3;
   localparam ADDR_SELECT_SIZE = 2;
   
   // Test bench Signals
   reg Clock_TB;

   // Manual signals
   reg PC_LD_TB;
   reg PC_Reset_TB;
   reg MAR_Reset_TB;
   reg MAR_Ld_TB;
   reg [PC_SELECT_SIZE-1:0] PC_SRC_TB;
   reg [ADDR_SELECT_SIZE-1:0] ADDR_SRC_TB;

   // Output of MAR
   wire [DATA_WIDTH-1:0] MAR_Output_TB;

   localparam reset_vector = 8'hFF;

   // Module Data-Path wires
   wire [DATA_WIDTH-1:0] MUX_PC_to_PC_TB;
   wire [DATA_WIDTH-1:0] PC_to_MUX_ADDR_TB;
   wire [DATA_WIDTH-1:0] MUX_ADDR_to_MAR_TB;

   // -------------------------------------------
   // Multiplexor routed to PC
   // -------------------------------------------
   Mux8 #(.DATA_WIDTH(DATA_WIDTH)) MUX_PC
   (
      .select_i(PC_SRC_TB),
      .data0_i({DATA_WIDTH{1'b0}}),
      .data1_i({DATA_WIDTH{1'b0}}),
      .data2_i(reset_vector),
      .data3_i({DATA_WIDTH{1'b0}}),
      .data_o(MUX_PC_to_PC_TB)
   );

   // -------------------------------------------
   // Program Counter
   // -------------------------------------------
   ProgramCounter #(.DATA_WIDTH(DATA_WIDTH)) PC
   (
      .clk_i(Clock_TB),
      .reset_ni(PC_Reset_TB),
      .ld_ni(PC_LD_TB),
      .inc_ni(1'b1),
      .data_i(MUX_PC_to_PC_TB),
      .data_o(PC_to_MUX_ADDR_TB)
   );

   // -------------------------------------------
   // Multiplexor routed to MAR
   // -------------------------------------------
   Mux4 #(.DATA_WIDTH(DATA_WIDTH)) MUX_ADDR
   (
      .select_i(ADDR_SRC_TB),
      .data0_i(PC_to_MUX_ADDR_TB),
      .data1_i({DATA_WIDTH{1'b0}}),
      .data2_i({DATA_WIDTH{1'b0}}),
      .data3_i({DATA_WIDTH{1'b0}}),
      .data_o(MUX_ADDR_to_MAR_TB)
   );

   // -------------------------------------------
   // Memory Address Register
   // -------------------------------------------
   Register #(.DATA_WIDTH(DATA_WIDTH)) MAR
   (
      .clk_i(Clock_TB),
      .reset_ni(MAR_Reset_TB),
      .ld_ni(MAR_Ld_TB),
      .data_i(MUX_ADDR_to_MAR_TB),
      .data_o(MAR_Output_TB)
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
   end

   always begin
      $display("%d: Starting reset sequence", $stime);
      // ------------------------------------
      // Reset
      // ------------------------------------
      @(posedge Clock_TB);
      PC_Reset_TB = 1'b0;
      MAR_Reset_TB = 1'b0;

      @(negedge Clock_TB);    // Take Action

      $display("%d Deactivating Reset", $stime);
      // Now exit the reset state
      @(posedge Clock_TB);
      PC_Reset_TB = 1'b1;     // Disable reset
      MAR_Reset_TB = 1'b1;

      @(negedge Clock_TB);    // Take Action

      // ------------------------------------
      // Move reset vector data through mux to PC input
      // ------------------------------------
      @(posedge Clock_TB);
      PC_SRC_TB = 2'b10;      // Select Reset vector constant
      PC_LD_TB = 1'b0;        // Enable loading PC

      @(negedge Clock_TB);    // Take Action

      @(posedge Clock_TB);
      PC_LD_TB = 1'b1;        // Disable loading PC
      ADDR_SRC_TB = 2'b00;    // Select PC output
      MAR_Ld_TB = 1'b0;       // Enable loading MAR register

      @(negedge Clock_TB);    // Take Action

      @(posedge Clock_TB);
      MAR_Ld_TB = 1'b1;       // Disable loading MAR register
      
      @(negedge Clock_TB);

      // Add extra cycle for trailing display edge
      @(posedge Clock_TB);
      @(negedge Clock_TB);

      // ------------------------------------
      // Simulation duration
      // ------------------------------------
      #50 $display("%d %m: Testbench simulation Finished.", $stime);
      $finish;
   end
endmodule
