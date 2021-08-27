`default_nettype none

// --------------------------------------------------------------------------
// A09 CPU module
// --------------------------------------------------------------------------
`include "../../Modules/constants.v"

module CPU
#(
    parameter DATA_WIDTH = 16,       // Data path width
    parameter ADDR_WIDTH = 8,        // Address range 2^8 = 256 bytes
    parameter WORD_SIZE = 1,         // Word size when Inc PC. 1 = 2bytes
    parameter RegFileSelectSize = 3  // Max register count, 2^3 = 8 regs
)
(
    input wire clk_i,
    input wire reset_ni,
    output wire ready_o,
    output wire halt_o,
    output wire [DATA_WIDTH-1:0] out_o,   // Visual debug
    output wire [DATA_WIDTH-1:0] ir_o,    // Visual debug
    output wire ir_ld_o,                  // Visual debug
    output wire mem_wr_o,                 // Visual debug
    output wire out_ld_o,                 // Visual debug
    output wire alu_ld_o                  // Visual debug
);

localparam ALUOpsSize = 4;
localparam ALUFlagSize = 4;
localparam PCSelectSize = 3;
localparam AddrSize = 8;  // AddrSize is the number of bits for an address

// --------------------------------------------------
// Internal signals (a.k.a. wires) between modules
// --------------------------------------------------
wire [DATA_WIDTH-1:0] pc_out;
wire [DATA_WIDTH-1:0] mux_pc_to_pc;
wire [DATA_WIDTH-1:0] mem_to_out;

wire [DATA_WIDTH-1:0] mux_bra_to_alu2;
wire [DATA_WIDTH-1:0] mux_addr_to_mem_addr;
wire [DATA_WIDTH-1:0] mux_data_to_regfile;
wire [DATA_WIDTH-1:0] mux_out_to_output;

wire [DATA_WIDTH-1:0] stk_to_mux_pc;
wire [DATA_WIDTH-1:0] source1;
wire [DATA_WIDTH-1:0] source2;

wire [DATA_WIDTH-1:0] absoluteZeroExtH;
wire [DATA_WIDTH-1:0] absoluteZeroExtL;
wire [DATA_WIDTH-1:0] relativeSignedExt;
wire [DATA_WIDTH-1:0] branchAddress;

wire [DATA_WIDTH-1:0] output_port;

wire [DATA_WIDTH-1:0] alu_res_to_mux_data;
wire [DATA_WIDTH-1:0] alu_to_out;
wire [ALUFlagSize-1:0] alu_to_flags;

// ---------------------------------------------------
// Control matrix signals
// ---------------------------------------------------
// Branch and Stack
wire stk_ld;
wire bra_src;
// IR
wire [DATA_WIDTH-1:0] ir;
wire ir_ld;
// PC
wire pc_ld;
wire pc_rst;
wire pc_inc;
wire [PCSelectSize-1:0] pc_src;
// Memory
wire mem_wr;
wire [1:0] addr_src;     // 2Bits
// Regster File
wire reg_we;
wire [1:0] data_src;     // 2Bits
// ALU
wire [ALUFlagSize-1:0] alu_flgs_to_scm;
wire [ALUOpsSize-1:0] alu_op;       // ALU operation: ADD, SUB etc.
wire flg_ld;
wire alu_ld;
wire flg_rst;
// Output
wire out_sel;     // 1 Bit
wire out_ld;

// External signals
wire ready;
wire halt;

// ---------------------------------------------------------------
// Defines for easier references
// ---------------------------------------------------------------

// IR register-file bit fields
`define DestRegLDI  ir[10:8]    // For LDI instruction
`define DestReg     ir[8:6]
`define Src2Reg     ir[5:3]
`define Src1Reg     ir[2:0]

// The instruction code and ALU operation are syncronized.
`define Instr    ir[15:12]
`define ALUOp    ir[15:12]

`define AddrH    ir[10:3]           // zero-extend-H
`define AddrL    ir[AddrSize-1:0]   // zero-extend-L

// ---------------------------------------------------------------
// Sign extenders
// ---------------------------------------------------------------

// Zero extend higher/middle absolute address bits from the IR register.
assign absoluteZeroExtH = {{DATA_WIDTH-AddrSize{1'b0}}, `AddrH};
// Zero extend lower absolute address bits from the IR register.
assign absoluteZeroExtL = {{DATA_WIDTH-AddrSize{1'b0}}, `AddrL};

// Sign extend the lower signed address bit from the IR register.
assign relativeSignedExt = {{DATA_WIDTH-AddrSize{ir[AddrSize-1]}}, `AddrL};

// ---------------------------------------------------------------
// Vectoring
// ---------------------------------------------------------------

// To generate the branch address we need to subtract WORD_SIZE from the PC
// because the PC has been auto-incremented to the next address which
// means it isn't at the current address.
assign branchAddress = mux_bra_to_alu2 + (pc_out - WORD_SIZE);

// Reset vector fetched referencing the bottom of memory
localparam ResetVector = 16'hFF;

// -------- Module ------------------------------------------
// Sequence control matrix
// ----------------------------------------------------------
SequenceControl #(.DATA_WIDTH(DATA_WIDTH)) ControlMatrix
(
    .clk_i(clk_i),
    .ir_i(ir),
    .alu_flags_i(alu_flgs_to_scm),
    .reset_ni(reset_ni),
    .stk_ld_o(stk_ld),
    .bra_src_o(bra_src),
    .ir_ld_o(ir_ld),
    .pc_ld_o(pc_ld),
    .pc_rst_o(pc_rst),
    .pc_inc_o(pc_inc),
    .pc_src_o(pc_src),
    .mem_wr_o(mem_wr),
    .addr_src_o(addr_src),
    .reg_we_o(reg_we),
    .data_src_o(data_src),
    .alu_op_o(alu_op),
    .alu_ld_o(alu_ld),
    .flg_ld_o(flg_ld),
    .flg_rst_o(flg_rst),
    .out_ld_o(out_ld),
    .out_sel_o(out_sel),
    .ready_o(ready),
    .halt_o(halt)
);

// -------- Module ------------------------------------------
// Create PC and bind to data input and controls
// ----------------------------------------------------------
ProgramCounter #(
    .DATA_WIDTH(DATA_WIDTH),
    .WORD_SIZE(WORD_SIZE)) PC
(
    .clk_i(clk_i),
    .reset_ni(pc_rst),
    .ld_ni(pc_ld),
    .inc_ni(pc_inc),
    .data_i(mux_pc_to_pc),
    .data_o(pc_out)
);

// -------- Module ------------------------------------------
// Create memory and connect to IR 
// ----------------------------------------------------------
Memory memory (
    .clk_i(clk_i),
    .data_i(source1),              // Register file src 1
    .address_i(mux_addr_to_mem_addr[ADDR_WIDTH-1:0]),
    .write_en_ni(mem_wr),
    .data_o(mem_to_out)
);

// -------- Module ------------------------------------------
// Create register file and connect to ALU
// ----------------------------------------------------------
RegisterFile #(.DATA_WIDTH(DATA_WIDTH)) RegFile
(
    .clk_i(clk_i),
    .reg_we_i(reg_we),
    .data_i(mux_data_to_regfile),
    .reg_dst_i(destReg),          // IR[8:6] or IR[10:8]
    .reg_src1_i(`Src1Reg),
    .reg_src2_i(`Src2Reg),
    .src1_o(source1),             // Output
    .src2_o(source2)              // Output
);

// -------- Module ------------------------------------------
// Create ALU and connect to Register file and memory
// ----------------------------------------------------------
ALU #(.DATA_WIDTH(DATA_WIDTH)) Alu(
    .flags_i({ALUFlagSize{1'b0}}),    // Not used yet
    .a_i(source1),
    .b_i(source2),
    .func_op_i(`ALUOp),
    .y_o(alu_to_out),
    .flags_o(alu_to_flags)
);

// ======================================================
// Multiplexers
// ======================================================

// -------- Module ------------------------------------------
// Create MUX_ADDR and connect to PC and Memory
// ----------------------------------------------------------
Mux4 #(
    .DATA_WIDTH(DATA_WIDTH)) MUX_ADDR
(
    .select_i(addr_src),
    .data0_i(pc_out),              // PC source
    .data1_i(source2),             // Source 2
    .data2_i(absoluteZeroExtL),    // zero extended lower
    .data3_i(absoluteZeroExtH),    // zero extended higher
    .data_o(mux_addr_to_mem_addr)
);

Mux8 #(
    .DATA_WIDTH(DATA_WIDTH)) MUX_PC
(
    .select_i(pc_src),
    .data0_i(branchAddress),       // Branch address
    .data1_i(stk_to_mux_pc),       // Return address
    .data2_i(ResetVector),         // Reset Vector
    .data3_i(source1),             // Reg-file src 1 (address)
    .data4_i(absoluteZeroExtL),    // Zero-extend-L
    .data5_i({DATA_WIDTH{1'b0}}),   // Unused
    .data6_i({DATA_WIDTH{1'b0}}),   // Unused
    .data7_i({DATA_WIDTH{1'b0}}),   // Unused
    .data_o(mux_pc_to_pc)
);

Mux2 #(
    .DATA_WIDTH(DATA_WIDTH)) MUX_BRA
(
    .select_i(bra_src),
    .data0_i(relativeSignedExt),    // sign extended
    .data1_i(source1),              // Register file src 1
    .data_o(mux_bra_to_alu2)
);

Mux4 #(
    .DATA_WIDTH(DATA_WIDTH)) MUX_DATA
(
    .select_i(data_src),
    .data0_i(absoluteZeroExtL),    // zero extended lower
    .data1_i(mem_to_out),          // Memory data out
    .data2_i(alu_res_to_mux_data), // ALU output
    .data3_i({DATA_WIDTH{1'b0}}),   // Unused
    .data_o(mux_data_to_regfile)
);

Mux2 #(
    .DATA_WIDTH(DATA_WIDTH)) MUX_OUT
(
    .select_i(out_sel),
    .data0_i(source1),             // Reg-File
    .data1_i({DATA_WIDTH{1'b0}}),   // Unused
    .data_o(mux_out_to_output)
);

// MUX_DST
wire [2:0] destReg; // 3 bits in size
assign destReg = `Instr == `LDI ? `DestRegLDI : `DestReg;

// ======================================================
// Registers
// ======================================================

// -------- Module ------------------------------------------
// Create IR and connect to putput
// ----------------------------------------------------------
Register #(.DATA_WIDTH(DATA_WIDTH)) IR
(
    .clk_i(clk_i),
    .reset_ni(reset_ni),
    .ld_ni(ir_ld),
    .data_i(mem_to_out),
    .data_o(ir)
);

Register #(.DATA_WIDTH(DATA_WIDTH)) Stack
(
    .clk_i(clk_i),
    .reset_ni(reset_ni),
    .ld_ni(stk_ld),
    .data_i(pc_out),    // No need adjust PC because it sits at the next addr.
    .data_o(stk_to_mux_pc)
);

Register #(.DATA_WIDTH(DATA_WIDTH)) ALUResults
(
    .clk_i(clk_i),
    .reset_ni(reset_ni),
    .ld_ni(alu_ld),
    .data_i(alu_to_out),       // ALU output
    .data_o(alu_res_to_mux_data)
);

// The ALU flags could feed the control matrix and
// feed back into the ALU, however, for A09 only,
// the control matrix is feed.
Register #(.DATA_WIDTH(ALUFlagSize)) ALU_Flags
(
    .clk_i(clk_i),
    .reset_ni(flg_rst),        // Typically Reset after Branch instructions
    .ld_ni(flg_ld),
    .data_i(alu_to_flags),
    .data_o(alu_flgs_to_scm)
);

// Output register. The output wires are typically connected to FPGA pins.
Register #(.DATA_WIDTH(DATA_WIDTH)) OutputR
(
    .clk_i(clk_i),
    .reset_ni(reset_ni),
    .ld_ni(out_ld),
    .data_i(mux_out_to_output),       // ALU output
    .data_o(output_port)
);

// ---------------------------------------------------------------
// Route signals to module outputs
// ---------------------------------------------------------------
// Visual debugging. Routes internal signals to cpu output
assign ir_o = ir;
assign alu_ld_o = alu_ld;
assign out_o = output_port;
assign ready_o = ready;
assign halt_o = halt;

endmodule
