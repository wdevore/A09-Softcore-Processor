`default_nettype none

// A09 CPU targeted for an FPGA

`undef SIMULATE

// `include "../../modules/alu/alu.v"
// `include "../../modules/register/register.v"
`include "../../../Modules/constants.v"

module top
(
    input wire clk,             // 25MHz clock input
    // from uC to FPGA  ----------------------------
    input wire clock_i,         
    input wire reset_i,         
    input wire alu_ld_i,        // ALU load
    input wire src1_clk_i,      // SRC 1 clock
    input wire src2_clk_i,      // SRC 2 clock
    input wire alu_op_i,        // ALU op
    output wire activity,       // Active clock indicator
    output wire [15:0] signals
);

localparam DATA_WIDTH = 16;     // 16bit Data width
localparam AddrWidth = 8;      // 8bit Address width
localparam WordSize = 1;       // Instructions a 1 = 2bytes in size
localparam FlagSize = 4;       //

wire [DATA_WIDTH-1:0] alu_to_out;
wire [DATA_WIDTH-1:0] alu_res;
wire [FlagSize-1:0] alu_to_flags;
wire [FlagSize-1:0] alu_flags;

reg [DATA_WIDTH-1:0] source1;
reg [DATA_WIDTH-1:0] source2;
reg [DATA_WIDTH-1:0] flags;

reg [3:0] alu_op;
reg [1:0] src1; // counter
reg [1:0] src2; // counter

// ----------------------------------------------------------
// Clock
// ----------------------------------------------------------
localparam ClockSize = 25;
reg [ClockSize-1:0] clk_1hz_counter = ClockSize'b0;  // Hz clock generation counter
reg        clk_cyc = 1'b0;           // Hz clock
localparam FREQUENCY = 23'd2;  // 2Hz
  
// Clock divder and generator
always @(posedge clk) begin
    if (clk_1hz_counter < ClockSize'b0010000000000000000000000)
        clk_1hz_counter <= clk_1hz_counter + FREQUENCY;
    else begin
        clk_1hz_counter <= ClockSize'b0;
        clk_cyc <= ~clk_cyc;
    end
end

// always @* begin
//     // source1 = DataWidth'b0000000000010010;  // 18 = 0x12
//     // source2 = DataWidth'b0000000000010101;  // 21 = 0x15
//     // Add = 0000000000100111 = 39
//     // Sub = 1111111111111101 = -3
//     // AND = 0000000000010000
//     // OR  = 0000000000010111
//     // XOR = 0000000000000111
// end

always @(alu_op_i) begin
    if (alu_op_i == 1'b0)
        alu_op = `ADD;
    else
        alu_op = `SUB;
end

always @(posedge src1_clk_i) begin
    src1 = src1 + 1;
    case (src1)
        2'b00:
            source1 = DATA_WIDTH'b0000;
        2'b01:
            source1 = DATA_WIDTH'b0001;
        2'b10:
            source1 = DATA_WIDTH'b1000;
        2'b11:
            source1 = DATA_WIDTH'b1111;
    endcase
end

always @(posedge src2_clk_i) begin
    src2 = src2 + 1;
    case (src2)
        2'b00:
            source2 = DATA_WIDTH'b0000;
        2'b01:
            source2 = DATA_WIDTH'b0001;
        2'b10:
            source2 = DATA_WIDTH'b1000;
        2'b11:
            source2 = DATA_WIDTH'b1100;
    endcase
end

// ----------------------------------------------------------
// Modules
// ----------------------------------------------------------
ALU #(.DATA_WIDTH(DATA_WIDTH)) Alu(
    .flags_i({FlagSize{1'b0}}),    // Not used yet
    .a_i(source1),
    .b_i(source2),
    .func_op_i(alu_op),
    .y_o(alu_to_out),
    .flags_o(alu_to_flags)
);

Register #(.DATA_WIDTH(4)) ALU_Flags
(
    .clk_i(clock_i),
    .reset_ni(reset_i),        // Typically reset after Branch instructions
    .ld_ni(alu_ld_i),
    .data_i(alu_to_flags),
    .data_o(alu_flags)
);

Register #(.DATA_WIDTH(DATA_WIDTH)) ALUResults
(
    .clk_i(clock_i),
    .reset_ni(reset_i),
    .ld_ni(alu_ld_i),
    .data_i(alu_to_out),       // ALU output
    .data_o(alu_res)
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
    signals[7] =  alu_to_out[0],  // white
    signals[6] =  alu_to_out[1],  // white
    signals[5] =  alu_to_out[2],  // white
    signals[4] =  alu_to_out[3],  // white
    signals[3] =  alu_to_out[4],  // white
    signals[2] =  alu_to_out[5],  // white
    signals[1] =  alu_to_out[6],  // white
    signals[0] =  alu_to_out[7];  // white

assign
    signals[8]   = alu_flags[0],  // Blue
    signals[9]   = alu_flags[1],  // Blue
    signals[10]  = alu_flags[2],  // Blue
    signals[11]  = alu_flags[3];  // Blue

assign
    signals[15] = alu_ld_i,   // Green  Z
    signals[14] = alu_op,     // Red    C
    signals[13] = src2[0],    // Yellow N
    signals[12] = src2[1];    // Yellow V

assign
    activity = clk_cyc;

endmodule  // top