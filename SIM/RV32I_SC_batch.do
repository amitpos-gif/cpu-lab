set SRC {C:/Users/amitp/OneDrive/Desktop/Comp_Lab/Lab_5/DUT/RV32IM SINGLE CYCLE}
set OUT {C:/Users/amitp/OneDrive/Desktop/Comp_Lab/Lab_5/BENCHMARKS/test1/RV32IM/RV32IM-SINGLE CYCLE/man_compiled/output/MODELSIM}
if {[file exists work]} { vdel -all -lib work }
vlib work
vmap work work
vcom -work work -2008 -explicit "$SRC/cond_compilation_package.vhd"
vcom -work work -2008 -explicit "$SRC/const_package.vhd"
vcom -work work -2008 -explicit "$SRC/aux_package.vhd"
vcom -work work -2008 -explicit "$SRC/CONTROL.VHD"
vcom -work work -2008 -explicit "$SRC/IDECODE.VHD"
vcom -work work -2008 -explicit "$SRC/IFETCH.VHD"
vcom -work work -2008 -explicit "$SRC/EXECUTE.VHD"
vcom -work work -2008 -explicit "$SRC/MUL.vhd"
vcom -work work -2008 -explicit "$SRC/DMEMORY.VHD"
vcom -work work -2008 -explicit "$SRC/RV32I_CORE.vhd"
vcom -work work -2008 -explicit "$SRC/tb_RV32I_SC.vhd"
vsim -c -L altera_mf -voptargs=+acc work.tb_RV32I_SC
run 20 us
mem save -o "$OUT/DTCM_SC.mem" -f mti -data hex -addr hex -startaddress 0 -endaddress 2047 -wordsperline 1 sim:/tb_RV32I_SC/CORE/MEM/data_memory/MEMORY/m_mem_data_a
echo "=== DTCM exported ==="
quit -f
