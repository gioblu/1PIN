#1PIN OPENSOURCE COMMUNICATION PROTOCOL

MASTER SLAVE ARCHITECTURE | 255 SELECTABLE IDS | 3,18KB/S 
***
###ONLY ONE WIRE USED TO COMMUNICATE BIDIRECTIONALLY FROM 2,38KB/S TO 3,18 KB/S FROM 1 TO 255 ARDUINO BOARDS WITH CYCLIC REDUNDANCY CHECK AND CORRECT RECEIVING AKNOWLEDGE

YES, ON THE SAME WIRE, YES, WITH ONLY ONE WIRE, AND YES, WITHOUT 1WIRE :P!!
***
In the makers / DIY / Arduino world is really difficult to see efficient communication with Serial, i2c or 1wire.
Users are annoyed by really complex ways to bring information from a MCU to another one and often those are propietary.

For this reason at least 2 years ago I started to develop a new standard of communication based only on the Arduino software resources.
I choose to start this way to serve a really compatible protocol that could fit theorically on every board that works
with Arduino IDE without harming any other function or library. This happens because 1PIN use only software to work.

So NO INTTERRUPT, NO TIMER, NO WATCHDOG directly used. 

This means that 1PIN can run freely on ATtiny85 without harming PWM, micros(), delayMicroseconds() or other libraries flashed. 

digitalWrite/Read are useless for this application (long duration), digitalWriteFast library do the job elegantly.
***
LOW SPEED:  2,38 kb/s - 396 cmd/s - 476 req/s | ACCURACY 99.93% (9365 cmd received / 10000 sent)

LOW SETUP:  (Arduino duemilanove) [BITwidth 35|BITspacer 105|startWINDOW 70| readDELAY 4]
***
STD SPEED:  2,85 kb/s - 476 cmd/s - 571 req/s | ACCURACY 96.01% (9601 cmd received / 10000 sent)

STD SETUP:  (Arduino duemilanove) [BITwidth 28|BITspacer  84|startWINDOW 40| readDELAY 4]
***
FAST SPEED: 3,18 kb/s - 530 cmd/s - 636 req/s | ACCURACY 94.41 % (9441 cmd received / 10000 sent)

FAST SETUP: (Arduino duemilanove) [BITwidth 24|BITspacer 80|startWINDOW 24| readDELAY 0]
***

Idea by Giovanni Blu Mitolo & Martino di Filippo - www.gioblu.com - gioscarab@gmail.com

1PIN is released under CreativeCommons Attribution-NonCommercial-ShareAlike 3.0 Unported License





