----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 16.07.2025 17:28:12
-- Design Name: 
-- Module Name: ROM - Behavioral
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
use std.textio.all;

entity ROM is
    generic (
        size_words : in integer; -- each word is 4 bytes
        file_name : in string
    );
    Port ( 
           clk : in STD_LOGIC;                           -- 
           r_en : in STD_LOGIC;                          -- read enable
           addr : in STD_LOGIC_VECTOR (31 downto 0);     -- read address
           val_out : out STD_LOGIC_VECTOR (31 downto 0); -- output value
           ready : out STD_LOGIC;                        -- output is ready (async update)
           ready_sync : out STD_LOGIC                    --   
           );
end ROM;

architecture Behavioral of ROM is
    type ROM_TYPE is array(0 to size_words - 1) of std_logic_vector(31 downto 0);
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
    
    signal DATA : ROM_TYPE := CreateRom(file_name);
begin
    -- sequential
    process(clk) is
    begin
        if rising_edge(clk) then 
            ready_sync <= r_en;
            if(r_en = '0') then
                val_out <= (others => 'U');
            elsif(unsigned(addr) >= size_words) then
                report "Read address out of bounds, max: " & integer'image(size_words) & ", wanted: " & integer'image(to_integer(unsigned(addr)))
                severity error;
                val_out <= (others => 'U');
            else 
                val_out <= DATA(to_integer(unsigned(addr)));
            end if;
        end if;
    end process;
    
    
    -- combinatorial
    ready <= r_en;
end Behavioral;


