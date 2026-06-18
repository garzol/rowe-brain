----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02.05.2026 14:58:54
-- Design Name: 
-- Module Name: pit6532 - Behavioral
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
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity PIT6532 is
  Port ( 
       fastclk     : in     STD_LOGIC;
       nReset      : in     STD_LOGIC;
       nCs         : in     STD_LOGIC;
       nRW         : in     STD_LOGIC;
       a_i         : in     STD_LOGIC_VECTOR(6 DOWNTO 0);
       d_i         : in     STD_LOGIC_VECTOR(7 DOWNTO 0);
       d_o         : out    STD_LOGIC_VECTOR(7 DOWNTO 0);
       test        : out    STD_LOGIC_VECTOR(7 DOWNTO 0)
);
end PIT6532;

architecture Behavioral of PIT6532 is

--PIT
signal PIT          : unsigned(7 downto 0) := (others=>'0');
--Interrupt Status Register
signal ISR          : std_logic_vector(7 downto 0) := (others=>'0');

signal preScaler    : unsigned(10 downto 0) := (0=>'1', others=>'0');

signal setISRb7     : std_logic := '0';
signal setpreScaler : std_logic := '0';
signal preScaler_int: unsigned(10 downto 0) := (0=>'1', others=>'0');
signal PIT_int      : unsigned(7 downto 0) := (others=>'0');
      
begin

test <= ISR;

p_prescale : process(fastclk)
        variable curScalClk : natural range 0 to 1024 := 0;
        variable oneMHzClk  : natural range 0 to 100  := 0;
    begin
        if (rising_edge(fastclk)) then
            if setpreScaler = '1' then
                preScaler <= preScaler_int;
                PIT       <= PIT_int;
            end if;
            --
            oneMHzClk := oneMHzClk+1;
            if oneMHzClk = 50 then   
                oneMHzClk := 0;
                curScalClk := curScalClk + 1;
                if preScaler = to_unsigned(curScalClk, preScaler'length) then
                    curScalClk := 0;
                    PIT <= PIT - "1";
                    if PIT = "11111111" then
                        preScaler <= (0=>'1', others=>'0');
                        --set bit 7 of ISR
                        setISRb7 <= '1';
                    end if;
                end if;

            end if;
            --
            if setISRb7 = '1' then
                setISRb7 <= '0'; --this signal is always at 1 for a maximum of 1 clock    
            end if;
        end if;
    end process p_prescale;
    
p_main : process(fastclk)
    begin
        if (rising_edge(fastclk)) then
            if nReset = '0' then
                --reset everything
                --PIT <= (others=>'0');
                ISR  <= (others=>'0');
                d_o <= (others=>'Z');
            else
                if setISRb7 = '1' then
                    ISR(7) <= '1';
                end if;
                if nCS = '0' then
                    if nRW = '1' then
                        --The CPU wants to read
                        if (a_i(0) = '1' and a_i(2) = '1') then
                            --read interrupt flag ($5)
                            d_o <= ISR;
                        elsif (a_i(0) = '0' and a_i(2) = '1') then 
                            --read timer disable IT ($4)
                            d_o <= std_logic_vector(PIT);
                            ISR(7) <= '0';
                        else
                            --not yet implemented. temporary for begining
                            d_o <= std_logic_vector(PIT);
                        end if;
                            
                    else
                        --The CPU wants to write
                        if (a_i(4)='1' and a_i(2)='1' and a_i(0)='1') then
                            --write timer div by 8T
                            PIT_int <= unsigned(d_i);
                            preScaler_int <= to_unsigned(8, preScaler'length);
                            setpreScaler  <= '1';
                            ISR(7) <= '0';
                        end if;
                    end if;
  
                end if;   --nCS
            end if;       --nReset
            if setpreScaler = '1' then
                setpreScaler <= '0'; --this signal is always at 1 for a maximum of 1 clock
            end if;
        end if;           --fastclk
    end process p_main;


end Behavioral;
