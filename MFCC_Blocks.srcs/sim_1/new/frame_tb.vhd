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
    
    signal    input_valid : std_logic;       
    signal    end_of_data : std_logic;  
    signal    input_value : signed(32 - 1 downto 0); 
    signal    output_valid : std_logic;
    signal    output_value : signed(32 - 1 downto 0);
    signal    stall : std_logic := '0';
    signal    request_stall : std_logic;
    
    signal input_val_temp : std_logic_vector(15 downto 0);
    signal input_valid_temp : std_logic;
    
    constant WIN_SIZE : integer := 512;
    constant STEP_SIZE : integer := 512 - 170;
begin
    frame_module : entity work.frame
    generic map(
        sample_size => 32,
        window_size => WIN_SIZE,
        step_size => STEP_SIZE
    )
    port map(
        clk_sampling => clk_sampling,
        clk_output => clk_output,
        input_valid => input_valid,
        end_of_data => end_of_data,
        output_valid => output_valid,
        stall => '0',
        request_stall => request_stall,
        input_value => input_value,
        output_value => output_value
    );
    
    wave_gen : entity work.complex_signal_generator(Behavioral) 
    generic map(
        FFT_Size => 512,
        FUNC_TYPE => 0
    )
    port map(
        clk => clk_sampling,
        reset => '1',
        real_out => input_val_temp,
        tvalid => input_valid
    );
    
    input_value <= resize(signed(input_val_temp), input_value'length);
    
    process is
    begin 
        clk_sampling <= '0';
        wait for 100ns;
        clk_sampling <= '1';
        wait for 100ns;
    end process;
    
    process is 
        variable input_cnt : integer := 0;
    begin 
        clk_output <= '0';
        wait for 25ns;
        
        clk_output <= '1';
        wait for 25ns;
    end process;
end Behavioral;
