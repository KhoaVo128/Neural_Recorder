----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/30/2025 07:45:48 PM
-- Design Name: 
-- Module Name: synchronizer - Behavioral
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

entity synchronizer is

    generic(
        depth: integer:=2
    );
    
    Port (
        clk: in std_logic;
        a: in std_logic;
        a_sync: out std_logic
    );
end synchronizer;

architecture Behavioral of synchronizer is
    signal rega: std_logic_vector((depth - 1) downto 0);
begin

    process(clk) is begin
        if(rising_edge(clk)) then 
            rega <= a & rega((depth - 1) downto 1);
        end if;
    end process;
    
    a_sync <= rega(0);

end Behavioral;
