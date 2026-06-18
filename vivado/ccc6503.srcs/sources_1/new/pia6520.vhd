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
use work.lib6520.all;    -- list of error codes

entity pia6520 is
    generic (
       --A6520TYP to be used for port A (RS1=0)
       --B6520TYP to be used for port B (RS1=1)
       --Port A output does not force '1' to '1' if the output
       --is locked down by the outside 
       --Therefore:
       --1/ we modelized 1 out port A to actual Z, 
       --2/ read back from A to CPU reads actual port, while
       --   read back from B is done by reading its output register
       --3/ we've put light pull ups on port A. 
       
       g_piatyp : t_piatyp := A6520TYP
       );
  Port ( 
       clk         : in     STD_LOGIC;
       nReset      : in     STD_LOGIC;
       nCs         : in     STD_LOGIC;
       nRW         : in     STD_LOGIC;
       RS0         : in     STD_LOGIC;     
       Port_X      : inout  STD_LOGIC_VECTOR(7 DOWNTO 0);
       d_i         : in     STD_LOGIC_VECTOR(7 DOWNTO 0);
       d_o         : out    STD_LOGIC_VECTOR(7 DOWNTO 0)
);
end pia6520;

architecture Behavioral of pia6520 is
--Direction of port bits
constant cINPUT     : std_logic := '0';
constant cOUTPUT    : std_logic := '1';

--bit2 in CRA register selection
constant cDDRSel    : std_logic := '0';
constant cORXSel    : std_logic := '1';

--Data Direction Register (0=As Input, 1=As Output
signal DDRX        : std_logic_vector(7 downto 0) := (others=>cOUTPUT);
--Output Register
signal PORX        : std_logic_vector(7 downto 0) := (others=>'1');
--Control Register
signal CRX         : std_logic_vector(7 downto 0) := (others=>'1');

--ctrl sig
signal opMode      : std_logic_vector(1 downto 0);
begin
G_PORTTYP_B:
if g_piatyp = B6520TYP generate
    PORT_SETTING_B : for i in DDRX'range generate
        PORT_X(i) <= '1' when nReset = '0' else
                     PORX(i) when DDRX(i) = cOUTPUT else
                     'Z';                
    end generate PORT_SETTING_B;
end generate G_PORTTYP_B; 
   
G_PORTTYP_A:
if g_piatyp = A6520TYP generate
    PORT_SETTING_A : for i in DDRX'range generate
        PORT_X(i) <= '0' when (DDRX(i) = cOUTPUT and PORX(i) = '0') else
                     'Z';                
    end generate PORT_SETTING_A;
end generate G_PORTTYP_A;    

opMode <= RS0&nRW;

p_main : process(clk)
    begin
        if (rising_edge(clk)) then
            if nReset = '0' then
                --reset everything
                DDRX  <= (others=>cOUTPUT);
                PORX  <= (others=>'1');
                CRX   <= (others=>'0');
                d_o <= (others=>'Z');
            else
                if nCS = '0' then
                    case opMode is
                        when "00" =>
                            if CRX(2) = '1' then
                                --write ORX
                                PORX <= d_i;
                            else
                                --write DDRX
                                DDRX <= d_i;
                            end if;
                        when "01" =>
                            if CRX(2) = '1' then
                                --read PORX
                                --check what to do with the 2 options A/B 

                                if g_piatyp = A6520TYP then
                                    d_o <= Port_X;
                                else
                                    for i in DDRX'range loop
                                        if DDRX(i) = cOUTPUT then
                                            d_o(i) <= PORX(i);
                                        else
                                            d_o(i) <= PORT_X(i);
                                        end if;
                                    end loop;
                                end if;
                            else
                                --read DDRX
                                d_o <= DDRX;
                            end if;
                        when "10" =>
                            --write CRX
                            CRX <= d_i;
                        when "11" =>
                            --read CRX
                            d_o <= CRX;
                            
                        when others =>
                            --impossible landing here
                            null;
                    end case;
                        
                end if; --end if CS
            end if;     --end if reset
        end if;
    end process p_main;


end Behavioral;
