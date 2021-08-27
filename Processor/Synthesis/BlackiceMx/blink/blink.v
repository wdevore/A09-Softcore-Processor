/******************************************************************************
*                                                                             *
* Copyright 2016 myStorm Copyright and related                                *
* rights are licensed under the Solderpad Hardware License, Version 0.51      *
* (the “License”); you may not use this file except in compliance with        *
* the License. You may obtain a copy of the License at                        *
* http://solderpad.org/licenses/SHL-0.51. Unless required by applicable       *
* law or agreed to in writing, software, hardware and materials               *
* distributed under this License is distributed on an “AS IS” BASIS,          *
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or             *
* implied. See the License for the specific language governing                *
* permissions and limitations under the License.                              *
*                                                                             *
******************************************************************************/

// White led row (Right)
//     0   1   2   3   4   5   6   7
// Pin 139 138 142 141 135 134 137 136

// (Left)
//     B B B   B   Y  Y  R  G
//     8 9 10  11  12 13 14 15
// Pin 4 3 144 143 8  7  2  1

module blink(
	input wire clk,
	output wire led,
	output wire [15:0] signals
);

	reg [30:0] count;

	reg [3:0] div;

	assign led = count[30];
	
	assign signals[7] = count[30];
	assign signals[6] = count[29];
	assign signals[5] = count[28];
	assign signals[4] = count[27];
	assign signals[3] = count[26];
	assign signals[2] = count[25];
	assign signals[1] = count[24];
	assign signals[0] = count[23];

	assign signals[15] = count[22];
	assign signals[14] = count[21];
	assign signals[13] = count[20];
	assign signals[12] = count[19];
	assign signals[11] = count[18];
	assign signals[10] = count[17];
	assign signals[9] =  count[16];
	assign signals[8] =  count[15];

	always @(posedge clk) begin
		if (div == 4'b0000) begin
			count <= count + 1;
		end
		div <= div + 1;
	end


endmodule
