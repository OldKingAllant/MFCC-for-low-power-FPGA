create_clock -period 1000.000 -name clk_output -waveform {0.000 500.000} -add [get_ports -filter { NAME =~  "*clk_output*" && DIRECTION == "IN" }]


create_generated_clock -name clk_sampling -source [get_ports *clk_output*] -divide_by 63 -add -master_clock clk_output [get_ports *clk_sampling*]

set_operating_conditions -grade extended
