onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /digital_system_tb/Y_i
add wave -noupdate /digital_system_tb/X_i
add wave -noupdate /digital_system_tb/clk_i
add wave -noupdate /digital_system_tb/ena_i
add wave -noupdate /digital_system_tb/rst_i
add wave -noupdate /digital_system_tb/ALUFN_i
add wave -noupdate /digital_system_tb/ALUout_o
add wave -noupdate /digital_system_tb/Nflag_o
add wave -noupdate /digital_system_tb/Cflag_o
add wave -noupdate /digital_system_tb/Zflag_o
add wave -noupdate /digital_system_tb/Vflag_o
add wave -noupdate /digital_system_tb/pwm_o
add wave -noupdate /digital_system_tb/DIGITAL_SYSTEM_INST/SYNC_DIGITAL_CIRC_INST/PWM_OUTPOT_UNIT_INST/TIMER_INST/clk
add wave -noupdate /digital_system_tb/DIGITAL_SYSTEM_INST/SYNC_DIGITAL_CIRC_INST/PWM_OUTPOT_UNIT_INST/TIMER_INST/rst
add wave -noupdate /digital_system_tb/DIGITAL_SYSTEM_INST/SYNC_DIGITAL_CIRC_INST/PWM_OUTPOT_UNIT_INST/TIMER_INST/ena
add wave -noupdate /digital_system_tb/DIGITAL_SYSTEM_INST/SYNC_DIGITAL_CIRC_INST/PWM_OUTPOT_UNIT_INST/TIMER_INST/EQUY
add wave -noupdate /digital_system_tb/DIGITAL_SYSTEM_INST/SYNC_DIGITAL_CIRC_INST/PWM_OUTPOT_UNIT_INST/TIMER_INST/timer_val
add wave -noupdate /digital_system_tb/DIGITAL_SYSTEM_INST/SYNC_DIGITAL_CIRC_INST/PWM_OUTPOT_UNIT_INST/TIMER_INST/count_q
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {28743560 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 253
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
WaveRestoreZoom {28736 ns} {28850574 ps}
