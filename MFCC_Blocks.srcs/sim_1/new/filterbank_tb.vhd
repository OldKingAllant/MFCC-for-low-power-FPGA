----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 24.07.2025 09:02:28
-- Design Name: 
-- Module Name: filterbank_tb - Behavioral
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

entity filterbank_tb is
--  Port ( );
end filterbank_tb;

architecture Behavioral of filterbank_tb is
    signal clk : std_logic;
    signal sample_valid : std_logic;
    signal sample : std_logic_vector(63 downto 0);
    signal end_of_frame : std_logic;
    signal accepts_samples : std_logic;
    signal coefficients : std_logic_vector((64 * 4) - 1 downto 0); --packed nmult coefficients
    signal valid : std_logic;
    
    signal coeff_1 : std_logic_vector(63 downto 0);
    signal coeff_2 : std_logic_vector(63 downto 0);
    signal coeff_3 : std_logic_vector(63 downto 0);
    signal coeff_4 : std_logic_vector(63 downto 0);
begin
    fbank : entity work.filterbanks(Behavioral) 
    generic map(
        sample_size => 32,
        low_freq => 50,
        high_freq => 6500,
        numfilters => 16,
        nfft => 512,
        precision => 8,
        sample_freq => 16000,
        nmult => 4
    )
    port map(
        clk => clk,
        sample_valid => sample_valid,
        sample => sample,
        end_of_frame => end_of_frame,
        accepts_samples => accepts_samples,
        coefficients => coefficients,
        valid => valid,
        receiver_ready => '1'
    );
    
    process
    is 
        variable count : integer := 0;
    begin
        end_of_frame <= '0';
        sample_valid <= '1';
        sample <= std_logic_vector(TO_UNSIGNED(256, 64));
        if(accepts_samples='1') then
            count := count + 1;
            if(count >= 257) then
                count := 0;
                end_of_frame <= '1';
            end if;
        end if;
        clk <= '0';
        wait for 100ns;
        clk <= '1';
        wait for 100ns;
    end process;
    
    coeff_1 <= coefficients(63 downto 0);
    coeff_2 <= coefficients(127 downto 64);
    coeff_3 <= coefficients(191 downto 128);
    coeff_4 <= coefficients(255 downto 192);

end Behavioral;
