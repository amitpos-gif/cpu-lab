onerror {resume}
add list -width 16 /tb_adder/cout
add list /tb_adder/alufn_adder
add list /tb_adder/x
add list /tb_adder/y
add list /tb_adder/s
configure list -usestrobe 0
configure list -strobestart {0 ps} -strobeperiod {0 ps}
configure list -usesignaltrigger 1
configure list -delta collapse
configure list -signalnamewidth 0
configure list -datasetprefix 0
configure list -namelimit 5
