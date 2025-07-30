----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 17.07.2025 09:15:04
-- Design Name: 
-- Module Name: preemphasis - Behavioral
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

--module used to apply pre-emphasis on input stream
--y(t) = x(t) - ax(t - 1)
--since we are used integer/fixed point, we can
--simply shift the old value instead of using
--a multiplier
--This is the procedure:
--Given a = (1 - c) 0 < c < 1
--x(t) - (1 - c)x(t - 1)
--x(t) - x(t - 1) + cx(t - 1)
--The term cx(t - 1) can then be computed
--as x(t - 1) >> bit_shift

--The purpose of this stage is to amplify the harmonics
--with higher frequencies, which are often more useful
--than low frequencies

--It is some kind of high-pass filter, but without
--keeping in consideration the previous output

--The shift value should be chosen to be as close
--as possible to the wanted value 

entity preemphasis is
    generic (
        sample_size : integer := 32; --sample size in bits
        bit_shift : integer := 5    --a = 1 - (1 >> bit_shift)
    );
    port (
        clk : in std_logic;
        input_valid : in std_logic; 
        input_value : in signed(sample_size - 1 downto 0);
        output_value : out signed(sample_size - 1 downto 0);
        output_valid : out std_logic;
        stall : in std_logic
    );
end preemphasis;

architecture Behavioral of preemphasis is
    --shift register holds previous input value used for
    --interpolation
    signal previous_value : signed(sample_size - 1 downto 0) := (others => '0');
begin
    -- sequential
    process(clk) is
    begin 
        if rising_edge(clk) then
            if(stall='0') then
                output_valid <= '0';
                if(input_valid = '1') then 
                    output_valid <= '1';
                    previous_value <= input_value;
                    output_value <= input_value - previous_value + shift_right(previous_value, bit_shift);
                end if;
            end if;
        end if;
    end process;

end Behavioral;
