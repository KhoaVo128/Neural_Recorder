----------------------------------------------------------------------------------
-- Company: ECD622 
-- Engineer: Thomas (Khoa) Vo
-- 
-- Create Date: 02/10/2026 10:23:15 PM
-- Design Name: TESTBNEHCING CLK MF
-- Module Name: clk_25mhz_v2_tb - Behavioral
-- Project Name: 
-- Target Devices: CMOD A7-35T
-- Tool Versions: 
-- Description: testing clk wiz 25mhz without lock
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

entity clk_25mhz_v2_tb is
--  Port ( );
end clk_25mhz_v2_tb;

architecture Behavioral of clk_25mhz_v2_tb is
	constant CLK12_PERIOD : time := 83.333333 ns; -- 12 MHz
    constant CLK25_PERIOD : time := 40 ns;        -- 25 MHz
	component clk_25mhz_v2 is
		
		Port(
			clk_src		: in std_logic;
			reset		: in std_logic;
			clk_out		: out std_logic
		);
	end component;
	
	signal clk_src_sig, reset_sig, clk_out_sig: std_logic;
begin
	UUT: clk_25mhz_v2 port map(clk_src => clk_src_sig, reset=>reset_sig, clk_out=> clk_out_sig);

	
	CLK_GEN: process begin
		loop
			clk_src_sig <= '1';
			wait for CLK12_PERIOD / 2 ;
			clk_src_sig <= '0';
			wait for CLK12_PERIOD / 2;
		end loop;
	end process;
	
	RESET_GEN : process
    begin
        reset_sig <= '1';
        wait for 80 ns;
        reset_sig <= '0';
        wait;
    end process;
	
	SIGNAL_GEN: process
		variable t1, t2 : time;
        variable measured_period : time;
    	begin
			wait until rising_edge(clk_out_sig);
			t1 := now;
			wait until rising_edge(clk_out_sig);
			t2 :=now;
			measured_period := t2 - t1;
			
			assert abs(measured_period - CLK25_PERIOD) < 1 ns
            	report "ERROR: clk_out is not 25 MHz!"
            	severity error;
            report "PASS: clk_out period = " & time'image(measured_period);

        	wait;
	end process;
	


end Behavioral;
