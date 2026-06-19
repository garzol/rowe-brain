## VHDL project

### Vivado version
At this moment the project can be built with vivado 2025.2

### Package for 6502 emulation
Cloning the 6503 CPU is not a big deal, for there are a lot of enthousiasts who have made plenty of good VHDL models. 
These models exist for more than 20 years for most of them. So, we can trust them.

The only spec is to have a cycle accurate model of the 6502

We have selected T65 CPU from  [opencores.org](https://opencores.org/projects/t65) (requires an account).  
The CPU to be cloned is actually a 6503. This is not a problem. The T65 is OK for this.

### Modelling 6503
The 6503 is a simplified version of the 6502. Therefore, it is easy to derive a 6503 from a 6502 entity.

The memory range for ROM is 2KB, no Ready signal.

Besides, the schematic of the R6500/1 Alternate shows that NMI, IRQ, OV are not used. Then we just have to set all these signals to  a fixed '1' and that's it.

### Modelling 6520
Datasheet : [R6520_datasheet.pdf](doc/R6520.pdf)

### Modelling 6532
Datasheet : [R6532_datasheet.pdf](doc/R6532_datasheet.pdf)

#### PIT
PIT is the programable timer interface
We have implemented the strict minimum. From the disassembled code, PIT is used only once around 0A4C:
````
0A49   88         L0A49         DEY               ;(2)
0A4A   10 F6                    BPL L0A42         ;(2/3)
0A4C   24 85      L0A4C         BIT $85           ;(3)
0A4E   10 FC                    BPL L0A4C         ;(2/3) Test of timer interrupt bit (wait for 1.5ms)
0A50   C6 13                    DEC $13           ;(5) m13--
0A52   30 03                    BMI L0A57         ;(2/3)
0A54   4C B8 09                 JMP L09B8         ;(3) loop back to begining of 7-segs loop
0A57   A9 DA      L0A57         LDA #$DA          ;(2) 
0A59   85 80                    STA PortA           ;(3) Read NVRAM, RAM out disable, Returns Hi-Z, Digits on
0A5B   A9 9A                    LDA #$9A          ;(2) 
0A5D   85 80                    STA PortA           ;(3) Read NVRAM, RAM out enable,  Returns Hi-Z, Digits on
0A5F   84 C0                    STY PortD          ;(3)  Write #FF to port D

````

The configuration of PIT appears here:
````
09CA   A8         L09CA         TAY               ;(2)
09CB   B9 EF 0F                 LDA $0FEF,Y       ;(4/5) Lookup table 7-seg values 0..9, -
09CE   49 FF      L09CE         EOR #$FF          ;(2)
09D0   A0 DA                    LDY #$DA          ;(2) Read NVRAM, RAM out disable, Returns Hi-Z, Digits on
09D2   84 80                    STY PortA           ;(3) PA<=digits on
09D4   85 C0                    STA PortD          ;(3) PD<=digit value to be displayed
09D6   86 82                    STX PortC           ;(3) PC<=digit number to be set
09D8   A2 CA                    LDX #$CA          ;(2) Read NVRAM, RAM out disable, Returns Hi-Z, Digits off
09DA   86 80                    STX PortA           ;(3)
09DC   A9 BC      L09DC         LDA #$BC          ;(2) d188
09DE   85 95                    STA $95           ;(3) Write timer divide by 8 (1/8MHz) 188*8us= 1.5ms
09E0   A4 00                    LDY $00           ;(3)
09E2   30 56                    BMI L0A3A         ;(2/4) service switch on ?
09E4   A5 33                    LDA $33           ;(3)
````

We think it is a pause of 1.5ms to let light up the 7-seg displays. They use the PIT in the div by 8 mode, no irq. Then, we only implemented this in our model.

#### PIOx2
#### RAM
The integrated RAM is partially used by the system. We have implemented the equivalent version in VHDL. 
It is weird to see that only 0x40 bytes of RAM are usable (by design) while 0x100 bytes are theoritically available from the device.

Please also notice how the stack is implemented. In theory, stack starts at 0x1FF decreasing from there to no minimum. But here, as the addresses are connected a specific way, the real start address of the stack is 0x3F.