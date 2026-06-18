----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 14.08.2025 15:46:43
-- Design Name: 
-- Module Name: cccmain - Behavioral
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

--PA5=0 =>   Returns are Hi-Z
--PA5=1 =>   Returns=>PD (0->Hi-Z, 1->0)

--PA6=1 =>   NVRAM data HI-Z
--PA6=0 =>   NVRAM out

--PA7=0 =>   Write to NVRAM
--PA7=1 =>   Read

--PA4=0 =>   Segment out PD (0->seg on, 1->seg off)
--PA4=1 =>   Segment Hi-Z (or off)

--PA2   =>   Unused (NC)

--PA0   =>   TX
--PA1   =>   RX

--PA3   =>   input, battery OK/KO

--PB0   =>   Money Cntrl Signal       P105,7
--PB1   =>   N/A (NC)
--PB2   =>   Play Cntrl Signal        P105,8
--PB3   =>   Toggle Signal            P105,9
--PB4   =>   Turntable Mtr Signal     P105,13
--PB5   =>   Transfer Mtr Signal      P105,14
--PB6   =>   Magazine Mtr Signal      P105,15
--PB7   =>   Detent Signal            P105,16

-- PB5=1 => Timer's counter running, PB5=0 => Timer reset

--Q117  =>   Opt. SW Index            P105,10      S6,R7
--Q116  =>   Opt. SW Home             P105,11      S6,R6
--Q122  =>   Outer Cam N.O.           P105,6       S6,R4
--Q123  =>   Inner Cam N.O.           P105,5       S6,R5
--Q124  =>   +8 On Signal (*)         P105,2       S0,R7
--Q125  =>   Cancel Signal            P105,1       S0,R6
--Q111  =>   Internal 20/40mn timer                S5,R6

--S101 (Memorec reset)        : S4,R7
--S102 (Memorec advance)      : S4,R6

--S106 (Test)                 : S1,R7
--S107 (Standard/As Select.)  : S1,R6

--S104 (Clear selection mem.) : S2,R7
--S105 (Manual credit)        : S2,R6

--mapping R6500/1 Alternate
--2316 ROM  : 0..7F (A0..A10) CS<=A11
--6532 : CS<=/A6&/A11 RAM A7<=0, A6<=0
--6532 : CS<=/A6&/A11 PA A7<=1, A6<=0, A1<=0 
--6532 : CS<=/A6&/A11 PB A7<=1, A6<=0, A1<=1 
--6520 : CS<=A6&A7&/A11 RS0<=A0, RS1<A1 


--2316:       800..FFF
--6532 RAM  : 000..03F
--6532 DRA  : 080
--6532 DDRA : 081
--6532 DRB  : 082
--6532 DDRB : 083
--6532 Timer : write 95 (write timer divide by 8, disable interrupt)
--6532 Timer : read 85 (read interrupt flag register, bit 7 is timer)
--6520 PA    : 0C0, 0C1 (DDRA/ORA, CRA)
--6520 PB    : 0C2, 0C3 (DDRB/ORB, CRB)

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
use work.liberr.all;    -- list of error codes
use work.lib6520.all;    -- list of error codes

entity cccmain is
  Port ( 
             SYSCLK      : in     STD_LOGIC;
 
             
             nIsolPorts  : out    STD_LOGIC;  --0=isolated, 1=connected
             PA5Enable   : out    STD_LOGIC;  --0=PA5 is read as 1, 
                                              --1=PA5 passes through from 40pin-uP
             --

             Port_A      : inout  STD_LOGIC_VECTOR(7 DOWNTO 0);
             Port_B      : inout  STD_LOGIC_VECTOR(7 DOWNTO 0);
             Port_C      : inout  STD_LOGIC_VECTOR(7 DOWNTO 0);
             Port_D      : inout  STD_LOGIC_VECTOR(7 DOWNTO 0);  

			 VS0         : out STD_LOGIC; -- added HW V3. led control
			 VS1         : out STD_LOGIC; -- added HW V3. led control
			 VS2         : out STD_LOGIC; -- added HW V3. led control

             --rx tx for wifi
			 TXp         : out STD_LOGIC;  -- added HW V3 09/2022. Opt1_33    =fpga pin34 (IO_L05N_2).   pin A13
			 RXp         : in  STD_LOGIC;  -- added HW V3 03/2023. Optin4_33  =fpga pin39 (IP_2/VREF_2). pin A12
  
             Dot_Seg     : out STD_LOGIC;  --  ex PG1 (E11)
             --scl/sda of the core board
             SCL         : inout  STD_LOGIC;
             SDA         : inout  STD_LOGIC
  );
end cccmain;

architecture Behavioral of cccmain is

-- Component Declarations

    
COMPONENT ROMROWE
  PORT (
    clka : IN STD_LOGIC;
    ena : IN STD_LOGIC;
    addra : IN STD_LOGIC_VECTOR(10 DOWNTO 0);
    douta : OUT STD_LOGIC_VECTOR(7 DOWNTO 0) 
  );
END COMPONENT;
COMPONENT RAMROWE
  PORT (
    clka : IN STD_LOGIC;
    ena : IN STD_LOGIC;
    wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    addra : IN STD_LOGIC_VECTOR(5 DOWNTO 0);
    dina : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    douta : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    clkb : IN STD_LOGIC;
    enb : IN STD_LOGIC;
    web : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    addrb : IN STD_LOGIC_VECTOR(5 DOWNTO 0);
    dinb : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    doutb : OUT STD_LOGIC_VECTOR(7 DOWNTO 0) 
  );
END COMPONENT;
component ledctrl
    Port ( 
           hiclk       : in     STD_LOGIC;
           ErrCod      : in     std_logic_vector(7 downto 0);
           vs0         : out    STD_LOGIC;
           vs1         : out    STD_LOGIC;
           vs2         : out    STD_LOGIC);
end component;



COMPONENT myramip
  GENERIC ( 
 	ADDRESS_WIDTH	: integer;
	DATA_WIDTH	    : integer
  );
  PORT (
    nReset  : IN STD_LOGIC;
    clock   : IN STD_LOGIC;
    we      : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    addr_A  : IN  std_logic_vector(ADDRESS_WIDTH - 1 DOWNTO 0);
    addr_B  : IN  std_logic_vector(ADDRESS_WIDTH - 1 DOWNTO 0);
    data    : IN  std_logic_vector(DATA_WIDTH - 1 DOWNTO 0);
    q_A     : OUT std_logic_vector(DATA_WIDTH - 1 DOWNTO 0);
    q_B     : OUT std_logic_vector(DATA_WIDTH - 1 DOWNTO 0)
  );
END COMPONENT;

COMPONENT pia6532
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
end COMPONENT;

COMPONENT PIT6532
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
end COMPONENT;


COMPONENT pia6520
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
       
       g_piatyp : t_piatyp
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
end COMPONENT;

component serialtrace
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
           ram_type         : out    std_logic;
           
           sm_simul         : out    boolean;
           sw_sig           : out    std_logic;
           sw_strb          : out    std_logic_vector(7 downto 0);
           sw_ret           : out    std_logic_vector(7 downto 0);
           sw_timer         : out    std_logic_vector(7 downto 0);

           trc_is_empty     : in     std_logic;
           trc_sig_out      : out    std_logic;
           trc_dout         : in     std_logic_vector(23 downto 0);

           soft_reset_sig   : out    std_logic;
           
           status           : out    STD_LOGIC_VECTOR (7 downto 0));
end component;

COMPONENT DBGFIFO
  PORT (
    clk : IN STD_LOGIC;
    srst : IN STD_LOGIC;
    din : IN STD_LOGIC_VECTOR(23 DOWNTO 0);
    wr_en : IN STD_LOGIC;
    rd_en : IN STD_LOGIC;
    dout : OUT STD_LOGIC_VECTOR(23 DOWNTO 0);
    full : OUT STD_LOGIC;
    empty : OUT STD_LOGIC 
  );
END COMPONENT;

component portdmux 
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
       sm_simul    : in    boolean;
       BitSwitches : in     t_BitSwitches

);
end component;

signal Port_A_int      : std_logic_vector(7 downto 0);
signal Port_B_int      : std_logic_vector(7 downto 0);
signal Port_C_int      : std_logic_vector(7 downto 0);
signal Port_D_int      : std_logic_vector(7 downto 0);
signal Port_D_prime    : std_logic_vector(7 downto 0);

signal Digit_Z101_int  : std_logic_vector(3 downto 0);
signal Digit_Z102_int  : std_logic_vector(3 downto 0);
signal Digit_Z103_int  : std_logic_vector(3 downto 0);
signal Digit_Z104_int  : std_logic_vector(3 downto 0);
signal Digit_Z402_int  : std_logic_vector(3 downto 0);
signal Digit_Z401_int  : std_logic_vector(3 downto 0);
signal Digit_Z400_int  : std_logic_vector(3 downto 0);

signal Digit_Z101_b_int  : std_logic_vector(7 downto 0);
signal Digit_Z102_b_int  : std_logic_vector(7 downto 0);
signal Digit_Z103_b_int  : std_logic_vector(7 downto 0);
signal Digit_Z104_b_int  : std_logic_vector(7 downto 0);
signal Digit_Z402_b_int  : std_logic_vector(7 downto 0);
signal Digit_Z401_b_int  : std_logic_vector(7 downto 0);
signal Digit_Z400_b_int  : std_logic_vector(7 downto 0);

signal CR40x_int         : std_logic_vector(7 downto 0);


--10 strobes, 8 returns
--bit 7 : 1 it's an emulated switch - 0 it's a true switch
--6 downto 0 for the timer, 
type t_swmtx   is array (0 to 9, 0 to 7) of unsigned(6 downto 0);

signal r_BitSwitches_int        : t_BitSwitches := (others => (others => '0'));
signal r_BitSwitches_mux        : t_BitSwitches := (others => (others => '0'));
signal r_BitSwitches_simu_int   : t_BitSwitches := (others => (others => '0'));

--signal cur_strobe      : std_logic_vector(3 downto 0);
signal returns         : std_logic_vector(7 downto 0);
signal ErrCod          : std_logic_vector(7 downto 0) := (others=>'0');
signal tracer_status   : std_logic_vector(7 downto 0);

signal nReset          : std_logic := '0';
--nResetf is faster than nReset and only used for isolports
signal nResetf         : std_logic := '0';

signal CLK_DIV0        : unsigned (47 downto 0):=(others=>'0');

signal nvr_read_sig    : std_logic;
signal nvr_addr        : std_logic_vector(7 downto 0);
signal DUMP_DATA       : std_logic_vector(7 downto 0);


signal debugT1         : boolean := false;

signal sm_simul        : boolean := false;   --initialized to false by serialtrace.vhd
signal sw_sig          : std_logic;
signal sw_strb         : std_logic_vector(7 downto 0);
signal sw_ret          : std_logic_vector(7 downto 0);
signal sw_timer        : std_logic_vector(7 downto 0);

signal dump_ram_typ             : std_logic;
signal RAM_nRW                  : STD_LOGIC_VECTOR(0 DOWNTO 0) := "0";  --read by default
signal RAM_Addr_Latch           : std_logic_vector (7 downto 0);
signal RAM_Alt_Addr_Latch       : std_logic_vector (7 downto 0);
signal RAM_DOUT                 : STD_LOGIC_VECTOR(8 DOWNTO 1);
signal BCK_NVRAM_DOUT           : STD_LOGIC_VECTOR(8 DOWNTO 1);
signal RAM_DIN                  : STD_LOGIC_VECTOR(8 DOWNTO 1);

signal Port_NVRAM               : STD_LOGIC_VECTOR(8 DOWNTO 1);

signal Display_Mode             : std_logic_vector(1 downto 0);
signal Digit_Z101_test          : std_logic_vector(7 downto 0);
signal Digit_Z102_test          : std_logic_vector(7 downto 0);
signal Digit_Z103_test          : std_logic_vector(7 downto 0);
signal Digit_Z104_test          : std_logic_vector(7 downto 0);
--require a special cable to test this
signal Port_B_test              : std_logic_vector (7 downto 0);
signal S104_cnt                 : unsigned (3 downto 0) := "0101";

type t_Heure is array (0 to 3) of unsigned (3 downto 0);                               
signal Heure                    : t_Heure := ("0110", "0101", "0001", "0001"); --10h30 by default
signal sig_h_incr_a             : std_logic := '0';
signal sig_h_incr_b             : std_logic := '0';
signal sig_h_decr_a             : std_logic := '0';

signal state_s105               : unsigned (1 downto 0) := "00"; --00 off, 01 on, 10 long on, 11 super long on
signal state_s101               : unsigned (1 downto 0) := "00"; --00 off, 01 on, 10 long on, 11 super long on
signal state_s102               : unsigned (1 downto 0) := "00"; --00 off, 01 on, 10 long on, 11 super long on

type t_SM_Sample is (s_Idle, s_Sample0, s_Sample1, s_Complete);

type t_SegV16 is array (0 to 15) of std_logic_vector(6 downto 0); --abcdefg

signal bin2seg                   : t_SegV16 := ("0111111", --0
                                                "0000110", --1
                                                "1011011", --2
                                                "1001111", --3
                                                "1100110", --4
                                                "1101101", --5
                                                "1111101", --6
                                                "0000111", --7
                                                "1111111", --8
                                                "1101111", --9
                                                "1110111", --A
                                                "1111100", --b
                                                "0111001", --c
                                                "1011110", --d
                                                "1111001", --E
                                                "1110001");--F
                                                
                                                
                                                
signal  d_i         : std_logic_vector (7 downto 0);
signal  irq_n_i     : std_logic ;
signal  nmi_n_i     : std_logic ;
signal  rdy_i       : std_logic ;
signal  rst_rst_n_i : std_logic ;
signal  so_n_i      : std_logic ;
signal  a_o         : std_logic_vector (15 downto 0);
signal  d_o         : std_logic_vector (7 downto 0);
signal  rd_o        : std_logic ;
signal  sync_o      : std_logic ;
signal  wr_n_o      : std_logic ;
signal  wr_o        : std_logic ;

signal  SYSCLK6502  : std_logic := '0' ; --clock at 1MHz

signal  rom_o       : std_logic_vector (7 downto 0);
signal  ram_o       : std_logic_vector (7 downto 0);
signal  piaa_o      : std_logic_vector (7 downto 0);
signal  piab_o      : std_logic_vector (7 downto 0);
signal  piac_o      : std_logic_vector (7 downto 0);
signal  piad_o      : std_logic_vector (7 downto 0);
signal  pit_o       : std_logic_vector (7 downto 0);
signal  we_v        : std_logic_vector(0 downto 0);

signal timer_nCs    : std_logic;
signal pa_nCs       : std_logic;
signal pb_nCs       : std_logic;
signal pd_nCs       : std_logic;
signal pc_nCs       : std_logic;

signal count        : UNSIGNED(5 downto 0);

signal address_temp                 : std_logic_vector(23 downto 0);
signal reg_CPUaddress               : std_logic_vector(15 downto 0);
signal reg_CPUwe                    : std_logic;

signal debug_flag   : std_logic_vector(7 downto 0) := (others=>'0');

signal BCK_RAM0_DOUT: STD_LOGIC_VECTOR(8 DOWNTO 1);

signal trc_is_full  : std_logic;
signal trc_is_empty : std_logic;
signal trc_din      : STD_LOGIC_VECTOR(23 DOWNTO 0);
signal trc_dout     : STD_LOGIC_VECTOR(23 DOWNTO 0);
signal trc_sig_in   : std_logic := '0';
signal trc_sig_out  : std_logic := '0';

signal soft_reset_sig : std_logic;

--signals for T65
signal Rdy			: std_logic;
signal R_W_n		: std_logic;

--debug only
signal Port_B_prog      : std_logic_vector(7 downto 0);
signal test             : std_logic_vector(7 downto 0);


begin

-- port read management
    Port_A_int <= Port_A;
    Port_B_int <= Port_B;
    Port_C_int <= Port_C;    
    Port_D_int <= Port_D;    

    
--Q117  =>   Opt. SW Index            P105,10      S6,R7
--Q116  =>   Opt. SW Home             P105,11      S6,R6
--Q122  =>   Outer Cam N.O.           P105,6       S6,R4
--Q123  =>   Inner Cam N.O.           P105,5       S6,R5
--Q124  =>   +8 On Signal (*)         P105,2       S0,R7
--Q125  =>   Cancel Signal            P105,1       S0,R6
    Port_B_test(0)  <=  r_BitSwitches_mux(6)(7);   
    Port_B_test(1)  <=  r_BitSwitches_mux(6)(6);   
    Port_B_test(2)  <=  r_BitSwitches_mux(6)(4);   
    Port_B_test(3)  <=  r_BitSwitches_mux(6)(5);   
    Port_B_test(4)  <=  r_BitSwitches_mux(0)(6);   
    Port_B_test(5)  <=  r_BitSwitches_mux(0)(7);   
--S106 (Test)                 : S1,R7
--S107 (Standard/As Select.)  : S1,R6


--Using port b for debug
--Port_B <= (7=>test(7), others => '1'); 
    

-- self reset management
    process (SYSCLK)
        constant delayfx20ns : unsigned (31 downto 0) := (14=>'1', others=>'0');
        constant delayx20ns  : unsigned (31 downto 0) := (23=>'1', others=>'0');
    begin
        if (rising_edge(SYSCLK)) then
            if soft_reset_sig = '1' then
                CLK_DIV0 <= (others=>'0');
                nReset   <= '0';
                nResetf  <= '0';
            else
                CLK_DIV0 <= CLK_DIV0 + "1";
                if CLK_DIV0 = delayx20ns then
                    nReset <= '1';
                end if;
                if CLK_DIV0 = delayfx20ns then
                    nResetf <= '1';
                end if;
            end if;
        end if;
    end process;
    
        
-- isolation management
--    PA5Enable <= '1' when sm_simul = false else
--                 '0';
    PA5Enable <= '1';
              
    nIsolPorts <= nResetf;
    

p_switch_matrix : process(SYSCLK)
        --variable CLK_DIV0       : unsigned (23 downto 0) := (others=>'0');
        --variable last_clk19      : std_logic := '0';
        variable strobnum        : integer range 0 to 15;	
        variable r_switches      : t_swmtx := ( others => (others => (others => '0')));
        variable delay_sample    : natural range 0 to 1023 := 0;
        variable cur_strobe      : std_logic_vector(3 downto 0);
        variable last_strb       : std_logic_vector(3 downto 0);
        constant c_delay_sample0 : natural  := 150;  --3us first sample
        constant c_delay_sample1 : natural  := 700;  --14us second sample
        variable samplePh        : t_SM_Sample := s_Idle;
    begin
        if (rising_edge(SYSCLK)) then
        
			if nReset = '0' then
			    --last_clk19        := '0';
			    last_strb         := "1111";
			    delay_sample      := 0;
			    r_switches        := ( others => (others => (others => '0')));
			    samplePh          := s_Idle;
			else
                cur_strobe     := Port_C_int(3 downto 0);
                strobnum    := to_integer(unsigned(cur_strobe));
                if Port_A_int(5) = '0' or strobnum>9 then
                    delay_sample := 0;
                    samplePh     := s_Idle;

                else
                    if cur_strobe /= last_strb then
                        delay_sample := c_delay_sample0;
                        samplePh := s_Sample0;
                    end if;
                    if delay_sample /= 0 then
                        delay_sample := delay_sample - 1;
                    end if;
                    if delay_sample = 1 then
                        --store returns while strobe is cur_strobe
                        case samplePh is
                            when s_Sample0 =>
                                delay_sample := c_delay_sample1;
                                samplePh := s_Sample1;
                                for R in 7 downto 0 loop
                                    r_switches(strobnum, R)(0) := not Port_D_int(R);
                                end loop;
                            when s_Sample1 =>
                                delay_sample := 0;
                                samplePh := s_Idle;
                                for R in 7 downto 0 loop
                                    r_switches(strobnum, R)(1) := not Port_D_int(R);
                                    
                                    if r_switches(strobnum, R)(1 downto 0) = "11" then
                                        r_BitSwitches_int(strobnum)(R) <= '1';
                                    else
                                        r_BitSwitches_int(strobnum)(R) <= '0';
                                    end if;
                                end loop;
                            when others =>
                                null;   
                        end case;  
                    end if;
    
                end if;   --end if Port_A_int(5) = '0' then
                last_strb   := cur_strobe;

            end if;
    


        end if;
end process p_switch_matrix;

    

    ErrCod <= cResetErr      when nReset = '0'        else
              cSysClkSyncErr when debug_flag(0) = '1' else
              cSimulMod      when debugT1  = true     else
              cnoErr; 

--    r_BitSwitches_mux    <= r_BitSwitches_int when sm_simul = false else
--                            r_BitSwitches_simu_int;
    --r_BitSwitches_mux    <= r_BitSwitches_int;
g_switches:
    for S in 1 to 9 generate
        r_BitSwitches_mux(S) <= r_BitSwitches_int(S) when sm_simul = false else
                                r_BitSwitches_int(S) or r_BitSwitches_simu_int(S);
    end generate g_switches;

    
    r_BitSwitches_mux(0)(7) <= r_BitSwitches_int(0)(7) when sm_simul = false else
                               r_BitSwitches_simu_int(0)(7);
g_8on_switches:
    for R in 0 to 6 generate
    r_BitSwitches_mux(0)(R) <= r_BitSwitches_int(0)(R) when sm_simul = false else
                               r_BitSwitches_int(0)(R) or r_BitSwitches_simu_int(0)(R);
    end generate g_8on_switches;
                           
      LEDCTL :  ledctrl port map    ( hiclk   => SYSCLK,
                                      ErrCod  => ErrCod,
                                      vs0     => VS0,
                                      vs1     => VS1,
                                      vs2     => VS2);
                                      


 



	 NVRAM : myramip GENERIC MAP (
 	                              ADDRESS_WIDTH	=> 8,
	                              DATA_WIDTH	=> 8  
	                              )
	                 PORT MAP (
	                            nReset    => nReset,
	                            clock     => SYSCLK,
	                            we        => RAM_nRW, 
	                            addr_A    => RAM_Addr_Latch(7 downto 0), 
	                            addr_B    => RAM_ALT_Addr_Latch(7 downto 0), 
	                            data      => RAM_DIN, 
	                            q_A       => RAM_DOUT,
	                            q_B       => BCK_NVRAM_DOUT);

p_nvram_mng : process(SYSCLK)
    variable last_PA7         : std_logic := '1'; --we
    variable last_PA6         : std_logic := '1'; --od
    variable latched_rd_addr  : std_logic_vector(7 downto 0);
    variable latched_wr_addr  : std_logic_vector(7 downto 0);
    
    variable timval           : natural := 0;
    begin
	    if (rising_edge(SYSCLK)) then
			-- diag of switches
			if nReset = '0' then
			    Port_NVRAM       <= (others => 'Z');
			    RAM_nRW          <= "0";
			    last_PA7         := '1';
			    last_PA6         := '1';
			    timval           := 0;
			else
			    RAM_Addr_Latch     <= Port_C_int;
			    RAM_ALT_Addr_Latch <= nvr_addr;
			    --WE falling edge (write signal)
			    if Port_A_int(7) = '0' then 
			        if last_PA7 = '1' then
			             latched_wr_addr := Port_C_int;
                         RAM_DIN          <= Port_D_int;
                         RAM_nRW          <= "1";
                     else
			             RAM_nRW          <= "0";
--                         if latched_wr_addr /= Port_C_int then
--                            debugT1 <= true;
--                         end if;
			         end if;
			     --OD falling edge (output data bus exposed)
			     --P5101 max time from falling edge to data output valid is 150ns
			     --we then apply 20nsx8 as OD to valid
			     elsif Port_A_int(6) = '0' then
			         if last_PA6 = '1' then
			             --latched_rd_addr := Port_C_int;
                         Port_NVRAM       <= RAM_DOUT;  --not used at the moment
                         timval := 9; --the trigger is at 1 then dlay is (9-8)*20ns
                     else
                        if timval > 0 then
                            timval := timval - 1;
                        end if;
                        if timval = 1 then
                            RAM_DIN          <= Port_D_int;
                            RAM_nRW          <= "1";
                        else
			                RAM_nRW          <= "0";
			            end if;
                        
                            
--                         if latched_rd_addr /= Port_C_int then
--                            null;
--                            --debugT1 <= true;
--                         end if;
                         Port_NVRAM       <= (others => 'Z'); --not used at the moment
                     end if;
                 else
                     Port_NVRAM       <= (others => 'Z');
			         RAM_nRW          <= "0";
			     end if;
			     --DUMP_DATA         <= BCK_NVRAM_DOUT;
			     --DUMP_DATA         <= BCK_RAM0_DOUT;
			     last_PA7 := Port_A_int(7);
			     last_PA6 := Port_A_int(6);
            end if;
        end if;
end process p_nvram_mng;

DUMP_DATA <= BCK_RAM0_DOUT when dump_ram_typ = '0' else
             BCK_NVRAM_DOUT;

p_switch_matrix_simu : process(SYSCLK)
    variable r_switches      : t_swmtx := ( others => (others => (others => '0')));
    variable last_clk19      : std_logic := '0';
    --variable strobnum        : integer range 0 to 15;	
    --variable last_strobnum   : integer range 0 to 15 := 0;			 
    variable sw_strobnum     : integer range 0 to 15;		 
    variable sw_retnum       : integer range 0 to 15;		 
    variable sw_timernum     : unsigned(7 downto 0);		 
    constant c_timerd2d      : integer range 0 to 127 :=127;
	 begin
	    if (rising_edge(SYSCLK)) then
			-- diag of switches
			if nReset = '0' then
			    last_clk19        := '0';
			    --last_strobnum     := 0;
			    r_switches        := ( others => (others => (others => '0')));
			else
    
                sw_strobnum := to_integer(unsigned(sw_strb));
                sw_retnum   := to_integer(unsigned(sw_ret));
                sw_timernum := unsigned(sw_timer);
              
                
                -- check uart commands
                if sw_sig = '1' then
                    for R in 7 downto 0 loop
                        if sw_ret(R) = '1' then
                            r_switches(sw_strobnum, R) := sw_timernum(6 downto 0);
                        end if;
                    end loop;
                    
                end if;
    
    
    

                           
                -- update matrix of timers (clk19=> a peu pres 10ms)
                if last_clk19 /= CLK_DIV0(19) and CLK_DIV0(19) = '1' then
                    for S in 9 downto 0 loop
                        for R in 7 downto 0 loop
                            if r_switches(S, R)(6 downto 0) /= 0 then
                                if r_switches(S, R) /= 127 then
                                    r_switches(S, R)(6 downto 0) := r_switches(S, R)(6 downto 0)-"1";
                                end if;

                            end if;
                        end loop;
                    end loop;
                end if;
                
                
                --manage the switch trace signal
                for R in 7 downto 0 loop
                    if r_switches(sw_strobnum, R) = 0 then
                        r_BitSwitches_simu_int(sw_strobnum)(R) <= '0';
                    else
                        r_BitSwitches_simu_int(sw_strobnum)(R) <= '1';
                    end if;
                end loop;
                
                last_clk19 := CLK_DIV0(19);

    	   end if;
        end if;
end process p_switch_matrix_simu;

 -- digit management
    process (SYSCLK)
        variable last_PA4       : std_logic := '1';
        variable cur_strb       : std_logic_vector(3 downto 0);
        variable SegsData       : std_logic_vector(6 downto 0);
        variable delay_sample   : natural range 0 to 7 := 0;
        constant c_delay_sample : natural  := 5;
    begin
        if (rising_edge(SYSCLK)) then
            --     PA4==0 (enable abcdefg outputs (inverted))
            -- and PA5==0 (disable returns inputs)
            -- and PA6==1 (NVRAM output disable
            if Port_A_int(5) = '0' and Port_A_int(6) = '1' then
                if Port_A_int(4) = '0' then
                    if last_PA4 = '1' then
                        cur_strb     := Port_C_int(3 downto 0);
                        delay_sample := c_delay_sample;
                    else
                        if delay_sample /= 0 then
                            delay_sample := delay_sample - 1;
                        end if;
                        if delay_sample = 1 then
                            --Let's affect the value to corresponding digit 
                            --PD7=g
                            --PD6=f
                            --PD5=e
                            --PD4=d
                            --PD3=c
                            --PD2=nothing
                            --PD1=b
                            --PD0=a
                            --Z101=strb7
                            --Z102=strb8
                            --Z103=strb5
                            --Z104=strb6
                            --
                            --Z402=1st digit=strb1
                            --Z401=2nd digit=strb2
                            --Z400=3rd digit=strb3
                            --
                            --CR40x indicator leds=strb0
                            SegsData := not (Port_D_int(7 downto 3), Port_D_int(1 downto 0));
                            case Port_C_int(3 downto 0) is
                                when "0111"   =>
                                    Digit_Z101_b_int <= "0"&SegsData;
                                when "1000"   =>
                                    Digit_Z102_b_int <= "0"&SegsData;
                                when "0101"   =>
                                    Digit_Z103_b_int <= "0"&SegsData;
                                when "0110"   =>
                                    Digit_Z104_b_int <= "0"&SegsData;
                                when "0001"   =>
                                    Digit_Z402_b_int <= "0"&SegsData;
                                when "0010"   =>
                                    Digit_Z401_b_int <= "0"&SegsData;
                                when "0011"   =>
                                    Digit_Z400_b_int <= "0"&SegsData;
                                when "0000"   =>
                                    CR40x_int        <= "0"&SegsData;
                                --not a digit
                                when others   =>
                                    null;
                            end case;
                        end if; --delay_sample==1
                    end if;     --last_PA4 == '1'
                end if;         --Port_A_int(4) == '0'
            else
                delay_sample := 0; --reinit process if PA5 or PA6 activated during it
            end if;             --Port_A_int(5) == '0' and Port_A_int(6) == '1'
            last_PA4 := Port_A_int(4);
        end if;
                    
    end process;



 
 	u0 : entity work.T65
		port map(
			Mode => "00",
			Res_n => nReset,
			Clk => SYSCLK6502,
			Rdy => Rdy,
			Abort_n => '1',
			IRQ_n => '1',
			NMI_n => '1',
			SO_n => '1',
			R_W_n => R_W_n,
			Sync => open,
			EF => open,
			MF => open,
			XF => open,
			ML_n => open,
			VP_n => open,
			VDA => open,
			VPA => open,
			A => address_temp,
			DI => d_i,
			DO => d_o);
			
	wr_o <= not (R_W_n or not Rdy);
      
    rdy_i  <= '1'; --permanently set to 1 (unused)
    so_n_i <= '1'; --permanently set to 1 (unused)
    d_i    <= rom_o  when a_o(11) = '1' else
              ram_o  when (a_o(7 downto 6) = "00")  else
              pit_o  when timer_nCs = '0' else
              piaa_o when (a_o(7 downto 6) = "10"  and a_o(1) = '0') else
              piac_o when (a_o(7 downto 6) = "10"  and a_o(1) = '1') else
              piad_o when (a_o(7 downto 6) = "11"  and a_o(1) = '0') else
              piab_o when (a_o(7 downto 6) = "11"  and a_o(1) = '1') else
              (others=>'1');
              
CCCPROG :  ROMROWE
  PORT MAP(
    clka    => SYSCLK,
    ena     => a_o(11),
    addra   => a_o(10 downto 0),
    douta   => rom_o(7 downto 0) 
  );

    --we_v(0)  <= wr_n_o;  --only to let work syntax of port mapping below 
    we_v(0)  <= reg_CPUwe and (not a_o(11)) and (not a_o(7)) and (not a_o(6));  --only to let work syntax of port mapping below 
    wr_n_o   <= not reg_CPUwe;
    
 RAM6532 : myramip GENERIC MAP (
 	                              ADDRESS_WIDTH	=> 6,
	                              DATA_WIDTH	=> 8  
	                              )
	                 PORT MAP (
	                            nReset    => nReset,
	                            clock     => SYSCLK,
	                            we        => we_v, 
	                            addr_A    => a_o(5 downto 0), 
	                            addr_B    => nvr_addr(5 downto 0), 
	                            data      => d_o, 
	                            q_A       => ram_o,
	                            q_B       => BCK_RAM0_DOUT);
-- RAM6532 : RAMROWE
--                 PORT MAP (
--                            clka      => SYSCLK,
--                            ena       => not a_o(7),
--                            wea       => we_v, 
--                            addra     => a_o(5 downto 0), 
--                            dina      => d_o, 
--                            douta     => ram_o, 
--                            clkb      => SYSCLK,
--                            enb       => '0',
--                            web       => "0", 
--                            addrb     => a_o(5 downto 0), 
--                            dinb      => d_o, 
--                            doutb     => open); 


--PA is addressed  when address is 80 or 81
-- /RS = 1 (A7=1)
-- A6 = 0 (/CS2)
-- A11 = 0 (CS1)
--
-- A0/A1 = 0 (ORA) or 1 (DDRA)
pa_nCs <= '0' when (a_o(11 downto 1) = "00001000000") else
             '1';

--PA is PA of the 6532
PORTASECTION: pia6532
  Port map( 
       clk         => SYSCLK,
       nReset      => nReset,
       nCs         => pa_nCs,
       nRW         => wr_n_o,
       A0          => a_o(0),    --0 for output register, 1 for DDRX
       Port_X      => Port_A,
       d_i         => d_o,
       d_o         => piaa_o
);

--PC is addressed  when address is 82 or 83
-- /RS = 1 (A7=1)
-- A6 = 0 (/CS2)
-- A11 = 0 (CS1)
--
-- A0/A1 = 2 (ORB) or 3 (DDRB)
pc_nCs <= '0' when (a_o(11 downto 1) = "00001000001") else
             '1';
--PC is PB of the 6532
PORTCSECTION: pia6532
  Port map( 
       clk         => SYSCLK,
       nReset      => nReset,
       nCs         => pc_nCs,
       nRW         => wr_n_o,
       A0          => a_o(0),    --0 for output register, 1 for DDRX
       Port_X      => Port_C,
       d_i         => d_o,
       d_o         => piac_o
);

--timer is on when address is 85 (read interrupt flags) 
--                         or 95 (write timer div by 8)
timer_nCs <= '0' when (a_o(11 downto 0) = X"085" or a_o(11 downto 0) = X"095") else
             '1';
--debug_1 : process(timer_nCs)
--        variable count1 : natural range 0 to 15000 := 0;
--    begin
--        if falling_edge(timer_nCs) then
--            count1 := count1 + 1;
--            if count1 = 15000 then
--                count1 := 0;
--                debug_flag(0) <= not debug_flag(0);
--            end if;
--        end if;
--    end process debug_1;
                 
TIMER6532Light:  PIT6532
  Port map( 
       fastclk     => SYSCLK,
       nReset      => nReset,
       nCs         => timer_nCs,
       nRW         => wr_n_o,
       a_i         => a_o(6 downto 0),
       d_i         => d_o,
       d_o         => pit_o,
       test        => test
);

pd_nCs <= '0' when (a_o(11 downto 1) = "00001100000") else
          '1';

--PD is PA of the 6520
PORTDSECTION: portdmux

  Port map( 
       clk         => SYSCLK,
       nReset      => nReset,
       nCs         => pd_nCs,
       nRW         => wr_n_o,
       RS0         => a_o(0),    --0 for output register, 1 for DDRX
       Port_D      => Port_D,
       d_i         => d_o,
       d_o         => piad_o,

       c_strobe    => Port_C_int(3 downto 0), --from Port_C_int(3 downto 0)
       PA5         => Port_A_int(5),     
       sm_simul    => sm_simul,
       BitSwitches => r_BitSwitches_simu_int

);

----PD is PA of the 6520
--PORTDSECTION: pia6520
--  Generic map (
--        g_piatyp => A6520TYP
--  )
--  Port map( 
--       clk         => SYSCLK,
--       nReset      => nReset,
--       nCs         => pd_nCs,
--       nRW         => wr_n_o,
--       RS0         => a_o(0),    --0 for output register, 1 for DDRX
--       Port_X      => Port_D,
--       d_i         => d_o,
--       d_o         => piad_o
--);

pb_nCs <= '0' when (a_o(11 downto 1) = "00001100001") else
          '1';
PORTBSECTION: pia6520
  Generic map (
        g_piatyp => B6520TYP
  )
  Port map( 
       clk         => SYSCLK,
       nReset      => nReset,
       nCs         => pb_nCs,
       nRW         => wr_n_o,
       RS0         => a_o(0),    --0 for output register, 1 for DDRX
       Port_X      => Port_B,    --Port_B_prog, --Port_B,
       d_i         => d_o,
       d_o         => piab_o
);
--Port_B <= X"FF"; --Port_B_int; --X"AA";


--p_6502_clk:
--process(SYSCLK) 
--    variable divide_50    : integer range 0 to 49 := 49;
--    constant c_divide_50  : integer range 0 to 49 := 49;
--begin
--    if (rising_edge(SYSCLK)) then
--        divide_50 := divide_50 - 1;
--        if divide_50 = 0 then
--            divide_50 := c_divide_50;
--            SYSCLK6502 <= not SYSCLK6502;
--        end if;     
--    end if;

--end process p_6502_clk;

p_6502_clk:
    -- Divides the board clock by 48 (50 MHz/48 = 1 MHz) 
    process(SYSCLK)
    begin
        if rising_edge(SYSCLK) then
            if nReset = '0' then
                count <= (others=>'0');
            else
                if count = x"2F" then 
                --if count = x"17" then 
                    count <= "000000";
                else
                    count <= count + 1;
                end if;
            end if;
        end if;
    end process p_6502_clk;
    process(SYSCLK)
    begin
        if rising_edge(SYSCLK) then
--            if nReset = '0' then
--                SYSCLK6502 <= '0';
--            else
                if count < x"17" then 
                --if count < x"0B" then 
                    SYSCLK6502 <= '0';
                else
                    SYSCLK6502 <= '1';
                end if;
--            end if;
        end if;
   end process;

    -- Sync Memory Writes   
    process(SYSCLK)
    begin
        if rising_edge(SYSCLK) then
            if nReset = '0' then
                reg_CPUwe <= '0';
            else
                --if count = x"17"  or count = x"18" then  
                --if count = x"0B"  or count = x"0C" then  
                --if count = x"0D"  then  
                if count = x"1B"  then  --historically 1B
                    reg_CPUwe <= wr_o; -- High only for 2 period of 50 MHz clock
                else
                    reg_CPUwe <= '0';
                end if;
            end if;
        end if;
    end process;

    -- Sync IO access when integrated in fpga core80 project
    process(SYSCLK)
    begin
        if rising_edge(SYSCLK) then
            if nReset = '0' then
                a_o <= (others=>'0');
            else
                --if count = x"16" then  
                --if count = x"0C" then  
                if count = x"1A" then  
                    a_o <= address_temp(15 downto 0); -- Same moment as CPUwe signal is assigned
                end if;
            end if;
        end if;
    end process;   

    process(SYSCLK6502)
    begin
        if rising_edge(SYSCLK6502) then
            if nReset = '0' then
                Rdy <= '0';
            else
 			    --Rdy <= not Rdy;
 			    Rdy <= '1';
 			end if;
        end if;
    end process;
    
      PPS4TRACE : serialtrace    
                Port map (
                    hiclk       =>  SYSCLK,

                    TXp         =>  TXp,
                    RXp         =>  RXp,

                    Digit_Z101_b  => Digit_Z101_b_int,
                    Digit_Z102_b  => Digit_Z102_b_int,
                    Digit_Z103_b  => Digit_Z103_b_int,
                    Digit_Z104_b  => Digit_Z104_b_int,
                    Digit_Z400_b  => Digit_Z400_b_int,
                    Digit_Z401_b  => Digit_Z401_b_int,
                    Digit_Z402_b  => Digit_Z402_b_int,
                    CR40x_b       => CR40x_int,
                    
                    r_BitSwitches =>  r_BitSwitches_mux,
                    
                    PA            =>  Port_A_int,
                    PB            =>  Port_B_int,
                    PC            =>  Port_C_int,
                    PD            =>  Port_D,

                    ram_req       =>  nvr_read_sig,
                    ram_addr      =>  nvr_addr,
                    ram_data      =>  DUMP_DATA,
                    ram_type      =>  dump_ram_typ,
                    
                    sm_simul      =>  sm_simul,
                    sw_sig        =>  sw_sig,
                    sw_strb       =>  sw_strb,
                    sw_ret        =>  sw_ret,
                    sw_timer      =>  sw_timer,
                    
                    trc_is_empty  =>  trc_is_empty,
                    trc_sig_out   =>  trc_sig_out,
                    trc_dout      =>  trc_dout,

                    soft_reset_sig=>  soft_reset_sig,   
                                     
                    status        =>  tracer_status);


p_trace: process(SYSCLK)
        variable last_d_trace      : std_logic_vector(15 downto 0);
        variable trc_was_full_once : boolean := false;
        variable max_lines         : natural range 0 to 4096 := 0; 
        variable last_SYSCLK6502   : std_logic := '0';
        variable trace_triggered   : std_logic := '0';
    begin
        if rising_edge(SYSCLK) then
            
            if nReset = '0' then
                last_d_trace := (others=>'0');
                trc_was_full_once := false;
                max_lines := 0;
                last_SYSCLK6502 := '0';
                trace_triggered := '0';
            else
                --if count = x"16" then  
                --if count = x"0C" then  
                if count = x"1A" then  
                    --if (last_d_trace /= a_o)  then  
                        if a_o(11 downto 0) = X"86A" then
                            trace_triggered := '1';
                        end if;
                        if max_lines < 2048 then     
                            if trace_triggered = '1' then             
                                max_lines := max_lines + 1;
                                if wr_o = '1' then
                                    --write
                                    trc_din <= a_o&d_o;
                                else
                                    trc_din <= a_o&d_i;
                                end if;
                                trc_sig_in <= '1';
                            end if;
                        end if;                               
                    --end if;        
                end if;
                last_SYSCLK6502 := SYSCLK6502;
                last_d_trace := a_o;
                if trc_sig_in = '1' then
                    trc_sig_in <= '0';
                end if;
            end if;
        end if;
                
    end process p_trace;
    
TRACE_FIFO : DBGFIFO
  PORT MAP (
    clk => SYSCLK,
    srst => not nReset,
    din => trc_din,
    wr_en => trc_sig_in,
    rd_en => trc_sig_out,
    dout => trc_dout,
    full => trc_is_full,
    empty => trc_is_empty
  );
end Behavioral;
