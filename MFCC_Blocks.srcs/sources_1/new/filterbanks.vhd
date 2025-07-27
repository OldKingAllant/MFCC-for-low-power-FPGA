----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 23.07.2025 10:00:21
-- Design Name: 
-- Module Name: filterbanks - Behavioral
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

entity filterbanks is
    generic (
        sample_size : integer;
        low_freq : integer;
        high_freq : integer;
        numfilters : integer;
        nfft : integer;
        precision : integer;
        sample_freq : integer;
        nmult : integer --number of multipliers used for convolution,
                        --the greater, the faster the design but also
                        --the greater the number of resources
    );
    port (
        clk : in std_logic;
        sample_valid : in std_logic;
        sample : in std_logic_vector((sample_size * 2) - 1 downto 0);
        end_of_frame : in std_logic;
        accepts_samples : out std_logic;
        coefficients : out std_logic_vector(((sample_size * 2) * nmult) - 1 downto 0); --packed nmult coefficients
        valid : out std_logic;
        receiver_ready : in std_logic
    );
end filterbanks;

--Applies mel-filterbank to compute mel coefficients
--It can multiply and accumulate on multiple filters
--at the same time, while also streaming the output
--coefficients. Internally uses ringbuffer to not
--lose frames and tells when the buffer is full

architecture Behavioral of filterbanks is
    function HzToMel(f: real) return real is 
    begin
        return 2595 * log10(1.0+f/700.0); 
    end function;
    
    function MelToHz(mel: real) return real is 
        variable pow_res : real;
    begin
        --mel / 2595
        --(10^(mel / 2595) - 1) * 700
        pow_res := 10.0 ** (mel / 2595);
        return 700.0 * (pow_res - 1.0);
    end function;
    
    constant NFFT_BINS : integer := (nfft / 2) + 1;
    constant LOW_MEL_FREQ : real := HzToMel(real(low_freq));
    constant HIGH_MEL_FREQ : real := HzToMel(real(high_freq));
    
    type FILTER is array(0 to NFFT_BINS - 1) of integer;
    type FILTERBANK is array(0 to numfilters - 1) of FILTER;
    
    function ComputeFilterbank(unused: integer) return FILTERBANK is
        type CENTRE_FREQS is array(0 to (numfilters + 2) - 1) of real;
        type FFT_BIN_FREQS is array(0 to NFFT_BINS - 1) of real;
        
        variable centre_freq : CENTRE_FREQS;
        variable fft_bin_freq : FFT_BIN_FREQS;
        
        variable curr_filter : FILTER;
        variable bank : FILTERBANK;
        
        variable weight : real;
    begin
        -- for (int i=0; i<numFilters+2; i++)
        -- mel2hz(lowFreqMel + (highFreqMel-lowFreqMel)/(numFilters+1)*i);
        for i in centre_freq'range loop
            centre_freq(i) := MelToHz(LOW_MEL_FREQ + (HIGH_MEL_FREQ - LOW_MEL_FREQ)/(real(numfilters) + 1.0)*i);
            report "Centre: " & real'image(centre_freq(i)) severity note;
        end loop;
        
        --(fs/2.0/(numFFTBins-1)*i);
        for i in fft_bin_freq'range loop
            fft_bin_freq(i) := real(sample_freq)/2.0/(NFFT_BINS - 1)*i;
        end loop;
        
        for filt in bank'range loop
            for bin in curr_filter'range loop
                if(fft_bin_freq(bin) < centre_freq(filt)) then
                    weight := 0.0;
                elsif(fft_bin_freq(bin) <= centre_freq(filt+1)) then
                    weight := (fft_bin_freq(bin) - centre_freq(filt)) / (centre_freq(filt + 1)  - centre_freq(filt));
                elsif(fft_bin_freq(bin) <= centre_freq(filt+2)) then
                    weight := (centre_freq(filt+2) - fft_bin_freq(bin)) / (centre_freq(filt + 2) - centre_freq(filt + 1));
                else 
                    weight := 0.0;
                end if;
                
                curr_filter(bin) := integer(weight*(2**precision));
                --if (fftBinFreq[bin] < filterCentreFreq[filt-1])
                --    weight = 0;
                --else if (fftBinFreq[bin] <= filterCentreFreq[filt])
                --    weight = (fftBinFreq[bin] - filterCentreFreq[filt-1]) / (filterCentreFreq[filt] - filterCentreFreq[filt-1]);
                --else if (fftBinFreq[bin] <= filterCentreFreq[filt+1])
                --    weight = (filterCentreFreq[filt+1] - fftBinFreq[bin]) / (filterCentreFreq[filt+1] - filterCentreFreq[filt]);
                --else
                --    weight = 0;
            end loop;
            bank(filt) := curr_filter;
        end loop;
        
        return bank;
    end function; 
    
    constant THE_BANK : FILTERBANK := ComputeFilterbank(0);
    constant VALUE_SIZE : integer := sample_size * 2;
    constant ONE : integer := 2**precision;
    
    type COEFF_TYPE is array(0 to numfilters - 1) of unsigned(VALUE_SIZE - 1 downto 0);
    type SPECTRAL_SAMPLES is array(0 to NFFT_BINS - 1) of unsigned(VALUE_SIZE - 1 downto 0);
    
    signal coeffs : COEFF_TYPE := (others => (others => '0'));       --coefficients for each filter
    signal samples : SPECTRAL_SAMPLES;--ringbuffer of power spectral data
    signal curr_sample_cnt : integer := 0; --number of processed samples for current frame
    signal curr_filter_base : integer := 0;--current filter that is to be applied to the current sample
    signal read_pos : integer := 0;  --read position in ringbuffer
    signal write_pos : integer := 0;
    
    --signal accepts_samples_temp : std_logic := '0';
begin
    assert (numfilters mod nmult) = 0 report "Number of filters must be perfectly divisible by multipliers";
    
    process(clk) is 
        variable mult_result : unsigned((VALUE_SIZE * 2) - 1 downto 0);
        variable next_write_pos : integer;
        variable safety_buffer_pos : integer;
        variable packed_coeff_position : integer; 
        variable processed_sample : unsigned(VALUE_SIZE - 1 downto 0);
        variable has_sample : std_logic;
        variable diff : integer;
    begin
        if rising_edge(clk) then
            has_sample := '0';
            valid <= '0';
            next_write_pos := write_pos + 1;
            safety_buffer_pos := write_pos + 2;
            diff := read_pos - write_pos;
            
            if((read_pos > write_pos and diff <= 4) or receiver_ready='0') then
                accepts_samples <= '0';
            else
                accepts_samples <= '1';
            end if;
            
            if(sample_valid='1') then                         --there is data on input
                if(not (next_write_pos = read_pos)) then      --check if there is no buffer overrun
                    samples(write_pos) <= unsigned(sample);
                end if;
                
                if(next_write_pos = read_pos) then
                    next_write_pos := write_pos; --keep previous pos
                end if;
            
                if(next_write_pos >= samples'length) then --wrap around
                    write_pos <= 0;
                else
                    write_pos <= next_write_pos;
                end if;
                
                if(read_pos = write_pos) then --read process is idle
                    processed_sample := unsigned(sample);
                    has_sample := '1';
                else 
                    processed_sample := samples(read_pos);
                end if;
            else
                processed_sample := samples(read_pos);
            end if;
            
            
            if(((not (read_pos = write_pos)) or has_sample = '1') and receiver_ready='1') then
                --multiply and accumulate for filter
                --between curr_filter_base and 
                --curr_filter_base + nmult
                for filter in 0 to nmult - 1 loop
                    mult_result := processed_sample * THE_BANK(curr_filter_base + filter)(curr_sample_cnt);
                    coeffs(curr_filter_base + filter) <= coeffs(curr_filter_base + filter) + mult_result(VALUE_SIZE - 1 downto 0);
                end loop;
                
                if(curr_sample_cnt + 1 >= NFFT_BINS) then
                    --for the filters between 
                    --curr_filter_base and curr_filter_base + nmult
                    --we have finished accumulating contributions, since
                    --this is the last sample in the frame
                    for coeff_index in 0 to nmult - 1 loop 
                        assert curr_filter_base + coeff_index < numfilters report "Something's wrong";
                        packed_coeff_position := coeff_index * VALUE_SIZE;
                        --check if coefficient for filter is at least 'one'
                        --apply mel-flooring if not
                        if(coeffs(curr_filter_base + coeff_index) < ONE) then
                            coefficients(packed_coeff_position + VALUE_SIZE - 1 downto packed_coeff_position) <= std_logic_vector(to_unsigned(ONE, VALUE_SIZE));
                        else
                            coefficients(packed_coeff_position + VALUE_SIZE - 1 downto packed_coeff_position) <= std_logic_vector(coeffs(curr_filter_base + coeff_index));
                        end if;
                        valid <= '1';
                    end loop;
                end if;
            
                if(curr_filter_base + nmult >= numfilters) then --we applied all filters to the current sample
                    curr_filter_base <= 0; --reset filter position
                    if(read_pos + 1 >= samples'length) then  --go to next sample
                        read_pos <= 0;
                    else 
                        read_pos <= read_pos + 1;
                    end if;
                    
                    if(curr_sample_cnt + 1 >= NFFT_BINS) then     --last sample in frame
                        for curr_coeff in coeffs'range loop       --reset coefficients
                            coeffs(curr_coeff) <= (others => '0');
                        end loop;
                        curr_sample_cnt <= 0;
                    else 
                        curr_sample_cnt <= curr_sample_cnt + 1; --else increment count
                    end if;
                else 
                    curr_filter_base <= curr_filter_base + nmult; --go to next chunk of filters
                end if;
            end if;
        end if;
    end process;

end Behavioral;
