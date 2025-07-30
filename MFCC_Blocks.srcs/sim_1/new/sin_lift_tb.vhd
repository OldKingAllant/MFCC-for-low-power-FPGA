----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 30.07.2025 11:01:36
-- Design Name: 
-- Module Name: sin_lift_tb - Behavioral
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

entity sin_lift_tb is
--  Port ( );
end sin_lift_tb;

architecture Behavioral of sin_lift_tb is
    signal clk : std_logic;
    signal input_valid : std_logic;
    signal input_value : std_logic_vector(64 - 1 downto 0);
    signal output_valid : std_logic;
    signal output_value : std_logic_vector(64 - 1 downto 0);
    signal request_stall : std_logic;
    signal stall : std_logic := '0';
begin
    lifter : entity work.sin_lifter(Behavioral) 
    generic map(
        sample_size => 64,
        precision => 8,
        window_size => 16,
        const => 22
    )
    port map(
        clk => clk,
        input_valid => input_valid,
        input_value => input_value,
        output_valid => output_valid,
        output_value => output_value,
        request_stall => request_stall,
        stall => '0'
    );
    
    process is
    begin
        input_valid <= '1';
        input_value <= std_logic_vector(to_unsigned(256, 64));
        clk <= '0';
        wait for 100ns;
        clk <= '1';
        wait for 100ns;
    end process;
end Behavioral;
