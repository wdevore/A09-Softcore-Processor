// --------------------------------------------------------------------------
// Test bench
// --------------------------------------------------------------------------
`timescale 1ns/1ps

`define VCD_OUTPUT "/media/RAMDisk/memory_tb.vcd"

module memory_tb;
   localparam Data_WIDTH = 16;                 // data width
   localparam Address_WIDTH = 8;
   
   // Test bench Signals
   // Outputs
   wire [Data_WIDTH-1:0] DOut_TB;          // Output from memory

   // Inputs
   reg [Data_WIDTH-1:0] DIn_TB;
   reg [Address_WIDTH-1:0] Address_TB;
   reg WriteEn_TB;
   reg Clock_TB;

   // -------------------------------------------
   // Device under test
   // -------------------------------------------
   Memory dut(
      .clk_i(Clock_TB),
      .data_i(DIn_TB),
      .address_i(Address_TB),
      .write_en_ni(WriteEn_TB),
      .data_o(DOut_TB)
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

      WriteEn_TB = 1'b1; // Disable writing to memory
      Address_TB = {Address_WIDTH{1'bx}}; // Begining address of 0x00
      DIn_TB = 16'b0;    // Initial data
   end

   always begin
      // ------------------------------------
      // Read memory location 0x00
      // ------------------------------------
      @(posedge Clock_TB);
      Address_TB = 8'h00;  // Assert address 0x00

      @(negedge Clock_TB);
      #10  // Wait for data

      if (DOut_TB !== 16'h00ff) begin
         $display("%d %m: ERROR - (A) Memory 0x00 address has invalid value (%h).", $stime, DOut_TB);
         $finish;
      end
      $display("%d Read location 0x00", $stime);

      // ------------------------------------
      // Read memory location 0x01
      // ------------------------------------
      @(posedge Clock_TB);
      Address_TB = 8'h01; // Change address 0x01 <-- Reset vector address

      $display("%d (B) Wait for Clock edge and Data wait", $stime);
      @(negedge Clock_TB);
      #10 // Wait for data

      if (DOut_TB !== 16'hf0f0) begin
         $display("%d %m: ERROR - (B) Memory 0x00 address has invalid value (%h).", $stime, DOut_TB);
         $finish;
      end
      $display("%d Read location 0x01", $stime);

      // ------------------------------------
      // Read memory location 0xFF for reset vector address
      // ------------------------------------
      @(posedge Clock_TB);
      Address_TB = 8'hFF; // Change address to 0xFF vector reset

      $display("%d (C) Wait for Clock edge and Data wait", $stime);
      @(negedge Clock_TB);
      #10 // Wait for data

      if (DOut_TB !== 16'h0001) begin
         $display("%d %m: ERROR - (C) Memory 0x00 address has invalid value (%h).", $stime, DOut_TB);
         $finish;
      end
      $display("%d Read location 0xFF", $stime);

      // ------------------------------------
      // Read memory location pointed to by reset vector address
      // ------------------------------------
      @(posedge Clock_TB);
      Address_TB = DOut_TB[6:0]; // Change address to vector reset address

      $display("%d (C) Wait for Clock edge and Data wait", $stime);
      @(negedge Clock_TB);
      #10 // Wait for data

      if (DOut_TB !== 16'hf0f0) begin
         $display("%d %m: ERROR - (D) Memory 0x00 address has invalid value (%h).", $stime, DOut_TB);
         $finish;
      end
      $display("%d Read reset location (%h)", $stime, Address_TB[6:0]);


      // =================================================================
      // ------------------------------------
      // Write to memory location 0x0A: 0x0666
      // ------------------------------------
      @(posedge Clock_TB);
      WriteEn_TB = 1'b0;    // Enable writing (active LOW)
      Address_TB = 16'h000A;   // Assert address
      DIn_TB = 16'h0666;

      @(negedge Clock_TB);
      #50 // Allow data to settle
      $display("%d Write location 0x0A", $stime);

      // ------------------------------------
      // Read memory location 0x0A
      // ------------------------------------
      @(posedge Clock_TB);
      WriteEn_TB = 1'b1;    // Disable writing
      Address_TB = 8'h0A;   // Assert address

      $display("%d (E) Waiting for Clock edge and Data", $stime);
      @(negedge Clock_TB);
      #10  // Wait a bit for data to settle

      // Now sample the output
      if (DOut_TB !== 16'h0666) begin
         $display("%d %m: ERROR - (E) Memory 0x00 address has invalid value (%h).", $stime, DOut_TB);
         $finish;
      end
      $display("%d Read location 0x0A", $stime);

      // ------------------------------------
      // Simulation duration
      // ------------------------------------
      #50 $display("%d %m: Testbench simulation PASSED.", $stime);
      $finish;
   end
endmodule
