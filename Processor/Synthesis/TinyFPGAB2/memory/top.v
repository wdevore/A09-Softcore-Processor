`default_nettype none

`undef SIMULATE

module top
(
    // See pins.pcf for pin Definitions
    output pin1_usb_dp,     // USB pull-up enable, set low to disable
    output pin2_usb_dn,     // Both 1-2 are assigned Zero
    input  pin3_clk_16mhz,   // 16 MHz on-board clock
    // pins 4-11 is the lower 8bits of the Output register
    output pin4,        // LSB
    output pin5,
    output pin6,
    output pin7,
    output pin8,
    output pin9,
    output pin10,   
    output pin11,
    output pin12,       // Addr Select out 0
    output pin13,       // Addr Select out 0
    output pin14_sdo,   // Write Enable out
    output pin15_sdi,   // mem_addr 0
    output pin16_sck,   // mem_addr 1
    output pin17_ss,    // mem_addr 2
    input pin18,        // Write Enable
    input pin19,        // Addr select 0
    input pin20,        // Addr select 1
    input pin21,        // Clock
    input pin22,        // Reset <== Clock Hold
    output pin23,       // Unused
    output pin24        // ClockCyl
);

// Properties: ports=1 bits=4096 rports=1 wports=0 dbits=8 abits=9 words=512

localparam AddrWidth = 8;       // 8bit Address width
localparam DataWidth = 16;      // 16bit Data width
localparam FREQUENCY = 23'd10;  // 10Hz
localparam WriteData = 16'h0055;

// A macro alias
`define WE    pin18
`define Addr0 pin19
`define Addr1 pin20
`define CLOCK pin21
`define RESET pin22

reg [AddrWidth-1:0] mem_addr;
wire [DataWidth-1:0] mem_to_out;

// ----------------------------------------------------------
// Clock unused
// ----------------------------------------------------------
reg [22:0] clk_1hz_counter = 23'b0;  // Hz clock generation counter
reg        clk_cyc = 1'b0;           // Hz clock

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
// Modules
// ----------------------------------------------------------

initial begin
    mem_addr = {AddrWidth{1'b0}};
end

always @(`Addr1, `Addr0) begin
    case ({`Addr1, `Addr0})
        2'b00:
            mem_addr = AddrWidth'h00;
        2'b01:
            mem_addr = AddrWidth'h01;
        2'b10:
            mem_addr = AddrWidth'h02;
        2'b11:
            mem_addr = AddrWidth'hFF;
    endcase    
end

Memory #(
    .WORDS(AddrWidth),
    .DATA_WIDTH(DataWidth)
) rom (
    .clk_i(`CLOCK & `RESET),
    .data_i(WriteData),
    .address_i(mem_addr),
    .write_en_ni(`WE),
    .data_o(mem_to_out)
);

// We can't load the MEM from here. It's done from memory.v
// initial $readmemh (`ROM, rom.mem, 0, 6);
// TODO #############
// Need to add 3us delay before accessing the ROM.
// This is an issue with the Lattice FPGA, perhaps to load the ROM from
// the configuration bitstream.

// ----------------------------------------------------------
// IO routing
// ----------------------------------------------------------
// Route Output wires to pins
assign
    pin4  = mem_to_out[0],
    pin5  = mem_to_out[1],
    pin6  = mem_to_out[2],
    pin7  = mem_to_out[3],
    pin8  = mem_to_out[4],
    pin9  = mem_to_out[5],
    pin10 = mem_to_out[6],
    pin11 = mem_to_out[7];

assign
    pin12     = `Addr0,
    pin13     = `Addr1,
    pin14_sdo = `WE,
    pin15_sdi = mem_addr[0],
    pin16_sck = mem_addr[1],
    pin17_ss  = mem_addr[2];

assign
    pin23 = 1'b0,
    pin24 = clk_cyc;

// TinyFPGA standard pull pins defaults
assign
    pin1_usb_dp = 1'b0,
    pin2_usb_dn = 1'b0;

endmodule  // top