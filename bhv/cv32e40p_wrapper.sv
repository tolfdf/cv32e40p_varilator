// Simple wrapper for cv32e40p core, WITHOUT UVM / tracer / assertions.
// Suitable for Verilator / simple testbenches.

`timescale 1ns/1ps

module cv32e40p_wrapper
  import cv32e40p_apu_core_pkg::*;   // APU parameters (APU_NARGS_CPU, etc.)
#(
  parameter PULP_XPULP       = 0,   // PULP ISA Extension
  parameter PULP_CLUSTER     = 0,   // PULP Cluster interface
  parameter FPU              = 0,   // Floating Point Unit
  parameter PULP_ZFINX       = 0,   // Float-in-GPRs
  parameter NUM_MHPMCOUNTERS = 1
)
(
  // ---------------------------------------------------------------------------
  // Clock and Reset
  // ---------------------------------------------------------------------------
  input  logic        clk_i,
  input  logic        rst_ni,

  input  logic        pulp_clock_en_i,   // PULP clock enable (only if PULP_CLUSTER = 1)
  input  logic        scan_cg_en_i,      // Enable all clock gates for testing

  // ---------------------------------------------------------------------------
  // Static configuration inputs (kept for compatibility)
  // Core itself uses its internal parameters; these are just "formal" ports.
  // ---------------------------------------------------------------------------
  input  logic [31:0] boot_addr_i,
  input  logic [31:0] mtvec_addr_i,
  input  logic [31:0] dm_halt_addr_i,
  input  logic [31:0] hart_id_i,
  input  logic [31:0] dm_exception_addr_i,

  // ---------------------------------------------------------------------------
  // Instruction memory interface
  // ---------------------------------------------------------------------------
  output logic        instr_req_o,
  input  logic        instr_gnt_i,
  input  logic        instr_rvalid_i,
  output logic [31:0] instr_addr_o,
  input  logic [31:0] instr_rdata_i,

  // ---------------------------------------------------------------------------
  // Data memory interface
  // ---------------------------------------------------------------------------
  output logic        data_req_o,
  input  logic        data_gnt_i,
  input  logic        data_rvalid_i,
  output logic        data_we_o,
  output logic [3:0]  data_be_o,
  output logic [31:0] data_addr_o,
  output logic [31:0] data_wdata_o,
  input  logic [31:0] data_rdata_i,

  // ---------------------------------------------------------------------------
  // APU interface
  // ---------------------------------------------------------------------------
  // handshake
  output logic                           apu_req_o,
  input  logic                           apu_gnt_i,
  // request channel
  output logic [APU_NARGS_CPU-1:0][31:0] apu_operands_o,
  output logic [APU_WOP_CPU-1:0]         apu_op_o,
  output logic [APU_NDSFLAGS_CPU-1:0]    apu_flags_o,
  // response channel
  input  logic                           apu_rvalid_i,
  input  logic [31:0]                    apu_result_i,
  input  logic [APU_NUSFLAGS_CPU-1:0]    apu_flags_i,

  // ---------------------------------------------------------------------------
  // Interrupt inputs
  // ---------------------------------------------------------------------------
  input  logic [31:0] irq_i,        // CLINT interrupts + extension
  output logic        irq_ack_o,
  output logic [4:0]  irq_id_o,

  // ---------------------------------------------------------------------------
  // Debug Interface
  // ---------------------------------------------------------------------------
  input  logic        debug_req_i,
  output logic        debug_havereset_o,
  output logic        debug_running_o,
  output logic        debug_halted_o,

  // ---------------------------------------------------------------------------
  // CPU Control Signals
  // ---------------------------------------------------------------------------
  input  logic        fetch_enable_i,
  output logic        core_sleep_o
);

  // ---------------------------------------------------------------------------
  // Core instance – no tracers / UVM / assertions
  // ---------------------------------------------------------------------------

  cv32e40p_core
  #(
    .PULP_XPULP       ( PULP_XPULP       ),
    .PULP_CLUSTER     ( PULP_CLUSTER     ),
    .FPU              ( FPU              ),
    .PULP_ZFINX       ( PULP_ZFINX       ),
    .NUM_MHPMCOUNTERS ( NUM_MHPMCOUNTERS )
  )
  core_i (
    // Clock and Reset
    .clk_i             ( clk_i             ),
    .rst_ni            ( rst_ni            ),

    .pulp_clock_en_i   ( pulp_clock_en_i   ),
    .scan_cg_en_i      ( scan_cg_en_i      ),

    // Instruction memory
    .instr_req_o       ( instr_req_o       ),
    .instr_gnt_i       ( instr_gnt_i       ),
    .instr_rvalid_i    ( instr_rvalid_i    ),
    .instr_addr_o      ( instr_addr_o      ),
    .instr_rdata_i     ( instr_rdata_i     ),

    // Data memory
    .data_req_o        ( data_req_o        ),
    .data_gnt_i        ( data_gnt_i        ),
    .data_rvalid_i     ( data_rvalid_i     ),
    .data_we_o         ( data_we_o         ),
    .data_be_o         ( data_be_o         ),
    .data_addr_o       ( data_addr_o       ),
    .data_wdata_o      ( data_wdata_o      ),
    .data_rdata_i      ( data_rdata_i      ),

    // APU interface
    .apu_req_o         ( apu_req_o         ),
    .apu_gnt_i         ( apu_gnt_i         ),
    .apu_operands_o    ( apu_operands_o    ),
    .apu_op_o          ( apu_op_o          ),
    .apu_flags_o       ( apu_flags_o       ),
    .apu_rvalid_i      ( apu_rvalid_i      ),
    .apu_result_i      ( apu_result_i      ),
    .apu_flags_i       ( apu_flags_i       ),

    // Interrupts
    .irq_i             ( irq_i             ),
    .irq_ack_o         ( irq_ack_o         ),
    .irq_id_o          ( irq_id_o          ),

    // Debug
    .debug_req_i       ( debug_req_i       ),
    .debug_havereset_o ( debug_havereset_o ),
    .debug_running_o   ( debug_running_o   ),
    .debug_halted_o    ( debug_halted_o    ),

    // Control
    .fetch_enable_i    ( fetch_enable_i    ),
    .core_sleep_o      ( core_sleep_o      )
  );

endmodule
