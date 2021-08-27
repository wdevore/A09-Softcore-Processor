`default_nettype none

module top
(
    // See pins.pcf for pin Definitions
    output pin1_usb_dp,     // USB pull-up enable, set low to disable
    output pin2_usb_dn,     // Both 1-2 are assigned Zero
    input  pin3_clk_16mhz,   // 16 MHz on-board clock -- UNUSED
    // pins 4-11 is the lower 8bits of the Output register
    output pin4,        // ALU results LSB
    output pin5,
    output pin6,
    output pin7,
    output pin8,
    output pin9,
    output pin10,       // SRC 2 ouput[0]
    output pin11,       // SRC 2 ouput[1]
    output pin12,       // ALU flag bit 0  Z
    output pin13,       // ALU flag bit 1  C
    output pin14_sdo,   // ALU flag bit 2  N
    output pin15_sdi,   // ALU flag bit 3  V
    output pin16_sck,   // SRC 1 ouput[0]
    output pin17_ss,    // SRC 1 ouput[1]
    input pin18,        // ALU load
    input pin19,        // SRC 1 clock
    input pin20,        // SRC 2 clock
    input pin21,        // Clock
    input pin22,        // Reset
    input pin23,        // ALU op bit 0
    output pin24        // ClockCyl
);

localparam DataWidth = 4;
localparam FlagSize = 4;

localparam FREQUENCY = 23'd4;  // 4Hz

// A macro alias
`define LOAD pin18
`define SRC1 pin19
`define SRC2 pin20
`define CLOCK pin21
`define RESET pin22
`define ALUOP pin23

wire [DataWidth-1:0] alu_to_out;
wire [DataWidth-1:0] alu_res;
wire [FlagSize-1:0] alu_to_flags;
wire [FlagSize-1:0] alu_flags;

reg [DataWidth-1:0] source1;
reg [DataWidth-1:0] source2;
reg [DataWidth-1:0] flags;

reg [3:0] alu_op;
reg [1:0] src1; // counter
reg [1:0] src2; // counter

reg [3:0] alu_op;

// ----------------------------------------------------------
// Clock unused
// ----------------------------------------------------------
reg [22:0] clk_1hz_counter = 23'b0;  // Hz clock generation counter
reg        clk_cyc = 1'b0;           // Hz clock
localparam FREQUENCY = 23'd4;  // 4Hz
  
// Clock divder and generator
always @(posedge pin3_clk_16mhz) begin
    if (clk_1hz_counter < 23'd7_999_999)
        clk_1hz_counter <= clk_1hz_counter + FREQUENCY;
    else begin
        clk_1hz_counter <= 23'b0;
        clk_cyc <= ~clk_cyc;
    end
end

// This may not happen for synthesis
initial begin
    source1 = 0;
    source2 = 0;
    src1 = 0;
    src2 = 0;
end

always @(`ALUOP) begin
    if (`ALUOP == 1'b0)
        alu_op = `ADD;
    else
        alu_op = `SUB;
end

always @(posedge `SRC1) begin
    src1 = src1 + 1;
    case (src1)
        2'b00:
            source1 = DataWidth'b0000;
        2'b01:
            source1 = DataWidth'b0001;
        2'b10:
            source1 = DataWidth'b1000;
        2'b11:
            source1 = DataWidth'b1111;
    endcase
end

always @(posedge `SRC2) begin
    src2 = src2 + 1;
    case (src2)
        2'b00:
            source2 = DataWidth'b0000;
        2'b01:
            source2 = DataWidth'b0001;
        2'b10:
            source2 = DataWidth'b1000;
        2'b11:
            source2 = DataWidth'b1100;
    endcase
end

// ----------------------------------------------------------
// Modules
// ----------------------------------------------------------

ALU #(.DATA_WIDTH(DataWidth)) Alu(
    .flags_i({FlagSize{1'b0}}),    // Not used yet
    .a_i(source1),
    .b_i(source2),
    .func_op_i(alu_op),
    .y_o(alu_to_out),
    .flags_o(alu_to_flags)
);

Register #(.DATA_WIDTH(4)) ALU_Flags
(
    .clk_i(`CLOCK),
    .reset_ni(`RESET),        // Typically reset after Branch instructions
    .ld_ni(`LOAD),
    .data_i(alu_to_flags),
    .data_o(alu_flags)
);

Register #(.DATA_WIDTH(DataWidth)) ALUResults
(
    .clk_i(`CLOCK),
    .reset_ni(`RESET),
    .ld_ni(`LOAD),
    .data_i(alu_to_out),       // ALU output
    .data_o(alu_res)
);

// ----------------------------------------------------------
// IO routing
// ----------------------------------------------------------
// Route Output wires to pins
assign
    pin4  = alu_res[0],
    pin5  = alu_res[1],
    pin6  = alu_res[2],
    pin7  = alu_res[3],
    pin8  = `LOAD,
    pin9  = `ALUOP,
    pin10 = src2[0],
    pin11 = src2[1];

assign
    pin12     = alu_flags[0],   // Green  Z
    pin13     = alu_flags[1],   // Red    C
    pin14_sdo = alu_flags[2],   // Yellow N
    pin15_sdi = alu_flags[3];   // Yellow V

assign
    pin16_sck     = src1[0],    // Blue
    pin17_ss      = src1[1];    // Blue

assign pin24 = clk_cyc;

// TinyFPGA standard pull pins defaults
assign
    pin1_usb_dp = 1'b0,
    pin2_usb_dn = 1'b0;

endmodule  // top