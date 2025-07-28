----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 28.07.2025 14:35:38
-- Design Name: 
-- Module Name: dct - Behavioral
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

entity dct is
  generic (
    sample_size : integer;
    precision : integer;
    numcoeffs : integer;
    numcepstra : integer
  );
  Port (
    clk : in std_logic;
    input_valid : in std_logic;
    input_coeff : in std_logic_vector(sample_size - 1 downto 0);
    output_valid : out std_logic;
    output_valud : out std_logic_vector(sample_size - 1 downto 0);
    request_stall : out std_logic;
    stall : in std_logic
  );
end dct;

architecture Behavioral of dct is

begin


end Behavioral;
