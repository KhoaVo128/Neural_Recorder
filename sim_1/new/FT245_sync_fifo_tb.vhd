----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 03/17/2026 01:13:58 AM
-- Design Name: 
-- Module Name: FT245_sync_fifo_tb - Behavioral
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
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;


entity FT245_sync_fifo_tb is
	--Port();
end FT245_sync_fifo_tb;

architecture Behavioral of FT245_sync_fifo_tb is

    --------------------------------------------------------------------
    -- Signals
    --------------------------------------------------------------------
    signal clk   : std_logic := '0';
    signal reset : std_logic := '1';

    -- FT245 interface
    signal txe      : std_logic := '1'; -- active LOW (0 = can transmit)
    signal data_out : std_logic_vector(7 downto 0);
    signal write    : std_logic;

    -- FIFO interface
    signal data_packet : std_logic_vector(23 downto 0) := (others => '0');
    signal fifo_empty  : std_logic := '1';
    signal rd_en       : std_logic;
    signal async_fifo_rd_reset_busy : std_logic := '0';

    constant CLK_PERIOD : time := 10 ns;

    --------------------------------------------------------------------
    -- Test data
    --------------------------------------------------------------------
    type packet_array is array (0 to 3) of std_logic_vector(23 downto 0);
    constant test_packets : packet_array := (
        x"010203", -- ID=01, MSB=02, LSB=03
        x"112233",
        x"AABBCC",
        x"0F0E0D"
    );

    signal packet_index : integer := 0;

begin

    --------------------------------------------------------------------
    -- DUT
    --------------------------------------------------------------------
    uut: entity work.FT245_sync_fifo
        port map (
            clk => clk,
            reset => reset,
            txe => txe,
            data_out => data_out,
            write => write,
            data_packet => data_packet,
            fifo_empty => fifo_empty,
            rd_en => rd_en,
            async_fifo_rd_reset_busy => async_fifo_rd_reset_busy
        );

    --------------------------------------------------------------------
    -- Clock
    --------------------------------------------------------------------
    clk_process : process
    begin
        while true loop
            clk <= '0';
            wait for CLK_PERIOD/2;
            clk <= '1';
            wait for CLK_PERIOD/2;
        end loop;
    end process;

    --------------------------------------------------------------------
    -- Reset
    --------------------------------------------------------------------
    reset_process : process
    begin
        wait for 100 ns;
        reset <= '0';
        wait;
    end process;

    --------------------------------------------------------------------
    -- FIFO MODEL (1-cycle latency)
    --------------------------------------------------------------------
    fifo_model : process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                fifo_empty <= '1';
                packet_index <= 0;
            else
                -- Provide data when rd_en is asserted
                if rd_en = '1' and packet_index < test_packets'length then
                    data_packet <= test_packets(packet_index);
                    fifo_empty <= '0';
                    packet_index <= packet_index + 1;
                elsif packet_index >= test_packets'length then
                    fifo_empty <= '1';
                else
                    fifo_empty <= '0';
                end if;
            end if;
        end if;
    end process;

    --------------------------------------------------------------------
    -- FT245 TXE MODEL
    --------------------------------------------------------------------
    txe_model : process
    begin
        wait until reset = '0';

        while true loop
            -- Allow transmission
            txe <= '0';
            wait for 500 ns;

            -- Block transmission (simulate USB backpressure)
            txe <= '1';
            wait for 200 ns;
        end loop;
    end process;

    --------------------------------------------------------------------
    -- MONITOR (prints output)
    --------------------------------------------------------------------
    monitor : process(clk)
    begin
        if rising_edge(clk) then
            if write = '0' then
                report "TX BYTE: " & integer'image(to_integer(unsigned(data_out)));
            end if;
        end if;
    end process;

end Behavioral;
