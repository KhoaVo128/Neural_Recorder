library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity spi_master_controller_tb is
end spi_master_controller_tb;

architecture Behavioral of spi_master_controller_tb is

    -- DUT generics
    constant CLK_FREQ_HZ : natural := 100_000_000;
    constant SPI_CLK_HZ  : natural := 100_000;
    constant WORD_LENGTH : natural := 32;
    constant NUM_CMDS    : integer := 16;

    -- Signals
    signal clk           : std_logic := '0';
    signal reset         : std_logic := '1';

    signal ready_out     : std_logic := '0';
    signal command_out_v : std_logic;
    signal data_in_v     : std_logic := '0';
    signal init_done     : std_logic;
    signal command_in    : std_logic_vector(WORD_LENGTH-1 downto 0);
    signal data_out      : std_logic_vector(WORD_LENGTH-1 downto 0) := (others => '0');

    signal data_packet_spi : std_logic_vector(23 downto 0);
    signal packet_ready    : std_logic;

    signal async_fifo_wr_reset_busy : std_logic := '0';
    signal fifo_full : std_logic := '0';

    constant CLK_PERIOD : time := 10 ns;

begin

    --------------------------------------------------------------------
    -- DUT Instantiation
    --------------------------------------------------------------------
    uut: entity work.spi_master_controller
        generic map (
            CLK_FREQ_HZ => CLK_FREQ_HZ,
            SPI_CLK_HZ  => SPI_CLK_HZ,
            WORD_LENGTH => WORD_LENGTH,
            NUM_CMDS    => NUM_CMDS
        )
        port map (
            clk => clk,
            reset => reset,

            ready_out => ready_out,
            command_out_v => command_out_v,
            data_in_v => data_in_v,
            init_done => init_done,
            command_in => command_in,
            data_out => data_out,

            data_packet_spi => data_packet_spi,
            packet_ready => packet_ready,

            async_fifo_wr_reset_busy => async_fifo_wr_reset_busy,
            fifo_full => fifo_full
        );

    --------------------------------------------------------------------
    -- Clock Generation
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
    -- SPI Handshake Emulator
    --------------------------------------------------------------------
    spi_model : process
    begin
        wait until reset = '0';
        wait for 50 ns;

        while true loop
            -- Tell controller SPI is ready
            ready_out <= '1';
            wait until rising_edge(clk);

            if command_out_v = '1' then
                -- emulate SPI transfer delay
                ready_out <= '0';
                wait for 200 ns;

                -- provide dummy data
                data_out <= std_logic_vector(to_unsigned(16#ABCD000# + now/1 ns, 32));

                data_in_v <= '1';
                wait until rising_edge(clk);
                data_in_v <= '0';
            end if;
        end loop;
    end process;

    --------------------------------------------------------------------
    -- FIFO behavior (optional stress test)
    --------------------------------------------------------------------
    fifo_model : process
    begin
        wait until reset = '0';
        wait for 5 us;

        -- simulate FIFO full condition briefly
        fifo_full <= '1';
        wait for 1 us;
        fifo_full <= '0';

        wait;
    end process;

end Behavioral;