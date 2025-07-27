----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 18.07.2025 11:30:33
-- Design Name: 
-- Module Name: window - Behavioral
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
use std.textio.all;

entity window is
    generic (
        sample_size : integer;
        window_size : integer;
        window_file : string;
        precision_shift : integer
    );
    port (
        clk : in std_logic;
        enable : in std_logic;
        value : in unsigned(sample_size - 1 downto 0);
        end_of_stream : in std_logic;
        valid : out std_logic;
        windowed_value : out unsigned(sample_size - 1 downto 0)
    );
end window;

--Applies hamming window to the framed signal. The samples
--are considered to have a fixed point precision

architecture Behavioral of window is
    constant MEM_SIZE : integer := window_size / 2;
    --Store only half of the values, the rest is reconstructed by symmetry
    type ROM_TYPE is array(0 to MEM_SIZE - 1) of std_logic_vector(31 downto 0);
    impure function CreateRom(file_name: in string) return ROM_TYPE is
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
    
    signal WINDOW : ROM_TYPE := CreateRom(window_file);
    signal curr_window_position : integer := 0; --current number of samples in frame
    signal curr_wave_position : integer := 0;   --position inside wave memory
    
    type WAVE_DIR is (INC, DEC);
    signal curr_wave_dir : WAVE_DIR := INC; --by symmetry, increase until half of the window, decrease to zero after
begin
    assert window_size mod 2 = 0 report "Window size must be multiple of 2";
    
    process(clk) is
        variable next_wave_pos : integer := 0;
        variable next_win_pos : integer := 0;
        variable temp_result : unsigned(63 downto 0);
    begin 
        if rising_edge(clk) then
            valid <= '0';
            if(enable = '1') then
                valid <= '1';
                --Apply window transform
                temp_result := shift_left(value, precision_shift) * unsigned(WINDOW(curr_wave_position));
                windowed_value <= temp_result(31 downto 0);
                
                next_win_pos := curr_window_position + 1;
                
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
                
                if(next_win_pos >= window_size) then
                    next_win_pos := 0;
                end if;
                
                curr_wave_position <= next_wave_pos;
                curr_window_position <= next_win_pos;
            elsif(end_of_stream = '1') then
                valid <= '1';
                windowed_value <= (others => '0');
            end if;
        end if;
    end process;

end Behavioral;
