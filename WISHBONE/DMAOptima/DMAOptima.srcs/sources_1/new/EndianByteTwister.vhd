----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 03/26/2015 06:04:43 PM
-- Design Name: 
-- Module Name: EndianByteTwister - Behavioral
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

entity EndianByteTwister is
    Port ( enable : in STD_LOGIC;
           dataIn : in STD_LOGIC_VECTOR (31 downto 0);
           dataOut : out STD_LOGIC_VECTOR (31 downto 0));
end EndianByteTwister;

architecture Behavioral of EndianByteTwister is

begin

   twist : process (enable, dataIn)
   begin
        if enable = '1' then
            dataOut(31 downto 24) <= dataIn(7 downto 0);
            dataOut(23 downto 16) <= dataIn(15 downto 8);
            dataOut(15 downto 8) <= dataIn(23 downto 16);
            dataOut(7 downto 0) <= dataIn(31 downto 24);
        else
            dataOut <= dataIn;
        end if;
   end process;


end Behavioral;
