`line 1 "tb/core/mm_ram.sv" 1
 
 

`line 4 "tb/core/mm_ram.sv" 0
 

`line 6 "tb/core/mm_ram.sv" 0
`timescale 1ns/1ps

`line 8 "tb/core/mm_ram.sv" 0
module mm_ram
    #(parameter RAM_ADDR_WIDTH = 18,
      parameter INSTR_RDATA_WIDTH = 32)
    (input  logic                         clk_i,
     input  logic                         rst_ni,

`line 14 "tb/core/mm_ram.sv" 0
     input  logic                         instr_req_i,
     input  logic [RAM_ADDR_WIDTH-1:0]    instr_addr_i,
     output logic [INSTR_RDATA_WIDTH-1:0] instr_rdata_o,
     output logic                         instr_rvalid_o,
     output logic                         instr_gnt_o,

`line 20 "tb/core/mm_ram.sv" 0
     input  logic                         data_req_i,
     input  logic [31:0]                  data_addr_i,
     input  logic                         data_we_i,
     input  logic [3:0]                   data_be_i,
     input  logic [31:0]                  data_wdata_i,
     output logic [31:0]                  data_rdata_o,
     output logic                         data_rvalid_o,
     output logic                         data_gnt_o,
     input  logic [5:0]                   data_atop_i,

`line 30 "tb/core/mm_ram.sv" 0
     input  logic [4:0]                   irq_id_i,
     input  logic                         irq_ack_i,

`line 33 "tb/core/mm_ram.sv" 0
     output logic                         irq_software_o,
     output logic                         irq_timer_o,
     output logic                         irq_external_o,
     output logic [15:0]                  irq_fast_o,

`line 38 "tb/core/mm_ram.sv" 0
     input  logic [31:0]                  pc_core_id_i,

`line 40 "tb/core/mm_ram.sv" 0
     output logic                         tests_passed_o,
     output logic                         tests_failed_o,
     output logic                         exit_valid_o,
     output logic [31:0]                  exit_value_o);


`line 46 "tb/core/mm_ram.sv" 0
    localparam int TIMER_IRQ_ID   = 7;
    localparam int RND_STALL_REGS = 16;
    localparam int IRQ_MAX_ID     = 31;
    localparam int IRQ_MIN_ID     = 26;

`line 51 "tb/core/mm_ram.sv" 0
    typedef enum logic [1:0] {T_RAM, T_PER, T_RND_STALL, T_ERR} transaction_t;

`line 53 "tb/core/mm_ram.sv" 0
    transaction_t transaction, granted_transaction, completed_transaction;
    mailbox #(transaction_t) granted_transactions = new();
    mailbox #(transaction_t) completed_transactions = new();

`line 57 "tb/core/mm_ram.sv" 0
    class rand_default_gnt;
         rand logic gnt;
    endclass : rand_default_gnt

`line 61 "tb/core/mm_ram.sv" 0
    logic [31:0] data_addr_aligned;

`line 63 "tb/core/mm_ram.sv" 0
    logic                          data_rvalid_q;
    logic                          instr_rvalid_q;
    logic [INSTR_RDATA_WIDTH-1:0]  core_instr_rdata;
    logic [31:0]                   core_data_rdata;
    logic                          response_phase;

`line 69 "tb/core/mm_ram.sv" 0
    logic                          ram_amoshimd_data_req;
    logic [31:0]                   ram_amoshimd_data_addr;
    logic                          ram_amoshimd_data_we;
    logic [63:0]                   ram_amoshimd_data_wdata;
    logic [7:0]                    ram_amoshimd_data_be;
    logic [63:0]                   ram_amoshimd_data_rdata;
    logic [31:0]                   tmp_ram_amoshimd_data_rdata;

`line 77 "tb/core/mm_ram.sv" 0
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

`line 89 "tb/core/mm_ram.sv" 0
    logic                          data_req_dec;
    logic [31:0]                   data_wdata_dec;
    logic [RAM_ADDR_WIDTH-1:0]     data_addr_dec;
    logic                          data_we_dec;
    logic [3:0]                    data_be_dec;
    logic [5:0]                    data_atop_dec;

`line 96 "tb/core/mm_ram.sv" 0
    logic [INSTR_RDATA_WIDTH-1:0]  ram_instr_rdata;
    logic                          ram_instr_req;
    logic [RAM_ADDR_WIDTH-1:0]     ram_instr_addr;
    logic                          ram_instr_gnt;
    logic                          ram_instr_valid;

`line 102 "tb/core/mm_ram.sv" 0
    logic [31:0] print_wdata;
    logic        print_valid;

`line 105 "tb/core/mm_ram.sv" 0
    logic [31:0] sig_end_d, sig_end_q;
    logic [31:0] sig_begin_d, sig_begin_q;

`line 108 "tb/core/mm_ram.sv" 0
    logic [31:0] timer_irq_mask_q;
    logic [31:0] timer_cnt_q;
    logic        irq_timer_q;
    logic        timer_reg_valid;
    logic        timer_val_valid;
    logic [31:0] timer_wdata;

`line 115 "tb/core/mm_ram.sv" 0
    logic [31:0] rnd_stall_regs [0:RND_STALL_REGS-1];

`line 117 "tb/core/mm_ram.sv" 0
    logic        rnd_stall_req;
    logic [31:0] rnd_stall_addr;
    logic [31:0] rnd_stall_wdata;
    logic        rnd_stall_we;
    logic [31:0] rnd_stall_rdata;

`line 123 "tb/core/mm_ram.sv" 0
    logic        rnd_stall_instr_req;
    logic [RAM_ADDR_WIDTH-1:0] rnd_stall_instr_addr;
    logic        rnd_stall_instr_gnt;
    logic        rnd_stall_instr_valid;
    logic [INSTR_RDATA_WIDTH-1:0] rnd_stall_instr_rdata;

`line 129 "tb/core/mm_ram.sv" 0
    logic        rnd_stall_data_req;
    logic [RAM_ADDR_WIDTH-1:0] rnd_stall_data_addr;
    logic        rnd_stall_data_gnt;
    logic        rnd_stall_data_valid;
    logic [31:0] rnd_stall_data_rdata;
    logic [31:0] rnd_stall_data_wdata;
    logic        rnd_stall_data_we;
    logic [3:0]  rnd_stall_data_be;

`line 138 "tb/core/mm_ram.sv" 0
    logic [31:0] rnd_stall_addr_q;
    logic [31:0] error_addr_q;

`line 141 "tb/core/mm_ram.sv" 0
    typedef struct packed {
      logic        irq_software;
      logic        irq_timer;
      logic        irq_external;
      logic [15:0] irq_fast;
    } Interrupts_tb_t;

`line 148 "tb/core/mm_ram.sv" 0
    Interrupts_tb_t irq_rnd_lines;


`line 151 "tb/core/mm_ram.sv" 0
     
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


`line 165 "tb/core/mm_ram.sv" 0
    always_comb data_addr_aligned = {data_addr_i[31:2], 2'b0};

`line 167 "tb/core/mm_ram.sv" 0
     
     
     
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

`line 194 "tb/core/mm_ram.sv" 0
        if (data_req_i) begin

`line 196 "tb/core/mm_ram.sv" 0
            if (data_we_i) begin  
                if (data_addr_i < 2 ** RAM_ADDR_WIDTH) begin
                    data_req_dec   = data_req_i;
                    data_addr_dec  = data_addr_i[RAM_ADDR_WIDTH-1:0];
                    data_wdata_dec = data_wdata_i;
                    data_we_dec    = data_we_i;
                    data_be_dec    = data_be_i;
                    data_atop_dec  = data_atop_i;
                    transaction    = T_RAM;

`line 206 "tb/core/mm_ram.sv" 0
                end else if (data_addr_i == 32'h1000_0000) begin
                    print_wdata = data_wdata_i;
                    print_valid = 1;

`line 210 "tb/core/mm_ram.sv" 0
                end else if (data_addr_i == 32'h2000_0000) begin
                    if (data_wdata_i == 123456789)
                        tests_passed_o = 1'b1;
                    else if (data_wdata_i == 1)
                        tests_failed_o = 1'b1;
                    else
                        $display("Test result written: %d", data_wdata_i);

`line 218 "tb/core/mm_ram.sv" 0
                end else if (data_addr_i == 32'h2000_0004) begin
                    exit_valid_o = 1;
                    exit_value_o = data_wdata_i;

`line 222 "tb/core/mm_ram.sv" 0
                end else if (data_addr_i == 32'h2000_0008) begin
                    sig_begin_d = data_wdata_i;

`line 225 "tb/core/mm_ram.sv" 0
                end else if (data_addr_i == 32'h2000_000C) begin
                    sig_end_d = data_wdata_i;

`line 228 "tb/core/mm_ram.sv" 0
                end else if (data_addr_i == 32'h2000_0010) begin
                    exit_valid_o = 1;
                    exit_value_o = 0;

`line 232 "tb/core/mm_ram.sv" 0
                end else if (data_addr_i == 32'h1500_0000) begin
                    timer_wdata = data_wdata_i;
                    timer_reg_valid = 1;

`line 236 "tb/core/mm_ram.sv" 0
                end else if (data_addr_i == 32'h1500_0004) begin
                    timer_wdata = data_wdata_i;
                    timer_val_valid = 1;

`line 240 "tb/core/mm_ram.sv" 0
                end else if (data_addr_i[31:16] == 16'h1600) begin
                    rnd_stall_req   = data_req_i;
                    rnd_stall_wdata = data_wdata_i;
                    rnd_stall_addr  = data_addr_i;
                    rnd_stall_we    = data_we_i;

`line 246 "tb/core/mm_ram.sv" 0
                end
            end else begin   
                if (data_addr_i < 2 ** RAM_ADDR_WIDTH) begin
                    data_req_dec   = data_req_i;
                    data_addr_dec  = data_addr_i[RAM_ADDR_WIDTH-1:0];
                    data_wdata_dec = data_wdata_i;
                    data_we_dec    = data_we_i;
                    data_be_dec    = data_be_i;
                    data_atop_dec  = data_atop_i;
                    transaction    = T_RAM;

`line 257 "tb/core/mm_ram.sv" 0
                end else if (data_addr_i[31:16] == 16'h1600) begin
                    rnd_stall_req   = data_req_i;
                    rnd_stall_wdata = data_wdata_i;
                    rnd_stall_addr  = data_addr_i;
                    rnd_stall_we    = data_we_i;
                    transaction     = T_RND_STALL;

`line 264 "tb/core/mm_ram.sv" 0
                end else
                    transaction = T_ERR;
            end
        end
    end


`line 271 "tb/core/mm_ram.sv" 0
     
     
     
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) rnd_stall_addr_q <= 0;
        else if (transaction == T_RND_STALL) rnd_stall_addr_q <= rnd_stall_addr;
    end


`line 280 "tb/core/mm_ram.sv" 0
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) error_addr_q <= 0;
        else if (transaction != T_RAM) error_addr_q <= data_addr_i;
    end

`line 285 "tb/core/mm_ram.sv" 0
     
     
     
    always_comb begin : read_mux
        data_rdata_o = '0;

`line 291 "tb/core/mm_ram.sv" 0
        if (response_phase && granted_transaction == T_RAM) begin

`line 293 "tb/core/mm_ram.sv" 0
            data_rdata_o = core_data_rdata;

`line 295 "tb/core/mm_ram.sv" 0
        end else if (response_phase && granted_transaction == T_RND_STALL) begin

`line 297 "tb/core/mm_ram.sv" 0
     
              
    
            data_rdata_o = 32'h0;
    

`line 303 "tb/core/mm_ram.sv" 0
        end else if (response_phase && granted_transaction == T_PER) begin

`line 305 "tb/core/mm_ram.sv" 0
             
            if (error_addr_q == 32'h1000_0000) begin
                 
                $write("%c", data_wdata_i[7:0]);
                data_rdata_o = 32'h0;

`line 311 "tb/core/mm_ram.sv" 0
             
            end else if ((error_addr_q & 32'hFFFF_FFF0) == 32'h2000_0000) begin
                data_rdata_o = 32'h0;

`line 315 "tb/core/mm_ram.sv" 0
            end else begin
                $display("WARNING: access to unknown PER address %08x", error_addr_q);
                data_rdata_o = 32'h0;
            end

`line 320 "tb/core/mm_ram.sv" 0
        end else if (response_phase && granted_transaction == T_ERR) begin

`line 322 "tb/core/mm_ram.sv" 0
            $display("WARNING: out of bounds read from %08x (T_ERR)", error_addr_q);

`line 324 "tb/core/mm_ram.sv" 0
        end
    end





`line 331 "tb/core/mm_ram.sv" 0
     
     
     
    always_ff @(posedge clk_i or negedge rst_ni) begin : print_peripheral
        if(print_valid) begin
             
            $write("%c", print_wdata[7:0]);
        end
    end


`line 342 "tb/core/mm_ram.sv" 0
     
     
     
    always_ff @(posedge clk_i or negedge rst_ni) begin : tb_timer
        if (!rst_ni) begin
            timer_irq_mask_q <= 0;
            timer_cnt_q      <= 0;
            irq_timer_q      <= 0;

`line 351 "tb/core/mm_ram.sv" 0
            for (int i=0; i<RND_STALL_REGS; i++)
                rnd_stall_regs[i] <= 0;

`line 354 "tb/core/mm_ram.sv" 0
            rnd_stall_rdata <= 0;

`line 356 "tb/core/mm_ram.sv" 0
        end else begin
            if (timer_reg_valid) begin
                timer_irq_mask_q <= timer_wdata;

`line 360 "tb/core/mm_ram.sv" 0
            end else if (timer_val_valid) begin
                timer_cnt_q <= timer_wdata;

`line 363 "tb/core/mm_ram.sv" 0
            end else if (rnd_stall_req) begin
                if (rnd_stall_we)
                    rnd_stall_regs[rnd_stall_addr[5:2]] <= rnd_stall_wdata;
                else
                    rnd_stall_rdata <= rnd_stall_regs[rnd_stall_addr_q[5:2]];

`line 369 "tb/core/mm_ram.sv" 0
            end else begin
                if (timer_cnt_q > 0)
                    timer_cnt_q <= timer_cnt_q - 1;

`line 373 "tb/core/mm_ram.sv" 0
                if (timer_cnt_q == 1)
                    irq_timer_q <= 1'b1 & timer_irq_mask_q[TIMER_IRQ_ID];

`line 376 "tb/core/mm_ram.sv" 0
                if (irq_ack_i && irq_id_i == TIMER_IRQ_ID)
                    irq_timer_q <= 0;
            end
        end
    end


`line 383 "tb/core/mm_ram.sv" 0
     
     
     
     
     


`line 390 "tb/core/mm_ram.sv" 0
     
     
     
    always_comb begin
        ram_data_atop_conv = 0;

`line 396 "tb/core/mm_ram.sv" 0
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
                default:  ;
            endcase
        end
    end


`line 415 "tb/core/mm_ram.sv" 0
    amo_shim #(.AddrMemWidth(32)) i_amo_shim (
        .clk_i       ( clk_i ),
        .rst_ni      ( rst_ni ),

`line 419 "tb/core/mm_ram.sv" 0
        .in_req_i    ( ram_data_req ),
        .in_gnt_o    ( ram_data_gnt ),
        .in_add_i    ( 32'(ram_data_addr) ),
        .in_amo_i    ( ram_data_atop_conv ),
        .in_wen_i    ( ram_data_we ),
        .in_wdata_i  ( 64'(ram_data_wdata) ),
        .in_be_i     ( 8'(ram_data_be) ),
        .in_rdata_o  ( tmp_ram_data_rdata ),

`line 428 "tb/core/mm_ram.sv" 0
        .out_req_o   ( ram_amoshimd_data_req ),
        .out_add_o   ( ram_amoshimd_data_addr ),
        .out_wen_o   ( ram_amoshimd_data_we ),
        .out_wdata_o ( ram_amoshimd_data_wdata ),
        .out_be_o    ( ram_amoshimd_data_be ),
        .out_rdata_i ( ram_amoshimd_data_rdata )
    );


`line 437 "tb/core/mm_ram.sv" 0
    assign ram_data_rdata = tmp_ram_data_rdata[31:0];

`line 439 "tb/core/mm_ram.sv" 0
     
     
     
    dp_ram #(
        .ADDR_WIDTH(RAM_ADDR_WIDTH),
        .INSTR_RDATA_WIDTH(INSTR_RDATA_WIDTH)
    ) dp_ram_i (
        .clk_i     ( clk_i ),

`line 448 "tb/core/mm_ram.sv" 0
        .en_a_i    ( ram_instr_req ),
        .addr_a_i  ( ram_instr_addr ),
        .wdata_a_i ( 0 ),
        .rdata_a_o ( ram_instr_rdata ),
        .we_a_i    ( 0 ),
        .be_a_i    ( 4'b1111 ),

`line 455 "tb/core/mm_ram.sv" 0
        .en_b_i    ( ram_amoshimd_data_req ),
        .addr_b_i  ( ram_amoshimd_data_addr[RAM_ADDR_WIDTH-1:0] ),
        .wdata_b_i ( ram_amoshimd_data_wdata[31:0] ),
        .rdata_b_o ( tmp_ram_amoshimd_data_rdata ),
        .we_b_i    ( ram_amoshimd_data_we ),
        .be_b_i    ( ram_amoshimd_data_be[3:0] )
    );

`line 463 "tb/core/mm_ram.sv" 0
    assign ram_amoshimd_data_rdata = 64'(tmp_ram_amoshimd_data_rdata);


`line 466 "tb/core/mm_ram.sv" 0
     
     
     
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            sig_end_q   <= 0;
            sig_begin_q <= 0;
        end else begin
            sig_end_q   <= sig_end_d;
            sig_begin_q <= sig_begin_d;
        end
    end


`line 480 "tb/core/mm_ram.sv" 0
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            data_rvalid_q  <= 0;
            instr_rvalid_q <= 0;
        end else begin
            data_rvalid_q  <= ram_data_req;
            instr_rvalid_q <= ram_instr_req;
        end
    end


`line 491 "tb/core/mm_ram.sv" 0
     
     
     
    always_comb begin
        int success;
        rand_default_gnt default_gnt = new();

`line 498 "tb/core/mm_ram.sv" 0
        data_gnt_o = 0;
        data_rvalid_o = 0;

`line 501 "tb/core/mm_ram.sv" 0
        if (data_req_i) begin
            if (transaction == T_RAM)
                data_gnt_o = ram_data_gnt;
            else
                data_gnt_o = 1;
        end else begin
            success = default_gnt.randomize();
            data_gnt_o = default_gnt.gnt;
        end

`line 511 "tb/core/mm_ram.sv" 0
        if (response_phase) begin
            if (granted_transaction == T_RAM)
                data_rvalid_o = ram_data_valid;
            else
                data_rvalid_o = 1;
        end
    end


`line 520 "tb/core/mm_ram.sv" 0
    initial begin
        forever begin
            @(posedge clk_i);
            if (data_req_i && data_gnt_o)
                granted_transactions.put(transaction);
            if (data_rvalid_o)
                completed_transactions.put(granted_transaction);
        end
    end


`line 531 "tb/core/mm_ram.sv" 0
    initial begin
        response_phase = 0;

`line 534 "tb/core/mm_ram.sv" 0
        forever begin
            granted_transactions.get(granted_transaction);
            response_phase = 1;

`line 538 "tb/core/mm_ram.sv" 0
            completed_transactions.get(completed_transaction);
            response_phase = 0;
        end
    end


`line 544 "tb/core/mm_ram.sv" 0
    assign instr_gnt_o    = ram_instr_gnt;
    assign instr_rvalid_o = ram_instr_valid;
    assign instr_rdata_o  = core_instr_rdata;


`line 549 "tb/core/mm_ram.sv" 0
     
    always_comb begin
        ram_instr_req    = instr_req_i;
        ram_instr_addr   = instr_addr_i;
        ram_instr_gnt    = instr_req_i;
        ram_instr_valid  = instr_rvalid_q;
        core_instr_rdata = ram_instr_rdata;

`line 557 "tb/core/mm_ram.sv" 0
        ram_data_req     = data_req_dec;
        ram_data_addr    = data_addr_dec;
        ram_data_valid   = data_rvalid_q;
        core_data_rdata  = ram_data_rdata;
        ram_data_wdata   = data_wdata_dec;
        ram_data_we      = data_we_dec;
        ram_data_be      = data_be_dec;
        ram_data_atop    = data_atop_dec;

`line 566 "tb/core/mm_ram.sv" 0
 
          
                 
                
                 
               
              
        

`line 575 "tb/core/mm_ram.sv" 0
          
                  
                 
                
               
                
                   
                   
        

`line 585 "tb/core/mm_ram.sv" 0
    end


`line 588 "tb/core/mm_ram.sv" 0
     
    assign irq_software_o = irq_rnd_lines.irq_software;
    assign irq_timer_o    = irq_rnd_lines.irq_timer | irq_timer_q;
    assign irq_external_o = irq_rnd_lines.irq_external;
    assign irq_fast_o     = irq_rnd_lines.irq_fast;


`line 595 "tb/core/mm_ram.sv" 0
 

`line 597 "tb/core/mm_ram.sv" 0
    
     
        
        
      
                       
                      

`line 605 "tb/core/mm_ram.sv" 0
                 
                
                 

`line 609 "tb/core/mm_ram.sv" 0
                
               
                

`line 613 "tb/core/mm_ram.sv" 0
                  
                   

`line 616 "tb/core/mm_ram.sv" 0
                 
                  

`line 619 "tb/core/mm_ram.sv" 0
               
                

`line 622 "tb/core/mm_ram.sv" 0
                  
                   

`line 625 "tb/core/mm_ram.sv" 0
                  
                   

`line 628 "tb/core/mm_ram.sv" 0
                  
                
                 
                 
               
    


`line 636 "tb/core/mm_ram.sv" 0
     
        
        
      
                       
                      

`line 643 "tb/core/mm_ram.sv" 0
                 
                
                 

`line 647 "tb/core/mm_ram.sv" 0
                
               
                

`line 651 "tb/core/mm_ram.sv" 0
                  
                   

`line 654 "tb/core/mm_ram.sv" 0
                 
                  

`line 657 "tb/core/mm_ram.sv" 0
                
                 

`line 660 "tb/core/mm_ram.sv" 0
                   
                    

`line 663 "tb/core/mm_ram.sv" 0
                   
                    

`line 666 "tb/core/mm_ram.sv" 0
                  
                
                 
                 
               
    


`line 674 "tb/core/mm_ram.sv" 0
      
                      
                       
                       
                   
                  
             
                  
            
            
                
                
               
                
                 
               
                 
    



`line 695 "tb/core/mm_ram.sv" 0
endmodule

`line 697 "tb/core/mm_ram.sv" 0
