onerror {resume}
add list -width 13 /tb_logic/x
add list /tb_logic/y
add list /tb_logic/alufn_in_logic
add list /tb_logic/logic_out
configure list -usestrobe 0
configure list -strobestart {0 ps} -strobeperiod {0 ps}
configure list -usesignaltrigger 1
configure list -delta all
configure list -signalnamewidth 0
configure list -datasetprefix 0
configure list -namelimit 5
