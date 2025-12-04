#!/bin/bash
set -e

########################################
# CLEAN
########################################
rm -rf obj_dir wave.fst tb_top.vcd

########################################
# VERILATOR COMPILE + TRACING
########################################

verilator -E tb/core/mm_ram.sv > pre.sv
echo "DEBUG: Using mm_ram.sv at: $(realpath tb/core/mm_ram.sv)"
echo "DEBUG-LISTING:"
sed -n '290,320p' tb/core/mm_ram.sv

verilator \
  -Wall \
  --error-limit 0 \
  --Wno-fatal \
  --timing \
  --cc \
  --exe \
  --trace-fst \
  --trace-structs \
  --trace-depth 10 \
  -Irtl \
  -Irtl/include \
  -Ibhv \
  -Ibhv/include \
  -Itb/core \
  -Itb/core/include \
  tb/core/include/perturbation_pkg.sv \
  rtl/include/cv32e40p_apu_core_pkg.sv \
  rtl/include/cv32e40p_fpu_pkg.sv \
  rtl/include/cv32e40p_pkg.sv \
  tb/core/mm_ram.sv \
  tb/core/dp_ram.sv \
  tb/core/amo_shim.sv \
  tb/core/cv32e40p_random_interrupt_generator.sv \
  tb/core/cv32e40p_random_stall.sv \
  tb/core/tb_fpga_tdp_ram.sv \
  tb/core/tb_top.sv \
  rtl/cv32e40p_load_store_unit.sv \
  rtl/fpga_tdp_ram.sv \
  rtl/cv32e40p_register_file_ff.sv \
  rtl/cv32e40p_alu_div.sv \
  rtl/cv32e40p_memory_wrapper.sv \
  rtl/cv32e40p_ex_stage.sv \
  rtl/cv32e40p_if_stage.sv \
  rtl/cv32e40p_int_controller.sv \
  rtl/cv32e40p_core_memory.sv \
  rtl/cv32e40p_hwloop_regs.sv \
  rtl/cv32e40p_id_stage.sv \
  rtl/cv32e40p_aligner.sv \
  rtl/cv32e40p_sleep_unit.sv \
  rtl/cv32e40p_fifo.sv \
  rtl/cv32e40p_controller.sv \
  rtl/cv32e40p_ff_one.sv \
  rtl/cv32e40p_apu_disp.sv \
  rtl/cv32e40p_popcnt.sv \
  rtl/cv32e40p_core.sv \
  rtl/cv32e40p_decoder.sv \
  rtl/cv32e40p_pmp.sv \
  rtl/cv32e40p_prefetch_controller.sv \
  rtl/cv32e40p_compressed_decoder.sv \
  rtl/cv32e40p_clock_gate.sv \
  rtl/cv32e40p_cs_registers.sv \
  rtl/cv32e40p_alu.sv \
  rtl/cv32e40p_mult.sv \
  rtl/cv32e40p_obi_interface.sv \
  rtl/cv32e40p_prefetch_buffer.sv \
  bhv/cv32e40p_sim_clock_gate.sv \
  bhv/cv32e40p_apu_tracer.sv \
  bhv/cv32e40p_wrapper.sv \
  bhv/cv32e40p_core_log.sv \
  --top-module tb_top \
  sim_main.cpp

########################################
# BUILD SIMULATOR
########################################
make -C obj_dir -f Vtb_top.mk -j

echo ""
echo "======================================================="
echo "Build complete."
echo "Run simulation:   ./obj_dir/Vtb_top"
echo "Waveform output:  wave.fst"
echo "Open in GTKWave:  gtkwave wave.fst &"
echo "======================================================="

