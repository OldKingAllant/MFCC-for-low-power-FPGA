create_clock -period 1000.000 -name clk_output -waveform {0.000 500.000} -add [get_ports -filter { NAME =~  "*clk_output*" && DIRECTION == "IN" }]



set_input_delay -clock [get_clocks *clk*] -add_delay 5.000 [get_ports {input_valid {input_value[0]} {input_value[1]} {input_value[2]} {input_value[3]} {input_value[4]} {input_value[5]} {input_value[6]} {input_value[7]} {input_value[8]} {input_value[9]} {input_value[10]} {input_value[11]} {input_value[12]} {input_value[13]} {input_value[14]} {input_value[15]} {input_value[16]} {input_value[17]} {input_value[18]} {input_value[19]} {input_value[20]} {input_value[21]} {input_value[22]} {input_value[23]} {input_value[24]} {input_value[25]} {input_value[26]} {input_value[27]} {input_value[28]} {input_value[29]} {input_value[30]} {input_value[31]}}]
set_output_delay -clock [get_clocks *clk*] -add_delay 5.000 [get_ports -filter { NAME =~  "*" && DIRECTION == "OUT" }]


set_false_path -from [get_clocks *clk*] -to [get_pins {fft/fft_block/U0/i_synth/xfft_inst/non_floating_point.arch_d.xfft_inst/pe_gen[0].natural_order_input.PE/has_TW_mult.MULT/i_cmpy/three_mult_structure.use_dsp.i_dsp48/mult1_preadder_d_plus_a.mult1/mult/use_prim.appDSP48[0].bppDSP48[1].use_dsp.use_dsp48e1.iDSP48E1/ACIN[0]}]
set_false_path -from [get_clocks *clk*] -to [get_pins {fft/fft_block/U0/i_synth/xfft_inst/non_floating_point.arch_d.xfft_inst/pe_gen[0].natural_order_input.PE/has_TW_mult.MULT/i_cmpy/three_mult_structure.use_dsp.i_dsp48/mult1_preadder_d_plus_a.mult1/mult/use_prim.appDSP48[0].bppDSP48[1].use_dsp.use_dsp48e1.iDSP48E1/ACIN[10]}]

create_clock -period 1000.000 -name main_clk -waveform {0.000 500.000} -add [get_ports -filter { NAME =~  "*clk*" && DIRECTION == "IN" }]

