`default_nettype none

// --------------------------------------------------------------------------
// Sequence control matrix
// ##### This is for the youtube video series. IGNORE IT!
// --------------------------------------------------------------------------
 
module SequenceControl
#(
    parameter DATA_WIDTH = 16
)
(
    input wire clk_i,
    input wire reset_ni,               // Active low
    // IR
    input wire [DATA_WIDTH-1:0] ir_i,  // Provides: Op-code, CN, Dest/Src regs
    output wire ir_ld_no,
    output wire ir_rst_no,
    // PC
    output wire pc_ld_no,
    output wire pc_rst_no,
    output wire pc_inc_no,
    output wire [PCSelectSize-1:0] pc_src_o,
    // Memory
    output wire mem_wr_no,
    output wire [AddrSelectSize-1:0] addr_src_o,
    // Output
    output wire out_ld_no,
    output wire out_sel_o,
    // Misc
    output wire ready_po,              // Active high
    output wire halt_po                // Active high
);

localparam PCSelectSize = 3;        // 8 possible sources
localparam AddrSelectSize = 2;      // 4 possible sources
localparam StateSize = 4;           // 16 possible states
localparam VectorStateSize = 2;     // 4 possible vector reset states

// Sequence states
localparam  S_Reset         = 4'b0000,
            S_FetchPCtoMEM  = 4'b0001,
            S_FetchMEMtoIR  = 4'b0010,
            S_Decode        = 4'b0011,
            S_Execute       = 4'b0100,
            S_Ready         = 4'b0101,
            S_HALT          = 4'b0110;

// Reset sequence states
localparam  S_Vector1       = 2'b00,
            S_Vector2       = 2'b01,
            S_Vector3       = 2'b10,
            S_Vector4       = 2'b11;

// Internal state signals
reg [StateSize-1:0] state;
reg [StateSize-1:0] next_state;

reg [VectorStateSize-1:0] vector_state;
reg [VectorStateSize-1:0] next_vector_state;

// Datapath Control Signals
reg ir_rst;
reg pc_inc;
reg pc_ld;
reg [PCSelectSize-1:0] pc_src;       // MUX_PC selector

reg stk_ld;
reg ir_ld;

reg out_ld;
reg out_sel;

reg mem_wr;
reg [1:0] addr_src;     // MUX_ADDR selector

// External Functional states
reg halt;
reg ready; // The "ready" flag is Set when the CPU has completed its reset activities.

// Once the reset sequence has complete this flag is Set.
reg resetComplete;

// Simulation
initial begin
    // Be default the CPU always attempts to start in Reset mode.
    state = S_Reset;
    // Also configure the reset sequence start state.
    vector_state = S_Vector1;
end

// -------------------------------------------------------------
// Combinational control signals
// -------------------------------------------------------------
always @(state, vector_state) begin

    // ======================================
    // Initial conditions on a *state* or *vector_state* change
    // ======================================
    ready = 1'b1;           // Default: CPU is ready
    resetComplete = 1'b1;   // Default: Reset is complete

    next_state = S_Reset;
    next_vector_state = S_Vector1;
    
    halt = 1'b0;        // Default to non-active of state (Active High)

    // PC
    pc_inc = 1'b1;      // Disable Increment PC
    pc_ld =  1'b1;      // Disable PC loading
    pc_src = 3'b000;    // Doesn't matter

    ir_rst = 1'b1;      // Disable resetting IR
    ir_ld = 1'b1;       // Disable IR loading

    // Output 
    out_ld = 1'b1;      // Disable output loading
    out_sel = 1'b0;     // Reg-File Source 1

    // Memory
    mem_wr = 1'b1;      // Disable Write (active low) i.e. Enable Read (Active high)
    addr_src = 2'b00;   // Select PC as source

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
                    ir_rst = 1'b0;      // Enable resetting IR

                    next_vector_state = S_Vector2;
                end
                S_Vector2: begin
                    `ifdef SIMULATE
                        $display("%d S_Vector2", $stime);
                    `endif
                    // PC is loaded and asserted to Memory.

                    next_vector_state = S_Vector3;
                end
                S_Vector3: begin
                    `ifdef SIMULATE
                        $display("%d S_Vector3", $stime);
                    `endif
                    // Memory data out is ready and asserted to IR
                    ir_ld = 1'b0;      // Enable IR loading

                    next_vector_state = S_Vector4;
                end
                S_Vector4: begin
                    `ifdef SIMULATE
                        $display("%d S_Vector4", $stime);
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
            ready = 1'b1;   // CPU is ready
            next_state = S_FetchPCtoMEM;
        end

        // Part 1 of fetch sequence: PC to Mem address input
        S_FetchPCtoMEM: begin
            `ifdef SIMULATE
                $display("%d S_FetchPCtoMEM", $stime);
            `endif

            // Next state
            next_state = S_FetchMEMtoIR;
        end

        // Part 2 of fetch sequence
        S_FetchMEMtoIR: begin
            `ifdef SIMULATE
                $display("%d S_FetchMEMtoIR", $stime);
            `endif

            next_state = S_HALT;

            ir_ld = 1'b0;       // Enable loading IR
            // Take advantage of the next clock to bump the PC
            pc_inc = 1'b0;      // Enable Increment PC
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

        default:
            next_state = S_Reset;

    endcase // End (state)
end

// -------------------------------------------------------------
// Sequence control (sync). Move to the next state on the
// rising edge of the next clock.
// -------------------------------------------------------------
always @(posedge clk_i) begin
    if (~reset_ni) begin
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
assign ir_rst_no = ir_rst;
assign pc_inc_no = pc_inc;
assign pc_ld_no = pc_ld;
assign pc_src_o = pc_src;
assign ir_ld_no = ir_ld;
assign mem_wr_no = mem_wr;
assign addr_src_o = addr_src;
assign halt_po = halt;
assign out_ld_no = out_ld;
assign out_sel_o = out_sel;
assign ready_po = ready;

endmodule
