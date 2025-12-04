`define CV32E40P_TRACE_EXECUTION
`timescale 1ns/1ps

module tb_top2
    #(parameter INSTR_RDATA_WIDTH = 32,
      parameter RAM_ADDR_WIDTH    = 18,
      parameter BOOT_ADDR         = 'h180,
      parameter PULP_XPULP        = 0,
      parameter PULP_CLUSTER      = 0,
      parameter FPU               = 0,
      parameter PULP_ZFINX        = 0,
      parameter NUM_MHPMCOUNTERS  = 1,
      parameter DM_HALT_ADDR      = 32'h1A110800
     );

    // Clock / Reset parameters (Verilator-safe)
    localparam time CLK_PHASE_HI         = 25ns;
    localparam time CLK_PHASE_LO         = 25ns;
    localparam time CLK_PERIOD           = CLK_PHASE_HI + CLK_PHASE_LO;

    localparam time STIM_APPLICATION_DEL = CLK_PERIOD * 0.1;
    localparam time RESP_ACQUISITION_DEL = CLK_PERIOD * 0.6;
    localparam time RESET_DEL            = STIM_APPLICATION_DEL;
    localparam int  RESET_WAIT_CYCLES    = 4;

    logic clk   = 1'b1;
    logic rst_n = 1'b0;

    int unsigned cycle_cnt_q;

    logic        tests_passed;
    logic        tests_failed;
    logic        exit_valid;
    logic [31:0] exit_value;

    // Plusargs handling
    logic plusargs_ready = 1'b0;
    logic want_vcd       = 1'b0;
    logic want_verbose   = 1'b0;

    initial begin
        #1;
        plusargs_ready = 1'b1;

        want_vcd     = $test$plusargs("vcd");
        want_verbose = $test$plusargs("verbose");

        if (want_vcd) begin
            $dumpfile("riscy_tb.vcd");
            $dumpvars(0, tb_top2);
        end

        $display("Simulation started at time %t", $time);
    end

    always @(posedge clk) begin
        if (core_memory.cv32e40p_memory_i.data_addr_i == 32'h1000_0000 &&
            core_memory.cv32e40p_memory_i.data_req_i &&
            core_memory.cv32e40p_memory_i.data_we_i) begin

            $write("%c", core_memory.cv32e40p_memory_i.data_wdata_i[7:0]);
        end
    end

    initial begin : clock_gen
        forever begin
            #CLK_PHASE_HI clk = 1'b0;
            #CLK_PHASE_LO clk = 1'b1;
        end
    end

    initial begin : reset_gen
        rst_n = 1'b0;
        #100;
        repeat (RESET_WAIT_CYCLES) @(posedge clk);
        #RESET_DEL rst_n = 1'b1;

        if (want_verbose)
            $display("Reset deasserted at %t", $time);
    end

    initial begin
        $timeformat(-9, 0, "ns", 9);
    end

    logic maxcycles_set = 1'b0;
    int   maxcycles_val = 0;

    initial begin
        #1;
        if ($value$plusargs("maxcycles=%d", maxcycles_val)) begin
            maxcycles_set = 1'b1;
            $display("Maxcycles set to %0d", maxcycles_val);
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cycle_cnt_q <= 0;
        end else begin
            cycle_cnt_q <= cycle_cnt_q + 1;

            if (maxcycles_set && cycle_cnt_q >= maxcycles_val) begin
                $fatal(2, "Simulation aborted: maxcycles=%0d reached", maxcycles_val);
            end
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
        end else begin
            if (tests_passed) begin
                $display("ALL TESTS PASSED");
            end

            if (tests_failed) begin
                $display("TEST(S) FAILED!");
                $finish;
            end

            if (exit_valid) begin
                if (exit_value == 0)
                    $display("[%t] EXIT SUCCESS", $time);
                else
                    $display("EXIT FAILURE: %0d", exit_value);
                $finish;
            end
        end
    end

    cv32e40p_core_memory
        #(
          .INSTR_RDATA_WIDTH(INSTR_RDATA_WIDTH),
          .RAM_ADDR_WIDTH   (RAM_ADDR_WIDTH),
          .BOOT_ADDR        (BOOT_ADDR),
          .PULP_XPULP       (PULP_XPULP),
          .PULP_CLUSTER     (PULP_CLUSTER),
          .FPU              (FPU),
          .PULP_ZFINX       (PULP_ZFINX),
          .NUM_MHPMCOUNTERS (NUM_MHPMCOUNTERS),
          .DM_HALT_ADDR     (DM_HALT_ADDR)
         )
    core_memory (
        .clk_i          (clk),
        .rst_ni         (rst_n),
        .tests_passed_o (tests_passed),
        .tests_failed_o (tests_failed),
        .exit_valid_o   (exit_valid),
        .exit_value_o   (exit_value)
    );

endmodule
