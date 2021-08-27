`default_nettype none

// --------------------------------------------------------------------------
// Sequence control matrix
// --------------------------------------------------------------------------

module SequenceControl
#(
    parameter DATA_WIDTH = 16
)
(
    input wire clk_i,
    input wire [DATA_WIDTH-1:0] ir_i,  // Provides: Op-code, CN, Dest/Src regs
    input wire [ALUFlgCnt-1:0] alu_flags_i,
    input wire reset_ni,               // Active low
    // Branch and Stack
    output wire stk_ld_o,
    output wire bra_src_o,
    // IR
    output wire ir_ld_o,
    // PC
    output wire pc_ld_o,
    output wire pc_rst_o,
    output wire pc_inc_o,
    output wire [PCSelectSize-1:0] pc_src_o,
    // Memory
    output wire mem_wr_o,
    output wire [AddrSelectSize-1:0] addr_src_o,
    // Regster File
    output wire reg_we_o,
    output wire [DataSrcSelectSize-1:0] data_src_o,
    // ALU
    output wire [ALUOpSize-1:0] alu_op_o,       // ALU operation: ADD, SUB etc.
    output wire alu_ld_o,
    output wire flg_ld_o,
    output wire flg_rst_o,
    // Output
    output wire out_ld_o,
    output wire out_sel_o,      // 1 Bit
    // External Signals
    output wire ready_o,              // Active high
    output wire halt_o                // Active high
);

localparam ALUOpSize = 4;           // 16 max operations
localparam ALUFlgCnt = 4;           // 4 flags
localparam PCSelectSize = 3;        // 8 possible sources
localparam AddrSelectSize = 2;      // 4 possible sources
localparam DataSrcSelectSize = 2;   // 4 possible sources
localparam StateSize = 4;
localparam VectorStateSize = 2;

// ---------------------------------------------------
// Sequence states
// ---------------------------------------------------
localparam  S_Reset          = 4'b0000,
            S_Fetch          = 4'b0001,
            S_Decode         = 4'b0010,
            S_ALUExecute     = 4'b0011,
            S_BasicExecute   = 4'b0100,
            S_Ready          = 4'b0101,
            S_HALT           = 4'b0110;

// Reset sequence states
localparam  S_Vector1       = 2'b00,
            S_Vector2       = 2'b01,
            S_Vector3       = 2'b10;

// ---------------------------------------------------
// Bit field definitions
// ---------------------------------------------------
`define OPCODE ir_i[15:12]    // op-code field

`define REG_SRC1 ir_i[2:0]
`define REG_SRC2 ir_i[5:3]
`define REG_DEST ir_i[8:6]    // For LDI it is different

`define IgnoreDest ir_i[10]    // Used mostly CMP for comparisons

// The ALU operation *is* the instruction itself.
`define ALUOp  ir_i[15:12]

`define ZFlag alu_flags_i[0] // Zero results
`define CFlag alu_flags_i[1] // Carry generated
`define NFlag alu_flags_i[2] // Negative bit set -- Sign
`define VFlag alu_flags_i[3] // Overflow occured

// ---------------------------------------------------
// Internal state signals
// ---------------------------------------------------
reg [StateSize-1:0] state;        // 3Bits for state
reg [StateSize-1:0] next_state;   // 3Bits for next state

reg [VectorStateSize-1:0] vector_state;
reg [VectorStateSize-1:0] next_vector_state;

// ---------------------------------------------------
// External Functional states
// ---------------------------------------------------
reg halt;
reg ready; // The "ready" flag is Set when the CPU has complete its reset activities.

// ---------------------------------------------------
// Internal signals
// ---------------------------------------------------
// Once the reset sequence has complete this flag is Set.
reg resetComplete;

reg pc_rst;             // PC reset
reg pc_inc;             // PC increment
reg pc_ld;
reg [PCSelectSize-1:0] pc_src;       // MUX_PC selector

reg bra_src;
reg stk_ld;
reg ir_ld;

reg out_ld;
reg out_sel;

reg flg_ld;
reg flg_rst;
reg alu_ld;
reg [ALUOpSize-1:0] alu_op;

reg mem_wr;
reg [1:0] addr_src;     // MUX_ADDR selector

reg reg_we;
reg [1:0] data_src;     // MUX_DATA selector

// ---------------------------------------------------
// Simulation
// ---------------------------------------------------
initial begin
    // Be default the CPU always attempts to start in Reset mode.
    state = S_Reset;
    // Also configure the reset sequence start state.
    vector_state = S_Vector1;
end

// Used for FPGA Simlation debugging
`ifdef SIMULATE
    reg [15:12] opCode;
    always @* begin
        opCode = `OPCODE;
    end
`endif    

// -------------------------------------------------------------
// Combinational control signals
// -------------------------------------------------------------
always @(state, vector_state) begin

    // ======================================
    // Initial conditions on a *state* or *vector_state* change
    // ======================================
    ready = 1'b1;           // Default: CPU is ready           -- Green
    resetComplete = 1'b1;   // Default: Reset is complete

    next_state = S_Reset;
    next_vector_state = S_Vector1;
    
    halt = 1'b0;        // Disable halt regardless of state    -- Red

    // PC
    pc_rst = 1'b1;      // Disable resetting PC
    pc_inc = 1'b1;      // Disable Increment PC  -- Red
    pc_ld =  1'b1;      // Disable PC loading    -- Blue
    pc_src = 3'b111;    // Select PC
    bra_src = 1'b0;     // Select Sign extend

    // Misc: Stack, Output
    stk_ld = 1'b1;      // Disable Stack loading
    ir_ld = 1'b1;       // Disable IR loading       -- Yellow

    // Output 
    out_ld = 1'b1;      // Disable output loading  -- Yellow
    out_sel = 1'b0;     // Reg-File

    // ALU and Flags
    flg_rst = 1'b1;     // Disbled ALU flags reset
    flg_ld = 1'b1;      // Disable Flag state loading
    alu_ld = 1'b1;      // Disable loading ALU output
    alu_op = 4'b1111;   // Unknown ALU operation

    // Memory
    mem_wr = 1'b1;      // Disable Write (active low) i.e. Enable Read (Active high)
    addr_src = 2'b00;   // Select PC as source

    // Reg-File
    reg_we = 1'b1;      // Disable writing to reg file      -- Yellow
    data_src = 2'b00;   // Select Zero extended-L source

    // ======================================
    // Main state machine
    // ======================================
    case (state)
        // CPU is in a reset state waiting for the Reset flag to deactivate (High)
        // While in this state the CPU continuosly loads the Reset-Vector.
        S_Reset: begin
            `ifdef SIMULATE
                $display("%d S_Reset", $stime);
            `endif
            ready = 1'b0;               // CPU is not ready while resetting.
            resetComplete = 1'b0;       // Reset not complete
            
            // ------------------------------------------------------
            // Vector reset sequence
            // ------------------------------------------------------
            case (vector_state)
                S_Vector1: begin
                    `ifdef SIMULATE
                        $display("%d S_Vector1", $stime);
                    `endif
                    pc_src = 3'b010;    // Select Reset vector constant
                    pc_ld = 1'b0;       // Enable loading PC

                    next_vector_state = S_Vector2;
                end
                S_Vector2: begin
                    `ifdef SIMULATE
                        $display("%d S_Vector2", $stime);
                    `endif

                    `ifdef SIMULATE
                        $display("%d S_Vector3", $stime);
                    `endif
                    // Memory data out is ready and asserted to IR
                    ir_ld = 1'b0;      // Enable IR loading

                    next_vector_state = S_Vector3;
                end
                S_Vector3: begin
                    `ifdef SIMULATE
                        $display("%d S_Vector3", $stime);
                    `endif
                    // IR is loaded. Route Zero-extend-L to PC
                    pc_src = 3'b100;        // Select Zero-extend-L
                    pc_ld = 1'b0;           // Enable loading PC
                    resetComplete = 1'b1;   // Reset completed

                    // Reset completes by the next negedge clock
                    // Transition to the ready state now that the PC is loaded
                    // with the address of the first instruction.
                    next_state = S_Ready;
                end
                default: begin
                    `ifdef SIMULATE
                        $display("%d ###### default Vector state ######", $stime);
                    `endif
                    next_vector_state = S_Vector1;
                end
            endcase
        end

        S_Ready: begin
            // We enter this state at the end of the Reset sequence.
            `ifdef SIMULATE
                $display("%d S_Ready", $stime);
            `endif

            // Manipulate signals if necessary. None at this time.
            // You may even have another sub-sequence to handle any
            // Ready functionality.
            next_state = S_Fetch;
        end

        S_HALT: begin
            `ifdef SIMULATE
                $display("%d S_HALT", $stime);
            `endif
            // We can only exit this state on a reset.
            next_state = S_HALT;
            halt = 1'b1;
            ready = 1'b0;
        end

        S_Fetch: begin
            `ifdef SIMULATE
                $display("%d S_Fetch", $stime);
            `endif

            next_state = S_Decode;

            ir_ld = 1'b0;       // Enable loading IR

            // Also, take advantage of the next clock to bump the PC
            pc_inc = 1'b0;      // Enable Increment PC
        end

        S_Decode: begin
            `ifdef SIMULATE
                $display("%d S_Decode : {%b}", $stime, `OPCODE);
            `endif

            // --- Next state setup -------------
            next_state = S_Fetch;

            case (`OPCODE)
                `NOP: begin // No operation (a.k.a. do nothing)
                    // Simply loop back to fetching the next instruction
                    `ifdef SIMULATE
                        $display("%d OPCODE: NOP", $stime);
                    `endif
                end

                // ---------------------------------------------------
                // ALU
                // ---------------------------------------------------
                `ADD: begin // ALU add operation
                    `ifdef SIMULATE
                        $display("%d OPCODE: ADD", $stime);
                    `endif

                    next_state = S_ALUExecute;
                    alu_op = `ALUOp;
                end

                `SUB: begin // ALU subtract or compare operation
                    if (`IgnoreDest == 1'b0) begin
                        `ifdef SIMULATE
                            $display("%d OPCODE: SUB", $stime);
                        `endif
                        // The destination is required so an extra cycle is needed.
                        next_state = S_ALUExecute;
                    end
                    else begin
                        // For some instructions, for example CMP,
                        // we don't care about a destination just the ALU flags.
                        `ifdef SIMULATE
                            $display("%d OPCODE: CMP", $stime);
                        `endif
                    end

                    alu_op = `ALUOp;
                end

                `SHL: begin // ALU Shift-left Logical operation
                    `ifdef SIMULATE
                        $display("%d OPCODE: SHL", $stime);
                    `endif

                    next_state = S_ALUExecute;
                    alu_op = `ALUOp;
                end

                `SHR: begin // ALU Shift-right Logical operation
                    `ifdef SIMULATE
                        $display("%d OPCODE: SHR", $stime);
                    `endif

                    next_state = S_ALUExecute;
                    alu_op = `ALUOp;
                end

                // ---------------------------------------------------
                // Branch Directs
                // ---------------------------------------------------
                `BNE: begin
                    // The lower 8bits contains a relative signed address
                    // The address is relative to the BNE instruction itself.
                    `ifdef SIMULATE
                        $display("%d OPCODE: BNE [V:%0b,N:%0b,C:%0b,Z:%0b] : %4b", $stime, `VFlag, `NFlag, `CFlag, `ZFlag, alu_flags_i);
                    `endif

                    // If Z-flag NOT Set then branch
                    if (`ZFlag == 1'b0) begin
                        `ifdef SIMULATE
                            $display("%d +++ Taking branch +++", $stime);
                        `endif
                        bra_src = 1'b0;     // Select Signed Extended

                        pc_ld = 1'b0;       // Enable PC load
                        pc_src = 3'b000;     // Select Branch address source

                        // The flags aren't needed after the flag
                        // has been checked.
                        flg_rst = 1'b0;     // Enable ALU flags reset

                        // Add extra cycle for branch to complete
                        next_state = S_BasicExecute;
                    end
                end

                // ---------------------------------------------------
                // Flow
                // ---------------------------------------------------
                `JMP: begin // Jump
                    // Jmp to an absolute address specified by Source 1
                    `ifdef SIMULATE
                        $display("%d OPCODE: JMP", $stime);
                    `endif

                    pc_src = 3'b011;    // Select Reg-File Source 1
                    pc_ld = 1'b0;       // Enable loading PC

                    // Add extra cycle for jump to complete
                    next_state = S_BasicExecute;
                end

                // A JMI "Jump immediate" would allow embedding an 8 bit
                // signed address instead of loading a register with an
                // address.

                `JPL: begin // Jump and Link = Call and Return
                    `ifdef SIMULATE
                        $display("%d OPCODE: JPL", $stime);
                    `endif                        

                    pc_src = 3'b011;    // Select Reg-File Source 1
                    pc_ld = 1'b0;       // Enable loading PC
                    stk_ld = 1'b0;      // Enable loading Stack reg with return address

                    // Add extra cycle for jump to complete
                    next_state = S_BasicExecute;
                end

                `RET: begin // Return from JPL instruction
                    `ifdef SIMULATE
                        $display("%d OPCODE: RET", $stime);
                    `endif
                    pc_src = 3'b001;    // Select Stack address
                    pc_ld = 1'b0;       // Enable loading PC
                    // Add extra cycle for Return to complete
                    next_state = S_BasicExecute;
                end

                // ---------------------------------------------------
                // Load/Store
                // ---------------------------------------------------
                `LDI: begin // Load Immediate.
                    // The lower 8bits are loaded into the desination register.
                    // The bits are zero-extended-L
                    // The destination reg = IR[10:8]
                    `ifdef SIMULATE
                        $display("%d OPCODE: LDI", $stime);
                    `endif
                    
                    reg_we = 1'b0;      // Enable write to reg file
                    data_src = 2'b00;   // Select Zero extended-L source
                end

                // ---------------------------------------------------
                // Misc/Output
                // ---------------------------------------------------
                `OTR: begin // Copy Reg-file to output register
                    `ifdef SIMULATE
                        $display("%d OPCODE: OTR", $stime);
                    `endif

                    // Source is a Reg-File.
                    out_ld = 1'b0;      // Enable output loading
                    out_sel = 1'b0;     // Select Reg-File source
                end

                `HLT: begin // halt
                    `ifdef SIMULATE
                        $display("%d OPCODE: HLT", $stime);
                    `endif
                    // Signals CPU to stop
                    next_state = S_HALT;
                end

            endcase

            // If it's an ALU instruction then set signals
            if (alu_op != 4'b1111) begin
                alu_ld = 1'b0;      // Enable loading ALU output
                flg_ld = 1'b0;      // Enable loading ALU flags
            end
        end

        S_BasicExecute: begin
            `ifdef SIMULATE
                $display("%d S_BasicExecute", $stime);
            `endif

            // This state allows other instructions an extra clock
            // to complete their sequence.
            // The next state is alway fetch
            next_state = S_Fetch;
        end

        S_ALUExecute: begin
            `ifdef SIMULATE
                $display("%d S_ALUExecute Dest Reg Store", $stime);
            `endif

            // The next state is alway fetch
            next_state = S_Fetch;

            data_src = 2'b10;    // Select ALU output
            reg_we = 1'b0;       // Enable write to Reg File
        end

        default:
            next_state = S_Reset;

    endcase // End (state)
end

// -------------------------------------------------------------
// Sequence control (sync). Move to the next state on the
// rising edge of the next clock.
// -------------------------------------------------------------
always @(posedge clk_i) begin
    if (!reset_ni) begin
        state <= S_Reset;
        vector_state <= S_Vector1;
    end
    else
        if (resetComplete)
            state <= next_state;
        else begin
            state <= S_Reset;
            vector_state <= next_vector_state;
        end
end

// -------------------------------------------------------------
// Route internal signals to outputs
// -------------------------------------------------------------
assign pc_rst_o = pc_rst;
assign pc_inc_o = pc_inc;
assign pc_ld_o = pc_ld;
assign pc_src_o = pc_src;
assign ir_ld_o = ir_ld;
assign stk_ld_o = stk_ld;
assign bra_src_o = bra_src;
assign flg_ld_o = flg_ld;
assign flg_rst_o = flg_rst;
assign mem_wr_o = mem_wr;
assign addr_src_o = addr_src;
assign halt_o = halt;
assign reg_we_o = reg_we;
assign data_src_o = data_src;
assign alu_ld_o = alu_ld;
assign alu_op_o = alu_op;
assign out_ld_o = out_ld;
assign out_sel_o = out_sel;
assign ready_o = ready;

endmodule
