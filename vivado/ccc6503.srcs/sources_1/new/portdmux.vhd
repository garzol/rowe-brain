----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 29.05.2026 10:10:41
-- Design Name: 
-- Module Name: portdmux - Behavioral
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

use work.common.all;
use work.lib6520.all;    

entity portdmux is
  Port ( 
       clk         : in     STD_LOGIC;
       nReset      : in     STD_LOGIC;
       nCs         : in     STD_LOGIC;
       nRW         : in     STD_LOGIC;
       RS0         : in     STD_LOGIC;     
       Port_D      : inout  STD_LOGIC_VECTOR(7 DOWNTO 0);
       d_i         : in     STD_LOGIC_VECTOR(7 DOWNTO 0);
       d_o         : out    STD_LOGIC_VECTOR(7 DOWNTO 0);
       
       c_strobe    : in     STD_LOGIC_VECTOR(3 downto 0); --from Port_C_int(3 downto 0)
       PA5         : in     STD_LOGIC;     
       sm_simul    : in     boolean;
       BitSwitches : in     t_BitSwitches

);
end portdmux;

architecture Behavioral of portdmux is



signal Port_D_mux  : STD_LOGIC_VECTOR(7 DOWNTO 0);

--Direction of port bits
constant cINPUT     : std_logic := '0';
constant cOUTPUT    : std_logic := '1';

--bit2 in CRA register selection
constant cDDRSel    : std_logic := '0';
constant cORXSel    : std_logic := '1';

--Data Direction Register (0=As Input, 1=As Output
signal DDRX        : std_logic_vector(7 downto 0) := (others=>cINPUT);
--Output Register
signal PORX        : std_logic_vector(7 downto 0) := (others=>'1');
--Control Register
signal CRX         : std_logic_vector(7 downto 0) := (others=>'1');

--ctrl sig
signal opMode      : std_logic_vector(1 downto 0);
begin



   
PORT_SETTING_A : for i in DDRX'range generate
    PORT_D(i) <= '0' when (DDRX(i) = cOUTPUT and PORX(i) = '0') else
                 'Z';                
end generate PORT_SETTING_A;

opMode <= RS0&nRW;

p_main : process(clk)
    begin
        if (rising_edge(clk)) then
            if nReset = '0' then
                --reset everything
                DDRX  <= (others=>cINPUT);
                PORX  <= (others=>'Z');
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
                                --read PORD

                                d_o <= Port_D_mux;

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



--Port_D <= Port_D_mux;

--port D
    process (clk)
        variable cur_strobe     : std_logic_vector(3 downto 0);
        variable delay_sample   : natural range 0 to 511 := 0;
        variable last_strb      : std_logic_vector(3 downto 0);
        constant c_delay_sample : natural  := 10;
        variable strobnum       : integer range 0 to 9;	
    begin
        if (rising_edge(clk)) then
            if nReset = '0' then
                Port_D_mux <= Port_D;
                --Port_D     <= (others=>'Z');
                last_strb  := "1111";  --impossible value
            else            
                cur_strobe    := c_strobe; --Port_C_int(3 downto 0);                      
                strobnum    := to_integer(unsigned(cur_strobe));
                if sm_simul = true then

                    if PA5 = '0' then -- Port_A_int(5) --Returns are Hi-Z
                        delay_sample := 0;
                        Port_D_mux <= Port_D;
                        --Port_D     <= Port_D_mux;
                    else              --Returns are applied to port D
                        --strobnum    := to_integer(unsigned(cur_strobe));
                          if strobnum = 0 then
                                for R in 6 downto 0 loop
                                    Port_D_mux(R)   <=  Port_D(R) and (not BitSwitches(strobnum)(R));
                                    --Port_D_mux(R)   <=  Port_D(R);
                                    --Port_D(R)          <= Port_D_mux(R);
                                end loop;  
                                Port_D_mux(7)           <=   (not BitSwitches(strobnum)(7));
                          else
                                for R in 7 downto 0 loop
                                    Port_D_mux(R)   <=  Port_D(R) and (not BitSwitches(strobnum)(R));
                                    --Port_D_mux(R)   <=  Port_D(R);
                                    --Port_D(R)          <= Port_D_mux(R);
                                end loop;  
                          end if;     
--                        for R in 7 downto 0 loop
--                            Port_D_mux(R)   <=  Port_D(R) and (not BitSwitches(strobnum)(R));
--                            --Port_D_mux(R)   <=  Port_D(R);
--                            --Port_D(R)          <= Port_D_mux(R);
--                        end loop;  
             
                    end if;     --end if Port_A_int(5) = '0' else
                    --last_strb := cur_strobe;                        
                    
                else  --this is not sm_simu, normal read port D as input
                    --debugT1 <= false;
                    --Port_D <= Port_D_mux;                           
                    Port_D_mux <= Port_D;
                end if;
                last_strb := cur_strobe;    
                
                
            end if;
        end if;
    end process;
    


end Behavioral;
