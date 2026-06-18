----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 12.08.2024 17:02:48
-- Design Name: 
-- Module Name: serialtrace - Behavioral
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
-- reset cmd YBXQZ
--
--List of frame types that this module can send:
--0x41 (A) : display frame. Length:
--0x42 (B) : display frame. Length:
--0x51 (Q) : mem dump 1K bytes.
--0x52 (R) : ram/nvram dump 128 bytes.
--0x53 (S) : switch matrix.
--0x59 (Y) : display IOs
----------------------------------------------------------------------------------

--return frame id values:
--X"40"   @ for reporting a reset and cause
--X"41"   A for running frame
--X"51"
--X"52"   R for memory dump
--X"59"   Y for second running frame (PA, etc...)
--X"5B"   [ for a trace data

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
library UNISIM;
use UNISIM.VComponents.all;

use work.common.all;


entity serialtrace is
    Port ( 
           hiclk            : in     STD_LOGIC;

           
		   TXp              : out    STD_LOGIC;  
		   RXp              : in     STD_LOGIC;  
		   
           Digit_Z101_b     : in     STD_LOGIC_VECTOR (7 downto 0);
           Digit_Z102_b     : in     STD_LOGIC_VECTOR (7 downto 0);
           Digit_Z103_b     : in     STD_LOGIC_VECTOR (7 downto 0);
           Digit_Z104_b     : in     STD_LOGIC_VECTOR (7 downto 0);
           Digit_Z400_b     : in     STD_LOGIC_VECTOR (7 downto 0);
           Digit_Z401_b     : in     STD_LOGIC_VECTOR (7 downto 0);
           Digit_Z402_b     : in     STD_LOGIC_VECTOR (7 downto 0);
           CR40x_b          : in     STD_LOGIC_VECTOR (7 downto 0);
           
           r_BitSwitches    : in     t_BitSwitches;

           PA               : in     STD_LOGIC_VECTOR (7 downto 0);
           PB               : in     STD_LOGIC_VECTOR (7 downto 0);
           PC               : in     STD_LOGIC_VECTOR (7 downto 0);
           PD               : in     STD_LOGIC_VECTOR (7 downto 0);
           
           ram_req          : out    std_logic;
           ram_addr         : out    STD_LOGIC_VECTOR (7 downto 0);
           ram_data         : in     STD_LOGIC_VECTOR (7 downto 0);
           ram_type         : out    std_logic;                     -- '0' RAM, '1' NVRAM
           
           sm_simul         : out    boolean;
           sw_sig           : out    std_logic;
           sw_strb          : out    std_logic_vector(7 downto 0);
           sw_ret           : out    std_logic_vector(7 downto 0);
           sw_timer         : out    std_logic_vector(7 downto 0);

           trc_is_empty     : in     std_logic;
           trc_sig_out      : out    std_logic;
           trc_dout         : in     std_logic_vector(23 downto 0);
           
           soft_reset_sig   : out    std_logic;
           
           status           : out    STD_LOGIC_VECTOR (7 downto 0)
           );

end serialtrace;

architecture Behavioral of serialtrace is

component uart_tx is
 generic (
	g_CLKS_PER_BIT : integer := 2604   -- Needs to be set correctly
	);
 port (
	i_clk       : in  std_logic;
	i_tx_dv     : in  std_logic;
	i_tx_byte   : in  std_logic_vector(7 downto 0);
	o_tx_active : out std_logic;
	o_tx_serial : out std_logic;
	o_tx_done   : out std_logic
	);
end component uart_tx;


component uart_rx is
 generic (
	g_CLKS_PER_BIT : integer := 2604   -- i.e. 19200bauds if clock at 50MHz Needs to be set correctly
	);
 port (
	i_clk       : in  std_logic;
	i_rx_serial : in  std_logic;
	o_rx_dv     : out std_logic;
	o_rx_byte   : out std_logic_vector(7 downto 0)
	);
end component uart_rx;
 

--uart sigs
-- constant c_CLKS_PER_BIT : integer := 2604;  --19200 bauds
-- constant c_CLKS_PER_BIT : integer := 434;      --115200 bauds
constant c_CLKS_PER_BIT : integer := 167;      --300000 bauds
--for tx
signal r_TX_DV     : std_logic := '0';    -- command start transmitting
signal r_TX_BYTE   : std_logic_vector(7 downto 0); -- byte to send
signal w_TX_DONE   : std_logic := '0';  -- rises when finished
signal w_TX_BUSY   : std_logic := '0';  -- 0 TX if available, 1 otherwise
--for rx
signal w_RX_DV     : std_logic := '0';  --signal a byte received (stay 1 for 4 ticks)
signal w_RX_BYTE   : std_logic_vector(7 downto 0); -- byte read

--rx command is 3-byte long
type t_RxCmd is array (0 to 3) of std_logic_vector(7 downto 0);
signal RX_CMD      : t_RxCmd := (X"00", X"00", X"00", X"00");
signal NEW_CMD4    : boolean := false;



-- status for rx cmds
signal status_int : std_logic_vector(7 downto 0) := X"02"; -- light off by default

-- signals for handling rx cmds
signal sig_dram        : std_logic := '0'; --start ram dump signal. Set for 1 phi after cmd sent from uart
signal nvr_dump_on     : boolean   := false;  --this dump is activated

-- debug tracer
signal trc_dump_on     : boolean   := false;  --this dump is activated

-- signals for handling simple cmds
signal sig_dcmd        : std_logic := '0'; --start ram dump signal. Set for 1 phi after cmd sent from uart
signal dcmd_on         : boolean   := false;  --this dump is activated

-- signals for handling  cmds that are exclusive with rspect to time frames
signal sig_dcmd_excl   : std_logic := '0'; --start ram dump signal. Set for 1 phi after cmd sent from uart
signal dcmd_on_excl    : boolean   := false;  --this dump is activated

-- signals for handling simple cmds
signal sig_swsim       : std_logic := '0'; --start ram dump signal. Set for 1 phi after cmd sent from uart


signal bckdr_addr_int   : STD_LOGIC_VECTOR(7 DOWNTO 0);   -- address to be selected in the ram space
signal bckdr_rx_req_int : std_logic := '0';


signal soft_reset_int   : std_logic := '0';


signal sm_simul_int     : boolean   := false;

signal trc_sig_out_int  : std_logic := '0';
--unique identificator 
constant swuuid         : std_logic_vector(63 downto 0) := X"000000000AECE153";  
begin


-- permanent associations
    status       <= status_int;
    ram_req      <= bckdr_rx_req_int;
    ram_addr     <= bckdr_addr_int;
    sm_simul     <= sm_simul_int;     --uart cmd to modify this 
-- permanent associations for sw_sig
    sw_sig       <= sig_swsim;

--
    soft_reset_sig <= soft_reset_int;

--
    trc_sig_out <= trc_sig_out_int;
    
    
        
-- Instantiate UART receiver
UART_RX_INST : uart_rx
generic map (
  g_CLKS_PER_BIT => c_CLKS_PER_BIT
  )
port map (
  i_clk       => hiclk,
  i_rx_serial => RXp,        -- port rx
  o_rx_dv     => w_RX_DV,    -- byte receive complete
  o_rx_byte   => w_RX_BYTE   -- byte to read
  );


-- Instantiate UART transmitter
UART_TX_INST : uart_tx
generic map (
  g_CLKS_PER_BIT => c_CLKS_PER_BIT
  )
port map (
  i_clk       => hiclk,
  i_tx_dv     => r_TX_DV,    -- command start transmitting
  i_tx_byte   => r_TX_BYTE,  -- byte to send
  o_tx_active => w_TX_BUSY,  -- on s'en fout c'est l'image des bits a transmettre
  o_tx_serial => TXp,        -- port tx
  o_tx_done   => w_TX_DONE   -- rises when finished (lasts 1 ticks by def)
  );


p_main_wx:	process (hiclk)
        variable  delay       : natural range  0 to 16777215 := 0; 
        variable  dspldump_on : boolean := false;
        variable  numbyt_dspl : integer range 0 to 63   := 0;
	    variable  numbyt_dr   : natural range 0 to 2047 := 0;  -- dedicated to nvram dump
	    variable  tr_byte_rank: natural range 0 to 7    := 0;
	    variable  st_seq_dram : natural range 0 to 63   := 0;  -- state machine for dumping a ram
	    variable  st_seq_dcmd : natural range 0 to 63   := 0;  -- state machine for dumping a ram
	    variable  st_seq_uart : natural range 0 to 63   := 0;  -- state machine for dumping a ram

        variable  mem_sz      : natural range 0 to 1024;    -- actually 128 | 1024, for now
        
        variable digit_idx    : natural range 0 to 15;
        
        --intern variable to manage reset/reprog case.
        variable  rootcause   : std_logic_vector(7 downto 0);
        
        variable  last_spo    : std_logic := '0';
        variable  statusSig   : std_logic := '0';
	begin
        if rising_edge(hiclk) then
            
            if     sig_dram = '1' then
                nvr_dump_on <= true;
            elsif sig_dcmd = '1' then
                dcmd_on    <= true;
            elsif sig_dcmd_excl = '1' then
                dcmd_on_excl    <= true;
            elsif trc_is_empty = '0' then
                trc_dump_on <= true;
            end if;
        
        
            
        
            if w_TX_DONE  = '1' then
                r_TX_DV <= '0';
            end if;

            --manage the 100ms tick for displ frames
            delay := delay+1;
            if delay > 5000000 then
                delay  := 0;
                --ram dumping command has priority over time frames
                if nvr_dump_on = false and dcmd_on = false then
                    dspldump_on := true;
                end if;
            end if;
            
--            if delay = 5000000/2 then
--                nvr_dump_on <= true;
--            end if;
            
            if dspldump_on = true then
                if r_TX_DV = '0' then
                    case numbyt_dspl is
                        when 0      =>
                            r_TX_DV <= '1'; --say uart is busy	
                            r_TX_BYTE <= X"41";  --code of 'A' for display running frame
                            numbyt_dspl := numbyt_dspl+1; --we added the first byte lately, thus the value "30"...       
                        when 1      =>
                            r_TX_DV <= '1'; --say uart is busy	
                            --r_TX_BYTE <= "0000"&Digit_Z101;  
                            r_TX_BYTE <= Digit_Z101_b;  
                            numbyt_dspl := numbyt_dspl+1;  
                        when 2      =>
                            r_TX_DV <= '1'; --say uart is busy	
                            --r_TX_BYTE <= "0000"&Digit_Z102;  
                            r_TX_BYTE <= Digit_Z102_b;  
                            numbyt_dspl := numbyt_dspl+1;  
                        when 3      =>
                            r_TX_DV <= '1'; --say uart is busy	
                            --r_TX_BYTE <= "0000"&Digit_Z103;  
                            r_TX_BYTE <= Digit_Z103_b;  
                            numbyt_dspl := numbyt_dspl+1;  
                        when 4      =>
                            r_TX_DV <= '1'; --say uart is busy	
                            --r_TX_BYTE <= "0000"&Digit_Z104;  
                            r_TX_BYTE <= Digit_Z104_b;  
                            numbyt_dspl := numbyt_dspl+1;  
                        when 5      =>
                            r_TX_DV <= '1'; --say uart is busy	
                            --r_TX_BYTE <= "0000"&Digit_Z400;  
                            r_TX_BYTE <= Digit_Z400_b;  
                            numbyt_dspl := numbyt_dspl+1;  
                        when 6      =>
                            r_TX_DV <= '1'; --say uart is busy	
                            --r_TX_BYTE <= "0000"&Digit_Z401;  
                            r_TX_BYTE <= Digit_Z401_b;  
                            numbyt_dspl := numbyt_dspl+1;  
                        when 7      =>
                            r_TX_DV <= '1'; --say uart is busy	
                            --r_TX_BYTE <= "0000"&Digit_Z402;  
                            r_TX_BYTE <= Digit_Z402_b;  
                            numbyt_dspl := numbyt_dspl+1;  
                        when 8 to 17 =>
                            r_TX_DV <= '1'; --say uart is busy	
                            r_TX_BYTE <= r_BitSwitches(numbyt_dspl-8);  
                            numbyt_dspl := numbyt_dspl+1;  

                        when 18       =>
                            r_TX_DV <= '1'; --say uart is busy	
                            r_TX_BYTE <= X"59";  --code of 'Y' for display IOs (32-byte frame)
                            numbyt_dspl := numbyt_dspl+1; 
                         when 19      =>
                            r_TX_DV <= '1'; --say uart is busy	
                            r_TX_BYTE <= PA;  
                            numbyt_dspl := numbyt_dspl+1;  
                         when 20      =>
                            r_TX_DV <= '1'; --say uart is busy	
                            r_TX_BYTE <= PB;  
                            numbyt_dspl := numbyt_dspl+1;  
                         when 21      =>
                            r_TX_DV <= '1'; --say uart is busy	
                            r_TX_BYTE <= PC;  
                            numbyt_dspl := numbyt_dspl+1;  
                         when 22      =>
                            r_TX_DV <= '1'; --say uart is busy	
                            r_TX_BYTE <= PD;  
                            numbyt_dspl := numbyt_dspl+1;  
                        when 23      =>
                            r_TX_DV <= '1'; --say uart is busy	
                            r_TX_BYTE <= CR40x_b;  
                            numbyt_dspl := numbyt_dspl+1;  
                           
                        when others =>
                            dspldump_on := false;
                            numbyt_dspl := 0;
                       
                    end case;
                 end if;  --endif r_TX_DV=0
              end if;    --endif dspldump_on=true
          
        if dcmd_on_excl = true then
            case RX_CMD(0) is
  
                
                --soft reset or reprog mode
                when X"42"   =>
                     case st_seq_dcmd is
                        when 0       =>
                            --is it XQZ? (soft reset)
                            if    RX_CMD(1) = X"58" and RX_CMD(2) = X"51" and RX_CMD(3) = X"5A" then
                                soft_reset_int <= '1';
                                st_seq_dcmd := 2;    --end of story, resets reset signal
                           --is it XQR? (reprog mode)
                            elsif RX_CMD(1) = X"58" and RX_CMD(2) = X"51" and RX_CMD(3) = X"52" then
                                soft_reset_int <= '1';
                                st_seq_dcmd := 1;    --end of story, leaves reset signal in active state
                            else
                            --illlegal request
                                soft_reset_int <= '0';
                                st_seq_dcmd := 2;    --end of story, resets reset signal
                            end if;
                        when 1       => 
                            --ok cmd done, stay in reprog mode
                            soft_reset_int <= '1';
                            dcmd_on_excl <= false;
                            st_seq_dcmd := 0;                        
                        when others  =>
                            soft_reset_int <= '0';
                            dcmd_on_excl <= false;
                            st_seq_dcmd := 0;
                    end case;   
                                                 

                when others  =>
                    dcmd_on_excl <= false;
                
            end case;
        end if;

        if dcmd_on = true     and dspldump_on = false then
            case RX_CMD(0) is
------added for acknowleged reset
                --soft reset or reprog mode
                when X"43"   =>
                     case st_seq_dcmd is
                        when 0       =>
                            --is it XQZ? (soft reset)
                            if    RX_CMD(1) = X"58" and RX_CMD(2) = X"51" and RX_CMD(3) = X"5A" then
                                soft_reset_int <= '1';
                                st_seq_dcmd := 2;    --end of story, resets reset signal
                           --is it XQR? (reprog mode)
                            elsif RX_CMD(1) = X"58" and RX_CMD(2) = X"51" and RX_CMD(3) = X"52" then
                                soft_reset_int <= '1';
                                st_seq_dcmd := 1;    --end of story, leaves reset signal in active state
                           --is it XQ0? (force output mode)
                            elsif RX_CMD(1) = X"58" and RX_CMD(2) = X"51" and RX_CMD(3) = X"30" then
                                soft_reset_int <= '0';
                                st_seq_dcmd := 3;    --end of story, leaves reset signal in active state
                            --go to switch matrix simulation mode
                            elsif RX_CMD(1) = X"58" and RX_CMD(2) = X"51" and RX_CMD(3) = X"31" then
                                sm_simul_int <= true;
                                st_seq_dcmd := 3;    --end of story, leaves reset signal in active state
                            --exit switch matrix simulation mode
                            elsif RX_CMD(1) = X"58" and RX_CMD(2) = X"51" and RX_CMD(3) = X"32" then
                                sm_simul_int <= false;
                                st_seq_dcmd := 3;    --end of story, leaves reset signal in active state
                            else
                            --illlegal request
                                soft_reset_int <= '0';
                                st_seq_dcmd := 4;    --end of story, resets reset signal
                            end if;
                        when 1       => 
                            --ok cmd done, stay in reprog mode
                            soft_reset_int <= '1';
                            rootcause := "00000001"; --mark reprog origin
                            st_seq_dcmd := 5;                        
                            --superMode <= "00";
                        when 2       =>
                            soft_reset_int <= '0';
                            rootcause := "00000010"; --mark reset origin
                            st_seq_dcmd := 5;
                            st_seq_uart := 0;
                            --superMode <= "00";
                            
                        when 3       =>
                            soft_reset_int <= '0';
                            rootcause := "00000100"; --mark super mode origin
                            st_seq_dcmd := 5;
                            st_seq_uart := 0;
                            
                        when 4       =>
                            soft_reset_int <= '0';
                            rootcause := "00001000"; --mark super mode origin
                            st_seq_dcmd := 5;
                            st_seq_uart := 0;
                            
                        when 5      =>    
                            st_seq_dcmd := 6;
                            st_seq_uart := 0;
                        when 6       =>   
                            --we are done; we now print the result
                            if r_TX_DV = '0' then
                                case st_seq_uart is
                                    when 0      =>
                                        r_TX_DV   <= '1';     --say uart is busy	
                                        r_TX_BYTE <= X"40";   --code of '@' for ack reset or reprog
                                        st_seq_uart := 1;
                                    when 1      => 
                                        r_TX_DV   <= '1';     --say uart is busy	
                                        r_TX_BYTE <= X"C4";  --ccc-companion
                                        st_seq_uart := 2;
                                    when 2      => 
                                        r_TX_DV   <= '1';     --say uart is busy	
                                        r_TX_BYTE <= RX_CMD(3);  --last byte of the command string
                                        --r_TX_BYTE <= rootcause;  --
                                        st_seq_uart := 3;
--                                    when 3      => 
--                                        r_TX_DV   <= '1';     --say uart is busy	
--                                        r_TX_BYTE <= DIP_SW;  --
--                                        st_seq_uart := 4;
                                    when others =>
                                        dcmd_on <= false;
                                        st_seq_dcmd := 0;
                                        numbyt_dr   := 0;
                                end case;  --st_seq_uart
                            end if;                            
                                                 
                        when others =>  --illegal to reach here        
                                dcmd_on <= false;
                                st_seq_dcmd := 0;
                                numbyt_dr   := 0;
                    
                    end case;   
                         
------end of acknowledgeed reset

--
                            
                when others  =>
                    dcmd_on <= false;
                    st_seq_dcmd := 0;
                    numbyt_dr   := 0;
                
            end case;
         end if;
         
        --tempo, trace display
        if trc_dump_on = true and dspldump_on = false and trc_is_empty = '0' then
            if r_TX_DV = '0' then
                if tr_byte_rank = 0 then 
                    r_TX_DV        <= '1';     --say uart is busy	
                    r_TX_BYTE      <= X"5B";  --code of '[' 
                    tr_byte_rank   := 1;
                    trc_sig_out_int<= '1';
                elsif tr_byte_rank = 1 then
                    r_TX_DV        <= '1';     --say uart is busy	
                    r_TX_BYTE      <= trc_dout(7 downto 0);   
                    tr_byte_rank   := 2;
                    trc_sig_out_int<= '0';
                elsif tr_byte_rank = 2 then
                    r_TX_DV        <= '1';     --say uart is busy	
                    r_TX_BYTE      <= trc_dout(15 downto 8);   
                    tr_byte_rank   := 3;
                elsif tr_byte_rank = 3 then
                    r_TX_DV        <= '1';     --say uart is busy	
                    r_TX_BYTE      <= trc_dout(23 downto 16);   
                    tr_byte_rank   := 0;
                    trc_dump_on    <= false;
                end if;
            end if;
        end if;
        --end tempo
        --command 0x52xyzt triggers nvr_dump_on
        if nvr_dump_on = true and dspldump_on = false then
            if r_TX_DV = '0' then
                if numbyt_dr = 0 then
                    r_TX_DV        <= '1';     --say uart is busy	
                    mem_sz := 256;
                    r_TX_BYTE      <= X"52";  --code of 'R' 
 
                    numbyt_dr   := 1;
                    st_seq_dram := 0;
                    
                    bckdr_addr_int   <= (others => '0'); --we will range from 0 to 127
                    bckdr_rx_req_int <= '0';  --maybe superfluous, or maybe not (for first time, it maybe not init)    

                    --following line requires VHDL2008
                elsif numbyt_dr <= mem_sz then
                    case st_seq_dram is 
                        when 0     =>
                            --request byte at addr bckdr_addr from device bckdr_r_device
                            bckdr_rx_req_int <= '1';
                            --bckdr_addr_int   <= (others => '0'); --we will range from 0 to 127
                            st_seq_dram := 1;
                        when 1     =>
                            --wait for answer from the dumper device
                            r_TX_BYTE <= ram_data;
                            bckdr_rx_req_int   <= '0';   --rearm signal
                            r_TX_DV   <= '1'; --say uart is busy	
                            numbyt_dr := numbyt_dr + 1;
                            st_seq_dram := 0; 
                            bckdr_addr_int  <= std_logic_vector( unsigned(bckdr_addr_int) + 1 );
                        when others =>
                            st_seq_dram := 0; -- should not get here 
                            bckdr_rx_req_int <= '0';                              
                    end case;
                else
                    nvr_dump_on <= false;
                    numbyt_dr   := 0;
                    mem_sz      := 0;   --useless, but just to make sure
                    bckdr_rx_req_int <= '0';                              
                    st_seq_dram := 0; -- should not get here
                end if;            
            end if;
        end if;
        if trc_sig_out_int = '1' then
            trc_sig_out_int <= '0';
        end if;    
      end if; --endif rising_edge(hiclk)
   end process p_main_wx;

--RX handling
-- Every command is 1+3 bytes long (from 2024-08-12)
-- First byte is a sync byte and must be X"59", aka 'Y'
p_main_rx:	 process (hiclk)
	   variable lastw_RX_DV : std_logic := '0';
	   variable byte_num    : natural range 0 to 7 := 0;
	 begin
        if rising_edge(hiclk) then
			if w_RX_DV = '1' and lastw_RX_DV = '0' then      --the driver keeps this signal to 1 for 4 ticks
                --sync byte for making sure to start on frame start
                if byte_num = 0 then
                    if w_RX_BYTE = X"59" then
                        byte_num := 1;
                    end if;
                elsif byte_num = 4 then
                    RX_CMD(3) <= w_RX_BYTE;
                    byte_num := 0;
                    NEW_CMD4  <= true;   --1 tick signal to tell there is a new command
                else
                    RX_CMD(byte_num-1) <= w_RX_BYTE;
                    byte_num := byte_num + 1;
                end if;    
			end if;	                   --where it is managed only at CMD transition
			lastw_RX_DV := w_RX_DV;
			if NEW_CMD4 = true then
			    NEW_CMD4 <= false;
			end if;
	    end if;
	 end process p_main_rx;

--Incoming Command processing
p_rx_handle:     process(hiclk)
     begin
        if rising_edge(hiclk) then
            if NEW_CMD4 = true then
                case RX_CMD(0) is
                    --'Q' 0x51, for setting forced values in supervisor mode
                    --the command is XYZT: X='Q', 
                    --                     Y=0=>display A, 
                    --                     Z=abcdefgh: abcd: ieme digit, efgh: digit value
                    --                     T=don't care
                    --return: no ack
                    when X"51"     =>
                       status_int <= X"51";
                       sig_dcmd_excl <= '1';
                       
                    --'R' 0x52, for reading full ram (one of config, sys, miniprn
                    --the command is XYZT: X='R', 
                    --                     Y=0|1|2 type of ram to be read
                    --                     Z=don't care
                    --                     T=don't care
                    --return: 82+128 bytes of the given ram
                    when X"52"     =>
                       status_int <= X"52";
                       sig_dram <= '1';
                       ram_type <= RX_CMD(1)(0);
                    --'S' 0x53, for simulating a switch closing
                    --the command is XYZT: X='S', 
                    --                     Y=strobe code on which to trigger
                    --                     Z=return value 
                    --                     T=timer code
                    when X"53"     =>
                       status_int <= X"53";
                       sig_swsim <= '1';
                       sw_strb   <= RX_CMD(1);
                       sw_ret    <= RX_CMD(2);
                       sw_timer  <= RX_CMD(3);
                       
                    --'W' 0x57, for writing a byte to given address
                    --this command does not flash the result to iic
                    --there is another command for flashing
                    --the command is XYZT: X='W', 
                    --                     Y low nibble:
                    --                     Y=0|1|2|4|5 type of ram to be read
                    --                     0,1,2 for hmsys rams (sysconf, mnprn, nvram)
                    --                     4,5   for game prom and A1762 version
                    --                     Y high nibble is address high (for A17s space roms)
                    --                     Z=adress in range 0..127 (for hmsys) or 0..255 for game proms
                    --                     T=byte to write
                    when X"57"     =>
                       status_int    <= X"57";
                       sig_dcmd_excl <= '1';
                       
                    --'B' 0x42, for soft reset
                    --the command is BXQZ for soft reset
                    --the command is BXQR for going into reprog mode
                    --
                    when X"42"     =>
                       status_int    <= X"42";
                       sig_dcmd_excl <= '1';
                       
                    --'C' 0x43, for soft reset with acknowledge
                    --the command is CXQZ for soft reset
                    --the command is CXQR for going into reprog mode
                    --the command is CXQ0 for display overlay
                    --the command is CXQ1 for going to simulated switch matrix
                    --the command is CXQ2 for going back to real switch matrix
                    --The ack reply is @<src><sw ident> (@ is 0x40)
                    when X"43"     =>
                       status_int    <= X"43";
                       sig_dcmd <= '1';

                    --'D' 0x44, for getting dip switch
                    --the command is DXXX 
                    --
                    --The  reply is E<dip_sw>
                    when X"44"     =>
                       status_int    <= X"44";
                       sig_dcmd <= '1';
                       
                    --'F' 0x46, for flashing ram (one of config, sys, miniprn)
                    --the command is XYZT: X='F', 
                    --                     Y=0|1|2 type of ram to be read
                    --                     Z=don't care
                    --                     T=don't care
                    when X"46"     =>
                       status_int    <= X"46";
                       sig_dcmd_excl <= '1';
                     
                    --'Z' 0x5A, for getting fletcher crc 
                    --the command is XYZT: X='Z', 
                    --                     Y=0|1|2|4|5 type of ram to be checked
                    --                     Z=n where 2^n is the dataspan to control
                    --                     T=don't care
                    when X"5A"     =>
                       status_int <= X"5A";
                       sig_dcmd   <= '1';
                     
                    when others    =>
                        status_int <= X"FF";
                end case;

            end if;
            
            --signal is at 1 for only 1 tick
            if sig_dram = '1' then
                sig_dram  <= '0';
            end if;
            if sig_dcmd = '1' then
                sig_dcmd  <= '0';
            end if;
            if sig_dcmd_excl = '1' then
                sig_dcmd_excl  <= '0';
            end if;
            if sig_swsim = '1' then
                sig_swsim  <= '0';
            end if;
            
        end if;
     end process p_rx_handle;




     
end Behavioral;
