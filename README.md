# rowe-brain
Clonage of  the CPU section of the CCC board 6-08871-01 (Jukeboxes ROWE AMI CTI-2 RI-3 R-84 R-85.)


## Context

The Central Control Computer (CCC) of the ROWE AMI CTI-2 RI-3, R84 R85 R86 R87 R88 jukeboxes is the "brain" of the jukebox.

As often on these 50-year-old systems, breakdowns appear more and more frequently, and they end up not being able to be repaired at all.

Hence the idea of making clones of these electronic board, using modern components as much as possible but with the constraint of having to respect the external logic of the signals to be able to replace the original boards with their clone in a pure spirit of plug&play.

## Objective

The objective of this project is the cloning of the ccc board 6-08871-01.

We have established 2 milestones:

- Redesign of the board itself.

- Cloning of the 40-pin microcontroller, with its program

## Variants of boards

The CCC board exists in 2 versions:

- 6-08871-01

- 6-08871-04

The 2 boards are interchangeable. However, concerning their 40-pin sockets, the -01 hosts a Rockwell microcontroller based on 650x, while the -04 must be equipped with a MOSTEK 3870 microcontroller.

The differences are very well described in the document [r84ts_dl.pdf](r84ts_dl.pdf).

They both have 40 DIL pins, but their pin-out is different. Hence, you cannot fit a -01 with a MOSTEK, or vice-versa a -04 with a Rockwell one.

Since the first schematic we have had access to was the -01 (see rowe ami doc p.38), we decided to go cloning the -01. Besides, we are more accustomed to 6502 instruction set rather than to Mostek.

The Rockwell microcontroller is also available in an alternate format (called R6500/1 Alternate). It is a non integrated version of the microcontroller.
## Milestone 1: Redesign of the board


### Synopsis
Le synopsis général de la carte est le suivant:

![Synopsis](images/cccsynops.001.png "Synopsis of the board")

### List of subsections
#### Untouched subsections
We have made an exact chineese copy of the timer and the "uart" subsections, just replacing certain obsolete components with newer (although we kept using the NE555 for example, because this one is probably not going to disappear)

Why? Because, we need to keep being compatible with the 40-pin original CPUs. Therefore, there was no interesting alternative for these sections.

#### NVRAM
We first believed that a FM18 would make the deal. But it does not work due to an incompatible timing of the /WE signal. We then started with a M48Z58Y-70MH1F SOH28 (sort of SOIC), which is almost the only possible solution given that we were looking for a +5V device. But this one is equipped with a "snaphat" backup battery, which make it a poor solution.

We finally decided to go with a CY14B256LA-ZS, which would have been the perfect solution if the device was not a 3V3 device...

So we had to interface it with a string of translator devices TXB0108, TXS0108... To make it compatible with the rest of the system.

CY14B256LA-ZS is an admirable device. It gets its "non volatile" function from a 68uF capacitor, which gives the required power at power off of the system, giving enough power to make the save. It is quite expensive, though.



### Result 
![Original vs clone](images/ovsc.jpg "Original vs clone: identical outlines")

This board is available for sale on my site:
[pps4.fr](https://www.pps4.fr/pd/clone-central-control-computer-board-for-rowe-ami/)

Of course, you can redesign it by yourself if you prefer, taking advice from the synopsis above. But I don't see the point, since the work has already been done.


## Milestone 2: Cloning of the microcontroller
### What is to be rewritten in VHDL 
![Schematic of the original microcontroller](images/schemacpu.jpg)

### ROM Copy 
We have read the 2K bin code which resides in the 2316 of the R6500/1 Alternate board. This board is made of :
- The CPU, which is a R6503 Rockwell device, clocked at 1MHz.
- A 6520 PIO
- A 6532 PIT
- A 2316 2K ROM

2316 is nothing else than a 2716, with 3 specific chip select pin logic, specified by the customer at fabrication time. But we are fortunate, because the pattern chosen by the customer here, is identical to the one of a normal 2716. Then, once the chip is delicately unsoldered, one just need to use a standard prom programer (Dataman mempro in my case) to read it. And that's it!    


You will find the result in the bin file in this repo.  

The txt file is the commented (work in perpetual progress) disassembled code. 

