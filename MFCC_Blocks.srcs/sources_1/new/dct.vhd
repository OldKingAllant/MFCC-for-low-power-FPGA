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
use IEEE.math_real.all;

entity dct is
  generic (
    sample_size : integer := 64;
    precision : integer := 8;
    numcoeffs : integer := 16;
    numcepstra : integer := 16;
    nmult : integer := 4
  );
  Port (
    clk : in std_logic;
    input_valid : in std_logic;
    input_coeff : in std_logic_vector(sample_size - 1 downto 0);
    output_valid : out std_logic;
    output_value : out std_logic_vector(sample_size - 1 downto 0);
    request_stall : out std_logic;
    stall : in std_logic
  );
end dct;

architecture Behavioral of dct is
    type DCT_ROW is array(0 to numcoeffs - 1) of std_logic_vector(sample_size - 1 downto 0);
    type DCT_TABLE is array(0 to numcepstra) of DCT_ROW;
    
    function CreateDctTable(unused: integer) return DCT_TABLE is
        variable curr_row : DCT_ROW;
        variable table : DCT_TABLE;
        variable temp_value : real;
        variable curr_index : integer;
        
        constant SQRT_2_N : real := sqrt(2.0 / real(numcoeffs));
    begin
        --row[i] = cos(PI * (i + 1 - 0.5) * i / N)
        for cepstra in table'range loop
            curr_row := (others => (others => '0'));
            curr_index := 0;
            for entry in curr_row'range loop
                temp_value := (SQRT_2_N * cos(MATH_PI * (real(cepstra) + 1.0 - 0.5) * real(curr_index) / real(numcoeffs))) * real(2**precision);
                if(temp_value >= 0.0) then
                    curr_row(entry) := std_logic_vector(to_signed(integer(floor(temp_value)), sample_size));
                else 
                    curr_row(entry) := std_logic_vector(to_signed(integer(ceil(temp_value)), sample_size));
                end if;
                curr_index := curr_index + 1;
                report integer'image(to_integer(signed(curr_row(entry)))) severity note;
            end loop;
            table(cepstra) := curr_row;
        end loop;
        
        return table;
    end function;
    
    constant DCT_LUT : DCT_TABLE := CreateDctTable(0);
    
    constant VALUE_SIZE : integer := sample_size;
    
    type COEFF_BUFF_TY is array(0 to numcoeffs * 2 - 1) of unsigned(sample_size - 1 downto 0);
    type OUT_BUFF_TY is array(0 to numcepstra - 1) of signed(sample_size - 1 downto 0);
    type MFCC_BUFF_TY is array(0 to numcepstra - 1) of signed(VALUE_SIZE - 1 downto 0);
    type TEMP_MFCC_TY is array(0 to nmult - 1) of signed(VALUE_SIZE - 1 downto 0);
    
    signal coeff_buffer : COEFF_BUFF_TY := (others => (others => '0'));
    signal mfcc_work_buffer : MFCC_BUFF_TY := (others => (others => '0'));
    signal curr_coeff_cnt : integer := 0; 
    signal curr_cepstra_base : integer := 0;
    signal read_pos : integer := 0;
    signal write_pos : integer := 0;
    
    signal output_buffer : OUT_BUFF_TY;
    signal output_cnt : integer := 0;
    signal output_pos : integer := 0;
begin
    process(clk) is
        variable mult_result : signed((VALUE_SIZE * 2) - 1 downto 0);
        variable next_write_pos : integer;
        variable has_sample : std_logic;
        variable diff : integer;
        variable processed_sample : unsigned(VALUE_SIZE - 1 downto 0);
        variable temp_mfcc : TEMP_MFCC_TY;
    begin
        mult_result := (others => '0');
        next_write_pos := 0;
        has_sample := '0';
        diff := 0;
        processed_sample := (others => '0');
        temp_mfcc := (others => (others => '0'));
        
        if rising_edge(clk) then
            has_sample := '0';
            output_valid <= '0';
            next_write_pos := write_pos + 1;
            diff := read_pos - write_pos;
            
             if(read_pos > write_pos and diff <= 4) then
                request_stall <= '1';
            else
                request_stall <= '0';
            end if;
            
            if(input_valid='1' and stall='0') then           --there is data on input
                if(not (next_write_pos = read_pos)) then      --check if there is no buffer overrun
                    coeff_buffer(write_pos) <= unsigned(input_coeff);
                end if;
                
                if(next_write_pos = read_pos) then
                    next_write_pos := write_pos; --keep previous pos
                end if;
            
                if(next_write_pos >= coeff_buffer'length) then --wrap around
                    write_pos <= 0;
                else
                    write_pos <= next_write_pos;
                end if;
                
                if(read_pos = write_pos) then --read process is idle
                    processed_sample := unsigned(input_coeff);
                    has_sample := '1';
                else 
                    processed_sample := coeff_buffer(read_pos);
                end if;
            else
                processed_sample := coeff_buffer(read_pos);
            end if;
            
            if(((not (read_pos = write_pos)) or has_sample = '1') and stall='0') then
                for cepstra in 0 to nmult - 1 loop
                    mult_result := signed(processed_sample) * signed(DCT_LUT(curr_cepstra_base + cepstra)(curr_coeff_cnt));
                    temp_mfcc(cepstra) := mfcc_work_buffer(curr_cepstra_base + cepstra) + mult_result(VALUE_SIZE - 1 downto 0);
                    mfcc_work_buffer(curr_cepstra_base + cepstra) <= temp_mfcc(cepstra);
                    --report integer'image(to_integer(signed(temp_mfcc(cepstra)))) severity note;
                end loop;
                
                if(curr_coeff_cnt + 1 >= numcoeffs) then
                    for mfcc_index in 0 to nmult - 1 loop
                        output_buffer(curr_cepstra_base + mfcc_index) <= shift_right(temp_mfcc(mfcc_index), precision);
                        --output_buffer(curr_cepstra_base + mfcc_index) <= shift_right(mfcc_work_buffer(curr_cepstra_base + mfcc_index), precision);
                    end loop;
                    output_cnt <= output_cnt + nmult;
                end if;
                
                if(curr_cepstra_base + nmult >= numcepstra) then --we applied all filters to the current sample
                    curr_cepstra_base <= 0; --reset filter position
                    if(read_pos + 1 >= coeff_buffer'length) then  --go to next sample
                        read_pos <= 0;
                    else 
                        read_pos <= read_pos + 1;
                    end if;
                    
                    if(curr_coeff_cnt + 1 >= numcoeffs) then     --last sample in frame
                        for curr_mfcc in mfcc_work_buffer'range loop       --reset coefficients
                            mfcc_work_buffer(curr_mfcc) <= (others => '0');
                        end loop;
                        curr_coeff_cnt <= 0;
                    else 
                        curr_coeff_cnt <= curr_coeff_cnt + 1; --else increment count
                    end if;
                else 
                    curr_cepstra_base <= curr_cepstra_base + nmult; --go to next chunk of filters
                end if;
            end if;
            
            if(output_cnt = numcepstra and stall='0') then
                output_valid <= '1';
                output_value <= std_logic_vector(output_buffer(output_pos));
                if(output_pos + 1 >= output_buffer'length) then
                    output_pos <= 0;
                    output_cnt <= 0;
                else
                    output_pos <= output_pos + 1;
                end if;
            end if;
        end if;
    end process;
end Behavioral;
