onerror {resume}
add list -width 25 /tb_shifter/inp_shifter
add list /tb_shifter/x_control
add list /tb_shifter/alufn_shifter
add list /tb_shifter/outp_shifter
add list /tb_shifter/cout_shifter
configure list -usestrobe 0
configure list -strobestart {0 ps} -strobeperiod {0 ps}
configure list -usesignaltrigger 1
configure list -delta all
configure list -signalnamewidth 0
configure list -datasetprefix 0
configure list -namelimit 5
