onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb_control_lab3/clk
add wave -noupdate /tb_control_lab3/rst
add wave -noupdate /tb_control_lab3/ena
add wave -noupdate /tb_control_lab3/done
add wave -noupdate /tb_control_lab3/DTCM_wr
add wave -noupdate /tb_control_lab3/Cin
add wave -noupdate /tb_control_lab3/Cout
add wave -noupdate /tb_control_lab3/DTCM_addr_in
add wave -noupdate /tb_control_lab3/DTCM_out
add wave -noupdate /tb_control_lab3/ALUFN
add wave -noupdate /tb_control_lab3/Ain
add wave -noupdate /tb_control_lab3/RFin
add wave -noupdate /tb_control_lab3/RFout
add wave -noupdate /tb_control_lab3/RFaddr_rd
add wave -noupdate /tb_control_lab3/RFaddr_wr
add wave -noupdate /tb_control_lab3/IRin
add wave -noupdate /tb_control_lab3/PCin
add wave -noupdate /tb_control_lab3/PCsel
add wave -noupdate /tb_control_lab3/Imm1_in
add wave -noupdate /tb_control_lab3/Imm2_in
add wave -noupdate /tb_control_lab3/mov_s
add wave -noupdate /tb_control_lab3/done_s
add wave -noupdate /tb_control_lab3/and_s
add wave -noupdate /tb_control_lab3/or_s
add wave -noupdate /tb_control_lab3/xor_s
add wave -noupdate /tb_control_lab3/jnc_s
add wave -noupdate /tb_control_lab3/jc_s
add wave -noupdate /tb_control_lab3/jmp_s
add wave -noupdate /tb_control_lab3/sub_s
add wave -noupdate /tb_control_lab3/add_s
add wave -noupdate /tb_control_lab3/ld_s
add wave -noupdate /tb_control_lab3/st_s
add wave -noupdate /tb_control_lab3/Cflag
add wave -noupdate /tb_control_lab3/Zflag
add wave -noupdate /tb_control_lab3/Nflag
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ps
update
WaveRestoreZoom {0 ps} {1024 ns}
