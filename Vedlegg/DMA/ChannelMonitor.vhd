----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 03/26/2015 08:11:12 PM
-- Design Name: 
-- Module Name: ChannelMonitor - Behavioral
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

entity ChannelMonitor is
    Port ( 
            clk : in std_logic;
            reset : in std_logic;
            
            channelActive : in STD_LOGIC;
           interruptOut : out STD_LOGIC);
end ChannelMonitor;

architecture Behavioral of ChannelMonitor is

    signal activity : std_logic := '0';

begin

    monitor : process(clk, reset, channelActive)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                activity <= '0';
                interruptOut <= '0';
            else
                activity <= channelActive;
                if activity = '1' and channelActive = '0' then -- Channel is finished if it turns from '1' to '0', send out intterupt
                    interruptOut <= '1';
                else
                    interruptOut <= '0';
                end if;
            end if;
        end if;
    end process;
end Behavioral;
