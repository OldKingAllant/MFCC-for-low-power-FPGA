----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 03.08.2025 09:42:08
-- Design Name: 
-- Module Name: pipeline_tb - Behavioral
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

entity pipeline_tb is
--  Port ( );
end pipeline_tb;

architecture Behavioral of pipeline_tb is
    --signal   clk_sampling : std_logic;
    signal   clk_output : std_logic;
    
    signal input_val_temp : std_logic_vector(15 downto 0);
    signal input_valid_temp : std_logic;
    signal input_value : std_logic_vector(31 downto 0);
    
    signal output_valid : std_logic;
    signal output_value : std_logic_vector(63 downto 0);
    
    constant SAMPLE_RATE : integer := 16000;
    constant OUT_RATE : integer := 1000000;
    constant INPUT_CLK_DIV : integer := integer(ceil(real(OUT_RATE)/real(SAMPLE_RATE))) - 1;
    
    signal input_enable_cnt : integer := 0;
    signal enable_gen : std_logic := '0';
    signal enable_mfcc : std_logic := '0';
    signal input_valid : std_logic;
begin
    process(clk_output)
    is begin
        if rising_edge(clk_output) then
            enable_mfcc <= '0';
            enable_gen <= '0';
            if(input_enable_cnt + 1 >= INPUT_CLK_DIV) then
                input_enable_cnt <= 0;
                enable_mfcc <= '1';
            else
                if(input_enable_cnt + 1 >= INPUT_CLK_DIV - 1) then
                    enable_gen <= '1';
                end if;
                input_enable_cnt <= input_enable_cnt + 1;
            end if;
        end if;
    end process;
    
    wave_gen : entity work.complex_signal_generator(Behavioral) 
    generic map(
        FFT_Size => 512,
        FUNC_TYPE => 2
    )
    port map(
        clk => clk_output,
        reset => '1',
        real_out => input_val_temp,
        tvalid => input_valid_temp,
        enable => enable_gen
    );
    
    
    input_valid <= '1' when enable_mfcc='1' and input_valid_temp='1' else '0';
    input_value <= std_logic_vector(resize(signed(input_val_temp), 32));
    
    mfcc_extract : entity work.pipeline
    port map(
        clk_output => clk_output,
        input_valid => input_valid,
        input_value => input_value,
        output_valid => output_valid,
        output_value => output_value
    );
    
    --process is
    --begin 
    --    clk_sampling <= '0';
    --    wait for 31500ns;
    --    clk_sampling <= '1';
    --    wait for 31500ns;
    --end process;
    
    process is 
    begin 
        clk_output <= '0';
        wait for 500ns;
        clk_output <= '1';
        wait for 500ns;
    end process;
end Behavioral;
