// Simple cv32e40p_clock_gate for Verilator: plain latch + AND, no pragmas.
`timescale 1ns/1ps

module cv32e40p_clock_gate (
    input  logic clk_i,     // input clock
    input  logic en_i,      // enable: allow clock to propagate
    input  logic test_en_i, // test/scan mode: forces clock on
    output logic clk_o      // gated clock output
);

    logic latch_q;

    // Latch is transparent when clk_i is LOW
    always_latch begin
        if (!clk_i)
            latch_q <= (en_i | test_en_i);
    end

    // AND gate produces gated clock
    assign clk_o = clk_i & latch_q;

endmodule
