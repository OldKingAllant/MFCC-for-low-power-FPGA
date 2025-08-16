----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 15.08.2025 11:05:36
-- Design Name: 
-- Module Name: test_window - Behavioral
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
use std.textio.all;

entity test_window is
    generic (
        sample_size : integer := 32;
        window_size : integer := 512;
        --window_file : string;
        precision : integer := 8
    );
    port (
        clk : in std_logic;
        input_valid : in std_logic;
        input_value : in std_logic_vector(sample_size - 1 downto 0);
        output_valid : out std_logic;
        output_value : out std_logic_vector(sample_size - 1 downto 0);
        stall : in std_logic;
        stall_request : out std_logic
    );
end test_window;

--Applies hamming window to the framed signal. The samples
--are considered to have a fixed point precision

architecture Behavioral of test_window is
    constant MEM_SIZE : integer := window_size / 2;
    --Store only half of the values, the rest is reconstructed by symmetry
    type ROM_TYPE is array(0 to MEM_SIZE - 1) of std_logic_vector(31 downto 0);
    impure function CreateRomFromFile(file_name: in string) return ROM_TYPE is
        FILE fd : text is in file_name;
        variable curr_line : line;
        variable RET_ROM : ROM_TYPE;
    begin
        for index in ROM_TYPE'range loop 
            readline(fd, curr_line);
            hread(curr_line, RET_ROM(index));
        end loop;
        return RET_ROM;
    end function;
    
    function CreateRom(unused: integer) return ROM_TYPE is
        variable RET_ROM : ROM_TYPE;
        variable temp_val : real;
    begin
        for index in RET_ROM'range loop
            --h = 0.54 - 0.46 * np.cos(2 * np.pi * n / (window_length - 1))
            temp_val := (0.54 - 0.46 * cos(2.0 * MATH_PI * real(index) / (real(window_size) - 1.0))) * real(2**precision);
            RET_ROM(index) := std_logic_vector(to_signed(integer(floor(temp_val)), 32));
        end loop;
        return RET_ROM;
    end function;
    
    constant WINDOW : ROM_TYPE := CreateRom(0);
    --signal curr_window_position : integer := 0; --current number of samples in frame
    signal curr_wave_position : integer := 0;   --position inside wave memory
    
    type WAVE_DIR is (INC, DEC);
    signal curr_wave_dir : WAVE_DIR := INC; --by symmetry, increase until half of the window, decrease to zero after
    
    --signal out_value_temp : std_logic_vector(sample_size - 1 downto 0);
begin
    assert window_size mod 2 = 0 report "Window size must be multiple of 2";
    
    stall_request <= '0';
    
    process(clk) is
        variable next_wave_pos : integer := 0;
        --variable next_win_pos : integer := 0;
        variable temp_result : signed(63 downto 0);
    begin 
        next_wave_pos := 0;
        --next_win_pos := 0;
        temp_result := (others => '0');
        if rising_edge(clk) then
            if(stall='0') then
                output_valid <= '0';
                if(input_valid = '1') then
                    output_valid <= '1';
                    --Apply window transform
                    temp_result := shift_right(shift_left(signed(input_value), precision) * signed(WINDOW(curr_wave_position)), precision);
                    --out_value_temp <= std_logic_vector(temp_result(31 downto 0));
                    output_value <= std_logic_vector(temp_result(31 downto 0));
                
                    --next_win_pos := curr_window_position + 1;
                
                    if(curr_wave_dir = INC) then                 --Still in first half of window
                        next_wave_pos := curr_wave_position + 1; --increase position
                        if(next_wave_pos >= MEM_SIZE) then       --Half reached
                            next_wave_pos := curr_wave_position;
                            curr_wave_dir <= DEC;
                        end if;
                    else --In second half of window
                        next_wave_pos := curr_wave_position - 1; --Decrease position
                        if(next_wave_pos < 0) then
                            next_wave_pos := 0;
                            curr_wave_dir <= INC;
                        end if;
                    end if;
                
                    --if(next_win_pos >= window_size) then
                    --    next_win_pos := 0;
                    --end if;
                
                    curr_wave_position <= next_wave_pos;
                    --curr_window_position <= next_win_pos;
                end if;
            end if;
        end if;
    end process;

end Behavioral;
