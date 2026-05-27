onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb_datapath_simple/clk
add wave -noupdate /tb_datapath_simple/rst
add wave -noupdate /tb_datapath_simple/DTCM_wr
add wave -noupdate /tb_datapath_simple/Cin
add wave -noupdate /tb_datapath_simple/Cout
add wave -noupdate /tb_datapath_simple/DTCM_addr_in
add wave -noupdate /tb_datapath_simple/DTCM_out
add wave -noupdate /tb_datapath_simple/ALUFN
add wave -noupdate /tb_datapath_simple/Ain
add wave -noupdate /tb_datapath_simple/RFin
add wave -noupdate /tb_datapath_simple/RFout
add wave -noupdate /tb_datapath_simple/RFaddr_rd
add wave -noupdate /tb_datapath_simple/RFaddr_wr
add wave -noupdate /tb_datapath_simple/IRin
add wave -noupdate /tb_datapath_simple/PCin
add wave -noupdate /tb_datapath_simple/PCsel
add wave -noupdate /tb_datapath_simple/Imm1_in
add wave -noupdate /tb_datapath_simple/Imm2_in
add wave -noupdate /tb_datapath_simple/Cflag
add wave -noupdate /tb_datapath_simple/Zflag
add wave -noupdate /tb_datapath_simple/Nflag
add wave -noupdate /tb_datapath_simple/add_s
add wave -noupdate /tb_datapath_simple/sub_s
add wave -noupdate /tb_datapath_simple/and_s
add wave -noupdate /tb_datapath_simple/or_s
add wave -noupdate /tb_datapath_simple/xor_s
add wave -noupdate /tb_datapath_simple/mov_s
add wave -noupdate /tb_datapath_simple/ld_s
add wave -noupdate /tb_datapath_simple/st_s
add wave -noupdate /tb_datapath_simple/jmp_s
add wave -noupdate /tb_datapath_simple/jc_s
add wave -noupdate /tb_datapath_simple/jnc_s
add wave -noupdate /tb_datapath_simple/done_s
add wave -noupdate /tb_datapath_simple/TBactive
add wave -noupdate /tb_datapath_simple/ITCM_tb_wr
add wave -noupdate /tb_datapath_simple/ITCM_tb_in
add wave -noupdate /tb_datapath_simple/ITCM_tb_addr_in
add wave -noupdate /tb_datapath_simple/DTCM_tb_wr
add wave -noupdate /tb_datapath_simple/DTCM_tb_in
add wave -noupdate /tb_datapath_simple/DTCM_tb_out
add wave -noupdate /tb_datapath_simple/DTCM_tb_addr_in
add wave -noupdate /tb_datapath_simple/DTCM_tb_addr_out
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {260104 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 240
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
WaveRestoreZoom {0 ps} {967181 ps}
