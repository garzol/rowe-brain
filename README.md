# rowe-brain
Clonage of  the CPU section of the CCC board 6-08871-01 (Jukeboxes ROWE AMI CTI-2 RI-3 R-84 R-85.)

## ROM Copy 
We have read the 2K bin code which resides in the 2316 of the R6500/alternate board. This board is made of :
- The CPU, which is a R6503 Rockwell device, clocked at 1MHz.
- A 6520 PIO
- A 6532 PIT
- A 2316 2K ROM

2316 is nothing else than a 2716, with 3 specific chip select pin logic, specified by the customer at fabrication time. But we are fortunate, because the pattern chosen by the customer here, is identical to the one of a normal 2716. Then, once the chip is delicately unsoldered, one just need to use a standard prom programer (Dataman mempro in my case) to read it. And that's it!    


You will find the result in the bin file in this repo.  

The txt file is the commented (work in perpetual progress) disassembled code. 

