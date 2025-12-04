#include "Vtb_top.h"
#include "verilated.h"
#include "verilated_vcd_c.h"

int main(int argc, char **argv) {
    // MUST be first before any Verilog that uses plusargs (we removed them, but keep this right)
    Verilated::commandArgs(argc, argv);

    VerilatedContext* contextp = new VerilatedContext;
    contextp->traceEverOn(true);

    Vtb_top* top = new Vtb_top(contextp);

    VerilatedVcdC* tfp = new VerilatedVcdC;
    top->trace(tfp, 99);
    tfp->open("tb_top.vcd");

    while (!contextp->gotFinish()) {
        top->eval();
        contextp->timeInc(1);              // advance time
        tfp->dump(contextp->time());       // dump waveform
    }

    top->final();
    tfp->close();

    delete top;
    delete tfp;
    delete contextp;
    return 0;
}
