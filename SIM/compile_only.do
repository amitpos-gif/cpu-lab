set SRC {C:/Users/amitp/OneDrive/Desktop/Comp_Lab/Lab_5/DUT/RV32IM PIPLINE}
vlib work
vmap work work
vcom -work work -2008 -explicit "$SRC/cond_compilation_package.vhd"
vcom -work work -2008 -explicit "$SRC/const_package.vhd"
vcom -work work -2008 -explicit "$SRC/aux_package.vhd"
vcom -work work -2008 -explicit "$SRC/CONTROL.VHD"
vcom -work work -2008 -explicit "$SRC/IDECODE.vhd"
vcom -work work -2008 -explicit "$SRC/IFETCH.VHD"
vcom -work work -2008 -explicit "$SRC/EXECUTE.VHD"
vcom -work work -2008 -explicit "$SRC/MUL_STAGE1.VHD"
vcom -work work -2008 -explicit "$SRC/MUL_STAGE2.VHD"
vcom -work work -2008 -explicit "$SRC/DMEMORY.VHD"
vcom -work work -2008 -explicit "$SRC/WB_MUX.vhd"
vcom -work work -2008 -explicit "$SRC/IF_ID_REG.vhd"
vcom -work work -2008 -explicit "$SRC/ID_EX_REG.vhd"
vcom -work work -2008 -explicit "$SRC/ex_mem_reg.vhd"
vcom -work work -2008 -explicit "$SRC/MEM_WB_REG.vhd"
vcom -work work -2008 -explicit "$SRC/forwarding_unit.vhd"
vcom -work work -2008 -explicit "$SRC/STALL_UNIT.vhd"
vcom -work work -2008 -explicit "$SRC/FLUSH_UNIT.vhd"
vcom -work work -2008 -explicit "$SRC/RV32I_CORE_PIPLINE.vhd"
vcom -work work -2008 -explicit "$SRC/tb_RV32I.vhd"
quit -f
