----------------------------------------------------------------------------------
-- Company: 
-- Engineer:  
-- 
-- Create Date: 02/06/2026 07:49:26 PM
-- Design Name: 
-- Module Name: top - Behavioral
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

entity top is
	Port (
		sysclk 	: in std_logic;
		pio1	: out std_logic;
		pio2	: out std_logic;
		btn		: in std_logic_vector(1 downto 0);
		led		: out std_logic_vector(1 downto 0)
	);
end top;
	

architecture Behavioral of top is
	component clk_25mhz is
		Port(
			clk_out : out std_logic;
  	        reset: in std_logic;
          	locked: out std_logic;
           	clk_src: in std_logic
		);
	end component;
begin
	UUT1 : clk_25mhz port map(clk_out => pio2, reset => btn(0), locked => led(0) , clk_src => sysclk);
	pio1 <= sysclk;
		
end Behavioral;
