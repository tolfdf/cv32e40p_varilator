// ============================================================================
// Dual-Port RAM (dp_ram) - 32-bit word memory
// ============================================================================

`timescale 1ns/1ps

module dp_ram
    #(parameter ADDR_WIDTH = 18,
      parameter INSTR_RDATA_WIDTH = 32)
(
    input  logic                  clk_i,

    // -----------------------
    // Port A (instruction)
    // -----------------------
    input  logic                          en_a_i,
    input  logic [ADDR_WIDTH-1:0]         addr_a_i,   // byte address
    input  logic [31:0]                   wdata_a_i,  // unused
    output logic [INSTR_RDATA_WIDTH-1:0]  rdata_a_o,
    input  logic                          we_a_i,     // ignored
    input  logic [3:0]                    be_a_i,     // ignored

    // -----------------------
    // Port B (data)
    // -----------------------
    input  logic                          en_b_i,
    input  logic [ADDR_WIDTH-1:0]         addr_b_i,   // byte address
    input  logic [31:0]                   wdata_b_i,
    output logic [31:0]                   rdata_b_o,
    input  logic                          we_b_i,
    input  logic [3:0]                    be_b_i
);

    // Total bytes and number of 32-bit words
    localparam int BYTES = 2**ADDR_WIDTH;
    localparam int WORDS = BYTES / 4;

    // 32-bit word memory.
    // This is what $readmemh("...hello_world.mem", dp_ram_i.mem) will fill:
    // one file word -> one mem[word_index].
    logic [31:0] mem [0:WORDS-1];

    // Convert byte address to word index (drop low 2 bits)
    logic [ADDR_WIDTH-3:0] word_addr_a;
    logic [ADDR_WIDTH-3:0] word_addr_b;

    assign word_addr_a = addr_a_i[ADDR_WIDTH-1:2];
    assign word_addr_b = addr_b_i[ADDR_WIDTH-1:2];

    // Optional plusargs for verbose prints
    logic plusargs_ready = 1'b0;
    logic verbose_enable = 1'b0;

    initial begin
        #1;
        plusargs_ready = 1'b1;
        verbose_enable = $test$plusargs("verbose");
    end

    // Main RAM behavior
    always_ff @(posedge clk_i) begin

        // -----------------------
        // Port A: instruction fetch (read-only)
        // -----------------------
        if (en_a_i) begin
            // INSTR_RDATA_WIDTH is 32 in your setup, so this is just mem[word_addr_a]
            rdata_a_o <= mem[word_addr_a];
        end

        // -----------------------
        // Port B: data access
        // -----------------------
        if (en_b_i) begin
            if (we_b_i) begin
                // Write with byte enables: read-modify-write
                logic [31:0] w = mem[word_addr_b];

                if (be_b_i[0]) w[7:0]   = wdata_b_i[7:0];
                if (be_b_i[1]) w[15:8]  = wdata_b_i[15:8];
                if (be_b_i[2]) w[23:16] = wdata_b_i[23:16];
                if (be_b_i[3]) w[31:24] = wdata_b_i[31:24];

                mem[word_addr_b] <= w;
            end else begin
                // Read
                rdata_b_o <= mem[word_addr_b];

                if (verbose_enable) begin
                    $display("dp_ram READ addr=0x%08x data=0x%08x",
                             {word_addr_b, 2'b00}, mem[word_addr_b]);
                end
            end
        end
    end

endmodule
