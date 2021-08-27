`default_nettype none

// Note:
// You could use the "include" macro to add the register.v
// module, however, I prefer to use the makefile to define
// any dependences.
// For example:
// `include "../../../Modules/register.v"

// The "top" module is our gateway to the outside world
// You can call it anything you like, just make sure to
// update the makefile to match.
// The default behaviour of the toolchain is to look for
// a module called "top".
module top
(
    // Standard pin configuration relative to TinyFPGA
    output wire pin1_usb_dp,     // USB pull-up enable, set low to disable
    output wire pin2_usb_dn,     // Both 1-2 are assigned Zero
    input  wire pin3_clk_16mhz,   // 16 MHz on-board clock -- UNUSED
    // pins 4-11 are the lower 8bits of the Register
    output wire pin4,        // LSB
    output wire pin5,
    output wire pin6,
    output wire pin7,
    output wire pin8,
    output wire pin9,
    output wire pin10,   
    output wire pin11,       // MSB
    output wire pin12,       // Pattern LSB
    output wire pin13,       // Pattern MSB
    output wire pin14_sdo,   // Unused Off
    output wire pin15_sdi,   // Unused Off
    output wire pin16_sck,   // Unused Off
    output wire pin17_ss,    // Unused Off
    output wire pin18,       // Unused Off
    output wire pin19,       // Unused Off
    output wire pin20,       // Unused Off
    input wire pin21,        // Clock
    input wire pin22,        // Reset
    input wire pin23,        // Load
    output wire pin24        // Clock aLive indicator
);

localparam PC_SelectSize = 3;
localparam ADDR_SelectSize = 2;
localparam FREQUENCY = 23'd4;  // 4Hz

// A macro alias
`define CLOCK pin21
`define RESET pin22
`define LOAD pin23

// ----------------------------------------------------------
// Clock for "alive" indicator
// ----------------------------------------------------------
reg [22:0] clk_1hz_counter = 23'b0;  // clock generation counter
reg        clk_cyc = 1'b0;           // clock

wire PC_rst;
wire PC_ld;
wire MAR_rst;
wire MAR_ld;

wire [PC_SelectSize-1:0] PC_Src;
wire [ADDR_SelectSize-1:0] ADDR_Src;

// Clock divder and generator
always @(posedge pin3_clk_16mhz) begin
    if (clk_1hz_counter < 23'd7_999_999)
        clk_1hz_counter <= clk_1hz_counter + FREQUENCY;
    else begin
        clk_1hz_counter <= 23'b0;
        clk_cyc <= ~clk_cyc;
    end
end

// ----------------------------------------------------------
// Module
// ----------------------------------------------------------
MealyCM matrix
(
    .clk_i(`CLOCK),        // negative edge
    .reset_ni(`RESET),     // active low
    .pc_rst_no(pin12),
    .pc_ld_no(pin13),
    .mar_rst_no(pin14_sdo),
    .mar_ld_no(pin15_sdi),
    .pc_src_o(PC_Src),
    .addr_src_o(ADDR_Src)
);


// ----------------------------------------------------------
// Main quest :-)
// ----------------------------------------------------------

// ----------------------------------------------------------
// IO routing
// ----------------------------------------------------------
assign
    pin4 = 0,   // white
    pin5 = 0,   // white
    pin6 = 0,   // white
    pin7 = 0,   // white
    pin8 = 0,   // white
    pin9 = 0,   // white
    pin10 = 0,  // white
    pin11 = 0;  // white

// assign
//     pin12 = 0, // Green
//     pin13 = 0; // Red

assign
    // pin14_sdo = 0,   // Unused Off
    // pin15_sdi = 0,   // Unused Off
    pin16_sck = 0,   // Unused Off
    pin17_ss = 0,    // Unused Off
    pin18 = 0,       // Unused Off
    pin19 = 0,       // Unused Off
    pin20 = 0;       // Unused Off

assign pin24 = clk_cyc;     // Green pulsing

// ----------------------------------------------------------
// TinyFPGA standard pull pin defaults
// ----------------------------------------------------------
assign
    pin1_usb_dp = 1'b0,
    pin2_usb_dn = 1'b0;

endmodule