// Copyright 2017 Embecosm Limited
// Copyright 2018 Robert Balas
// Copyright...
// (keep your original header / license text)

// Top level wrapper for a RI5CY / CV32E40P testbench

`define CV32E40P_TRACE_EXECUTION
`timescale 1ns/1ps

module tb_top
    #(parameter INSTR_RDATA_WIDTH = 32,
      parameter RAM_ADDR_WIDTH    = 18,
      parameter BOOT_ADDR         = 32'h00000180,
      parameter PULP_XPULP        = 0,
      parameter PULP_CLUSTER      = 0,
      parameter FPU               = 0,
      parameter PULP_ZFINX        = 0,
      parameter NUM_MHPMCOUNTERS  = 1,
      parameter DM_HALTADDRESS    = 32'h1A110800);

    // Clock parameters
    const time CLK_PHASE_HI         = 5ns;
    const time CLK_PHASE_LO         = 5ns;
    const time CLK_PERIOD           = CLK_PHASE_HI + CLK_PHASE_LO;

    const time STIM_APPLICATION_DEL = CLK_PERIOD * 0.1;
    const time RESP_ACQUISITION_DEL = CLK_PERIOD * 0.9;
    const time RESET_DEL            = STIM_APPLICATION_DEL;
    const int  RESET_WAIT_CYCLES    = 4;

    // clock and reset for tb
    logic clk   = 1'b1;
    logic rst_n = 1'b0;

    // cycle counter
    int unsigned cycle_cnt_q;

    // testbench result
    logic        tests_passed;
    logic        tests_failed;
    logic        exit_valid;
    logic [31:0] exit_value;

    // signals for core
    logic fetch_enable;
    assign fetch_enable = 1'b1;

    // ---------------------------------------------
    // VCD dumping (ALWAYS ON, NO PLUSARGS)
    // ---------------------------------------------
    initial begin
        $display("Simulation started at time %t", $time);
        $dumpfile("tb_top.vcd");
        $dumpvars(0, tb_top);
    end

   
    // ---------------------------------------------
    // Program load
    // ---------------------------------------------
    initial begin : load_prog
         // Wait for reset deassertion so RAM is stable
        wait (rst_n == 1'b1);
         #10;

         $display("[TB] Loading hello_world.mem ...");

        // Path is relative to the *simulation working directory*.
        // If you run from project root: ./obj_dir/Vtb_top
        // and your mem file is tb/core/custom/hello_world.mem:
        $readmemh("tb/core/custom/hello_world.mem",
              wrapper_i.ram_i.dp_ram_i.mem);

        $display("[TB] Memory initialized.");
    end




    // ---------------------------------------------
    // Clock generation
    // ---------------------------------------------
    initial begin : clock_gen
        $display("[clock_gen] Starting.");

        forever begin
            #CLK_PHASE_HI clk = 1'b0;
            #CLK_PHASE_LO clk = 1'b1;
        end
    end

    // ---------------------------------------------
    // Reset generation (NO plusargs)
    // ---------------------------------------------
    initial begin : reset_gen
        $display("[reset_gen] Starting.");
        rst_n = 1'b0;
        #100;
        repeat (RESET_WAIT_CYCLES) @(posedge clk);

        #RESET_DEL rst_n = 1'b1;
        $display("Reset deasserted at %t", $time);
    end

    // ---------------------------------------------
    // Time format
    // ---------------------------------------------
    initial begin : timing_format
        $display("[timing_format] Starting.");

        $timeformat(-9, 0, "ns", 9);
    end

    // ---------------------------------------------
    // Optional max cycle limit WITHOUT $value$plusargs
    // (Hard-coded limit, change 0 to e.g. 100000 if you want)
    // ---------------------------------------------
    localparam int MAX_CYCLES = 0;  // 0 = disabled

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cycle_cnt_q <= 0;
        end
        else begin
            cycle_cnt_q <= cycle_cnt_q + 1;
            if (MAX_CYCLES != 0 && cycle_cnt_q >= MAX_CYCLES) begin
                $fatal(2, "Simulation aborted due to maximum cycle limit");
            end
        end
    end

    // ---------------------------------------------
    // Finish when testbench says PASS/FAIL
    // ---------------------------------------------
    always_ff @(posedge clk or negedge rst_n) begin

        if (!rst_n) begin
            // nothing
        end
        else begin
            if (tests_passed) begin
                $display("ALL TESTS PASSED");
                $finish;
            end
            if (tests_failed) begin
                $display("TEST(S) FAILED!");
                $finish;
            end
            if (exit_valid) begin
                if (exit_value == 0)
                    $display("[%t] EXIT SUCCESS", $time);
                else
                    $display("EXIT FAILURE: %d", exit_value);
                $finish;
            end
        end
    end

    // ---------------------------------------------
    // Wrapper instance
    // ---------------------------------------------
    cv32e40p_tb_subsystem
        #(.INSTR_RDATA_WIDTH ( INSTR_RDATA_WIDTH ),
          .RAM_ADDR_WIDTH    ( RAM_ADDR_WIDTH    ),
          .BOOT_ADDR         ( BOOT_ADDR         ),
          .PULP_XPULP        ( PULP_XPULP        ),
          .PULP_CLUSTER      ( PULP_CLUSTER      ),
          .FPU               ( FPU               ),
          .PULP_ZFINX        ( PULP_ZFINX        ),
          .NUM_MHPMCOUNTERS  ( NUM_MHPMCOUNTERS  ),
          .DM_HALTADDRESS    ( DM_HALTADDRESS    ))
    wrapper_i
        (.clk_i          ( clk          ),
         .rst_ni         ( rst_n        ),
         .fetch_enable_i ( fetch_enable ),
         .tests_passed_o ( tests_passed ),
         .tests_failed_o ( tests_failed ),
         .exit_valid_o   ( exit_valid   ),
         .exit_value_o   ( exit_value   ));

endmodule
