`default_nettype none

`undef SIMULATE

module top
(
    input wire clk,             // 25MHz clock input
    input wire clock_i,         // from uC to FPGA
    input wire reset_i,         // from uC to FPGA
    input wire mem_wr,          // from uC to FPGA
    input wire addr0,           // from uC to FPGA
    input wire addr1,           // from uC to FPGA
    output wire activity,       // Active clock indicator
    output wire [15:0] signals
);

// Properties: ports=1 bits=4096 rports=1 wports=0 dbits=8 abits=9 words=512

localparam DataWidth = 16;      // 16bit Data width
localparam AddrWidth = 8;       // 8bit Address width
localparam FREQUENCY = 1;//23'd10;  // 10Hz
localparam WriteData = 16'h0055;

reg [AddrWidth-1:0] mem_addr;
wire [DataWidth-1:0] mem_to_out;

// ----------------------------------------------------------
// Clock 
// ----------------------------------------------------------
localparam ClockSize = 25;
reg [ClockSize-1:0] clk_1hz_counter = ClockSize'b0;  // Hz clock generation counter
reg        clk_cyc = 1'b0;           // Hz clock

// Clock divder and generator
always @(posedge clk) begin
    if (clk_1hz_counter < ClockSize'b0010000000000000000000000)
        clk_1hz_counter <= clk_1hz_counter + FREQUENCY;
    else begin
        clk_1hz_counter <= ClockSize'b0;
        clk_cyc <= ~clk_cyc;
    end
end
 
always @(addr1, addr0) begin
    case ({addr1, addr0})
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

// ----------------------------------------------------------
// Modules
// ----------------------------------------------------------
Memory #(
    .WORDS(AddrWidth),
    .DATA_WIDTH(DataWidth)
) rom (
    .clk_i(clock_i & reset_i),
    .data_i(WriteData),
    .address_i(mem_addr),
    .write_en_ni(mem_wr),
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

// White led row (Right)
//     0   1   2   3   4   5   6   7
// Pin 139 138 142 141 135 134 137 136

// (Left)
//     B  B  B  B  Y  Y  R  G
//     8  9  10 11 12 13 14 15
// Pin 4  3 144 143 8  7  2  1

assign
    signals[7] =  mem_to_out[0],  // white
    signals[6] =  mem_to_out[1],  // white
    signals[5] =  mem_to_out[2],  // white
    signals[4] =  mem_to_out[3],  // white
    signals[3] =  mem_to_out[4],  // white
    signals[2] =  mem_to_out[5],  // white
    signals[1] =  mem_to_out[6],  // white
    signals[0] =  mem_to_out[7];  // white

assign
    signals[12] = addr0,
    signals[13] = addr1,
    signals[14] = mem_wr,
    signals[8]  = mem_addr[0],
    signals[9]  = mem_addr[1],
    signals[10] = mem_addr[2];

assign
    signals[11] = 1'b0,
    signals[15] = 1'b0;

assign
    activity = clk_cyc;

endmodule  // top