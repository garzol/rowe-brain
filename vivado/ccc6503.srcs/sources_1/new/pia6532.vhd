----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02.05.2026 14:58:54
-- Design Name: 
-- Module Name: piax - Behavioral
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

entity pia6532 is
  Port ( 
       clk         : in     STD_LOGIC;
       nReset      : in     STD_LOGIC;
       nCs         : in     STD_LOGIC;
       nRW         : in     STD_LOGIC;
       A0          : in     STD_LOGIC;     --0 for output register, 1 for DDRX
       Port_X      : inout  STD_LOGIC_VECTOR(7 DOWNTO 0);
       d_i         : in     STD_LOGIC_VECTOR(7 DOWNTO 0);
       d_o         : out    STD_LOGIC_VECTOR(7 DOWNTO 0)
);
end pia6532;

architecture Behavioral of pia6532 is
--Direction of port bits
constant cINPUT     : std_logic := '0';
constant cOUTPUT    : std_logic := '1';

--A0 register selection
constant cA0DDRSel    : std_logic := '1';
constant cA0ODRSel    : std_logic := '0';

--Data Direction Register (0=As Input, 1=As Output
signal DDRX        : std_logic_vector(7 downto 0) := (others=>cINPUT);
--Data Register
signal DRX         : std_logic_vector(7 downto 0) := (others=>'1');

begin

PORT_SETTING : for i in DDRX'range generate
    PORT_X(i) <= DRX(i) when DDRX(i) = cOUTPUT else
                 'Z';                
end generate PORT_SETTING;

p_main : process(clk)
    begin
        if (rising_edge(clk)) then
            if nReset = '0' then
                --reset everything
                DDRX <= (others=>cINPUT);
                DRX  <= (others=>'1');
                d_o <= (others=>'Z');
            else
                if nCS = '0' then
                    if nRW = '1' then
                        --The CPU wants to read
                        if A0 = cA0DDRSel then
                            d_o <= DDRX;
                        else
                            -- d_o <= DRX;
                            d_o <= PORT_X;
                        end if;
                    else
                        d_o <= (others=>'Z');
                        --The CPU wants to write
                        if A0 = cA0DDRSel then
                            DDRX <= d_i;
                        else
                            DRX  <= d_i;
                        end if;
                    end if;
                else      --nCS
                    d_o <= (others=>'Z');    
                end if;
            end if;
        end if;
    end process p_main;


end Behavioral;
