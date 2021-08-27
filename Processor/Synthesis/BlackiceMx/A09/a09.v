`default_nettype none

// A09 CPU targeted for the BlackiceMx FPGA

module top
(
    input wire clk,             // 25MHz clock input
    input wire clock_i,         // Microcontroller to FPGA
    input wire reset_i,         // Reset from uC to FPGA
    output wire indic,          // Active clock indicator
    output wire indic2,
    output wire indic3,
    output wire indic4,
    output wire [15:0] signals
);

localparam DataWidth = 16;     // 16bit Data width
localparam AddrWidth = 8;      // 8bit Address width
localparam WordSize = 1;       // Instructions a 1 = 2bytes in size
    
wire [DataWidth-1:0] OutReg;
reg ready;
reg halt;
reg ir_ld;
reg pc_ld;
reg pc_inc;
reg reg_we;
reg output_ld;
reg alu_ld;
reg [DataWidth-1:0] ir;

// ----------------------------------------------------------
// Clock used for heartbeat LED
// ----------------------------------------------------------
reg [22:0] clk_1hz_counter = 23'b0;  // Hz clock generation counter
reg        clk_cyc = 1'b0;           // Hz clock
localparam FREQUENCY = 23'd1;  // 4Hz

// Clock divider and generator
always @(posedge clk) begin
    if (clk_1hz_counter < 23'd7_999_999)
        clk_1hz_counter <= clk_1hz_counter + FREQUENCY;
    else begin
        clk_1hz_counter <= 23'b0;
        clk_cyc <= ~clk_cyc;
    end
end
    
// ----------------------------------------------------------
// Modules
// ----------------------------------------------------------

CPU #(
    .DATA_WIDTH(DataWidth),
    .ADDR_WIDTH(AddrWidth),
    .WORD_SIZE(WordSize)) cpu
(
    .clk_i(clock_i),
    .reset_ni(reset_i),
    .ready_o(ready),
    .halt_o(halt),
    .ir_o(ir),
    .out_o(OutReg),
    .ir_ld_o(ir_ld),
    .pc_ld_o(pc_ld),
    .pc_inc_o(pc_inc),
    .reg_we_o(reg_we),
    .out_ld_o(output_ld),
    .alu_ld_o(alu_ld)
);

// ----------------------------------------------------------
// IO routing
// ----------------------------------------------------------
// Route Output wires to pins

// White led row (Right)
//     0   1   2   3   4   5   6   7
// Pin 139 138 142 141 135 134 137 136

// (Left)
//     B  B  B  B  Y  Y  R  G
//     8  9  10 11 12 13 14 15
// Pin 4  3 144 143 8  7  2  1

assign
    signals[0] =  OutReg[3],  // white
    signals[1] =  OutReg[2],  // white
    signals[2] =  OutReg[1],  // white
    signals[3] =  OutReg[0],  // white
    signals[4] =  OutReg[7],  // white
    signals[5] =  OutReg[6],  // white
    signals[6] =  OutReg[5],  // white
    signals[7] =  OutReg[4];  // white

assign
    signals[11] =  ir[12],  // blue
    signals[10] =  ir[13],  // blue
    signals[9]  =  ir[14],  // blue
    signals[8]  =  ir[15],  // blue
    signals[12] =  reg_we,  // yellow
    signals[13] =  ir_ld,   // yellow
    signals[14] =  halt,    // Red
    signals[15] =  ready;   // Green

// Onboard LEDs next to the HDMI connector
assign indic4 = ~pc_inc;      // Red
assign indic2 = ~output_ld;   // Yellow
assign indic  = clk_cyc;      // Green
assign indic3 = ~pc_ld;       // Blue

endmodule  // top