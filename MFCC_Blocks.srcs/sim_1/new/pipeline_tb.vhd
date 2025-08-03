----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 03.08.2025 09:42:08
-- Design Name: 
-- Module Name: pipeline_tb - Behavioral
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

entity pipeline_tb is
--  Port ( );
end pipeline_tb;

architecture Behavioral of pipeline_tb is
    signal   clk_sampling : std_logic;
    signal   clk_output : std_logic;
    
    signal input_val_temp : std_logic_vector(15 downto 0);
    signal input_valid : std_logic;
    signal input_value : std_logic_vector(31 downto 0);
    
    signal output_valid : std_logic;
    signal output_value : std_logic_vector(63 downto 0);
begin
    wave_gen : entity work.complex_signal_generator(Behavioral) 
    generic map(
        FFT_Size => 512,
        FUNC_TYPE => 2
    )
    port map(
        clk => clk_sampling,
        reset => '1',
        real_out => input_val_temp,
        tvalid => input_valid
    );
    
    input_value <= std_logic_vector(resize(signed(input_val_temp), 32));
    
    mfcc_extract : entity work.pipeline
    port map(
        clk_sampling => clk_sampling,
        clk_output => clk_output,
        input_valid => input_valid,
        input_value => input_value,
        output_valid => output_valid,
        output_value => output_value
    );
    
    process is
    begin 
        clk_sampling <= '0';
        wait for 100ns;
        clk_sampling <= '1';
        wait for 100ns;
    end process;
    
    process is 
        variable input_cnt : integer := 0;
    begin 
        clk_output <= '0';
        wait for 25ns;
        clk_output <= '1';
        wait for 25ns;
    end process;
end Behavioral;
