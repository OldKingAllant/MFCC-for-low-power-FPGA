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

entity spectrum_tb is
--  Port ( );
end spectrum_tb;

architecture Behavioral of spectrum_tb is
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
begin
    fft : entity work.fft(Behavioral) port map(
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
        FUNC_TYPE => 1
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
        clk <= '0';
        wait for 100ns;
        clk <= '1';
        wait for 100ns;
    end process;
    
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

end Behavioral;
