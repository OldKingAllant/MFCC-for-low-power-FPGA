----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 17.07.2025 10:35:34
-- Design Name: 
-- Module Name: frame - Behavioral
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

--This module is used to group samples in frames
--which are partially overlapped

entity frame is
    generic(
        sample_size : integer; --sample size in bits
        window_size : integer; --how many samples in the current window
        step_size : integer    --liar, this is not the step size, the correct step size is windows_size - step_size
    );
    port(
        clk_sampling : in std_logic; --input clock 
        clk_output : in std_logic;   --this clock in a way is sampling the sampled and filtered signal (at least >= 2x of the other clock)
        enable : in std_logic;       --if the input value is valid (comes from previous stage)
        end_of_data : in std_logic;  --if there are no more input samples and we should pad the data
        curr_value : in unsigned(sample_size - 1 downto 0); 
        valid : out std_logic;
        stream_out : out unsigned(sample_size - 1 downto 0)
    );
end frame;

architecture Behavioral of frame is
    type INTERNAL_RAM is array(0 to window_size - 1) of unsigned(sample_size - 1 downto 0);
    signal MEM : INTERNAL_RAM := (others => (others => '0')); --Single ringbuffer used for both input and output
    
    signal first_fill : std_logic := '0';  --if the first fill has been performed
    signal output_position : integer := 0; --index inside ringbuffer used for output
    signal input_position : integer  := 0; --same but for input
    --signal enable_output : std_logic := '0';
    signal output_jump_position : integer := 0; --last position to which we need to reset the output pointer
                                                --when starting a new frame (for overlap)
    
    type OUT_STATE is (NORMAL, OVERLAP);
    signal curr_out_state : OUT_STATE := NORMAL;
    signal curr_out_cnt : integer := 0; --number of output samples in current frame
    signal advance_cnt : integer := 0;  --how many samples we advanced during the current frame
begin
    --sampling process, input
    --new samples
    process(clk_sampling) is 
        variable temp_input_position : integer;
    begin 
        if rising_edge(clk_sampling) then
            if(enable = '1') then
                MEM(input_position) <= curr_value; --if the output process is slow, this statement
                                                   --will overwrite the previous input value
                                                   --This, however, should never happen
                
                temp_input_position := input_position + 1;
                
                if(not(temp_input_position = output_jump_position)) then --avoid buffer overrun
                    if(temp_input_position >= window_size) then --counter is out of bounds, reset
                        input_position <= 0;
                        first_fill <= '1'; --this flag is true regardless if this is actually the first fill or not
                    else
                        input_position <= temp_input_position;
                    end if;
                end if;
            end if;
        end if;
    end process;
    
    process(clk_output) is
        variable next_output_position : integer;
        variable next_output_count : integer;
        variable next_jump_position : integer;
    begin 
        if rising_edge(clk_output) then
            if(enable = '1') then
                valid <= '0';
                if(not(output_position = input_position)) then  --If no buffer underrun
                    valid <= '1';
                    next_output_position := output_position + 1;
                    next_output_count := curr_out_cnt + 1;
                    stream_out <= MEM(output_position);
                    
                    if(next_output_position >= window_size) then --Reset output counter if out of bounds
                            next_output_position := 0;
                    end if;
                    
                    if(curr_out_state = NORMAL) then --We are not in the overlapped part of a window
                        if(advance_cnt + 1 <= window_size - step_size) then --If we have not yet advanced by 'step' samples
                            next_jump_position := output_jump_position + 1; --Increment position of next window
                            advance_cnt <= advance_cnt + 1;
                            if(next_jump_position >= window_size) then --Reset on overflow
                                next_jump_position := 0;
                            end if;
                         end if;
                         
                        if(next_output_count >= window_size) then --End of current window
                            next_output_count := 0;
                            next_output_position := next_jump_position; --Reset pointer to position of next window
                            curr_out_state <= OVERLAP;
                        end if;
                    elsif(curr_out_state = OVERLAP) then --We are at the start of a window (overlap part)
                        if(next_output_count >= step_size) then --Nothing to do here other than check if we are out of the overlap
                            curr_out_state <= NORMAL;
                            advance_cnt <= 0;
                        end if;
                    end if;
                    
                    curr_out_cnt <= next_output_count;
                    output_position <= next_output_position;
                    
                    output_jump_position <= next_jump_position;
                end if;
            elsif(end_of_data = '1') then --Add padding
                valid <= '1';
                stream_out <= (others => '0');    
            end if;
        end if;
    end process;

end Behavioral;
