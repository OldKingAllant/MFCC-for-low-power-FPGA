----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 20.07.2025 17:04:20
-- Design Name: 
-- Module Name: power_spectrum - Behavioral
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

entity power_spectrum is
    generic (
        sample_size : integer;
        fft_size : integer;
        precision : integer := 8
    );
    port (
        clk : in std_logic;
        input_valid : in std_logic;
        re_in : in std_logic_vector(sample_size - 1 downto 0);
        im_in : in std_logic_vector(sample_size - 1 downto 0);
        output_valid : out std_logic;
        sum : out std_logic_vector((sample_size * 2) - 1 downto 0);
        output_value : out std_logic_vector((sample_size * 2) - 1 downto 0);
        request_stall : out std_logic;
        stall : in std_logic
    );
end power_spectrum;

architecture Behavioral of power_spectrum is
    constant RESULT_SIZE : integer := sample_size * 2;
    constant HALF_FFT_SIZE : integer := fft_size / 2;
    constant AVG_SHIFT : integer := integer(log2(real(HALF_FFT_SIZE)));
    
    signal re_squared : signed(RESULT_SIZE - 1 downto 0);
    signal im_squared : signed(RESULT_SIZE - 1 downto 0);
    signal valid_squared : std_logic := '0';
    signal sum_internal : signed(RESULT_SIZE - 1 downto 0);
    signal valid_sum : std_logic := '0';
    signal point_count : integer := 0;
begin
    request_stall <= '0';
    process(clk) is
        variable temp_spectrum : unsigned(RESULT_SIZE - 1 downto 0);
        variable next_point_count : integer;
    begin
        temp_spectrum := (others => '0');
        next_point_count := 0;
        if rising_edge(clk) then
            valid_squared <= '0';
            --valid_sum <= '0';
            --valid <= '0';
            
            if(stall='0') then
                if(input_valid='1') then
                    re_squared <= signed(re_in) * signed(re_in);
                    im_squared <= signed(im_in) * signed(im_in);
                    valid_squared <= '1';
                end if;    
            end if;
            
            if(valid_squared='1') then
                valid_sum <= '1';
                sum_internal <= re_squared + im_squared;
            else
                valid_sum <= '0';
            end if;
            if(valid_sum='1') then
                next_point_count := point_count + 1;
                    
                if(next_point_count <= HALF_FFT_SIZE + 1) then
                    output_valid <= '1';
                elsif(next_point_count >= fft_size) then
                    next_point_count := 0;
                    output_valid <= '0';
                else
                    output_valid <= '0';
                end if;
                    
                temp_spectrum := shift_right(unsigned(sum_internal), AVG_SHIFT);
                output_value <= std_logic_vector(temp_spectrum);
                point_count <= next_point_count;
            else
                output_valid <= '0';
            end if;
        end if;
    end process;
    
    sum <= std_logic_vector(sum_internal);
end Behavioral;
