----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 29.07.2025 10:09:56
-- Design Name: 
-- Module Name: dct_tb - Behavioral
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

entity dct_tb is
--  Port ( );
end dct_tb;

architecture Behavioral of dct_tb is
    signal clk : std_logic;
    signal input_valid : std_logic;
    signal input_coeff : std_logic_vector(63 downto 0);
    signal output_valid : std_logic;
    signal output_value : std_logic_vector(63 downto 0);
    signal request_stall : std_logic;
    signal stall : std_logic;
    --signal prev_
begin
    dct_block : entity work.dct
    --generic map(
    --    sample_size => 64,
    --    precision => 8,
    --    numcoeffs => 16,
    --    numcepstra => 16,
    --    nmult => 4
    --)
    port map(
        clk => clk,
        input_valid => input_valid,
        input_coeff => input_coeff,
        output_valid => output_valid,
        output_value => output_value,
        request_stall => request_stall,
        stall => '0'
    );
    
    process is
        variable input_cnt : integer := 0;
    begin
        input_valid <= '0';
        input_coeff <= (others => '0');
        
        if(input_cnt < 16) then
            input_valid <= '1';
            input_coeff <= std_logic_vector(to_unsigned(input_cnt*256, 64));
            input_cnt := input_cnt + 1;
        end if;
        clk <= '0';
        wait for 500ns;
        clk <= '1';
        wait for 500ns;
    end process;
end Behavioral;
