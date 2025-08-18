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
        const : integer := 22;
        input_cnt : integer := 2
    );
    port (
        clk : in std_logic;
        input_valid : in std_logic;
        input_value : in std_logic_vector((sample_size * input_cnt) - 1 downto 0);
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
    signal out_valid_temp : std_logic := '0';
    
    constant INPUT_BUF_SIZE : integer := window_size * 2;
    type INPUT_BUFF_TY is array(0 to INPUT_BUF_SIZE - 1) of std_logic_vector(sample_size - 1 downto 0);
    
    signal input_buffer : INPUT_BUFF_TY := (others => (others => '0'));
    signal coeff_cnt : integer := 0;
    
    type STATE_TY is (FILLING, COMPUTING);
    signal state : STATE_TY := FILLING;
begin
    process(clk) is
        variable mult_result : signed((sample_size * 2) - 1 downto 0);
        variable curr_coeff_count : integer;
    begin
        mult_result := (others => '0');
        curr_coeff_count := 0;
        if rising_edge(clk) then
            if(stall='0') then
                out_valid_temp <= '0';
                out_value_temp <= (others => '0');
                
                if(coeff_cnt=INPUT_BUF_SIZE) then
                    request_stall <= '1';
                else
                    request_stall <= '0';
                end if;
                
                curr_coeff_count := coeff_cnt;
                
                if(state=FILLING and input_valid='1') then
                    for i in 0 to input_cnt - 1 loop
                        input_buffer(curr_coeff_count + i) <= input_value(((i + 1)*sample_size)-1 downto (i*sample_size));
                    end loop;
                    curr_coeff_count := curr_coeff_count + input_cnt;
                    if(curr_coeff_count=INPUT_BUF_SIZE) then
                        request_stall <= '1';
                    end if;
                    if(curr_coeff_count=window_size) then
                        state <= COMPUTING;
                    end if;
                end if;
                
                if(state=COMPUTING) then
                    mult_result := LIFT_WIN(curr_window_pos) * signed(input_buffer(0));
                    mult_result := shift_right(mult_result, precision);
                    out_valid_temp <= '1';
                    out_value_temp <= std_logic_vector(mult_result(sample_size - 1 downto 0));
                    
                    if(curr_window_pos + 1 >= LIFT_WIN'length) then
                        curr_window_pos <= 0;
                    else
                        curr_window_pos <= curr_window_pos + 1;
                    end if;
                    
                    input_buffer(0 to INPUT_BUF_SIZE - 2) <= input_buffer(1 to INPUT_BUF_SIZE - 1);
                    curr_coeff_count := curr_coeff_count - 1;
                
                    if(curr_coeff_count=0) then
                        state <= FILLING;
                        curr_coeff_count := 0;
                    end if;
                end if;
                
                output_valid <= out_valid_temp;
                output_value <= out_value_temp;
                
                coeff_cnt <= curr_coeff_count;
            end if;
        end if;
    end process;
end Behavioral;
