`default_nettype none

// --------------------------------------------------------------------------
// Test bench
// --------------------------------------------------------------------------
`timescale 1ns/1ps

`define VCD_OUTPUT "/media/RAMDisk/cm_7c_tb.vcd"

module cm_7c_tb;
   localparam DATA_WIDTH = 16;
   localparam WORDS = 8;
   localparam PC_SELECT_SIZE = 3;
   localparam ADDR_SELECT_SIZE = 2;
   localparam ADDR_LOW_BITS = 8;
   
   // Matrix output control signals
   wire PC_Ld_TB;
   wire PC_Inc_TB;
   wire IR_Ld_TB;
   wire IR_Rst_TB;
   wire MEM_Wr_TB;
   wire Out_Ld_TB;
   wire Out_Sel_TB;
   wire Ready_TB;
   wire Halt_TB;
   wire [PC_SELECT_SIZE-1:0] PC_SRC_TB;
   wire [ADDR_SELECT_SIZE-1:0] ADDR_SRC_TB;

   // Matrix inputs
   reg Clock_TB;
   reg Matrix_Reset_TB;
   
   localparam reset_vector = 16'h00FF;

   // Module Data-Path wires
   wire [DATA_WIDTH-1:0] MUX_PC_to_PC_TB;
   wire [DATA_WIDTH-1:0] PC_to_MUX_ADDR_TB;
   wire [DATA_WIDTH-1:0] MUX_ADDR_to_MEM_TB;
   wire [DATA_WIDTH-1:0] MEM_to_IR_TB;
   wire [DATA_WIDTH-1:0] IR_Out_TB;

   // -------------------------------------------
   // Sign extenders
   // -------------------------------------------
   wire [DATA_WIDTH-1:0] absoluteZeroExtL;

   // Zero extend lower absolute address bits from the IR register.
   assign absoluteZeroExtL = {{DATA_WIDTH-ADDR_LOW_BITS{1'b0}}, IR_Out_TB[ADDR_LOW_BITS-1:0]};

   // -------------------------------------------
   // Multiplexor routed to PC
   // -------------------------------------------
   Mux8 #(.DATA_WIDTH(DATA_WIDTH)) MUX_PC
   (
      .select_i(PC_SRC_TB),
      .data0_i({DATA_WIDTH{1'b0}}),       // Hooked up...yet
      .data1_i({DATA_WIDTH{1'b0}}),       // Hooked up...yet
      .data2_i(reset_vector),
      .data3_i({DATA_WIDTH{1'b0}}),       // Hooked up...yet
      .data4_i(absoluteZeroExtL),
      .data5_i({DATA_WIDTH{1'b0}}),       // Left for dead
      .data6_i({DATA_WIDTH{1'b0}}),       // Left for dead
      .data7_i({DATA_WIDTH{1'b0}}),       // Left for dead
      .data_o(MUX_PC_to_PC_TB)
   );

   // -------------------------------------------
   // Program Counter
   // -------------------------------------------
   ProgramCounter #(.DATA_WIDTH(DATA_WIDTH)) PC
   (
      .clk_i(Clock_TB),
      .reset_ni(1'b1),              // Unused. Alternate is to load 0 constant
      .ld_ni(PC_Ld_TB),
      .inc_ni(PC_Inc_TB),
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
      .data1_i({DATA_WIDTH{1'b0}}),       // Long forgotten
      .data2_i({DATA_WIDTH{1'b0}}),       // Long forgotten
      .data3_i({DATA_WIDTH{1'b0}}),       // Long forgotten
      .data_o(MUX_ADDR_to_MEM_TB)
   );

   // -------------------------------------------
   // Memory BRAM
   // -------------------------------------------
   Memory #(.WORDS(WORDS)) Mem
   (
      .clk_i(Clock_TB),
      .data_i({DATA_WIDTH{1'b0}}),        // This TB doesn't write to memory
      .address_i(MUX_ADDR_to_MEM_TB[WORDS-1:0]),
      .write_en_ni(MEM_Wr_TB),
      .data_o(MEM_to_IR_TB)
   );

   // -------------------------------------------
   // Instruction register
   // -------------------------------------------
   Register #(.DATA_WIDTH(DATA_WIDTH)) IR
   (
      .clk_i(Clock_TB),
      .reset_ni(IR_Rst_TB),
      .ld_ni(IR_Ld_TB),
      .data_i(MEM_to_IR_TB),
      .data_o(IR_Out_TB)
   );

   SequenceControl #(.DATA_WIDTH(DATA_WIDTH)) Matrix
   (
      .clk_i(Clock_TB),
      .reset_ni(Matrix_Reset_TB),
      .ir_i(IR_Out_TB),
      .ir_ld_no(IR_Ld_TB),
      .ir_rst_no(IR_Rst_TB),
      .pc_ld_no(PC_Ld_TB),
      .pc_inc_no(PC_Inc_TB),
      .pc_src_o(PC_SRC_TB),
      .mem_wr_no(MEM_Wr_TB),
      .addr_src_o(ADDR_SRC_TB),
      .out_ld_no(Out_Ld_TB),
      .out_sel_o(Out_Sel_TB),
      .ready_po(Ready_TB),
      .halt_po(Halt_TB)
   );

   // -------------------------------------------
   // Test bench clock
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

      // Reset as in-active
      Matrix_Reset_TB = 1'b1;
   end

   always begin
      // ------------------------------------
      // Let the clock run a bit for a decent header
      // ------------------------------------
      @(posedge Clock_TB);
      @(negedge Clock_TB);

      @(posedge Clock_TB);
      $display("%d: Starting reset sequence", $stime);
      Matrix_Reset_TB = 1'b0;
      @(negedge Clock_TB);


      // ------------------------------------
      // Keep reset active for N clock cycles
      // ------------------------------------
      @(posedge Clock_TB);
      @(negedge Clock_TB);

      @(posedge Clock_TB);
      $display("%d Deactivating Reset", $stime);
      // Now exit the reset state
      Matrix_Reset_TB = 1'b1;
      @(negedge Clock_TB);

      @(posedge Clock_TB);
      @(negedge Clock_TB);

      @(posedge Clock_TB);
      @(negedge Clock_TB);

      @(posedge Clock_TB);
      @(negedge Clock_TB);

      @(posedge Clock_TB);
      @(negedge Clock_TB);

      @(posedge Clock_TB);
      @(negedge Clock_TB);

      @(posedge Clock_TB);
      @(negedge Clock_TB);

      @(posedge Clock_TB);
      @(negedge Clock_TB);

      @(posedge Clock_TB);
      @(negedge Clock_TB);
      // ------------------------------------
      // Simulation duration
      // ------------------------------------
      #50 $display("%d %m: Testbench simulation Finished.", $stime);
      $finish;
   end
endmodule
