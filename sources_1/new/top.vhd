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
----TEST CLK SOURCE
--	Port (
--		sysclk 	: in std_logic;
--		pio1	: out std_logic;
--		pio2	: out std_logic;
--		btn		: in std_logic_vector(1 downto 0);
--		led		: out std_logic_vector(1 downto 0)
--	);

----TEST DATA GEN
	Port(
--------INPUTS
		--sysclk	: in std_logic; --<--external clk
		pio18	: in std_logic; --<--external clk
		pio19	: in std_logic; --<--TXE
		pio20	: in std_logic; --<--RXF :
		btn		: in std_logic_vector(1 downto 0);
--------OUTPUTS
		pio2	: out std_logic;-->--OE    -- set high
		pio3	: out std_logic;-->--write
		pio4	: out std_logic;-->--read  -- set high
		gpio_io	: out std_logic_vector (7 downto 0)
	);
end top;
	

architecture Behavioral of top is
----TEST CLK SOURCE
--	component clk_25mhz is
--		Port(
--			clk_out : out std_logic;
--  	        reset: in std_logic;
--          	locked: out std_logic;
--           	clk_src: in std_logi
--		);
--	end component;

	component synchronizer is
		Port(
			clk: in std_logic;
			a: in std_logic;
			a_sync: out std_logic
		);
	end component;

	component data_generator_16b_v1 is
		Port(
			clk			: in std_logic;
			reset		: in std_logic;
			txe			: in std_logic;
			write		: out std_logic;
			data_out	: out std_logic_vector(7 downto 0)
		);
	end component;
	signal txe_sync : std_logic;

	component data_generator_v2 is
		Port (
		clk			: in std_logic;
		reset		: in std_logic;
		txe			: in std_logic;
		--rxf			: in std_logic;
		write		: out std_logic;
		data_out	: out std_logic_vector(7 downto 0)	
		);
	end component;
begin
----TEST CLK SOURCE
--	UUT1 : clk_25mhz port map(clk_out => pio2, reset => btn(0), locked => led(0) , clk_src => sysclk);
--	pio1 <= sysclk;

----TEST DATA GENERATOR
--	UUT_SYNCHRONIZER: synchronizer port map(clk=>pio18, a=>pio19, a_sync=>txe_sync);
	UUT_DATA_GEN: data_generator_16b_v1 port map(clk=>pio18, reset => btn(0), txe => pio19, write => pio3, data_out => gpio_io);
----TEST DATA GENERATOR V2
--	UUT_DATA_GEN_V2: data_generator_v2 port map(clk=>pio18, reset => btn(0), txe => pio19, write => pio3, data_out => gpio_io);
	pio2 <= '1';
	pio4 <= '1';
end Behavioral;
