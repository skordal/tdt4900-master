----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 03/26/2015 06:04:43 PM
-- Design Name: 
-- Module Name: EndianFWTwister - Behavioral
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

entity EndianFWTwister is
    Port ( enable : in STD_LOGIC;
           dataIn : in STD_LOGIC_VECTOR (127 downto 0);
           dataOut : out STD_LOGIC_VECTOR (127 downto 0));
end EndianFWTwister;

architecture Behavioral of EndianFWTwister is

    component EndianByteTwister
    port (
        enable : in std_logic;
        dataIn : in std_logic_vector(31 downto 0);
        dataOut : in std_logic_vector(31 downto 0)
    );
    end component;

begin

    twister3 : EndianByteTwister
    port map(
        enable => enable,
        dataIn => dataIn(127 downto 96),
        dataOut => dataOut(127 downto 96)
    );

    twister2 : EndianByteTwister
    port map(
        enable => enable,
        dataIn => dataIn(95 downto 64),
        dataOut => dataOut(95 downto 64)
    );
     
    twister1 : EndianByteTwister
    port map(
        enable => enable,
        dataIn => dataIn(63 downto 32),
        dataOut => dataOut(63 downto 32)
    );
    
    twister0 : EndianByteTwister
    port map(
        enable => enable,
        dataIn => dataIn(31 downto 0),
        dataOut => dataOut(31 downto 0)
    );
            

end Behavioral;
