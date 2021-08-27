`default_nettype none

// --------------------------------------------------------------------------
// Test bench for a fetch cycle
// --------------------------------------------------------------------------
`timescale 1ns/1ps

`define VCD_OUTPUT "/media/RAMDisk/cpu_tb.vcd"

module cpu_tb;
   parameter AddrWidth_TB = 8;      // 8bit Address width
   parameter DataWidth_TB = 16;     // 16bit Data width
   parameter WordSize_TB = 1;       // Instructions a 1 = 2bytes in size

   // Test bench Signals
 
   // Inputs
   reg Clock_TB;
   reg Reset_TB;
   wire CPU_Halt_TB;
   wire CPU_Ready_TB;
   wire IR_Ld_TB;
   wire [DataWidth_TB-1:0] IR_TB;
   wire Mem_Wr_TB;
   wire Out_Ld_TB;
   wire ALU_Ld_TB;
   wire [DataWidth_TB-1:0] OutReg_TB;

   // Debugging
   integer index;
   integer cycleCnt;

   // -------------------------------------------
   // Device under test
   // -------------------------------------------
   CPU #(
      .DATA_WIDTH(DataWidth_TB),
      .ADDR_WIDTH(AddrWidth_TB),
      .WORD_SIZE(WordSize_TB)) cpu
   (
      .clk_i(Clock_TB),
      .reset_ni(Reset_TB),
      .ready_o(CPU_Ready_TB),
      .halt_o(CPU_Halt_TB),
      .ir_ld_o(IR_Ld_TB),
      .mem_wr_o(Mem_Wr_TB),
      .out_ld_o(Out_Ld_TB),
      .alu_ld_o(ALU_Ld_TB),
      .ir_o(IR_TB),
      .out_o(OutReg_TB)
   );
    
   // -------------------------------------------
   // Test bench clock
   // -------------------------------------------
   initial begin
      Clock_TB <= 1'b0;
      cycleCnt = 0;
   end
   
   // The clock runs until the sim finishes. #100 = 200ns clock cycle
   always begin
      #100 Clock_TB = ~Clock_TB;
   end
 
   // -------------------------------------------
   // Configure starting sim states
   // -------------------------------------------
   initial begin
      $dumpfile(`VCD_OUTPUT);  // waveforms file needs to be the same name as the tb file.
      $dumpvars;  // Save waveforms to vcd file
      
      $display("%d %m: Starting testbench simulation...", $stime);

      // Setup defaults
      Reset_TB = 1'b1;
   end
     
   always begin
      // ------------------------------------
      // Reset CPU
      // ------------------------------------
      Reset_TB = 1'b0;  // Enable reset

      for(index = 0; index < 2; index = index + 1) begin
         @(posedge Clock_TB);
         @(negedge Clock_TB);
      end

      Reset_TB = 1'b1;
   
      for(index = 0; index < `CLOCKS; index = index + 1) begin
         @(posedge Clock_TB);
         @(negedge Clock_TB);
      end

      $display("------- Reg File contents ------");
      for(index = 0; index < 8; index = index + 1)
         $display("Reg [%h] = %b <- 0x%h", index, cpu.RegFile.bank[index], cpu.RegFile.bank[index]);

      $display("------- Memory contents ------");
      for(index = 0; index < 15; index = index + 1)
         $display("memory [%h] = %b <- 0x%h", index, cpu.memory.mem[index], cpu.memory.mem[index]);
     
      $display("------- Output contents ------");
      $display("Output {%h}", cpu.output_port);
       
      // ------------------------------------
      // Simulation END
      // ------------------------------------
      #100 $display("%d %m: Testbench simulation FINISHED.", $stime);
      $finish;
   end
endmodule
