--------------------------------------------------------------------------------
-- Company: ECD622
-- Engineer: Thomas Vo
-- Create Date: 03/12/2026 09:35:58 PM
-- Design Name: FT245 sync FIFO driver

-- Module Name: FT245_sync_fifo - Behavioral
-- Project Name: ECD-622 Neuro Recording System
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- Dependencies: 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--------------------------------------------------------------------------------
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

entity FT245_sync_fifo is
    Port (
        -- FT245 SYNC FIFO INTERFACE
        clk             : in  std_logic;
        reset           : in  std_logic;
        txe             : in  std_logic;
        data_out        : out std_logic_vector(7 downto 0);
        write           : out std_logic;

        -- ASYNC FIFO INTERFACE (STANDARD FIFO)
        data_packet     : in  std_logic_vector(23 downto 0);
        fifo_empty      : in  std_logic;
        rd_en           : out std_logic;
        async_fifo_rd_reset_busy : in std_logic
    );
end FT245_sync_fifo;

architecture Behavioral of FT245_sync_fifo is
	
    type state_t is (
        IDLE,
        READ_REQ,
        WAIT_DATA,
        SEND_SYNC1,
        SEND_SYNC2,
        SEND_ID,
        SEND_MSB,
        SEND_LSB,
        SEND_CK,
        WAIT_TXE
    );
	
	constant SYNC1 : std_logic_vector(7 downto 0) := x"AA";
	constant SYNC2 : std_logic_vector(7 downto 0) := x"55";
    
    signal state : state_t := IDLE;
    signal rd_en_i : std_logic := '0';
    signal channel_id : std_logic_vector(7 downto 0) := x"00";
    signal data_msb   : std_logic_vector(7 downto 0) := x"00";
    signal data_lsb   : std_logic_vector(7 downto 0) := x"00";
    signal check_sum  : std_logic_vector(7 downto 0);

    signal current_byte : unsigned(2 downto 0) := (others => '0');

begin

process(clk)
begin
    if(reset = '1') then
        state <= IDLE;
        write <= '1';
        current_byte <= "000";

    elsif rising_edge(clk) then
        write   <= '1';
        rd_en_i <= '0';
        case state is
            when IDLE =>
                if (fifo_empty = '0') and (async_fifo_rd_reset_busy = '0') then 
                    rd_en_i <= '1'; 
                    state <= READ_REQ;
                end if;
            when READ_REQ =>                                                                    -- this assumes standard fifo's new data is available after 1 cyle after rd_en
                state <= WAIT_DATA;
            when WAIT_DATA =>
                channel_id <= data_packet(23 downto 16);                           
                data_msb   <= data_packet(15 downto 8);
                data_lsb   <= data_packet(7 downto 0);
                current_byte <= "000";
                state <= WAIT_TXE;
            when WAIT_TXE =>
                if txe = '0' then
                    case current_byte is
                        when "000" => data_out <= SYNC1;
                        when "001" => data_out <= SYNC2;
                        when "010" => data_out <= channel_id;
                        when "011" => data_out <= data_msb;
                        when "100" => data_out <= data_lsb;
                        when "101" => data_out <= data_msb XOR data_lsb XOR channel_id;         --CHECK SUM
                        when others => data_out <= x"AA";
                    end case;
                    write <= '0';
                    case current_byte is
                        when "000" => state  <= SEND_SYNC1;
                        when "001" => state  <= SEND_SYNC2;
                        when "010" => state  <= SEND_ID;
                        when "011" => state  <= SEND_MSB;
                        when "100" => state  <= SEND_LSB;
                        when "101" => state  <= SEND_CK;
                        when others => state <= IDLE;
                    end case;
                else
                	state <= WAIT_TXE;
                end if;
            when SEND_SYNC1 =>
                current_byte <= "001";
                state <= WAIT_TXE;
            when SEND_SYNC2 =>
                current_byte <= "010";
                state <= WAIT_TXE;
            when SEND_ID =>
                current_byte <= "011";
                state <= WAIT_TXE;
            when SEND_MSB =>
                current_byte <= "100";
                state <= WAIT_TXE;
            when SEND_LSB =>
            	current_byte <= "101";
                state <= WAIT_TXE;
            when SEND_CK =>
            	state <= IDLE;
        end case;
    end if;
end process;

rd_en <= rd_en_i;

end Behavioral;