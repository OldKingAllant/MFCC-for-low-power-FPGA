----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 17.07.2025 09:50:24
-- Design Name: 
-- Module Name: preemph_tb - Behavioral
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
use ieee.numeric_std.all;

entity preemph_tb is
end preemph_tb;

architecture Behavioral of preemph_tb is
 signal       clk : std_logic;
 signal       enable : std_logic; 
 signal       val_in : unsigned(31 downto 0);
 signal       val_out : unsigned(31 downto 0);
 signal       ready : std_logic;
 signal       ready_sync : std_logic;
begin
    preemph_module : entity work.preemphasis(Behavioral) 
    generic map(
        sample_size => 32,
        bit_shift => 5
    )
    port map(
        clk => clk,
        enable => enable,
        val_in => val_in,
        val_out => val_out,
        ready => ready,
        ready_sync => ready_sync
    );
    
    process is 
    begin 
        clk <= '0';
        wait for 100ns;
        clk <= '1';
        wait for 100ns;
    end process;
    
    enable <= '1';
    val_in <= to_unsigned(16#20#, 32);

end Behavioral;
