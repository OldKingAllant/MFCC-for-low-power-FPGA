----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 20.07.2025 10:43:10
-- Design Name: 
-- Module Name: fft - Behavioral
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
library xil_defaultlib;

use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
entity fft is
    generic (
        sample_size : integer := 32
    );
    port (
        clk : in std_logic;
        input_valid : in std_logic;
        input_value : in signed(sample_size - 1 downto 0);
        request_stall : out std_logic;
        stall : in std_logic;
        output_valid : out std_logic;
        output_re : out std_logic_vector(sample_size - 1 downto 0);
        output_im : out std_logic_vector(sample_size - 1 downto 0);
        frame_end : out std_logic
    );
end fft;

architecture Behavioral of fft is
  COMPONENT xfft_0
  PORT (
    aclk : IN STD_LOGIC;
    aclken : IN STD_LOGIC;
    s_axis_config_tdata : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    s_axis_config_tvalid : IN STD_LOGIC;
    s_axis_config_tready : OUT STD_LOGIC;
    s_axis_data_tdata : IN STD_LOGIC_VECTOR(63 DOWNTO 0);
    s_axis_data_tvalid : IN STD_LOGIC;
    s_axis_data_tready : OUT STD_LOGIC;
    s_axis_data_tlast : IN STD_LOGIC;
    m_axis_data_tdata : OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
    m_axis_data_tvalid : OUT STD_LOGIC;
    m_axis_data_tready : IN STD_LOGIC;
    m_axis_data_tlast : OUT STD_LOGIC;
    event_frame_started : OUT STD_LOGIC;
    event_tlast_unexpected : OUT STD_LOGIC;
    event_tlast_missing : OUT STD_LOGIC;
    event_status_channel_halt : OUT STD_LOGIC;
    event_data_in_channel_halt : OUT STD_LOGIC;
    event_data_out_channel_halt : OUT STD_LOGIC 
  );
  END COMPONENT;
  
  type STATE is (CONFIG, NORMAL);
  signal curr_state : STATE := CONFIG;
  signal config_clk_count : integer := 0;
  signal curr_fft_cnt : integer := 0;
  --signal new_frame_asserted : std_logic := '0';
  
  --for fft
  signal config_data : std_logic_vector(15 downto 0) := "0000000000000001";
  signal config_valid : std_logic;
  signal config_ready : std_logic;
  
  signal data_valid : std_logic := '0';
  signal fft_in_ready : std_logic;
  signal fft_in_data : std_logic_vector(sample_size * 2 - 1 downto 0);
  signal fft_in_last : std_logic;
  
  signal fft_out_last : std_logic;
  signal fft_out_data : std_logic_vector(sample_size * 2 - 1 downto 0);
  
  signal new_frame : std_logic;
  signal unexpected_tlast : std_logic;
  signal missing_tlast : std_logic;
  signal in_channel_halt : std_logic;
  
  signal m_data_tready : std_logic;
  
  signal aclken : std_logic;
  
  signal error_occurred : std_logic := '0';
  
  constant CONSTANT_CONFIG : std_logic_vector(15 downto 0) := "0000000000000001";
  constant FFT_SIZE : integer := 512;
  
begin
    m_data_tready <= '0' when stall='1' or error_occurred='1' else '1';
    request_stall <= '1' when fft_in_ready='0' else '0';
    aclken <= '1' when stall='0' else '0';
    
  fft_block : xfft_0
  PORT MAP (
    aclk => clk,
    aclken => '1',
    s_axis_config_tdata => config_data,
    s_axis_config_tvalid => config_valid,
    s_axis_config_tready => config_ready,
    
    s_axis_data_tdata => fft_in_data,
    s_axis_data_tvalid => data_valid,
    s_axis_data_tready => fft_in_ready,
    s_axis_data_tlast => fft_in_last,
    
    m_axis_data_tdata => fft_out_data,
    m_axis_data_tvalid => output_valid,
    m_axis_data_tlast => fft_out_last,
    m_axis_data_tready => m_data_tready,
    
    event_frame_started => new_frame,
    event_tlast_unexpected => unexpected_tlast,
    event_tlast_missing => missing_tlast,
    event_data_in_channel_halt => in_channel_halt
  );
  
  process(clk) is 
    --variable temp_input : std_logic_vector(sample_size - 1 downto 0);
    variable next_count : integer;
  begin 
    --temp_input := (others => '0');
    next_count := 0;
    if rising_edge(clk) then
        assert unexpected_tlast = '0' report "Unexpected tlast event, count: " & integer'image(curr_fft_cnt);
        assert missing_tlast = '0' report "Missing tlast, count: " & integer'image(curr_fft_cnt);
        
        if(unexpected_tlast='1' or missing_tlast='1') then
            error_occurred <= '1';
        end if;
        
        config_data <= (others => '0');
        
        if(curr_state = CONFIG) then
            config_valid <= '1';
            config_data <= CONSTANT_CONFIG;
            if(config_ready = '1') then
                config_clk_count <= config_clk_count + 1;
                if(config_clk_count = 1) then
                    config_valid <= '0';
                    curr_state <= NORMAL;
                end if;
            end if;
        end if;
        
        fft_in_last <= '0';
        data_valid <= '0';
        
        if(stall='0') then
            if(curr_state = NORMAL  and input_valid='1' and fft_in_ready='1') then
                    data_valid <= '1';
                    --temp_input := std_logic_vector(input_value);
                    fft_in_data <= std_logic_vector(resize(unsigned(input_value), sample_size * 2));
                   -- fft_in_data(sample_size * 2 - 1 downto sample_size) <= (others => '0');
                    
                    next_count := curr_fft_cnt + 1;
                    if(next_count >= FFT_SIZE) then
                        next_count := 0;
                        fft_in_last <= '1';
                    end if;
                    curr_fft_cnt <= next_count;
            end if;
        end if;
    end if;
  end process;
  
  output_re <= fft_out_data(sample_size - 1 downto 0);
  output_im <= fft_out_data(sample_size * 2 - 1 downto sample_size);
  
  frame_end <= fft_out_last;

end Behavioral;
