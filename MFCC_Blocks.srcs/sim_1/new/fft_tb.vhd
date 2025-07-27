----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 20.07.2025 12:03:03
-- Design Name: 
-- Module Name: fft_tb - Behavioral
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

entity fft_tb is
end fft_tb;

architecture Behavioral of fft_tb is
    signal    clk : std_logic;
    signal    enable : std_logic;
    signal    input_val : unsigned(31 downto 0) := (others => '0');
    signal    output_ready : std_logic;
    signal    output_re : std_logic_vector(31 downto 0);
    signal    output_im : std_logic_vector(31 downto 0);
    signal frame_end : std_logic;
    signal temp_val : std_logic_vector(15 downto 0);
begin
    fft_block : entity work.fft(Behavioral) port map(
        clk => clk,
        enable => enable,
        input_val => input_val,
        output_ready => output_ready,
        output_re => output_re,
        output_im => output_im,
        frame_end => frame_end
    );
    
    wave_gen : entity work.complex_signal_generator(Behavioral) 
    generic map(
        FFT_Size => 512,
        FUNC_TYPE => 1
    )
    port map(
        clk => clk,
        reset => '1',
        imagery_out => temp_val
    );
    
    input_val(15 downto 0) <= unsigned(temp_val);
    enable <= '1';
    
    --process 
    --is 
    --begin 
    --    input_val(0) <= '0';
    --    wait for 50us;
    --    input_val(0) <= '1';
    --    wait for 50us;
    --end process;
    
    process 
    is 
    begin
        clk <= '0';
        wait for 100ns;
        clk <= '1';
        wait for 100ns;
    end process;

end Behavioral;
