----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 20.07.2025 18:58:14
-- Design Name: 
-- Module Name: spectrum_tb - Behavioral
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
use IEEE.math_real.all;

entity spectrum_tb is
--  Port ( );
end spectrum_tb;

architecture Behavioral of spectrum_tb is
    signal    clk : std_logic;
    signal    wave_clk : std_logic;
    
    signal    input_valid_fft : std_logic;
    signal    input_value_fft : std_logic_vector(31 downto 0) := (others => '0');
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
    
    constant SAMPLE_RATE : integer := 16000;
    constant OUT_RATE : integer := 1000000;
    constant INPUT_CLK_DIV : integer := integer(ceil(real(OUT_RATE)/real(SAMPLE_RATE))) - 1;
    
    signal input_enable_cnt : integer := 0;
    signal enable_gen : std_logic := '0';
    signal enable_mfcc : std_logic := '0';
    
    signal input_val_temp : std_logic_vector(15 downto 0);
    signal input_valid_temp : std_logic;
begin
    process(clk)
    is begin
        if rising_edge(clk) then
            enable_mfcc <= '0';
            enable_gen <= '0';
            if(input_enable_cnt + 1 >= INPUT_CLK_DIV) then
                input_enable_cnt <= 0;
                enable_mfcc <= '1';
            else
                if(input_enable_cnt + 1 >= INPUT_CLK_DIV - 1) then
                    enable_gen <= '1';
                end if;
                input_enable_cnt <= input_enable_cnt + 1;
            end if;
        end if;
    end process;
    
    fft : entity work.test_fft port map(
        clk => clk,
        input_valid => input_valid_fft,
        input_value => input_value_fft,
        output_valid => output_valid_fft,
        output_re => output_re,
        output_im => output_im,
        frame_end => frame_end,
        request_stall => fft_stall_req,
        stall => spectrum_stall_req
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
        stall => '0',
        request_stall => spectrum_stall_req
    );
    
    wave_gen : entity work.complex_signal_generator(Behavioral) 
    generic map(
        FFT_Size => 512,
        FUNC_TYPE => 2
    )
    port map(
        clk => clk,
        reset => '1',
        real_out => input_val_temp,
        tvalid => input_valid_temp,
        enable => enable_gen
    );
    
    input_valid_fft <= '1' when enable_mfcc='1' and input_valid_temp='1' else '0';
    input_value_fft <= std_logic_vector(resize(signed(input_val_temp), 32));
    
    process 
    is 
    begin
        clk <= '0';
        wait for 500ns;
        clk <= '1';
        wait for 500ns;
    end process;

end Behavioral;
