----------------------------------------------------------------------------------
-- Company: ECD622
-- Engineer: Thomas Vo
-- 
-- Create Date: 02/06/2026 07:52:05 PM
-- Design Name: Data Generator
-- Module Name: data_generator - Behavioral
-- Project Name: Neural Recording System ECD622
-- Target Devices: CMODA7-35T
-- Tool Versions: 
-- Description: Module create for Testing the FT245 style Sync Fifo on FT2232HL Mini Module
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
use IEEE.NUMERIC_STD_UNSIGNED.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity data_generator_16b_v1 is
	Port (
		clk			: in std_logic;
		reset		: in std_logic;
		txe			: in std_logic;
		--rxf			: in std_logic;
		write		: out std_logic;
		data_out	: out std_logic_vector(7 downto 0)	
	);
end data_generator_16b_v1;

architecture Behavioral of data_generator_16b_v1 is
----STATES AND STUFF
	type state_t is  (IDLE, WAIT_TXE_LOW, LOAD ,TX_BYTE_1, TX_BYTE_2);
	--type state_t is  (IDLE,WAIT_TXE_LOW, LOAD, TRANSMIT);
	signal state, next_state: state_t;

----DATA TO BE TRANSMITED	
	signal data_tx, next_data_tx: std_logic_vector (7 downto 0);
	signal data_16b, next_data_16b : std_logic_vector(15 downto 0);
	signal wr, next_wr : std_logic;
----WHICH BYTE TO TRANSFER
	signal byte_count, next_byte_count: std_logic_vector (0 downto 0) := 1x"0";
	
begin
 
	process(clk) begin
		if rising_edge(clk) then
			if reset = '1' then
				state<=IDLE;
				data_tx <= 8x"0";
				byte_count <= 1x"0";
				data_16b <= 16x"253";
			else
				data_tx <= next_data_tx;
				state<=next_state;
				byte_count <= next_byte_count;
				data_16b <= next_data_16b;
			end if;	
		end if;
	end process;
	
	process(ALL) begin
		next_byte_count <= byte_count;
		next_state <= state;
		next_data_tx <= data_tx;
		next_data_16b <= data_16b;
		next_wr <= wr;
		case(state) is
			when IDLE =>
				wr <= '0';
				next_byte_count <= 1x"0";
				next_data_16b <= 16d"253";
				next_state <= WAIT_TXE_LOW;
			when WAIT_TXE_LOW =>
				wr <= '1';
				if txe ='0' then
					next_state <= LOAD;
				else
					next_state <= WAIT_TXE_LOW;
				end if;
			when LOAD =>
				wr <='1';
				if byte_count = 1x"0" then
					next_data_tx <= data_16b(7 downto 0);
					next_state <= TX_BYTE_1;
				else
					next_data_tx <= data_16b(15 downto 8);
					next_state <= TX_BYTE_2;
				end if;
			when TX_BYTE_1 =>
				wr <= '0';
				next_byte_count <= byte_count + 1;
				next_state <= LOAD;
			when TX_BYTE_2 =>
				wr <= '0';
				next_byte_count <= byte_count + 1;
				if txe = '0' then
										next_data_16b <= data_16b + 1;
					next_state <= LOAD;
				else
					next_state <= WAIT_TXE_LOW;
				end if;
												
		end case;
	end process;
	write <= wr;
	data_out <= data_tx;

end Behavioral;
