// Dual-port RAM – Verilator-friendly replacement for XPM memory

`timescale 1ns/1ps

module fpga_tdp_ram #(
    parameter ADDR_WIDTH = 18,
    parameter DATA_WIDTH = 32
)(
    input  logic                      clk_i,
    input  logic                      rst_ni,

    // Port A
    input  logic                      en_a_i,
    input  logic [ADDR_WIDTH-1:0]     addr_a_i,
    input  logic [DATA_WIDTH-1:0]     wdata_a_i,
    output logic [DATA_WIDTH-1:0]     rdata_a_o,
    input  logic                      we_a_i,
    input  logic [(DATA_WIDTH/8)-1:0] be_a_i,

    // Port B
    input  logic                      en_b_i,
    input  logic [ADDR_WIDTH-1:0]     addr_b_i,
    input  logic [DATA_WIDTH-1:0]     wdata_b_i,
    output logic [DATA_WIDTH-1:0]     rdata_b_o,
    input  logic                      we_b_i,
    input  logic [(DATA_WIDTH/8)-1:0] be_b_i
);

    localparam MEM_BYTES = (1 << ADDR_WIDTH);
    logic [7:0] mem [0:MEM_BYTES-1];

    // -------- WRITE PORT A --------
    always_ff @(posedge clk_i) begin
        if (en_a_i) begin
            if (we_a_i) begin
                for (int i = 0; i < DATA_WIDTH/8; i++) begin
                    if (be_a_i[i])
                        mem[addr_a_i + i] <= wdata_a_i[8*i +: 8];
                end
            end
        end
    end

    // -------- READ PORT A --------
    always_ff @(posedge clk_i) begin
        if (en_a_i) begin
            for (int i = 0; i < DATA_WIDTH/8; i++)
                rdata_a_o[8*i +: 8] <= mem[addr_a_i + i];
        end
    end

    // -------- WRITE PORT B --------
    always_ff @(posedge clk_i) begin
        if (en_b_i) begin
            if (we_b_i) begin
                for (int i = 0; i < DATA_WIDTH/8; i++) begin
                    if (be_b_i[i])
                        mem[addr_b_i + i] <= wdata_b_i[8*i +: 8];
                end
            end
        end
    end

    // -------- READ PORT B --------
    always_ff @(posedge clk_i) begin
        if (en_b_i) begin
            for (int i = 0; i < DATA_WIDTH/8; i++)
                rdata_b_o[8*i +: 8] <= mem[addr_b_i + i];
        end
    end

endmodule
