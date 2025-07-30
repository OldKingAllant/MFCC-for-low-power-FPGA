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
 signal       input_valid : std_logic; 
 signal       input_value : signed(31 downto 0) := (others => '0');
 signal       output_value : signed(31 downto 0);
 signal       output_valid : std_logic;
 
 signal input_val_temp : std_logic_vector(15 downto 0);
begin
    preemph_module : entity work.preemphasis(Behavioral) 
    generic map(
        sample_size => 32,
        bit_shift => 5
    )
    port map(
        clk => clk,
        input_valid => input_valid,
        input_value => input_value,
        output_value => output_value,
        output_valid => output_valid,
        stall => '0'
    );
    
    wave_gen : entity work.complex_signal_generator(Behavioral) 
    generic map(
        FFT_Size => 512,
        FUNC_TYPE => 2
    )
    port map(
        clk => clk,
        reset => '1',
        real_out => input_val_temp,
        tvalid => input_valid
    );
    
    input_value <= resize(signed(input_val_temp), input_value'length);
    
    process is 
    begin 
        clk <= '0';
        wait for 100ns;
        clk <= '1';
        wait for 100ns;
    end process;
    
    --input_valid <= '1';
    --input_value <= to_unsigned(16#20#, 32);

end Behavioral;
