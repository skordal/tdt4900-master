----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 03/26/2015 08:26:01 PM
-- Design Name: 
-- Module Name: DetailsConverter - Behavioral
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
use ieee.numeric_std.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity DetailsConverter is
    Port ( src : in STD_LOGIC_VECTOR (31 downto 0);
           dest : in STD_LOGIC_VECTOR (31 downto 0);
           details : in STD_LOGIC_VECTOR (31 downto 0);
           enable : in STD_LOGIC;
           Fsrc : out STD_LOGIC_VECTOR (31 downto 0); -- F = Final
           Fdest : out STD_LOGIC_VECTOR (31 downto 0); -- F = Final
           byteCount : out STD_LOGIC_VECTOR (31 downto 0);
           enableEndianTwist : out STD_LOGIC
           );
end DetailsConverter;

architecture Behavioral of DetailsConverter is
    
    --signal maxOffset : unsigned(31 downto 0) := (31 downto 0 => '0'); 
    signal maxOffset : std_logic_vector(31 downto 0) := (31 downto 0 => '0'); 
    signal readCount : std_logic_vector(11 downto 0) := (11 downto 0 => '0');
    
begin
    
    readCount <= details(31 downto 20);

    calculateMaxOffset : process (readCount, enable)
    begin
        if enable = '1' then
            --maxOffset <= unsigned(readCount) * 4;
            maxOffset <= (31 downto 14 => '0') & readCount & "00";
        else
            maxOffset <= (31 downto 0 => '0');
        end if;
    end process;
    
    
    setOutput : process (src, dest, details, enable, maxOffset)
    begin
        if enable = '1' then
            --Fsrc <= std_logic_vector(unsigned(src) + maxOffset); 
            Fsrc <= std_logic_vector(unsigned(src) + unsigned(maxOffset)); 
            --Fdest <= std_logic_vector(unsigned(dest) + maxOffset);
            Fdest <= std_logic_vector(unsigned(dest) + unsigned(maxOffset));
            byteCount <= maxOffset;
            enableEndianTwist <= details(1);
        else
            Fsrc  <= (31 downto 0 => '0');
            Fdest <= (31 downto 0 => '0');
            byteCount <= (31 downto 0 => '0');
            enableEndianTwist <= '0';
        end if;
    
    end process;
    
    
    
    
    
    
    
    

end Behavioral;
