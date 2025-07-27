----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 17.07.2025 15:35:32
-- Design Name: 
-- Module Name: frame_tb - Behavioral
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
use ieee.std_logic_textio.hwrite;

entity frame_tb is
--  Port ( );
end frame_tb;

architecture Behavioral of frame_tb is
    signal   clk_sampling : std_logic;
    signal   clk_output : std_logic; --should be faster than sampling clock to avoid losing data
    signal   enable : std_logic;
    signal   curr_value : unsigned(31 downto 0);
    signal   valid : std_logic;
    signal   stream_out : unsigned(31 downto 0);
    
    constant WIN_SIZE : integer := 10;
    constant STEP_SIZE : integer := 6;
begin
    frame_module : entity work.frame(Behavioral) 
    generic map(
        sample_size => 32,
        window_size => WIN_SIZE,
        step_size => STEP_SIZE
    )
    port map(
        clk_sampling => clk_sampling,
        clk_output => clk_output,
        enable => enable,
        end_of_data => '0',
        curr_value => curr_value,
        valid => valid,
        stream_out => stream_out
    );
    
    enable <= '1';
    
    process is 
        variable input_value : integer := 0;
    begin 
        clk_sampling <= '0';
        curr_value <= to_unsigned(input_value, curr_value'length);
        input_value := input_value + 1;
        --if(input_value = 9) then
        --    input_value := 0;
        --else 
        --    input_value := input_value + 1;
        --end if;
        wait for 100ns;
        clk_sampling <= '1';
        wait for 100ns;
    end process;
    
    process is 
        file test_output : text open write_mode is "frame_tb.log";
        variable curr_line : line;
        variable curr_line_width : integer := 0;
        variable old_out_value : unsigned(31 downto 0) := (others => '1');
        
        constant UNDEF_VECTOR : std_logic_vector(31 downto 0) := (others => 'U');
        constant X_VECTOR : std_logic_vector(31 downto 0) := (others => 'X');
    begin 
        clk_output <= '0';
        wait for 25ns;
        clk_output <= '1';
        wait for 25ns;
        
        if(not (to_integer(stream_out) = to_integer(old_out_value)) and not (std_logic_vector(stream_out) = UNDEF_VECTOR)) then
            old_out_value := stream_out;
            hwrite(curr_line, std_logic_vector(stream_out));
            write(curr_line, ' ');
            curr_line_width := curr_line_width + 1;
        
            if(curr_line_width = WIN_SIZE) then
                curr_line_width := 0;
                writeline(test_output, curr_line);
                flush(test_output);
            end if;
        end if;
        
        
    end process;
end Behavioral;
