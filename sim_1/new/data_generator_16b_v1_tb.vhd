----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02/19/2026 02:14:52 PM
-- Design Name: 
-- Module Name: data_generator_16b_v1_tb - Behavioral
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

entity tb_data_generator_16b_v1 is
end tb_data_generator_16b_v1;

architecture Behavioral of tb_data_generator_16b_v1 is

    -- Component Declaration
    component data_generator_16b_v1
        Port (
            clk      : in  std_logic;
            reset    : in  std_logic;
            txe      : in  std_logic;
            write    : out std_logic;
            data_out : out std_logic_vector(7 downto 0)
        );
    end component;

    -- Testbench Signals
    signal clk_tb      : std_logic := '0';
    signal reset_tb    : std_logic := '1';
    signal txe_tb      : std_logic := '1';
    signal write_tb    : std_logic;
    signal data_out_tb : std_logic_vector(7 downto 0);

    constant CLK_PERIOD : time := 10 ns;

begin

    --------------------------------------------------------------------
    -- Instantiate the DUT (Device Under Test)
    --------------------------------------------------------------------
    DUT: data_generator_16b_v1
        Port map (
            clk      => clk_tb,
            reset    => reset_tb,
            txe      => txe_tb,
            write    => write_tb,
            data_out => data_out_tb
        );

    --------------------------------------------------------------------
    -- Clock Generation (100 MHz)
    --------------------------------------------------------------------
    clk_process : process
    begin
        while true loop
            clk_tb <= '0';
            wait for CLK_PERIOD/2;
            clk_tb <= '1';
            wait for CLK_PERIOD/2;
        end loop;
    end process;

    --------------------------------------------------------------------
    -- Stimulus Process
    --------------------------------------------------------------------
    stim_proc : process
    begin
        -- Hold reset for a few cycles
        wait for 50 ns;
        reset_tb <= '0';

        -- TXE high initially (FIFO not ready)
        txe_tb <= '1';
        wait for 100 ns;

        -- Make FIFO ready
        txe_tb <= '0';
        wait for 300 ns;

        -- Simulate FIFO becoming full
        txe_tb <= '1';
        wait for 100 ns;

        -- Ready again
        txe_tb <= '0';
        wait for 500 ns;

        -- End simulation
        wait;
    end process;

end Behavioral;

