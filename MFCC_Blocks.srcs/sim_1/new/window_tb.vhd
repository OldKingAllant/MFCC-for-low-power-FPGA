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
   signal     clk : std_logic;
   signal     input_valid : std_logic;
   signal     input_value : std_logic_vector(32 - 1 downto 0);
   signal     output_valid : std_logic;
   signal     output_value : std_logic_vector(32 - 1 downto 0);
   signal     stall : std_logic;
   signal     stall_request : std_logic;
begin
    stall <= '0';
    
    window_module : entity work.test_window
    --generic map(
    --    sample_size => 32,
    --    window_size => 512,
    --    precision => 8
    --)
    port map(
        clk => clk,
        input_valid => input_valid,
        input_value => input_value,
        output_valid => output_valid,
        output_value => output_value,
        stall => '0',
        stall_request => stall_request
    );
    
    input_value <= std_logic_vector(to_signed(1, 32));
    input_valid <= '1';
    
    process is
    begin 
        clk <= '0';
        wait for 500ns;
        clk <= '1';
        wait for 500ns;
    end process;
end Behavioral;
