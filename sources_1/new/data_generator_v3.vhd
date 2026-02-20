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

entity data_generator_v3 is
	Port (
		clk			: in std_logic;
		reset		: in std_logic;
		txe			: in std_logic;
		--rxf			: in std_logic;
		write		: out std_logic;
		data_out	: out std_logic_vector(7 downto 0)	
	);
end data_generator_v3;

architecture Behavioral of data_generator_v3 is
----STATES AND STUFF
	--type state_t is  (IDLE, TX_BYTE_1, TX_BYTE_2);
	type state_t is  (WAIT_TXE_LOW,WRITE_LOW);
	signal state: state_t := WAIT_TXE_LOW;

----DATA TO BE TRANSMITED	
	--signal data_tx, next_data_tx: std_logic_vector (15 downto 0);
	signal data_tx, next_data_tx : std_logic_vector (7 downto 0);
	signal wr : std_logic;
----WHICH BYTE TO TRANSFER
	--signal byte_count, next_byte_count: std_logic_vector (0 downto 0);
	
begin
 
    process(clk)
    begin
        if rising_edge(clk) then

            case state is

                --------------------------------------------------
                when WAIT_TXE_LOW =>
                    wr <= '1';

                    if txe = '0' then
                        state <= WRITE_LOW;
                    else
                    	state <= WAIT_TXE_LOW;
                    end if;

                --------------------------------------------------
                when WRITE_LOW =>
                    wr <= '0';

                    if reset = '1' then
                        -- During reset, always send 0
                        data_tx <= (others => '0');
                    else
                        -- Normal operation: increment data
                        data_tx <= data_tx + 1;
                    end if;

                    state <= WAIT_TXE_LOW;

            end case;

        end if;
    end process;

	write <= wr;
	data_out <= data_tx;
	


----16 BIT-WORD VER
--	process(clk) begin
--		if rising_edge(clk) then 
--			state <= IDLE when reset else next_state;
--		end if;
--	end process;
	
--	process(clk) begin	
--		if rising_edge(clk) then
--			byte_count <= next_byte_count;
--		end if;
--	end process;
	
--	process(clk) begin
--		if rising_edge(clk) then
--			data_tx <= next_data_tx;
--		end if;
--	end process;

--	process(ALL) begin
--		next_byte_count <= byte_count;
--		next_state <= state;
--		next_data_tx <= data_tx;
----		case(state) is
----			when IDLE =>
----				next_byte_count <= 1x"0";
----				x
----			when TX_BYTE_1 => 
----				pass;
----			when TX_BYTE_2 =>
----				pass;								
----		end case;
--	end process;

end Behavioral;
