`default_nettype none

// --------------------------------------------------------------------------
// Test bench
// --------------------------------------------------------------------------
`timescale 1ns/1ps

`define VCD_OUTPUT "/media/RAMDisk/mealy_tb.vcd"

module mealy_tb;
   localparam DATA_WIDTH = 8;
   localparam PC_SELECT_SIZE = 3;
   localparam ADDR_SELECT_SIZE = 2;
   
   // Test bench Signals
   // Outputs
   wire PC_LD_TB;
   wire PC_RST_TB;
   wire MAR_Reset_TB;
   wire MAR_Ld_TB;
   wire [PC_SELECT_SIZE-1:0] PC_SRC_TB;
   wire [ADDR_SELECT_SIZE-1:0] ADDR_SRC_TB;
   wire [DATA_WIDTH-1:0] MAR_Output_TB;

   // Inputs
   reg Clock_TB;

   reg Matrix_Reset_TB;

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
      .reset_ni(PC_RST_TB),
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
   // Simple Mealy Control Matrix
   // -------------------------------------------
   MealyCM Matrix
   (
      .clk_i(Clock_TB),
      .reset_ni(Matrix_Reset_TB),
      .pc_rst_no(PC_RST_TB),
      .pc_ld_no(PC_LD_TB),
      .mar_rst_no(MAR_Reset_TB),
      .mar_ld_no(MAR_Ld_TB),
      .pc_src_o(PC_SRC_TB),
      .addr_src_o(ADDR_SRC_TB)
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

      Matrix_Reset_TB = 1'b1;
   end

   always begin
      // ------------------------------------
      // Let the clock run to finish out the reset sequence.
      // ------------------------------------
      @(posedge Clock_TB);
      @(negedge Clock_TB);

      @(posedge Clock_TB);
      @(negedge Clock_TB);

      @(posedge Clock_TB);
      @(negedge Clock_TB);

      @(posedge Clock_TB);
      @(negedge Clock_TB);

      @(posedge Clock_TB);
      $display("%d: Starting reset sequence", $stime);
      Matrix_Reset_TB = 1'b0;
      @(negedge Clock_TB);


      // ------------------------------------
      // Keep reset active for 3 clock cycles
      // ------------------------------------
      @(posedge Clock_TB);
      @(negedge Clock_TB);

      @(posedge Clock_TB);
      @(negedge Clock_TB);

      $display("%d Deactivating Reset", $stime);
      // Now exit the reset state
      Matrix_Reset_TB = 1'b1;


      // ------------------------------------
      // Simulation duration
      // ------------------------------------
      #50 $display("%d %m: Testbench simulation Finished.", $stime);
      $finish;
   end
endmodule
