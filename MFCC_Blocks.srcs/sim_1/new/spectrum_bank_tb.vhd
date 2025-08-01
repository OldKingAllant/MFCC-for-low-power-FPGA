----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 25.07.2025 11:55:45
-- Design Name: 
-- Module Name: spectrum_bank_tb - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;

use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity spectrum_bank_tb is
--  Port ( );
end spectrum_bank_tb;

architecture Behavioral of spectrum_bank_tb is
    signal    clk : std_logic;
    signal    wave_clk : std_logic;
    
    signal    input_valid_fft : std_logic;
    signal    input_value_fft : signed(31 downto 0) := (others => '0');
    signal    output_valid_fft : std_logic;
    signal    output_re : std_logic_vector(31 downto 0);
    signal    output_im : std_logic_vector(31 downto 0);
    signal    frame_end : std_logic;
    
    signal    temp_val : std_logic_vector(15 downto 0);
    signal    spectrum_valid : std_logic;
    signal    sum : std_logic_vector(63 downto 0);
    signal    spectrum : std_logic_vector(63 downto 0);
    
    signal fft_stall_req : std_logic;
    signal spectrum_stall_req : std_logic;
    
    signal fbank_accepts_samples : std_logic;
    signal fbank_stall_req : std_logic;
    
    signal output_valid_fbank : std_logic;
    
    signal stall_filt : std_logic;
    signal stall_fft : std_logic;
    signal stall_pow : std_logic;
    
    type COEFF_ARR is array(0 to 3) of std_logic_vector(63 downto 0);
    signal coeff_array : COEFF_ARR;
    
    signal coefficients : std_logic_vector((64 * 4) - 1 downto 0); --packed nmult coefficients
begin
    fbank_stall_req <= '1' when fbank_accepts_samples='0' else '0';
    stall_fft <= '1' when spectrum_stall_req='1' or fbank_stall_req='1' else '0';
    stall_pow <= '1' when fbank_stall_req='1' else '0';
    stall_filt <= '0';
    
    fft : entity work.fft(Behavioral) port map(
        clk => clk,
        input_valid => input_valid_fft,
        input_value => input_value_fft,
        output_valid => output_valid_fft,
        output_re => output_re,
        output_im => output_im,
        frame_end => frame_end,
        request_stall => fft_stall_req,
        stall => stall_fft
    );
    
    pow_spectrum : entity work.power_spectrum(Behavioral) 
    generic map(
        sample_size => 32,
        fft_size => 512
    )
    port map(
        clk => clk,
        input_valid => output_valid_fft,
        re_in => output_re,
        im_in => output_im,
        output_valid => spectrum_valid,
        sum => sum,
        output_value => spectrum,
        stall => stall_pow,
        request_stall => spectrum_stall_req
    );
    
    fbank : entity work.filterbanks(Behavioral) 
    generic map(
        sample_size => 32,
        low_freq => 50,
        high_freq => 6500,
        numfilters => 16,
        nfft => 512,
        precision => 8,
        sample_freq => 16000,
        nmult => 4
    )
    port map(
        clk => clk,
        input_valid => spectrum_valid,
        input_value => spectrum,
        end_of_frame => '0',
        accepts_samples => fbank_accepts_samples,
        coefficients => coefficients,
        output_valid => output_valid_fbank,
        stall => stall_filt
    );
    
    wave_gen : entity work.complex_signal_generator(Behavioral) 
    generic map(
        FFT_Size => 512,
        FUNC_TYPE => 2
    )
    port map(
        clk => wave_clk,
        reset => '1',
        real_out => temp_val,
        tvalid => input_valid_fft
    );
    
    input_value_fft <= resize(signed(temp_val), input_value_fft'length);
    
    process 
    is 
    begin
        wave_clk <= '0';
        wait for 100ns;
        
        if(fft_stall_req='0') then
            wave_clk <= '1';
        else
            wave_clk <= '0';
        end if;
        
        wait for 100ns;
    end process;
    
    process 
    is 
    begin
        clk <= '0';
        wait for 100ns;
        clk <= '1';
        wait for 100ns;
        
        for coeff in coeff_array'range loop
            coeff_array(coeff) <= coefficients((64 * (coeff + 1)) - 1 downto (64 * coeff));
        end loop;
    end process;
    
end Behavioral;
