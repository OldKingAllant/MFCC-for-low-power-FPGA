create_clock -period 62500.000 -name clk_sampling -waveform {0.000 31250.000} -add [get_ports -filter { NAME =~  "*clk_sampling*" && DIRECTION == "IN" }]
create_clock -period 1000.000 -name clk_output -waveform {0.000 500.000} -add [get_ports -filter { NAME =~  "*clk_output*" && DIRECTION == "IN" }]
