----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 14.03.2025 14:05:05
-- Design Name: 
-- Module Name: myramip - Behavioral
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

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY myramip IS
	GENERIC
	(
		ADDRESS_WIDTH	: integer := 4;
		DATA_WIDTH	    : integer := 8
	);
	PORT
	(
		nReset			: IN  std_logic;
		clock			: IN  std_logic;
		data			: IN  std_logic_vector(DATA_WIDTH - 1 DOWNTO 0);
		addr_A        	: IN  std_logic_vector(ADDRESS_WIDTH - 1 DOWNTO 0);
		addr_B       	: IN  std_logic_vector(ADDRESS_WIDTH - 1 DOWNTO 0);
		we			    : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
		q_A			    : OUT std_logic_vector(DATA_WIDTH - 1 DOWNTO 0);
		q_B			    : OUT std_logic_vector(DATA_WIDTH - 1 DOWNTO 0)
	);
END myramip;

ARCHITECTURE rtl OF myramip IS
	TYPE RAM IS ARRAY(0 TO 2 ** ADDRESS_WIDTH - 1) OF std_logic_vector(DATA_WIDTH - 1 DOWNTO 0);

	SIGNAL ram_block : RAM := (others=>(others=>'1'));
	
BEGIN
	PROCESS (clock)
	BEGIN
		IF (clock'event AND clock = '1') THEN
            IF nReset = '0' THEN  
--                for rami in 0 to (2 ** ADDRESS_WIDTH - 1) loop
--                    --ram_block(rami) <= std_logic_vector(to_unsigned(rami, DATA_WIDTH));
--                    ram_block(rami) <= X"55";
--                end loop;
                  null;
            ELSE
                IF (we(0) = '1') THEN
                    ram_block(to_integer(unsigned(addr_A))) <= data;
                END IF;
    
                q_A <= ram_block(to_integer(unsigned(addr_A)));
                q_B <= ram_block(to_integer(unsigned(addr_B)));
            END IF;
		END IF;
	END PROCESS;
END rtl;

