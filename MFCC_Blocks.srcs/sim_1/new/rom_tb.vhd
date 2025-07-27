----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 16.07.2025 18:03:27
-- Design Name: 
-- Module Name: rom_tb - Behavioral
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

entity rom_tb is
--  Port ( );
end rom_tb;

architecture Behavioral of rom_tb is
    signal clk : std_logic := '0';
    signal ren : std_logic := '0';
    signal addr : std_logic_vector(31 downto 0);
    signal val : std_logic_vector(31 downto 0);
    signal ready : std_logic;
    signal ready_sync : std_logic;
-- clk : in STD_LOGIC;                           -- 
--           r_en : in STD_LOGIC;                          -- read enable
--           addr : in STD_LOGIC_VECTOR (31 downto 0);     -- read address
  --         val_out : out STD_LOGIC_VECTOR (31 downto 0); -- output value
    --       ready : out STD_LOGIC;                        -- output is ready (async update)
      --     ready_sync : out STD_LOGIC                    --   
begin
    rom_instance : entity work.ROM(Behavioral)
    generic map(
        size_words => 64,
        file_name => "../../../../input_samples_rom.txt"
    )
    port map(
        clk => clk,
        r_en => ren,
        addr => addr,
        val_out => val,
        ready => ready,
        ready_sync => ready_sync
    );
    
    process is 
    begin 
        clk <= '0';
        wait for 100ns;
        clk <= '1';
        wait for 100ns;
    end process;
    
    ren <= '1';
    addr <= std_logic_vector(to_unsigned(16#10#, 32));

end Behavioral;
