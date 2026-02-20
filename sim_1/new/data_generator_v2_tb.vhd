----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02/10/2026 10:26:39 PM
-- Design Name: 
-- Module Name: data_generator_tb - Behavioral
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

entity data_generator_v2_tb is
--  Port ( );
end data_generator_v2_tb;

architecture Behavioral of data_generator_v2_tb is
	constant CLK_PERIOD : time := 8.3333333 ns;
	component data_generator_v2 is
		Port(
			clk			: in std_logic;
			reset		: in std_logic;
			txe			: in std_logic;
			write		: out std_logic;
			data_out	: out std_logic_vector(7 downto 0)	
		);
	end component;
	
	signal clk_sig, reset_sig, txe_sig, write_sig : std_logic;
	signal data_out_sig : std_logic_vector(7 downto 0):=8x"0";
	
begin
	UUT: data_generator_v2 port map(clk 	=> clk_sig, 
									reset 	=> reset_sig,
									txe 	=> txe_sig,
									write 	=> write_sig,
									data_out=> data_out_sig
								);
	
	CLK_GEN: process begin
		loop
			clk_sig <= '1';
			wait for CLK_PERIOD;
			clk_sig <= '0';
			wait for CLK_PERIOD;
		end loop;
	end process;
	
	RESET_GEN : process
    begin
        reset_sig <= '1';
        wait for CLK_PERIOD * 2;
        reset_sig <= '0';
        wait;
    end process;
    
     --------------------------------------------------------------------
    -- Stimulus Process
    --------------------------------------------------------------------
    stimulus : process
    begin
        --------------------------------------------------------------
        -- 2. Stay in WAIT_TXE_LOW (txe = '1')
        --------------------------------------------------------------
        txe_sig <= '1';
        wait for 5*CLK_PERIOD;

        --------------------------------------------------------------
        -- 3. Drive txe LOW (should allow transmit state if coded)
        --------------------------------------------------------------
        txe_sig <= '0';
        wait for 10*CLK_PERIOD;

        --------------------------------------------------------------
        -- 4. Toggle txe HIGH again (forces exit from TRANSMIT)
        --------------------------------------------------------------
        txe_sig <= '1';
        wait for 5*CLK_PERIOD;

        --------------------------------------------------------------
        -- 5. Rapid toggling to test robustness
        --------------------------------------------------------------
        txe_sig <= '0';
        wait for 3*CLK_PERIOD;

        txe_sig <= '1';
        wait for 2*CLK_PERIOD;

        txe_sig <= '0';
        wait for 4*CLK_PERIOD;

        txe_sig <= '1';
        wait for 5*CLK_PERIOD;

        --------------------------------------------------------------
        -- End Simulation
        --------------------------------------------------------------
        wait;

    end process;

end Behavioral;
