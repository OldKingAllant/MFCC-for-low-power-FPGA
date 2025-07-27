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
    signal    enable : std_logic;
    signal    input_val : unsigned(31 downto 0) := (others => '0');
    signal    output_ready : std_logic;
    signal    output_re : std_logic_vector(31 downto 0);
    signal    output_im : std_logic_vector(31 downto 0);
    signal    frame_end : std_logic;
    signal    temp_val : std_logic_vector(15 downto 0);
    signal    spectrum_valid : std_logic;
    signal    sum : std_logic_vector(63 downto 0);
    signal    spectrum : std_logic_vector(63 downto 0);
    
    signal receiver_ready_fft : std_logic := '1';
    signal ready_to_receive_fft : std_logic := '1';
begin
    fft : entity work.fft(Behavioral) port map(
        clk => clk,
        enable => enable,
        input_val => input_val,
        output_ready => output_ready,
        output_re => output_re,
        output_im => output_im,
        frame_end => frame_end,
        receiver_ready => receiver_ready_fft,
        ready_to_receive => ready_to_receive_fft
    );
    
    pow_spectrum : entity work.power_spectrum(Behavioral) 
    generic map(
        sample_size => 32,
        fft_size => 512
    )
    port map(
        clk => clk,
        enable => output_ready,
        re_in => output_re,
        im_in => output_im,
        valid => spectrum_valid,
        sum => sum,
        spectrum => spectrum,
        receiver_ready => '1',
        ready_to_receive => receiver_ready_fft
    );
    
    wave_gen : entity work.complex_signal_generator(Behavioral) 
    generic map(
        FFT_Size => 512,
        FUNC_TYPE => 0
    )
    port map(
        clk => wave_clk,
        reset => '1',
        real_out => temp_val
    );
    
    input_val(15 downto 0) <= unsigned(temp_val);
    enable <= '1';
    
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
        
        if(ready_to_receive_fft='1') then
            wave_clk <= '1';
        else
            wave_clk <= '0';
        end if;
        
        wait for 100ns;
    end process;

end Behavioral;
