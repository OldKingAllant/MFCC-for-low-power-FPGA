----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 27.07.2025 13:32:16
-- Design Name: 
-- Module Name: log_compute - Behavioral
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

--Computes log10(x) for fixed point values
--It does not use newton iterations to
--improve accuracy (which would also be not that
--easy to do given that we are trying to use less
--power)
--How the problem is approached (high-level):
--log10(x) = log2(x) / log2(10)
--Given that log2(10) is constant, we just 
--precompute it and store it as real.
--The division can be seen as multiplication
--by the reciprocal: we precompute 1/log2(10) 
--and store it up to a desired precision

--For log2(x)
-- 1. The integer part is easy to compute, it is equal to
--    the index of the highest bit set to one
-- 2. ...

--Error varies between 1-2% with 8 bits of precision;
--it could be much lower by adding a few bits
--to the fractional part

entity log_compute is
  generic (
    sample_size : integer := 64;
    precision : integer := 8;
    num_coeffs: integer := 4;   --number of input coefficients in a single clock cycle
    total_coeffs: integer := 16; --total coefficients
    buf_size: integer := 20
  );
  port (
    clk : in std_logic;
    input_valid : in std_logic;
    input_coeffs : in std_logic_vector((sample_size * num_coeffs) - 1 downto 0);
    output_valid : out std_logic;
    output_value : out std_logic_vector(sample_size - 1 downto 0);
    request_stall : out std_logic;
    stall : in std_logic
  );
end log_compute;

architecture Behavioral of log_compute is
    constant ONE_OVER_LOG2_OF_10 : real := 0.30103; --1/log2(10)
    
    --Used to convert a real value to fixed point notation
    --up to the configured precision
    function ComputeFixedPointConstant(value: real) return std_logic_vector  is
        variable fract_part : std_logic_vector(0 to precision - 1);
        variable full_constant : std_logic_vector(sample_size - 1 downto 0);
        variable subtract_result : real;
        variable curr_value : real;
    begin
        fract_part := (others => '0');
        full_constant := (others => '0');
        curr_value := value; --Iterative value
        
        for curr_precision_index in 0 to precision - 1 loop --for each decimal position
            subtract_result := curr_value - (2.0**(-(curr_precision_index+1))); --subtract decimal part equivalent to position
            if(subtract_result >= 0.0) then --result is > 0, the current fraction is part of the value
                fract_part(curr_precision_index) := '1';
                curr_value := subtract_result;
            else
                fract_part(curr_precision_index) := '0'; --result would underflow, fraction is not inside value
            end if;
        end loop;
        
        full_constant(precision - 1 downto 0) := fract_part;
        return full_constant;
    end function; 
    
    constant ONE_OVER_LOG2_OF_10_FIXED : std_logic_vector(sample_size - 1 downto 0) := ComputeFixedPointConstant(ONE_OVER_LOG2_OF_10);
    
    --Computing the fractional part of the result is more difficult:
    --we create a lookup table, each entry i contains the result of 
    --log2(1 + i/(2**precision)) (scaled by 2**precision so we have values > 1.0).
    --After computing the integer part, we take the previous bits up to
    --the precision and use that value as an index in the lut.
    --After shifting the integer part by 'precision', we add
    --the integer and fractional parts together to have
    --log2(x)
    
    constant LUT_SIZE : integer := 2**precision;
    type LOG_LUT is array(0 to LUT_SIZE) of std_logic_vector(sample_size - 1 downto 0);
    
    function ComputeLut(unused: integer) return LOG_LUT is
        variable lut : LOG_LUT;
        variable lut_entry : integer;
        variable curr_value : integer;
    begin
        curr_value := 0;
        for curr_fract in lut'range loop
            lut_entry := integer(log2(1.0+(real(curr_value)/real(LUT_SIZE))) * real(LUT_SIZE));
            lut(curr_fract) := std_logic_vector(to_unsigned(lut_entry, sample_size));
            curr_value := curr_value + 1;
        end loop;
        return lut;
    end function;
    
    constant LUT : LOG_LUT := ComputeLut(0);
    
    type COEFF_BUF_TYPE is array(0 to buf_size - 1) of std_logic_vector(sample_size - 1 downto 0);
    signal coeff_buffer : COEFF_BUF_TYPE := (others => (others => '0'));
    signal coeff_count : integer := 0;
    
    type STATE_TY is (FILLING, COMPUTING);
    signal state : STATE_TY := FILLING;
begin
    --request_stall <= '0';
    
    process(clk) is
        variable msb_position : integer; --position of msb bit set to 1
        variable lut_index : integer;    
        variable lut_entry : unsigned(sample_size - 1 downto 0);
        variable log2_result : unsigned(sample_size - 1 downto 0);        --log2(x)
        variable log10_result : unsigned((sample_size * 2) - 1 downto 0); --log10(x), double precision bits due to mult
        variable curr_value : std_logic_vector(sample_size - 1 downto 0);
        variable curr_coeff_count : integer;
    begin
        msb_position := 0;
        lut_index := 0;
        lut_entry := (others => '0');
        log2_result := (others => '0');
        --log10_result := (others => '0');
        curr_value := (others => '0');
        curr_coeff_count := 0;
        
        if rising_edge(clk) then
            output_valid <= '0';
            
            if(coeff_count=buf_size) then
                request_stall <= '1';
            else
                request_stall <= '0';    
            end if;
            
            curr_coeff_count := coeff_count;
            
            assert state=FILLING or (input_valid='0' and state=COMPUTING) report "Input present during computation!";
            
            if(stall='0' and input_valid='1' and state=FILLING) then
                for i in 0 to num_coeffs - 1 loop
                    coeff_buffer(curr_coeff_count + i) <= input_coeffs(((i + 1)*sample_size)-1 downto (i*sample_size));
                end loop;
                curr_coeff_count := curr_coeff_count + num_coeffs;
                if(curr_coeff_count=buf_size) then
                    request_stall <= '1';
                end if;
                if(curr_coeff_count=total_coeffs) then
                    state <= COMPUTING;
                end if;
            end if;
            
            if(stall='0' and state=COMPUTING) then
                curr_value := coeff_buffer(0);
                --First block, compute msb
                msb_position := precision;
                for pos in precision to sample_size - 1 loop --simple priority encoder (for 64 bits
                    if(curr_value(pos) = '1') then          --the depth of the comb logic would be insane)
                        msb_position := pos;
                    end if;
                end loop;
                msb_position := msb_position;
                
                --'precision' bits before msb are used as lut index
                lut_index := to_integer(unsigned(curr_value((msb_position - 1) downto (msb_position - precision))));
                --retrieve fract part
                lut_entry := unsigned(LUT(lut_index));
                
                --multiply the integer part by 2**precision,
                --to that it is > 1 in fixed point 
                log2_result := shift_left(to_unsigned(msb_position - precision, sample_size), precision);
                log2_result := log2_result + lut_entry; --sum integer and fractional part to obtain full result
                
                --finally compute log10(x) = log2(x) * 1/log2(10),
                --drop 'precision' bits that were doubled by the multiplication
                log10_result := shift_right(log2_result * unsigned(ONE_OVER_LOG2_OF_10_FIXED), precision);
                output_valid <= '1';
                output_value <= std_logic_vector(log10_result(sample_size - 1 downto 0));
                
                coeff_buffer(0 to buf_size - 2) <= coeff_buffer(1 to buf_size - 1);
                curr_coeff_count := curr_coeff_count - 1;
                
                if(curr_coeff_count=0) then
                    state <= FILLING;
                    curr_coeff_count := 0;
                end if;
            end if;
            coeff_count <= curr_coeff_count;
        end if;
    end process;
end Behavioral;
