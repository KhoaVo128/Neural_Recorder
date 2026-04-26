----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Grace Huang, Thomas Vo
-- 
-- Create Date: 02/24/2026 08:54:44 PM
-- Design Name: 
-- Module Name: spi_master_controller - Behavioral
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity spi_master_controller is
	generic (
    CLK_FREQ_HZ  : natural := 100_000_000; -- Basys 3 clock
    SPI_CLK_HZ   : natural := 1_000_000;  -- RHS2116 max SCLK
    WORD_LENGTH  : natural := 32;
    NUM_CMDS    : integer := 16;


    FULL_INIT    : boolean := false;       
    STOP_AFTER_SAMPLES : natural := 0      
  	);
	Port (
		clk           : in  std_logic;
		reset         : in  std_logic;
		-- handshake with spi_vhdl
        ready_out  : in  std_logic;
        command_out_v : out  std_logic;
        data_in_v  : in std_logic;
        init_done : out std_logic;
        command_in  : out std_logic_vector(WORD_LENGTH-1 downto 0);
        data_out : in std_logic_vector(WORD_LENGTH-1 downto 0);
        --PACKET & PACKET ASSEMBLED
        data_packet_spi	: out std_logic_vector(23 downto 0);
        --HANDSHKING WITH ASYNC FIFO
        packet_ready	: out std_logic;
		async_fifo_wr_reset_busy : in std_logic;
		-- async fifo full
		fifo_full : in std_logic 

	);
end spi_master_controller;

architecture Behavioral of spi_master_controller is
------------------------------------------------------------------------------
-- RHS2116 command helpers (32-bit)
------------------------------------------------------------------------------
	function rhs_cmd_convert(
		c      : unsigned(5 downto 0);
		u_flag : std_logic;
		m_flag : std_logic;
		d_flag : std_logic;
		h_flag : std_logic ) return std_logic_vector is variable w : std_logic_vector(31 downto 0);
	begin
		w := (others => '0');
		w(31)           := '0';
		w(30)           := '0';
		w(29)           := u_flag;
		w(28)           := m_flag;
		w(27)           := d_flag;
		w(26)           := h_flag;
		w(21 downto 16) := std_logic_vector(c);
		return w;
	end function;
	
	function rhs_cmd_clear 
		return std_logic_vector is variable w : std_logic_vector(31 downto 0);
    begin
    	w := (others => '0');
    	w(31 downto 24) := "01101010"; -- 0x6A
    	return w;
	end function;
	
	function rhs_cmd_write(
    	r      : unsigned(7 downto 0);
    	d      : unsigned(15 downto 0);
    	u_flag : std_logic;
    	m_flag : std_logic
  	) return std_logic_vector is variable w : std_logic_vector(31 downto 0);
  	begin
    	w := (others => '0');
    	w(31)           := '1';
    	w(30)       	:= '0';
    	w(29)           := u_flag;
    	w(28)           := m_flag;
    	w(27 downto 24) := "0000";
    	w(23 downto 16) := std_logic_vector(r);
    	w(15 downto 0)  := std_logic_vector(d);             
    	return w;
	end function;
  
	function rhs_cmd_read(
  		r      : unsigned(7 downto 0);
  		u_flag : std_logic;
    	m_flag : std_logic
  	) return std_logic_vector is variable w : std_logic_vector(31 downto 0);
  	begin
		w := (others => '0');
		w(31)           := '1';
		w(30)           := '1';
		w(29)           := u_flag;
		w(28)           := m_flag;
		w(27 downto 24) := "0000";
		w(23 downto 16) := std_logic_vector(r);
		return w;
	end function;
	

  	type rom_t is array (natural range <>) of std_logic_vector(31 downto 0);

    ------------------------------------------------------------------------------
	-- INIT ROM(s)
  	------------------------------------------------------------------------------
	--Full example init from datasheet table (includes stim-related writes)
	
    constant INIT_ROM_FULL : rom_t := (
		rhs_cmd_read(to_unsigned(255,8), '0', '0'),
	
		rhs_cmd_write(to_unsigned(32,8), to_unsigned(16#0000#,16), '0', '0'),
		rhs_cmd_write(to_unsigned(33,8), to_unsigned(16#0000#,16), '0', '0'),
		rhs_cmd_write(to_unsigned(38,8), to_unsigned(16#FFFF#,16), '0', '0'),
	
		rhs_cmd_clear,
	
		rhs_cmd_write(to_unsigned(0,8),  to_unsigned(16#00C5#,16), '0', '0'),
		rhs_cmd_write(to_unsigned(1,8),  to_unsigned(16#051A#,16), '0', '0'),
		rhs_cmd_write(to_unsigned(2,8),  to_unsigned(16#0040#,16), '0', '0'),
		rhs_cmd_write(to_unsigned(3,8),  to_unsigned(16#0080#,16), '0', '0'),
		rhs_cmd_write(to_unsigned(4,8),  to_unsigned(16#0016#,16), '0', '0'),
		rhs_cmd_write(to_unsigned(5,8),  to_unsigned(16#0017#,16), '0', '0'),
		rhs_cmd_write(to_unsigned(6,8),  to_unsigned(16#00A8#,16), '0', '0'),
		rhs_cmd_write(to_unsigned(7,8),  to_unsigned(16#000A#,16), '0', '0'),
		rhs_cmd_write(to_unsigned(8,8),  to_unsigned(16#FFFF#,16), '0', '0'),
	
		rhs_cmd_write(to_unsigned(10,8), to_unsigned(16#0000#,16), '1', '0'),
		rhs_cmd_write(to_unsigned(12,8), to_unsigned(16#FFFF#,16), '1', '0'),
	
		rhs_cmd_write(to_unsigned(34,8), to_unsigned(16#00E2#,16), '0', '0'),
		rhs_cmd_write(to_unsigned(35,8), to_unsigned(16#00AA#,16), '0', '0'),
		rhs_cmd_write(to_unsigned(36,8), to_unsigned(16#0080#,16), '0', '0'),
		rhs_cmd_write(to_unsigned(37,8), to_unsigned(16#4F00#,16), '0', '0'),
	
		rhs_cmd_write(to_unsigned(42,8), to_unsigned(16#0000#,16), '1', '0'),
		rhs_cmd_write(to_unsigned(44,8), to_unsigned(16#0000#,16), '1', '0'),
		rhs_cmd_write(to_unsigned(46,8), to_unsigned(16#0000#,16), '1', '0'),
		rhs_cmd_write(to_unsigned(48,8), to_unsigned(16#0000#,16), '1', '0'),
	
		rhs_cmd_write(to_unsigned(64,8), to_unsigned(16#8000#,16), '1', '0'),
		rhs_cmd_write(to_unsigned(65,8), to_unsigned(16#8000#,16), '1', '0'),
		rhs_cmd_write(to_unsigned(66,8), to_unsigned(16#8000#,16), '1', '0'),
		rhs_cmd_write(to_unsigned(67,8), to_unsigned(16#8000#,16), '1', '0'),
		rhs_cmd_write(to_unsigned(68,8), to_unsigned(16#8000#,16), '1', '0'),
		rhs_cmd_write(to_unsigned(69,8), to_unsigned(16#8000#,16), '1', '0'),
		rhs_cmd_write(to_unsigned(70,8), to_unsigned(16#8000#,16), '1', '0'),
		rhs_cmd_write(to_unsigned(71,8), to_unsigned(16#8000#,16), '1', '0'),
		rhs_cmd_write(to_unsigned(72,8), to_unsigned(16#8000#,16), '1', '0'),
		rhs_cmd_write(to_unsigned(73,8), to_unsigned(16#8000#,16), '1', '0'),
		rhs_cmd_write(to_unsigned(74,8), to_unsigned(16#8000#,16), '1', '0'),
		rhs_cmd_write(to_unsigned(75,8), to_unsigned(16#8000#,16), '1', '0'),
		rhs_cmd_write(to_unsigned(76,8), to_unsigned(16#8000#,16), '1', '0'),
		rhs_cmd_write(to_unsigned(77,8), to_unsigned(16#8000#,16), '1', '0'),
		rhs_cmd_write(to_unsigned(78,8), to_unsigned(16#8000#,16), '1', '0'),
		rhs_cmd_write(to_unsigned(79,8), to_unsigned(16#8000#,16), '1', '0'),
	
		rhs_cmd_write(to_unsigned(96,8),  to_unsigned(16#8000#,16), '1', '0'),
		rhs_cmd_write(to_unsigned(97,8),  to_unsigned(16#8000#,16), '1', '0'),
		rhs_cmd_write(to_unsigned(98,8),  to_unsigned(16#8000#,16), '1', '0'),
		rhs_cmd_write(to_unsigned(99,8),  to_unsigned(16#8000#,16), '1', '0'),
		rhs_cmd_write(to_unsigned(100,8), to_unsigned(16#8000#,16), '1', '0'),
		rhs_cmd_write(to_unsigned(101,8), to_unsigned(16#8000#,16), '1', '0'),
		rhs_cmd_write(to_unsigned(102,8), to_unsigned(16#8000#,16), '1', '0'),
		rhs_cmd_write(to_unsigned(103,8), to_unsigned(16#8000#,16), '1', '0'),
		rhs_cmd_write(to_unsigned(104,8), to_unsigned(16#8000#,16), '1', '0'),
		rhs_cmd_write(to_unsigned(105,8), to_unsigned(16#8000#,16), '1', '0'),
		rhs_cmd_write(to_unsigned(106,8), to_unsigned(16#8000#,16), '1', '0'),
		rhs_cmd_write(to_unsigned(107,8), to_unsigned(16#8000#,16), '1', '0'),
		rhs_cmd_write(to_unsigned(108,8), to_unsigned(16#8000#,16), '1', '0'),
		rhs_cmd_write(to_unsigned(109,8), to_unsigned(16#8000#,16), '1', '0'),
		rhs_cmd_write(to_unsigned(110,8), to_unsigned(16#8000#,16), '1', '0'),
		rhs_cmd_write(to_unsigned(111,8), to_unsigned(16#8000#,16), '1', '0'),
	
		rhs_cmd_write(to_unsigned(32,8), to_unsigned(16#AAAA#,16), '0', '0'),
		rhs_cmd_write(to_unsigned(33,8), to_unsigned(16#00FF#,16), '0', '0'),
	
		rhs_cmd_read(to_unsigned(255,8), '0', '1')
	);

	------------------------------------------------------------------------------
	-- RECORD COMMAND ROM
  	------------------------------------------------------------------------------
	
	type RECORD_CMD_ARRAY is array (0 to NUM_CMDS-1) of std_logic_vector(WORD_LENGTH-1 downto 0);
	constant RECORD_ROM : RECORD_CMD_ARRAY  := (
		rhs_cmd_convert(to_unsigned(0,6),'0','0','1','0'),
		rhs_cmd_convert(to_unsigned(1,6),'0','0','1','0'),
		rhs_cmd_convert(to_unsigned(2,6),'0','0','1','0'),
		rhs_cmd_convert(to_unsigned(3,6),'0','0','1','0'),
		rhs_cmd_convert(to_unsigned(4,6),'0','0','1','0'),
		rhs_cmd_convert(to_unsigned(5,6),'0','0','1','0'),
		rhs_cmd_convert(to_unsigned(6,6),'0','0','1','0'),
		rhs_cmd_convert(to_unsigned(7,6),'0','0','1','0'),
		rhs_cmd_convert(to_unsigned(8,6),'0','0','1','0'),
		rhs_cmd_convert(to_unsigned(9,6),'0','0','1','0'),
		rhs_cmd_convert(to_unsigned(10,6),'0','0','1','0'),
		rhs_cmd_convert(to_unsigned(11,6),'0','0','1','0'),
		rhs_cmd_convert(to_unsigned(12,6),'0','0','1','0'),
		rhs_cmd_convert(to_unsigned(13,6),'0','0','1','0'),
		rhs_cmd_convert(to_unsigned(14,6),'0','0','1','0'),
		rhs_cmd_convert(to_unsigned(15,6),'0','0','1','0')
    );

	
	type state_type is (IDLE, SEND_CMD, WAIT_DONE, NEXT_CMD);
    signal state : state_type := IDLE;
    signal record_index : natural range 0 to NUM_CMDS-1;
    signal init_index 	: natural range 0 to INIT_ROM_FULL'length - 1;
    signal init_done_i: std_logic := '0';
    signal packet_ready_i: std_logic := '0';
    signal channel_id : unsigned(3 downto 0);
    signal packet_ready_reg : std_logic;
		
begin

	process (clk, reset) begin
		if reset = '1' then
				init_done_i <= '0';
				init_index <= 0;
				record_index <= 0;
				command_out_v <= '0';
				state <= IDLE;
				packet_ready_i <='0';
		elsif rising_edge(clk) then
            case(state) is
                when IDLE =>
                    command_out_v <= '0';
                    if ready_out = '1'  then
                        state <= SEND_CMD;
                    end if;
                when SEND_CMD =>
                    if init_done_i = '0' then
                        command_in <= INIT_ROM_FULL(init_index);
                    else 
                        command_in <= RECORD_ROM(record_index);
                    end if;
                    command_out_v <= '1';
                    state <= WAIT_DONE;
                when WAIT_DONE =>
                    command_out_v <= '0';
                    if data_in_v = '1' then
                        if init_done_i = '1' then
                            if fifo_full = '0' then
                                channel_id <= to_unsigned(record_index - 2, 4);
                                data_packet_spi <=  4x"0" & std_logic_vector(to_unsigned(record_index - 2, 4)) & data_out(31 downto 16);
                                packet_ready_i <= '1';
                            else
                                packet_ready_i <= '0';
                                state <= WAIT_DONE;
                            end if;
                        end if;
                        state <= NEXT_CMD;
                    end if;
                when NEXT_CMD =>
                    if init_done_i = '0' then
                        if init_index = INIT_ROM_FULL'length - 1 then
                            init_done_i <= '1';
                            init_index  <= 0;
                        else
                            init_index <= init_index + 1;
                        end if;
                    else
                        if record_index = NUM_CMDS - 1 then
                            record_index <= 0;
                        else
                            record_index <= record_index + 1;
                        end if;
                    end if;
                    packet_ready_i <= '0';
                    state <= IDLE;
            end case;				
        end if;
	end process;
	init_done <= init_done_i;
	packet_ready <= packet_ready_i;

end Behavioral;