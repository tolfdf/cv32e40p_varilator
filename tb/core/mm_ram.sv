// Copyright...
// (Full header preserved)

// RAM and MM wrapper for RI5CY / CV32E40P

`timescale 1ns/1ps

module mm_ram
    #(parameter RAM_ADDR_WIDTH = 18,
      parameter INSTR_RDATA_WIDTH = 32)
    (input  logic                         clk_i,
     input  logic                         rst_ni,

     input  logic                         instr_req_i,
     input  logic [RAM_ADDR_WIDTH-1:0]    instr_addr_i,
     output logic [INSTR_RDATA_WIDTH-1:0] instr_rdata_o,
     output logic                         instr_rvalid_o,
     output logic                         instr_gnt_o,

     input  logic                         data_req_i,
     input  logic [31:0]                  data_addr_i,
     input  logic                         data_we_i,
     input  logic [3:0]                   data_be_i,
     input  logic [31:0]                  data_wdata_i,
     output logic [31:0]                  data_rdata_o,
     output logic                         data_rvalid_o,
     output logic                         data_gnt_o,
     input  logic [5:0]                   data_atop_i,

     input  logic [4:0]                   irq_id_i,
     input  logic                         irq_ack_i,

     output logic                         irq_software_o,
     output logic                         irq_timer_o,
     output logic                         irq_external_o,
     output logic [15:0]                  irq_fast_o,

     input  logic [31:0]                  pc_core_id_i,

     output logic                         tests_passed_o,
     output logic                         tests_failed_o,
     output logic                         exit_valid_o,
     output logic [31:0]                  exit_value_o);


    localparam int TIMER_IRQ_ID   = 7;
    localparam int RND_STALL_REGS = 16;
    localparam int IRQ_MAX_ID     = 31;
    localparam int IRQ_MIN_ID     = 26;

    typedef enum logic [1:0] {T_RAM, T_PER, T_RND_STALL, T_ERR} transaction_t;

    transaction_t transaction, granted_transaction, completed_transaction;
    mailbox #(transaction_t) granted_transactions = new();
    mailbox #(transaction_t) completed_transactions = new();

    class rand_default_gnt;
         rand logic gnt;
    endclass : rand_default_gnt

    logic [31:0] data_addr_aligned;

    logic                          data_rvalid_q;
    logic                          instr_rvalid_q;
    logic [INSTR_RDATA_WIDTH-1:0]  core_instr_rdata;
    logic [31:0]                   core_data_rdata;
    logic                          response_phase;

    logic                          ram_amoshimd_data_req;
    logic [31:0]                   ram_amoshimd_data_addr;
    logic                          ram_amoshimd_data_we;
    logic [63:0]                   ram_amoshimd_data_wdata;
    logic [7:0]                    ram_amoshimd_data_be;
    logic [63:0]                   ram_amoshimd_data_rdata;
    logic [31:0]                   tmp_ram_amoshimd_data_rdata;

    logic                          ram_data_req;
    logic [RAM_ADDR_WIDTH-1:0]     ram_data_addr;
    logic [31:0]                   ram_data_wdata;
    logic [31:0]                   ram_data_rdata;
    logic [63:0]                   tmp_ram_data_rdata;
    logic                          ram_data_we;
    logic [3:0]                    ram_data_be;
    logic                          ram_data_gnt;
    logic                          ram_data_valid;
    logic [5:0]                    ram_data_atop;
    logic [3:0]                    ram_data_atop_conv;

    logic                          data_req_dec;
    logic [31:0]                   data_wdata_dec;
    logic [RAM_ADDR_WIDTH-1:0]     data_addr_dec;
    logic                          data_we_dec;
    logic [3:0]                    data_be_dec;
    logic [5:0]                    data_atop_dec;

    logic [INSTR_RDATA_WIDTH-1:0]  ram_instr_rdata;
    logic                          ram_instr_req;
    logic [RAM_ADDR_WIDTH-1:0]     ram_instr_addr;
    logic                          ram_instr_gnt;
    logic                          ram_instr_valid;

    logic [31:0] print_wdata;
    logic        print_valid;

    logic [31:0] sig_end_d, sig_end_q;
    logic [31:0] sig_begin_d, sig_begin_q;

    logic [31:0] timer_irq_mask_q;
    logic [31:0] timer_cnt_q;
    logic        irq_timer_q;
    logic        timer_reg_valid;
    logic        timer_val_valid;
    logic [31:0] timer_wdata;

    logic [31:0] rnd_stall_regs [0:RND_STALL_REGS-1];

    logic        rnd_stall_req;
    logic [31:0] rnd_stall_addr;
    logic [31:0] rnd_stall_wdata;
    logic        rnd_stall_we;
    logic [31:0] rnd_stall_rdata;

    logic        rnd_stall_instr_req;
    logic [RAM_ADDR_WIDTH-1:0] rnd_stall_instr_addr;
    logic        rnd_stall_instr_gnt;
    logic        rnd_stall_instr_valid;
    logic [INSTR_RDATA_WIDTH-1:0] rnd_stall_instr_rdata;

    logic        rnd_stall_data_req;
    logic [RAM_ADDR_WIDTH-1:0] rnd_stall_data_addr;
    logic        rnd_stall_data_gnt;
    logic        rnd_stall_data_valid;
    logic [31:0] rnd_stall_data_rdata;
    logic [31:0] rnd_stall_data_wdata;
    logic        rnd_stall_data_we;
    logic [3:0]  rnd_stall_data_be;

    logic [31:0] rnd_stall_addr_q;
    logic [31:0] error_addr_q;

    typedef struct packed {
      logic        irq_software;
      logic        irq_timer;
      logic        irq_external;
      logic [15:0] irq_fast;
    } Interrupts_tb_t;

    Interrupts_tb_t irq_rnd_lines;


    // Atomic op encodings
    localparam AMO_LR   = 5'b00010;
    localparam AMO_SC   = 5'b00011;
    localparam AMO_SWAP = 5'b00001;
    localparam AMO_ADD  = 5'b00000;
    localparam AMO_XOR  = 5'b00100;
    localparam AMO_AND  = 5'b01100;
    localparam AMO_OR   = 5'b01000;
    localparam AMO_MIN  = 5'b10000;
    localparam AMO_MAX  = 5'b10100;
    localparam AMO_MINU = 5'b11000;
    localparam AMO_MAXU = 5'b11100;


    always_comb data_addr_aligned = {data_addr_i[31:2], 2'b0};

    // =======================================================
    // Main MMIO decode
    // =======================================================
    always_comb begin
        tests_passed_o      = '0;
        tests_failed_o      = '0;
        exit_value_o        =  0;
        exit_valid_o        = '0;
        data_req_dec        = '0;
        data_addr_dec       = '0;
        data_wdata_dec      = '0;
        data_we_dec         = '0;
        data_be_dec         = '0;
        data_atop_dec       = '0;
        print_wdata         = '0;
        print_valid         = '0;
        timer_wdata         = '0;
        timer_reg_valid     = '0;
        timer_val_valid     = '0;
        sig_end_d           = sig_end_q;
        sig_begin_d         = sig_begin_q;
        rnd_stall_req       = '0;
        rnd_stall_addr      = '0;
        rnd_stall_wdata     = '0;
        rnd_stall_we        = '0;
        transaction         = T_PER;

        if (data_req_i) begin

            if (data_we_i) begin // WRITES
                if (data_addr_i < 2 ** RAM_ADDR_WIDTH) begin
                    data_req_dec   = data_req_i;
                    data_addr_dec  = data_addr_i[RAM_ADDR_WIDTH-1:0];
                    data_wdata_dec = data_wdata_i;
                    data_we_dec    = data_we_i;
                    data_be_dec    = data_be_i;
                    data_atop_dec  = data_atop_i;
                    transaction    = T_RAM;

                end else if (data_addr_i == 32'h1000_0000) begin
                    print_wdata = data_wdata_i;
                    print_valid = 1;

                end else if (data_addr_i == 32'h2000_0000) begin
                    if (data_wdata_i == 123456789)
                        tests_passed_o = 1'b1;
                    else if (data_wdata_i == 1)
                        tests_failed_o = 1'b1;
                    else
                        $display("Test result written: %d", data_wdata_i);

                end else if (data_addr_i == 32'h2000_0004) begin
                    exit_valid_o = 1;
                    exit_value_o = data_wdata_i;

                end else if (data_addr_i == 32'h2000_0008) begin
                    sig_begin_d = data_wdata_i;

                end else if (data_addr_i == 32'h2000_000C) begin
                    sig_end_d = data_wdata_i;

                end else if (data_addr_i == 32'h2000_0010) begin
                    exit_valid_o = 1;
                    exit_value_o = 0;

                end else if (data_addr_i == 32'h1500_0000) begin
                    timer_wdata = data_wdata_i;
                    timer_reg_valid = 1;

                end else if (data_addr_i == 32'h1500_0004) begin
                    timer_wdata = data_wdata_i;
                    timer_val_valid = 1;

                end else if (data_addr_i[31:16] == 16'h1600) begin
                    rnd_stall_req   = data_req_i;
                    rnd_stall_wdata = data_wdata_i;
                    rnd_stall_addr  = data_addr_i;
                    rnd_stall_we    = data_we_i;

                end
            end else begin  // READS
                if (data_addr_i < 2 ** RAM_ADDR_WIDTH) begin
                    data_req_dec   = data_req_i;
                    data_addr_dec  = data_addr_i[RAM_ADDR_WIDTH-1:0];
                    data_wdata_dec = data_wdata_i;
                    data_we_dec    = data_we_i;
                    data_be_dec    = data_be_i;
                    data_atop_dec  = data_atop_i;
                    transaction    = T_RAM;

                end else if (data_addr_i[31:16] == 16'h1600) begin
                    rnd_stall_req   = data_req_i;
                    rnd_stall_wdata = data_wdata_i;
                    rnd_stall_addr  = data_addr_i;
                    rnd_stall_we    = data_we_i;
                    transaction     = T_RND_STALL;

                end else
                    transaction = T_ERR;
            end
        end
    end


    // =======================================================
    // Random stall bookkeeping
    // =======================================================
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) rnd_stall_addr_q <= 0;
        else if (transaction == T_RND_STALL) rnd_stall_addr_q <= rnd_stall_addr;
    end


    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) error_addr_q <= 0;
        else if (transaction != T_RAM) error_addr_q <= data_addr_i;
    end

    // ------------------------------------------------------------
    // READ DATA MUX  (patched to support UART + test registers)
    // ------------------------------------------------------------
    always_comb begin : read_mux
        data_rdata_o = '0;

        if (response_phase && granted_transaction == T_RAM) begin

            data_rdata_o = core_data_rdata;

        end else if (response_phase && granted_transaction == T_RND_STALL) begin

    `ifndef VERILATOR
            data_rdata_o = rnd_stall_rdata;
    `else
            data_rdata_o = 32'h0;
    `endif

        end else if (response_phase && granted_transaction == T_PER) begin

            // UART @ 0x1000_0000
            if (error_addr_q == 32'h1000_0000) begin
                // *** FIXED HERE ***
                $write("%c", data_wdata_i[7:0]);
                data_rdata_o = 32'h0;

            // Test registers @ 0x2000_0000
            end else if ((error_addr_q & 32'hFFFF_FFF0) == 32'h2000_0000) begin
                data_rdata_o = 32'h0;

            end else begin
                $display("WARNING: access to unknown PER address %08x", error_addr_q);
                data_rdata_o = 32'h0;
            end

        end else if (response_phase && granted_transaction == T_ERR) begin

            $display("WARNING: out of bounds read from %08x (T_ERR)", error_addr_q);

        end
    end





    // =======================================================
    // Print-through pseudo peripheral
    // =======================================================
    always_ff @(posedge clk_i or negedge rst_ni) begin : print_peripheral
        if(print_valid) begin
            // Verbose mode removed (Verilator-incompatible)
            $write("%c", print_wdata[7:0]);
        end
    end


    // =======================================================
    // Timer logic
    // =======================================================
    always_ff @(posedge clk_i or negedge rst_ni) begin : tb_timer
        if (!rst_ni) begin
            timer_irq_mask_q <= 0;
            timer_cnt_q      <= 0;
            irq_timer_q      <= 0;

            for (int i=0; i<RND_STALL_REGS; i++)
                rnd_stall_regs[i] <= 0;

            rnd_stall_rdata <= 0;

        end else begin
            if (timer_reg_valid) begin
                timer_irq_mask_q <= timer_wdata;

            end else if (timer_val_valid) begin
                timer_cnt_q <= timer_wdata;

            end else if (rnd_stall_req) begin
                if (rnd_stall_we)
                    rnd_stall_regs[rnd_stall_addr[5:2]] <= rnd_stall_wdata;
                else
                    rnd_stall_rdata <= rnd_stall_regs[rnd_stall_addr_q[5:2]];

            end else begin
                if (timer_cnt_q > 0)
                    timer_cnt_q <= timer_cnt_q - 1;

                if (timer_cnt_q == 1)
                    irq_timer_q <= 1'b1 & timer_irq_mask_q[TIMER_IRQ_ID];

                if (irq_ack_i && irq_id_i == TIMER_IRQ_ID)
                    irq_timer_q <= 0;
            end
        end
    end


    // =======================================================
    // NO VERBOSE WRITES (disabled for Verilator)
    // =======================================================
    // always_ff @(posedge clk_i, negedge rst_ni) begin
    // end


    // =======================================================
    // AMO shim
    // =======================================================
    always_comb begin
        ram_data_atop_conv = 0;

        if (ram_data_atop[5]) begin
            unique case (ram_data_atop[4:0])
                AMO_LR:   ram_data_atop_conv = 4'hB;
                AMO_SC:   ram_data_atop_conv = 4'hC;
                AMO_SWAP: ram_data_atop_conv = 4'h1;
                AMO_ADD:  ram_data_atop_conv = 4'h2;
                AMO_XOR:  ram_data_atop_conv = 4'h5;
                AMO_AND:  ram_data_atop_conv = 4'h3;
                AMO_OR:   ram_data_atop_conv = 4'h4;
                AMO_MIN:  ram_data_atop_conv = 4'h8;
                AMO_MAX:  ram_data_atop_conv = 4'h6;
                AMO_MINU: ram_data_atop_conv = 4'h9;
                AMO_MAXU: ram_data_atop_conv = 4'h7;
                default: /* do nothing */;
            endcase
        end
    end


    amo_shim #(.AddrMemWidth(32)) i_amo_shim (
        .clk_i       ( clk_i ),
        .rst_ni      ( rst_ni ),

        .in_req_i    ( ram_data_req ),
        .in_gnt_o    ( ram_data_gnt ),
        .in_add_i    ( 32'(ram_data_addr) ),
        .in_amo_i    ( ram_data_atop_conv ),
        .in_wen_i    ( ram_data_we ),
        .in_wdata_i  ( 64'(ram_data_wdata) ),
        .in_be_i     ( 8'(ram_data_be) ),
        .in_rdata_o  ( tmp_ram_data_rdata ),

        .out_req_o   ( ram_amoshimd_data_req ),
        .out_add_o   ( ram_amoshimd_data_addr ),
        .out_wen_o   ( ram_amoshimd_data_we ),
        .out_wdata_o ( ram_amoshimd_data_wdata ),
        .out_be_o    ( ram_amoshimd_data_be ),
        .out_rdata_i ( ram_amoshimd_data_rdata )
    );


    assign ram_data_rdata = tmp_ram_data_rdata[31:0];

    // =======================================================
    // RAM instance
    // =======================================================
    dp_ram #(
        .ADDR_WIDTH(RAM_ADDR_WIDTH),
        .INSTR_RDATA_WIDTH(INSTR_RDATA_WIDTH)
    ) dp_ram_i (
        .clk_i     ( clk_i ),

        .en_a_i    ( ram_instr_req ),
        .addr_a_i  ( ram_instr_addr ),
        .wdata_a_i ( 0 ),
        .rdata_a_o ( ram_instr_rdata ),
        .we_a_i    ( 0 ),
        .be_a_i    ( 4'b1111 ),

        .en_b_i    ( ram_amoshimd_data_req ),
        .addr_b_i  ( ram_amoshimd_data_addr[RAM_ADDR_WIDTH-1:0] ),
        .wdata_b_i ( ram_amoshimd_data_wdata[31:0] ),
        .rdata_b_o ( tmp_ram_amoshimd_data_rdata ),
        .we_b_i    ( ram_amoshimd_data_we ),
        .be_b_i    ( ram_amoshimd_data_be[3:0] )
    );

    assign ram_amoshimd_data_rdata = 64'(tmp_ram_amoshimd_data_rdata);


    // =======================================================
    // Signature
    // =======================================================
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            sig_end_q   <= 0;
            sig_begin_q <= 0;
        end else begin
            sig_end_q   <= sig_end_d;
            sig_begin_q <= sig_begin_d;
        end
    end


    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            data_rvalid_q  <= 0;
            instr_rvalid_q <= 0;
        end else begin
            data_rvalid_q  <= ram_data_req;
            instr_rvalid_q <= ram_instr_req;
        end
    end


    // =======================================================
    // Grant + response handshake
    // =======================================================
    always_comb begin
        int success;
        rand_default_gnt default_gnt = new();

        data_gnt_o = 0;
        data_rvalid_o = 0;

        if (data_req_i) begin
            if (transaction == T_RAM)
                data_gnt_o = ram_data_gnt;
            else
                data_gnt_o = 1;
        end else begin
            success = default_gnt.randomize();
            data_gnt_o = default_gnt.gnt;
        end

        if (response_phase) begin
            if (granted_transaction == T_RAM)
                data_rvalid_o = ram_data_valid;
            else
                data_rvalid_o = 1;
        end
    end


    initial begin
        forever begin
            @(posedge clk_i);
            if (data_req_i && data_gnt_o)
                granted_transactions.put(transaction);
            if (data_rvalid_o)
                completed_transactions.put(granted_transaction);
        end
    end


    initial begin
        response_phase = 0;

        forever begin
            granted_transactions.get(granted_transaction);
            response_phase = 1;

            completed_transactions.get(completed_transaction);
            response_phase = 0;
        end
    end


    assign instr_gnt_o    = ram_instr_gnt;
    assign instr_rvalid_o = ram_instr_valid;
    assign instr_rdata_o  = core_instr_rdata;


    // RANDOM STALL MUX
    always_comb begin
        ram_instr_req    = instr_req_i;
        ram_instr_addr   = instr_addr_i;
        ram_instr_gnt    = instr_req_i;
        ram_instr_valid  = instr_rvalid_q;
        core_instr_rdata = ram_instr_rdata;

        ram_data_req     = data_req_dec;
        ram_data_addr    = data_addr_dec;
        ram_data_valid   = data_rvalid_q;
        core_data_rdata  = ram_data_rdata;
        ram_data_wdata   = data_wdata_dec;
        ram_data_we      = data_we_dec;
        ram_data_be      = data_be_dec;
        ram_data_atop    = data_atop_dec;

`ifndef VERILATOR
        if (rnd_stall_regs[0]) begin
            ram_instr_req    = rnd_stall_instr_req;
            ram_instr_addr   = rnd_stall_instr_addr;
            ram_instr_gnt    = rnd_stall_instr_gnt;
            ram_instr_valid  = rnd_stall_instr_valid;
            core_instr_rdata = rnd_stall_instr_rdata;
        end

        if (rnd_stall_regs[1]) begin
            ram_data_req     = rnd_stall_data_req;
            ram_data_addr    = rnd_stall_data_addr;
            ram_data_valid   = rnd_stall_data_valid;
            core_data_rdata  = rnd_stall_data_rdata;
            ram_data_wdata   = rnd_stall_data_wdata;
            ram_data_we      = rnd_stall_data_we;
            ram_data_be      = rnd_stall_data_be;
        end
`endif
    end


    // IRQ SIGNALS
    assign irq_software_o = irq_rnd_lines.irq_software;
    assign irq_timer_o    = irq_rnd_lines.irq_timer | irq_timer_q;
    assign irq_external_o = irq_rnd_lines.irq_external;
    assign irq_fast_o     = irq_rnd_lines.irq_fast;


`ifndef VERILATOR

    // Random stall modules
    cv32e40p_random_stall #(
        .ADDR_WIDTH(RAM_ADDR_WIDTH),
        .DATA_WIDTH(INSTR_RDATA_WIDTH)
    ) instr_random_stalls (
        .clk_i             ( clk_i ),
        .rst_ni            ( rst_ni ),

        .grant_mem_i       ( rnd_stall_instr_req ),
        .rvalid_mem_i      ( instr_rvalid_q ),
        .rdata_mem_i       ( ram_instr_rdata ),

        .grant_core_o      ( rnd_stall_instr_gnt ),
        .rvalid_core_o     ( rnd_stall_instr_valid ),
        .rdata_core_o      ( rnd_stall_instr_rdata ),

        .req_core_i        ( instr_req_i ),
        .req_mem_o         ( rnd_stall_instr_req ),

        .addr_core_i       ( instr_addr_i ),
        .addr_mem_o        ( rnd_stall_instr_addr ),

        .wdata_core_i      ( ),
        .wdata_mem_o       ( ),

        .we_core_i         ( ),
        .we_mem_o          ( ),

        .be_core_i         ( ),
        .be_mem_o          ( ),

        .stall_en_i        ( rnd_stall_regs[0] ),
        .stall_mode_i      ( rnd_stall_regs[2] ),
        .max_stall_i       ( rnd_stall_regs[4] ),
        .gnt_stall_i       ( rnd_stall_regs[6] ),
        .valid_stall_i     ( rnd_stall_regs[8] )
    );


    cv32e40p_random_stall #(
        .ADDR_WIDTH(RAM_ADDR_WIDTH),
        .DATA_WIDTH(32)
    ) data_random_stalls (
        .clk_i             ( clk_i ),
        .rst_ni            ( rst_ni ),

        .grant_mem_i       ( rnd_stall_data_req ),
        .rvalid_mem_i      ( data_rvalid_q ),
        .rdata_mem_i       ( ram_data_rdata ),

        .grant_core_o      ( rnd_stall_data_gnt ),
        .rvalid_core_o     ( rnd_stall_data_valid ),
        .rdata_core_o      ( rnd_stall_data_rdata ),

        .req_core_i        ( data_req_dec ),
        .req_mem_o         ( rnd_stall_data_req ),

        .addr_core_i       ( data_addr_dec ),
        .addr_mem_o        ( rnd_stall_data_addr ),

        .wdata_core_i      ( data_wdata_dec ),
        .wdata_mem_o       ( rnd_stall_data_wdata ),

        .we_core_i         ( data_we_dec ),
        .we_mem_o          ( rnd_stall_data_we ),

        .be_core_i         ( data_be_dec ),
        .be_mem_o          ( rnd_stall_data_be ),

        .stall_en_i        ( rnd_stall_regs[1] ),
        .stall_mode_i      ( rnd_stall_regs[3] ),
        .max_stall_i       ( rnd_stall_regs[5] ),
        .gnt_stall_i       ( rnd_stall_regs[7] ),
        .valid_stall_i     ( rnd_stall_regs[9] )
    );


    cv32e40p_random_interrupt_generator random_interrupt_generator_i (
        .rst_ni            ( rst_ni ),
        .clk_i             ( clk_i ),
        .irq_i             ( 1'b0 ),
        .irq_ack_i         ( irq_ack_i ),
        .irq_ack_o         ( ),
        .irq_rnd_lines_o   ( irq_rnd_lines ),
        .irq_mode_i        ( rnd_stall_regs[10] ),
        .irq_min_cycles_i  ( rnd_stall_regs[11] ),
        .irq_max_cycles_i  ( rnd_stall_regs[12] ),
        .irq_min_id_i      ( IRQ_MIN_ID ),
        .irq_max_id_i      ( IRQ_MAX_ID ),
        .irq_act_id_o      ( ),
        .irq_id_we_o       ( ),
        .irq_pc_id_i       ( pc_core_id_i ),
        .irq_pc_trig_i     ( rnd_stall_regs[13] ),
        .irq_lines_i       ( rnd_stall_regs[14][31:0] )
    );

`endif

endmodule
