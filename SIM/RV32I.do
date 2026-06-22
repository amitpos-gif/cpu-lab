# ============================================================================
#  LAB5 - RV32IM Pipeline - COMPILE + LOAD + WAVES  (no run, no export)
#  Usage:   do RV32I.do
# ============================================================================

# ---- 0. Source folder (edit if you move the project) -------------------------
set SRC "C:/Users/amitp/OneDrive/Desktop/Comp_Lab/Lab_5/DUT"

# ---- 1. Fresh work library ---------------------------------------------------
if {[file exists work]} { vdel -all -lib work }
vlib work
vmap work work

# ---- 2. Packages (order matters) ---------------------------------------------
vcom -work work -2008 -explicit $SRC/cond_compilation_package.vhd
vcom -work work -2008 -explicit $SRC/const_package.vhd
vcom -work work -2008 -explicit $SRC/aux_package.vhd

# ---- 3. Leaf design modules --------------------------------------------------
vcom -work work -2008 -explicit $SRC/CONTROL.VHD
vcom -work work -2008 -explicit $SRC/IDECODE.vhd
vcom -work work -2008 -explicit $SRC/IFETCH.VHD
vcom -work work -2008 -explicit $SRC/EXECUTE.VHD
vcom -work work -2008 -explicit $SRC/MUL_STAGE1.VHD
vcom -work work -2008 -explicit $SRC/MUL_STAGE2.VHD
vcom -work work -2008 -explicit $SRC/DMEMORY.VHD
vcom -work work -2008 -explicit $SRC/WB_MUX.vhd
vcom -work work -2008 -explicit $SRC/IF_ID_REG.vhd
vcom -work work -2008 -explicit $SRC/ID_EX_REG.vhd
vcom -work work -2008 -explicit $SRC/ex_mem_reg.vhd
vcom -work work -2008 -explicit $SRC/MEM_WB_REG.vhd
vcom -work work -2008 -explicit $SRC/forwarding_unit.vhd
vcom -work work -2008 -explicit $SRC/STALL_UNIT.vhd
vcom -work work -2008 -explicit $SRC/FLUSH_UNIT.vhd

# ---- 4. Core + testbench -----------------------------------------------------
vcom -work work -2008 -explicit $SRC/RV32I_CORE_PIPLINE.vhd
vcom -work work -2008 -explicit $SRC/tb_RV32I.vhd

# ---- 5. Elaborate ------------------------------------------------------------
vsim -gui -L altera_mf -voptargs=+acc work.tb_RV32I

# ---- 6. Waves ----------------------------------------------------------------
onerror {resume}
quietly WaveActivateNextPane {} 0

add wave -divider "TESTBENCH"
add wave -label clk            sim:/tb_RV32I/clk_i
add wave -label rst            sim:/tb_RV32I/rst_i
add wave -hex -label BPADDR    sim:/tb_RV32I/BPADDR_i

add wave -divider "PIPELINE PC / INSTR"
add wave -hex sim:/tb_RV32I/IFpc_o   sim:/tb_RV32I/IFinstruction_o
add wave -hex sim:/tb_RV32I/IDpc_o   sim:/tb_RV32I/IDinstruction_o
add wave -hex sim:/tb_RV32I/EXpc_o   sim:/tb_RV32I/EXinstruction_o
add wave -hex sim:/tb_RV32I/MEMpc_o  sim:/tb_RV32I/MEMinstruction_o
add wave -hex sim:/tb_RV32I/WBpc_o   sim:/tb_RV32I/WBinstruction_o

add wave -divider "HAZARD / IPC"
add wave -label STRIGGER          sim:/tb_RV32I/STRIGGER_o
add wave -unsigned -label STCNT   sim:/tb_RV32I/STCNT_o
add wave -unsigned -label FHCNT   sim:/tb_RV32I/FHCNT_o
add wave -unsigned -label CLKCNT  sim:/tb_RV32I/CLKCNT_o

add wave -divider "STAGE INTERNALS"
add wave -group IFETCH   -r -hex sim:/tb_RV32I/CORE/IFETCH_inst/*
add wave -group IF_ID    -r -hex sim:/tb_RV32I/CORE/IF_ID_inst/*
add wave -group CONTROL  -r -hex sim:/tb_RV32I/CORE/CONTROL_inst/*
add wave -group IDECODE  -r -hex sim:/tb_RV32I/CORE/IDECODE_inst/*
add wave -group ID_EX    -r -hex sim:/tb_RV32I/CORE/ID_EX_inst/*
add wave -group EXECUTE  -r -hex sim:/tb_RV32I/CORE/EXECUTE_inst/*
add wave -group MUL1     -r -hex sim:/tb_RV32I/CORE/MUL1_inst/*
add wave -group EX_MEM   -r -hex sim:/tb_RV32I/CORE/EX_MEM_inst/*
add wave -group DMEM     -r -hex sim:/tb_RV32I/CORE/DMEM_inst/*
add wave -group MUL2     -r -hex sim:/tb_RV32I/CORE/MUL2_inst/*
add wave -group MEM_WB   -r -hex sim:/tb_RV32I/CORE/MEM_WB_inst/*
add wave -group WB_MUX   -r -hex sim:/tb_RV32I/CORE/WB_MUX_inst/*
add wave -group FORWARD  -r -hex sim:/tb_RV32I/CORE/FWD_inst/*
add wave -group STALL    -r -hex sim:/tb_RV32I/CORE/STALL_inst/*
add wave -group FLUSH    -r -hex sim:/tb_RV32I/CORE/FLUSH_inst/*

configure wave -namecolwidth 280
configure wave -valuecolwidth 120
configure wave -timelineunits ns
update

echo "Loaded + waves ready. Run and export manually (commands below)."

# ============================================================================
#  MANUAL COMMANDS - copy/paste into the Transcript yourself
# ============================================================================
#  run:           run 500 us
#  check end:     examine sim:/tb_RV32I/IFinstruction_o     (parked on 0000006F)
#  list mems:     mem list
#
#  export DTCM:
#  mem save -o {C:/Users/amitp/OneDrive/Desktop/Comp_Lab/Lab_5/BENCHMARKS/test1/RV32IM/gcc_compiled/bin/M9K-intel/DTCM_test1_pipline.mem} -f mti -data hex -addr hex -startaddress 0 -endaddress 2047 -wordsperline 1 sim:/tb_RV32I/CORE/DMEM_inst/data_memory/MEMORY/m_mem_data_a
#
#  export ITCM (optional):
#  mem save -o {C:/Users/amitp/OneDrive/Desktop/Comp_Lab/Lab_5/BENCHMARKS/test1/RV32IM/gcc_compiled/bin/M9K-intel/ITCM_PIPLINE.mem} -f mti -data hex -addr hex -startaddress 0 -endaddress 2047 -wordsperline 1 sim:/tb_RV32I/CORE/IFETCH_inst/inst_memory/MEMORY/m_mem_data_a
# ============================================================================