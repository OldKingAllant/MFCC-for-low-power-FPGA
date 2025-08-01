----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 20.07.2025 12:03:03
-- Design Name: 
-- Module Name: fft_tb - Behavioral
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

entity fft_tb is
end fft_tb;

architecture Behavioral of fft_tb is
    signal    clk : std_logic;
    
    signal    input_valid : std_logic;
    signal    input_value : signed(31 downto 0);
    signal    request_stall : std_logic;
    signal    stall : std_logic;
    signal    output_valid : std_logic;
    signal    output_re : std_logic_vector(31 downto 0);
    signal    output_im : std_logic_vector(31 downto 0);
    signal    frame_end : std_logic;
    
    signal temp_val : std_logic_vector(15 downto 0);
begin
    fft_block : entity work.fft(Behavioral) port map(
        clk => clk,
        input_value => input_value,
        input_valid => input_valid,
        output_valid => output_valid,
        output_re => output_re,
        output_im => output_im,
        frame_end => frame_end,
        stall => '0',
        request_stall => request_stall
    );
    
    wave_gen : entity work.complex_signal_generator(Behavioral) 
    generic map(
        FFT_Size => 512,
        FUNC_TYPE => 1
    )
    port map(
        clk => clk,
        reset => '1',
        real_out => temp_val,
        tvalid => input_valid
    );
    
    input_value <= resize(signed(temp_val), 32);
    
    --process 
    --is 
    --begin 
    --    input_val(0) <= '0';
    --    wait for 50us;
    --    input_val(0) <= '1';
    --    wait for 50us;
    --end process;
    
    process 
    is 
    begin
        clk <= '0';
        wait for 100ns;
        clk <= '1';
        wait for 100ns;
    end process;

end Behavioral;
