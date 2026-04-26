----------------------------------------------------------------------------------
-- Company: ECD 622
-- Engineer: Thomas Vo
-- 
-- Create Date: 03/22/2026 11:19:23 PM
-- Design Name: 
-- Module Name: top_Basys3 - Behavioral
-- Project Name: Neuro Recorder 
-- Target Devices: Basys3 Board
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

-- USB_CLK bug fix
library UNISIM;
use UNISIM.VComponents.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity neuro_recorder is
	Port (
		--GENERAL INOUT
		CLK100MHZ : in std_logic;
		btnC	: in std_logic;
		LED : out std_logic_vector(15 downto 0);
				
		--SPI INTERFACE
		MOSI1_POS	: out std_logic;
		MISO1_POS	: in std_logic;
		SCLK_POS	: out std_logic;
		CS_POS		: out std_logic;

		--USB chip interface
		ADBUS: out std_logic_vector(7 downto 0);
		TXE: in std_logic; 			--TXE
		USB_CLK: in std_logic; 		--USB clock 60MHz
		OE: out std_logic; 			--OE
		RD: out std_logic;			--RD
		WR: out std_logic 			--WR
	);
end neuro_recorder;

architecture Behavioral of neuro_recorder is

	component synchronizer is
		Port(
			clk: in std_logic;
			a: in std_logic;
			a_sync: out std_logic
		);
	end component;
	
	component clk_100mhz is
		Port(
			clk_in 	: in std_logic;
			reset 	: in std_logic;
			clk_out	: out std_logic
		);
	end component;
	
	component async_fifo is
		PORT (
			rst : IN STD_LOGIC;
			wr_clk : IN STD_LOGIC;
			rd_clk : IN STD_LOGIC;
			din : IN STD_LOGIC_VECTOR(23 DOWNTO 0);
			wr_en : IN STD_LOGIC;
			rd_en : IN STD_LOGIC;
			dout : OUT STD_LOGIC_VECTOR(23 DOWNTO 0);
			full : OUT STD_LOGIC;
			empty : OUT STD_LOGIC;
			wr_rst_busy : OUT STD_LOGIC;
			rd_rst_busy : OUT STD_LOGIC
		);
	end component;
	

	
	component spi_master is
		generic ( CLK_FREQ	: natural := 100000000;                           -- main clk default value
              WORD_LENGTH 	: natural :=       	32;                           -- length of data for TX and RX
              SPICLK_FREQ 	: natural :=   1000000                            -- spi clk default value
        );
		
		port ( 
			clk        		: in  std_logic;                                      -- main clock
           	reset      		: in  std_logic;                                      -- reset signal
           	cs         		: out std_logic;                                      -- chip select
	
           	mosi			: out std_logic;                                      -- master out slave in output 1
           	miso			: in  std_logic;                                      -- master in slave out input 1

           	sclk       		: out std_logic;                                      -- SPI clock

           -- interface
           	command_in_v  	: in  std_logic;                                      -- master in slave out input 1
           	ready_in  		: out std_logic;                                      -- ready to get new data to transmit
           	data_out_v 		: out std_logic;                                      -- data received validity, new data available flag
          	
          	data_in  		: in  std_logic_vector(WORD_LENGTH - 1 downto 0);     -- data to transmit over mosi_1
           	data_out 		: out std_logic_vector(WORD_LENGTH - 1 downto 0)     -- data received from miso_1

         );
	end component;
	
	component spi_master_controller is
		generic (
			CLK_FREQ_HZ  : natural := 100_000_000; -- Basys 3 clock
			SPI_CLK_HZ   : natural :=   1_000_000; -- RHS2116 max SCLK
			WORD_LENGTH  : natural :=          32;
			NUM_CMDS     : integer :=          16;
		
		
			FULL_INIT    : boolean := false;       -- false = minimal init for MOSI testing
			STOP_AFTER_SAMPLES : natural := 0      -- 0 = run forever
		);
		Port (
			clk           : in  std_logic;
			reset         : in  std_logic;		
			
			-- handshake with spi_vhdl
			ready_out  : in  std_logic;
			command_out_v : out  std_logic;
			data_in_v 	: in std_logic;
			init_done	: out std_logic;
			command_in  : out std_logic_vector(WORD_LENGTH-1 downto 0);
			data_out : in std_logic_vector(WORD_LENGTH-1 downto 0);
			
			--PACKET & PACKET ASSEMBLED
			packet_ready	: out std_logic;
			data_packet_spi		: out std_logic_vector(23 downto 0);
			async_fifo_wr_reset_busy: in std_logic;
			fifo_full: in std_logic
		);
	end component;
	
	component FT245_sync_fifo is
		port(
			clk			: in std_logic;
			reset		: in std_logic;
			txe			: in std_logic;
			data_packet : in std_logic_vector(23 downto 0);
			write		: out std_logic;
			data_out	: out std_logic_vector(7 downto 0);
			--handshaking
			
			fifo_empty   : in std_logic;          --packet ready to be trasmit
			rd_en   : out std_logic;            -- sync fifo free for new data
			async_fifo_rd_reset_busy: in std_logic
		);
	end component;
	
	component FT245_Sync_FIFO_v2 is
		port(
			clk			: in std_logic;
			reset		: in std_logic;
			txe			: in std_logic;
			data_packet : in std_logic_vector(23 downto 0);
			write		: out std_logic;
			data_out	: out std_logic_vector(7 downto 0);
			
			--handshaking
			
			fifo_empty   : in std_logic;          --packet ready to be trasmit
			rd_en   : out std_logic;            -- sync fifo free for new data
			async_fifo_rd_reset_busy: in std_logic
		);
	end component;
	
	signal clock_100mhz : std_logic;
	signal reset_sync: std_logic;
	signal command, data: std_logic_vector(31 downto 0);
	signal command_v, data_v: std_logic;
	signal ready: std_logic;
	signal packet_ready_i: std_logic;
	signal data_packet_i: std_logic_vector(23 downto 0);
	signal data_packet_usb	: std_logic_vector(23 downto 0);
	
	
	signal transmit_done_i: std_logic;
	
	signal packet_available_i: std_logic;
	signal packet_available_sync: std_logic;
	signal fifo_full_i: std_logic;
	signal fifo_full_sync: std_logic;
	
	
	signal wr_reset_busy_i	: std_logic;
	signal rd_reset_busy_i	: std_logic;
	signal wr_reset_busy_sync : std_logic;
	signal rd_reset_busy_sync : std_logic;
	
	signal usb_clk_bufg : std_logic;
	signal external_reset: std_logic;
	signal internal_reset: std_logic;
	signal global_reset: std_logic;
	

	
	signal txe_sync: std_logic;
	
	
begin								
	BUFG_usb_clk : BUFG port map (
										I => USB_CLK,
										O => usb_clk_bufg
		);
									
	SYNC1 : synchronizer port map(
										clk => CLK100MHZ,
										a => wr_reset_busy_i,
										a_sync => wr_reset_busy_sync
								);
	SYNC2 : synchronizer port map(
										clk => usb_clk_bufg,--USB_CLK,
										a => rd_reset_busy_i,
										a_sync => rd_reset_busy_sync
								);
	SYNC_TXE : synchronizer port map(
										clk => usb_clk_bufg,--USB_CLK,
										a => TXE,
										a_sync => txe_sync
								);
	SYNC_EMPTY: synchronizer port map(
										clk => usb_clk_bufg,--USB_CLK,
										a => packet_available_i,
										a_sync => packet_available_sync
								);
	SYNC_FULL: synchronizer port map(
										clk => CLK100MHZ,
										a => fifo_full_i,
										a_sync => fifo_full_sync
								);
								
	SYNC_RST_EXTERNAL : synchronizer port map(
										clk => usb_clk_bufg,
										a => btnC,
										a_sync => external_reset
								);
	SYNC_RST_INTERNAL : synchronizer port map(
										clk => CLK100MHZ,
										a => btnC,
										a_sync => internal_reset
								);
	
	global_reset <= internal_reset or external_reset;
	MASTER_DRIVER : spi_master port map(
										clk =>CLK100MHZ,
										-- IO pins
										reset => btnC ,	--SOME BUTTON
										mosi => MOSI1_POS , --SOME IO
										miso => MISO1_POS,  --SOME IO
										cs => CS_POS,  		--SOME IO
										sclk => SCLK_POS, 	--SOME IO
										-- handshaking 
										command_in_v => command_v,
										ready_in => ready, 
										data_out_v => data_v, 
										data_in => command, 
										data_out => data
								);
 	
 	MASTER_CONTROLLER : spi_master_controller port map(
 										clk => CLK100MHZ,
 										reset => btnC , 	--SOME BUTTON
 										ready_out => ready,
 										command_out_v => command_v,
 										data_in_v => data_v, 
 										command_in => command,
 										init_done => LED(0),
 										-- INTERFACE WITH ASYNC FIFO
 										data_out=> data,
 										packet_ready => packet_ready_i,
 										data_packet_spi => data_packet_i,
 										async_fifo_wr_reset_busy => wr_reset_busy_sync,
 										fifo_full => fifo_full_sync
 								);
	FIFO_ASYNC : async_fifo port map(
										rst => global_reset,--btn(0),
										wr_clk => CLK100MHZ,
										rd_clk => usb_clk_bufg,--USB_CLK, 
										din => data_packet_i,
										wr_en => packet_ready_i,
										rd_en => transmit_done_i,
										dout => data_packet_usb,
										full => fifo_full_i ,
										empty => packet_available_i,
										wr_rst_busy => wr_reset_busy_i, 
										rd_rst_busy => rd_reset_busy_i	
								);
	FIFO_SYNC: FT245_sync_fifo port map(
										clk => usb_clk_bufg,
										reset => external_reset,
										txe => txe_sync,
										write => WR,
										data_packet => data_packet_usb,
										data_out => ADBUS(7 downto 0),
										fifo_empty => packet_available_sync, 
										rd_en => transmit_done_i,
										async_fifo_rd_reset_busy => rd_reset_busy_sync
								);
	OE <= '1';
	RD <= '1';	
	LED(11) <= fifo_full_sync;
	LED(12) <= packet_available_sync;
	LED(13) <= wr_reset_busy_sync;
	LED(14) <= rd_reset_busy_sync;
end Behavioral;