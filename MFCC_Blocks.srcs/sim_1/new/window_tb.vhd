----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 18.07.2025 14:13:36
-- Design Name: 
-- Module Name: window_tb - Behavioral
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

entity window_tb is
--  Port ( );
end window_tb;

architecture Behavioral of window_tb is
    signal    clk : std_logic;
    signal    enable : std_logic;
    signal    value : unsigned(31 downto 0) := (others => '0');
    signal    end_of_stream : std_logic;
    signal    valid : std_logic;
    signal    windowed_value : unsigned(31 downto 0);
begin
    window_module : entity work.window(Behavioral) 
    generic map(
        sample_size => 32,
        window_size => 32,
        window_file => "../../../../ham_window.txt",
        precision_shift => 0
    )
    port map(
        clk => clk,
        enable => enable,
        value => value,
        end_of_stream => end_of_stream,
        valid => valid,
        windowed_value => windowed_value
    );
    
    value(0) <= '1';
    enable <= '1';
    
    process is
    begin 
        clk <= '0';
        wait for 100ns;
        clk <= '1';
        wait for 100ns;
    end process;
end Behavioral;
