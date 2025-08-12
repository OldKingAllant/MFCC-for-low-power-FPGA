----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 03.08.2025 09:23:47
-- Design Name: 
-- Module Name: pipeline - Behavioral
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

entity pipeline is
  port (
     clk_sampling : in std_logic;
     clk_output   : in std_logic;
     input_valid  : in std_logic;
     input_value  : in std_logic_vector(31 downto 0);
     output_valid : out std_logic;
     output_value : out std_logic_vector(63 downto 0)
  );
end pipeline;

architecture Behavioral of pipeline is
    signal    end_of_data : std_logic; 
    signal    stall : std_logic := '0';
    signal    request_stall : std_logic;
    signal    effective_input_value : signed(31 downto 0);
    
    --signal input_val_temp : std_logic_vector(15 downto 0);
    --signal input_valid_temp : std_logic;
    
    constant WIN_SIZE : integer := 512;
    constant STEP_SIZE : integer := 512 - 170;
    -----------------------------
    
    signal input_valid_window : std_logic;
    signal input_value_window : signed(32 - 1 downto 0);
    signal window_stall_request : std_logic;
    
    -----------------------------
    
    signal input_valid_fft : std_logic;
    signal input_value_fft : signed(32 - 1 downto 0);
    signal fft_stall_req : std_logic;
    signal frame_end_fft : std_logic;
    
    -----------------------------
    
    signal input_valid_spectrum : std_logic;
    signal input_re : std_logic_vector(31 downto 0);
    signal input_im : std_logic_vector(31 downto 0);
    signal spectrum_stall_req : std_logic;
    
    ----------------------------
    
    signal input_valid_filt : std_logic;
    signal input_value_filt : std_logic_vector(63 downto 0);
    signal filt_accepts_samples : std_logic;
    signal bank_stall_req : std_logic;
    
    -----------------------------
    
    signal input_valid_log : std_logic;
    signal input_coeffs_log : std_logic_vector((64 * 2) - 1 downto 0);
    signal log_stall_req : std_logic;
    
    --type COEFF_ARR is array(0 to 7) of std_logic_vector(63 downto 0);
    --signal coeff_array : COEFF_ARR;
    
    -----------------------------
    
    signal input_valid_dct : std_logic;
    signal input_value_dct : std_logic_vector(63 downto 0);
    signal dct_stall_req : std_logic;
    
    -----------------------------
    
    signal input_valid_lift : std_logic;
    signal input_value_lift : std_logic_vector(63 downto 0);
    
    --signal final_output_valid : std_logic;
    --signal final_output_value : std_logic_vector(63 downto 0);
    
    signal stall_frame : std_logic;
    signal stall_window : std_logic;
    signal stall_fft : std_logic;
    signal stall_spectrum : std_logic;
    signal stall_bank : std_logic;
    signal stall_log : std_logic;
    signal stall_dct : std_logic;
begin
    bank_stall_req <= '1' when filt_accepts_samples='0' else '0';

    stall_frame <= '1' when window_stall_request='1' or fft_stall_req='1' or spectrum_stall_req='1' or bank_stall_req='1' or log_stall_req='1' or dct_stall_req='1' else '0';
    stall_window <= '1' when fft_stall_req='1' or spectrum_stall_req='1' or bank_stall_req='1'  or log_stall_req='1' or dct_stall_req='1' else '0';
    stall_fft <= '1' when spectrum_stall_req='1' or bank_stall_req='1'  or log_stall_req='1' or dct_stall_req='1' else '0';
    stall_spectrum <= '1' when bank_stall_req='1'  or log_stall_req='1' or dct_stall_req='1' else '0';
    stall_bank <= '1' when log_stall_req='1' or dct_stall_req='1' else '0';
    stall_log <= '1' when dct_stall_req='1' else '0';
    stall_dct <= '0';
    
    effective_input_value <= signed(input_value);
    
    frame_module : entity work.frame(Behavioral) 
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
        output_valid => input_valid_window,
        stall => stall_frame,
        request_stall => request_stall,
        input_value => effective_input_value,
        output_value => input_value_window
    );
    
    window : entity work.window(Behavioral) 
    generic map(
        sample_size => 32,
        window_size => 512,
        precision => 8
    )
    port map(
        clk => clk_output,
        input_valid => input_valid_window,
        input_value => input_value_window,
        stall_request => window_stall_request,
        stall => stall_window,
        output_valid => input_valid_fft,
        output_value => input_value_fft
    );
    
    fft : entity work.fft(Behavioral) 
    generic map(
        sample_size => 32
    )
    port map(
        clk => clk_output,
        input_valid => input_valid_fft,
        input_value => input_value_fft,
        request_stall => fft_stall_req,
        stall => stall_fft,
        frame_end => frame_end_fft,
        output_valid => input_valid_spectrum,
        output_re => input_re,
        output_im => input_im
    );
    
    pow_spectrum : entity work.power_spectrum(Behavioral) 
    generic map(
        sample_size => 32,
        fft_size => 512,
        precision => 8
    )
    port map(
        clk => clk_output,
        input_valid => input_valid_spectrum,
        re_in => input_re,
        im_in => input_im,
        stall => stall_spectrum,
        request_stall => spectrum_stall_req,
        output_valid => input_valid_filt,
        output_value => input_value_filt
    );
    
    filterbank : entity work.filterbanks(Behavioral)
    generic map(
        sample_size => 32,
        low_freq => 50,
        high_freq => 6500,
        numfilters => 16,
        nfft => 512,
        precision => 8,
        sample_freq => 16000,
        nmult => 2
    )
    port map(
        clk => clk_output,
        input_valid => input_valid_filt,
        input_value => input_value_filt,
        end_of_frame => '0',
        stall => stall_bank,
        accepts_samples => filt_accepts_samples,
        output_valid => input_valid_log,
        coefficients => input_coeffs_log
    );
    
    log_compute : entity work.log_compute(Behavioral) 
    generic map(
        sample_size => 64,
        precision => 8,
        num_coeffs => 2,
        total_coeffs => 16,
        buf_size => 20
    )
    port map(
        clk => clk_output,
        input_valid => input_valid_log,
        input_coeffs => input_coeffs_log,
        stall => stall_log,
        request_stall => log_stall_req,
        output_valid => input_valid_dct,
        output_value => input_value_dct
    );
    
    dct : entity work.dct(Behavioral)
    generic map(
        sample_size => 64,
        precision => 8,
        numcoeffs => 16,
        numcepstra => 16,
        nmult => 1
    )
    port map(
        clk => clk_output,
        input_valid => input_valid_dct,
        input_coeff => input_value_dct,
        stall => stall_dct,
        request_stall => dct_stall_req,
        output_valid => input_valid_lift,
        output_value => input_value_lift
    );
    
    lifter : entity work.sin_lifter(Behavioral) 
    generic map(
        sample_size => 64,
        precision => 8,
        window_size => 16,
        const => 22
    )
    port map(
        clk => clk_output,
        input_valid => input_valid_lift,
        input_value => input_value_lift,
        stall => '0',
        output_value => output_value,
        output_valid => output_valid
    );

end Behavioral;
