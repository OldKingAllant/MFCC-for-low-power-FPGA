----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 27.07.2025 15:00:27
-- Design Name: 
-- Module Name: log_tb - Behavioral
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


entity log_tb is
--  Port ( );
end log_tb;

architecture Behavioral of log_tb is
    signal clk : std_logic;
    signal input_valid : std_logic;
    signal input_value : std_logic_vector(63 downto 0);
    signal output_valid : std_logic;
    signal output_value : std_logic_vector(63 downto 0);
    signal request_stall : std_logic;
    signal stall : std_logic;
begin
    log_block : entity work.log_compute(Behavioral)
    generic map(
        sample_size => 64,
        precision => 12,
        num_coeffs => 1,
        total_coeffs => 16,
        buf_size => 20
    )
    port map(
        clk => clk,
        input_valid => input_valid,
        input_coeffs => input_value,
        output_valid => output_valid,
        output_value => output_value,
        request_stall => request_stall,
        stall => '0'
    );
    
    input_value <= std_logic_vector(to_unsigned(1234 * (2**12), 64));
    
    process is
        variable input_cnt : integer := 0;
    begin
        input_valid <= '0';
        if(input_cnt < 16) then
            input_valid <= '1';
            input_cnt := input_cnt + 1;
        end if;
        clk <= '0';
        wait for 100ns;
        clk <= '1';
        wait for 100ns;
    end process;

end Behavioral;
