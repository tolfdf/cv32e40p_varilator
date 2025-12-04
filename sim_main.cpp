#include "Vtb_top.h"
#include "verilated.h"
#include "verilated_fst_c.h"

vluint64_t main_time = 0;
double sc_time_stamp() { return main_time; }

int main(int argc, char **argv) {
    Verilated::commandArgs(argc, argv);

    // Enable tracing
    Verilated::traceEverOn(true);

    Vtb_top *top = new Vtb_top;

    // FST waveform dumper
    VerilatedFstC *tfp = new VerilatedFstC;
    top->trace(tfp, 99);
    tfp->open("wave.fst");

    // Main simulation loop
    while (!Verilated::gotFinish()) {
        top->eval();

        tfp->dump(main_time);

        // Critical: advance time so SV #delays work
        Verilated::timeInc(1);
        main_time++;
    }

    // Finish
    tfp->close();
    delete tfp;
    delete top;

    return 0;
}