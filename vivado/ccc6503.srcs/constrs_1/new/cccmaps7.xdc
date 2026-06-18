#LVCMOS33 version.
#LVTTL version.

create_clock -period 20.000 -name SYSCLK -waveform {0.000 10.000} [get_ports SYSCLK]

set_property BITSTREAM.CONFIG.SPI_32BIT_ADDR YES [current_design]

set_property BITSTREAM.CONFIG.DONEPIN PULLUP [current_design]

set_property BITSTREAM.CONFIG.CONFIGRATE 26 [current_design]

set_property BITSTREAM.CONFIG.USERID 32'h0C3FFFFF [current_design]

set_property BITSTREAM.STARTUP.STARTUPCLK CCLK [current_design]

set_property BITSTREAM.Config.SPI_buswidth 4 [current_design]

set_operating_conditions -heatsink none



set_property IOSTANDARD LVCMOS33 [get_ports SYSCLK]
set_property PACKAGE_PIN G4 [get_ports SYSCLK]

set_property IOSTANDARD LVCMOS33 [get_ports {nIsolPorts}]
set_property PACKAGE_PIN K3 [get_ports {nIsolPorts}]

set_property IOSTANDARD LVCMOS33 [get_ports {PA5Enable}]
set_property PACKAGE_PIN K4 [get_ports {PA5Enable}]

set_property IOSTANDARD LVCMOS33 [get_ports {Port_A[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {Port_A[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {Port_A[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {Port_A[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {Port_A[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {Port_A[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {Port_A[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {Port_A[7]}]

#ok
set_property PACKAGE_PIN P4 [get_ports {Port_A[7]}]
#ok
set_property PACKAGE_PIN C5 [get_ports {Port_A[6]}]
#ok
set_property PACKAGE_PIN C4 [get_ports {Port_A[5]}]
#ok
set_property PACKAGE_PIN B2 [get_ports {Port_A[4]}]

set_property PACKAGE_PIN A4 [get_ports {Port_A[1]}]
set_property PACKAGE_PIN A3 [get_ports {Port_A[0]}]

#ex nDO3, dummy here
set_property PACKAGE_PIN B1 [get_ports {Port_A[2]}]  
#ex nDO8, dummy here
set_property PACKAGE_PIN P3 [get_ports {Port_A[3]}]  



set_property IOSTANDARD LVCMOS33 [get_ports {Port_B[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {Port_B[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {Port_B[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {Port_B[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {Port_B[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {Port_B[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {Port_B[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {Port_B[7]}]

#ok
set_property PACKAGE_PIN P13 [get_ports {Port_B[0]}]
#ok
set_property PACKAGE_PIN P12 [get_ports {Port_B[2]}]
#ok
set_property PACKAGE_PIN P11 [get_ports {Port_B[3]}]
#ok
set_property PACKAGE_PIN P10 [get_ports {Port_B[4]}]
#ok
set_property PACKAGE_PIN N11 [get_ports {Port_B[5]}]
#ok
set_property PACKAGE_PIN N10 [get_ports {Port_B[6]}]
#ok
set_property PACKAGE_PIN M12 [get_ports {Port_B[7]}]

#ex RRSEL, dummy here
set_property PACKAGE_PIN H11 [get_ports {Port_B[1]}]     
  
set_property IOSTANDARD LVCMOS33 [get_ports {Port_C[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {Port_C[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {Port_C[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {Port_C[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {Port_C[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {Port_C[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {Port_C[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {Port_C[7]}]

#ok
set_property PACKAGE_PIN H4 [get_ports {Port_C[7]}]
#ok
set_property PACKAGE_PIN H3 [get_ports {Port_C[6]}]
#ok
set_property PACKAGE_PIN H2 [get_ports {Port_C[5]}]
#ok
set_property PACKAGE_PIN H1 [get_ports {Port_C[4]}]
#ok
set_property PACKAGE_PIN F14 [get_ports {Port_C[0]}]
#ok
set_property PACKAGE_PIN F13 [get_ports {Port_C[1]}]
#ok
set_property PACKAGE_PIN F12 [get_ports {Port_C[2]}]
#ok
set_property PACKAGE_PIN F11 [get_ports {Port_C[3]}]


set_property IOSTANDARD LVCMOS33 [get_ports {Port_D[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {Port_D[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {Port_D[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {Port_D[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {Port_D[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {Port_D[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {Port_D[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {Port_D[7]}]


#ok
set_property PACKAGE_PIN L1 [get_ports {Port_D[7]}]
#ok
set_property PACKAGE_PIN L2 [get_ports {Port_D[6]}]
#ok
set_property PACKAGE_PIN L3 [get_ports {Port_D[5]}]
#ok
set_property PACKAGE_PIN M1 [get_ports {Port_D[4]}]
#ok
set_property PACKAGE_PIN M2 [get_ports {Port_D[3]}]
#ok
set_property PACKAGE_PIN M3 [get_ports {Port_D[2]}]
#ok
set_property PACKAGE_PIN M4 [get_ports {Port_D[1]}]
#ok
set_property PACKAGE_PIN M5 [get_ports {Port_D[0]}]



set_property IOSTANDARD LVCMOS33 [get_ports SCL]
set_property IOSTANDARD LVCMOS33 [get_ports SDA]
set_property PACKAGE_PIN B13 [get_ports SCL]
set_property PACKAGE_PIN B14 [get_ports SDA]
set_property DRIVE 4 [get_ports SCL]
set_property DRIVE 4 [get_ports SDA]
set_property PULLTYPE PULLUP [get_ports SCL]
set_property PULLTYPE PULLUP [get_ports SDA]


set_property IOSTANDARD LVCMOS33 [get_ports TXp]
set_property IOSTANDARD LVCMOS33 [get_ports RXp]
set_property PACKAGE_PIN A13 [get_ports TXp]
set_property PACKAGE_PIN A12 [get_ports RXp]


set_property IOSTANDARD LVCMOS33 [get_ports VS0]
set_property IOSTANDARD LVCMOS33 [get_ports VS1]
set_property IOSTANDARD LVCMOS33 [get_ports VS2]
set_property PACKAGE_PIN B3 [get_ports VS0]
set_property PACKAGE_PIN B5 [get_ports VS1]
set_property PACKAGE_PIN B6 [get_ports VS2]

set_property PULLTYPE NONE [get_ports {Port_A[7]}]
set_property PULLTYPE NONE [get_ports {Port_A[6]}]
set_property PULLTYPE NONE [get_ports {Port_A[5]}]
set_property PULLTYPE NONE [get_ports {Port_A[4]}]

#set_property PULLTYPE PULLUP [get_ports {Port_A[7]}]
#set_property PULLTYPE PULLUP [get_ports {Port_A[6]}]
#set_property PULLTYPE PULLUP [get_ports {Port_A[5]}]
#set_property PULLTYPE PULLUP [get_ports {Port_A[4]}]


set_property PULLTYPE PULLUP [get_ports {Port_D[7]}]
set_property PULLTYPE PULLUP [get_ports {Port_D[6]}]
set_property PULLTYPE PULLUP [get_ports {Port_D[5]}]
set_property PULLTYPE PULLUP [get_ports {Port_D[4]}]
set_property PULLTYPE PULLUP [get_ports {Port_D[3]}]
set_property PULLTYPE PULLUP [get_ports {Port_D[2]}]
set_property PULLTYPE PULLUP [get_ports {Port_D[1]}]
set_property PULLTYPE PULLUP [get_ports {Port_D[0]}]

set_property PULLTYPE PULLUP [get_ports {Port_B[7]}]
set_property PULLTYPE PULLUP [get_ports {Port_B[6]}]
set_property PULLTYPE PULLUP [get_ports {Port_B[5]}]
set_property PULLTYPE PULLUP [get_ports {Port_B[4]}]
set_property PULLTYPE PULLUP [get_ports {Port_B[3]}]
set_property PULLTYPE PULLUP [get_ports {Port_B[2]}]
set_property PULLTYPE PULLUP [get_ports {Port_B[1]}]
set_property PULLTYPE PULLUP [get_ports {Port_B[0]}]


#set_property DRIVE 8 [get_ports {Port_A[7]}]
#set_property DRIVE 8 [get_ports {Port_A[6]}]
#set_property DRIVE 8 [get_ports {Port_A[5]}]
#set_property DRIVE 8 [get_ports {Port_A[4]}]
#set_property DRIVE 8 [get_ports {Port_A[3]}]
#set_property DRIVE 8 [get_ports {Port_A[2]}]
#set_property DRIVE 8 [get_ports {Port_A[1]}]
#set_property DRIVE 8 [get_ports {Port_A[0]}]

set_property PACKAGE_PIN E11 [get_ports Dot_Seg]
set_property IOSTANDARD LVCMOS33 [get_ports Dot_Seg]

