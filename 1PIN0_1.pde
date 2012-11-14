#include <digitalWriteFast.h>

//  1PIN: OPENSOURCE COMMUNICATION PROTOCOL - MASTER>SLAVE ARCHITECTURE | 255 SELECTABLE SLAVE IDS
//  Basically 2 entities: Master and slave and 2 objects: commands and requests.
//  COMMAND: |commandTYPE|ID|VALUE|VALUE|CRC| REQUEST: |REQ(byte255)|ID|SUBJECT|CRC|
//  TOOLS USED: micros(), delayMicroseconds(), digitalWriteFast lib | NO INTERRUPT, NO TIMERS

//  LOW SPEED:  2,38 kb/s - 396 cmd/s - 476 req/s | ACCURACY 99.93% (9993 cmd received / 10000 sent)
//  LOW SETUP:  (Arduino duemilanove) [BITwidth 35|BITspacer 105|startWINDOW 70| readDELAY 4]

//  STD SPEED:  2,85 kb/s - 476 cmd/s - 571 req/s | ACCURACY 96.01% (9601 cmd received / 10000 sent)
//  STD SETUP:  (Arduino duemilanove) [BITwidth 28|BITspacer  84|startWINDOW 40| readDELAY 4]

//  FAST SPEED: 3,18 kb/s - 530 cmd/s - 636 req/s | ACCURACY 94.41 % (9441 cmd received / 10000 sent)
//  FAST SETUP: (Arduino duemilanove) [BITwidth 24|BITspacer 80|startWINDOW 24| readDELAY 0]

//  Idea by Giovanni Blu Mitolo & Martino di Filippo - www.gioblu.com - gioscarab@gmail.com
//  1PIN is released under CreativeCommons Attribution-NonCommercial-ShareAlike 3.0 Unported License

// BASIC NODE INFO
const int inputPIN = A0;      // I/O pin where the wire is connected
boolean receiver = true;     // Master / Slave switch
const byte slaveID = 63;       // Node ID
// SETTING CONSTANTS
const int BITwidth = 24;      // single BIT duration in micros()
const int BITspacer = 80;     // syncronization spacer duration in micros()
const int spacerWINDOW = 24;  // Minimum acceptable HIGH spacer duration
const int readDELAY = 0;      // Delay before reading single BIT
// PROTOCOL SYMBOLS
const byte REQ = 255;         // 255 Request symbol | Don't use 255 as a CMD parameter, is used as REQ symbol
const byte ACK = 6;           // ♠ Acknowledge symbol | OK - roger - copy that
const byte NAK = 21;          // § Negative acknowledge symbol | NO - repeat - negative
const int FAIL = 0x100;       // FAIL symbol

// GLOBAL VARS
int failed = 0;
int mistakes = 0;

// THE REST
int current = 0;
int test = 0;
int testERROR = 0;
int oldvalue = 0;

void setup() {
  Serial.begin(115200);
}

// TRANSMISSION FUNCTIONS  ///////////////////////////////////////////////////////////////

void writeBIT(byte VALUE, int duration) {
  digitalWriteFast(inputPIN, VALUE);            // Standard digitalWrite function useless
  delayMicroseconds(duration);                  // really slow ; )
}

void byteTX(byte b) {
  pinModeFast(inputPIN, OUTPUT);
  writeBIT(HIGH, BITspacer);                    // Write initial spacer HIGH pulse
  writeBIT(LOW, BITwidth);                      // Write iniital standard bit LOW pulse
  for(int i = 7; i >= 0; i--) writeBIT(bitRead(b, i) == 1 ? HIGH : LOW, BITwidth);
}

int commandTX(byte ID, byte commandTYPE, unsigned int value) {
  byte bytesSend[5] = { ID, commandTYPE, value >> 8, value & 0xFF, 0 };
  for (int i = 0; i < 5; i++) {
    if (i < 4) bytesSend[4] ^= bytesSend[i];
    byteTX(bytesSend[i]);
  }
  digitalWriteFast(inputPIN, LOW);
  unsigned long time = micros();
  int r = FAIL;
  while(r == FAIL && micros() - time <= BITspacer + BITwidth) r = startRX();
  Serial.print(r);
  Serial.print(" ");
  Serial.print(test);
  Serial.print(" ");
  Serial.println(mistakes);
  if(r != ACK && failed < 5){ commandTX(ID, commandTYPE, value); failed++; mistakes++;}
  if(r == ACK) { failed = 0; return ACK; }
  if(r != ACK && failed >= 5) return FAIL;
}

int requestTX(byte ID, byte theSubject) {
 byte bytesSend[4] = { ID, 255, theSubject, 0 };
  for (int i = 0; i < 4; i++) {
    if (i < 3) bytesSend[3] ^= bytesSend[i];
    byteTX(bytesSend[i]);
  }
  digitalWriteFast(inputPIN, LOW);
  unsigned long time = micros();
  int r = FAIL;
  while(r == FAIL && micros() - time <= BITspacer + BITwidth) r = startRX();
  Serial.print(r);
  Serial.print(" ");
  Serial.println(test);
  if(r != ACK && failed < 5){ requestTX(ID, theSubject); failed++; }
  if(r == ACK) { failed = 0; return ACK; }
  if(r != ACK && failed >= 5) return FAIL;
}

// RECEIVING FUNCTIONS //////////////////////////////////////////////////////////////////

int bitRX() {
  unsigned long time = micros();                     // Save start time
  if(readDELAY > 0) delayMicroseconds(readDELAY);
  int BITreading = digitalReadFast(inputPIN);        // Speedy read of A0
  delayMicroseconds(BITwidth - (micros() - time));   // Delay untill bit is finished
  return BITreading;
}

byte byteRX() {
  byte BYTEValue = 0;
  for (int i = 7; i >= 0; i--) BYTEValue += ((bitRX() == HIGH) ? 1 : 0) << i;
  return BYTEValue;
}

int startRX() {
  pinModeFast(inputPIN, INPUT);
  unsigned long time = micros();                      // Save start time
  while (digitalReadFast(inputPIN) == HIGH && micros() - time <= BITspacer);
  time = micros() - time;                             // Calculate HIGH pulse duration
  if(time > spacerWINDOW) if(bitRX() == LOW) return (int)byteRX();
  // If you find a possible spacer a possibile byte is coming
  return FAIL;
}

void messageRX() {
  int num = 4;
  int firstBYTE = FAIL;
  while (firstBYTE == FAIL) firstBYTE = startRX();
  if(firstBYTE != slaveID) return;
  byte bytesREC[num];
  byte CRC = 0 ^ firstBYTE;
  bytesREC[0] = firstBYTE;
  for (int i = 1; i < num; i++) {
    bytesREC[i] = startRX();
    if (bytesREC[i] == FAIL) return;
    if(i == 1 && bytesREC[i] == REQ) num = 4;
    if(i == 1 && bytesREC[i] != REQ) num = 5;
    if (i < num - 1) CRC ^= bytesREC[i];
  }
  if (bytesREC[num - 1] == CRC) { byteTX(ACK); return; }
  if (bytesREC[num - 1] != CRC) { byteTX(NAK); return; }
}

//// LOOP //////////////////////////////////////////////////////////////////
byte value = 2;

void loop() {
  if(receiver) {
    messageRX();
  } else {
    value = commandTX(63,'@',test++);
    delay(25);
  }
}