----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02/08/2026 11:23:17 AM
-- Design Name: 
-- Module Name: spi_master - Behavioral
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity spi_master is
	Port (
--------GENERAL INPUT
		clk 	: in 	std_logic;
		reset	: in 	std_logic;

--------SPI INTERFACE 
		MISO	: in 	std_logic;
		MOSI	: out 	std_logic;
		SCLK	: out 	std_logic;
		CS		: out	std_logic;

--------MOSI Signal
		i_TX_Data	: out	std_logic_vector (31 downto 0);
		i_TX_DV		: in 	std_logic;
		o_TX_Ready	: out 	std_logic;

--------MISO Signal
		RX_data	: in	std_logic_vector (31 downto 0)
			 
	);
end spi_master;

architecture Behavioral of spi_master is
begin


end Behavioral;
