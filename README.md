1PIN OPENSOURCE COMMUNICATION PROTOCOL - MASTER SLAVE ARCHITECTURE | 255 SELECTABLE IDS
ONLY ONE WIRE USED TO COMMUNICATE BIDIRECTIONALLY FROM 2,38KB/S TO 2,97 KB/S FROM 1 TO 255 ARDUINOS
YES, ON THE SAME WIRE, YES, WITH ONLY ONE WIRE, AND YES, WITHOUT 1WIRE :P!!

In the makers / DIY / Arduino world is really difficult to see efficient communication with Serial, i2c or 1wire.
Users are annoyed by really complex ways to bring information from a MCU to another one and often those are propietary.
So the idea. Write a new standard of communication based only on the Arduino software resources.
I choose to start this way to serve a really compatible protocol that could fit theorically on every board that works
with Arduino IDE without harming any other function or library. This happens because 1PIN use only software to work.
So NO INTTERRUPT, NO TIMER, NO WATCHDOG directly used. This means that 1PIN could run freely on ATtiny85 without 
harming PWM, micros(), delayMicroseconds() or other functions/libraries flashed. 
digitalWrite and digitalRead are really useless for this application (really long duration), 1PIN needs PORT commands
to communicate fast, digitalWriteFast really elegant library to the job dinamically.

STD SPEED:  2,38 kb/s - 2380 baud/s - 396 cmd/s - 476 req/s | ACCURACY 99.93% (9993 cmd received / 10000 sent)
STD SETUP:  (Arduino duemilanove) [BITwidth 35|BITspacer 105|startWindow 70|readDelay 4]

FAST SPEED: 2,97 kb/s - 2976 baud/s - 496 cmd/s - 595 req/s | ACCURACY 86.78% (8678 cmd received / 10000 sent)
FAST SETUP: (Arduino duemilanove) [BITwidth 28|BITspacer  84|startWindow 40|readDelay 4]

Idea by Giovanni Blu Mitolo & Martino di Filippo - www.gioblu.com - gioscarab@gmail.com
1PIN is released under CreativeCommons Attribution-NonCommercial-ShareAlike 3.0 Unported License





