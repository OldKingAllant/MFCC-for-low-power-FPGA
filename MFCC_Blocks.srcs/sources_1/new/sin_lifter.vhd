----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 30.07.2025 10:36:55
-- Design Name: 
-- Module Name: sin_lifter - Behavioral
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
use IEEE.math_real.all;

entity sin_lifter is
    generic (
        sample_size : integer := 64;
        precision : integer := 8;
        window_size : integer := 16;
        const : integer := 22
    );
    port (
        clk : in std_logic;
        input_valid : in std_logic;
        input_value : in std_logic_vector(sample_size - 1 downto 0);
        output_valid : out std_logic;
        output_value : out std_logic_vector(sample_size - 1 downto 0);
        stall : in std_logic;
        request_stall : out std_logic
    );
end sin_lifter;

architecture Behavioral of sin_lifter is
    type WIN_TY is array(0 to window_size - 1) of signed(sample_size - 1 downto 0);
    
    function ComputeLiftWindow(unused: integer) return WIN_TY is
        variable win : WIN_TY := (others => (others => '0'));
        variable temp_value : real;
    begin
        --n = np.arange(1, mfcc_lift.shape[1] + 1)
        --D = 22
        --w = 1 + (D / 2) * np.sin(np.pi * n / D)
        for index in win'range loop
            temp_value := (1.0 + (real(const) / 2.0) * sin(MATH_PI * (real(index) + 1.0) / real(const))) * real(2**precision);
            win(index) := to_signed(integer(floor(temp_value)), sample_size);
        end loop;
        
        return win;
    end function;
    
    constant LIFT_WIN : WIN_TY := ComputeLiftWindow(0);
    signal curr_window_pos : integer := 0;
    
    signal out_value_temp : std_logic_vector(sample_size - 1 downto 0) := (others => '0');
begin
    request_stall <= '0';
    
    process(clk) is
        variable mult_result : signed((sample_size * 2) - 1 downto 0);
    begin
        mult_result := (others => '0');
        if rising_edge(clk) then
            if(stall='0') then
                output_valid <= '0';
                --output_value <= (others => '0');
                if(input_valid='1') then
                    mult_result := LIFT_WIN(curr_window_pos) * signed(input_value);
                    mult_result := shift_right(mult_result, precision);
                    output_valid <= '1';
                    out_value_temp <= std_logic_vector(mult_result(sample_size - 1 downto 0));
                    output_value <= out_value_temp;
                    
                    if(curr_window_pos + 1 >= LIFT_WIN'length) then
                        curr_window_pos <= 0;
                    else
                        curr_window_pos <= curr_window_pos + 1;
                    end if;
                end if;
            end if;
        end if;
    end process;
end Behavioral;
