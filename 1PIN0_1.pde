#include <digitalWriteFast.h>

//  1PIN: OPENSOURCE COMMUNICATION PROTOCOL - MASTER>SLAVE ARCHITECTURE | 255 SELECTABLE SLAVE IDS 
//  Basically 2 entities: Master and slave and 2 objects: commands and requests.
//  COMMAND: |commandTYPE|ID|VALUE|VALUE|CRC| REQUEST: |REQ(byte255)|ID|SUBJECT|CRC|
//  TOOLS USED: micros(), delayMicroseconds(), digitalWriteFast lib | NO INTERRUPT, NO TIMERS

//  STD SPEED:  2,38 kb/s - 2380 baud/s - 396 cmd/s - 476 req/s | ACCURACY 99.93% (9993 cmd received / 10000 sent)
//  STD SETUP:  (Arduino duemilanove) [BITwidth 35|BITspacer 105|startWindow 70|readDelay 4]

//  FAST SPEED: 2,97 kb/s - 2976 baud/s - 496 cmd/s - 595 req/s | ACCURACY 86.78% (8678 cmd received / 10000 sent)
//  FAST SETUP: (Arduino duemilanove) [BITwidth 28|BITspacer  84|startWindow 40|readDelay 4]

//  Idea by Giovanni Blu Mitolo & Martino di Filippo - www.gioblu.com - gioscarab@gmail.com
//  1PIN is released under CreativeCommons Attribution-NonCommercial-ShareAlike 3.0 Unported License

// BASIC NODE INFO
const int inputPIN = A0;      // I/O pin where the wire is connected
boolean receiver = false;     // Master / Slave switch
const byte nodeID = 63;       // Node ID

// SETTING CONSTANTS
const int BITwidth = 28;      // single BIT duration in micros()
const int BITspacer = 84;     // syncronization spacer duration in micros()
const int spacerWINDOW = 40;  // Minimum acceptable HIGH spacer duration
const int readDELAY = 4;      // Delay before reading single BIT

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
  
int messageTX(byte ID, byte commandTYPE, unsigned int value) {
  byte bytesSend[5] = { commandTYPE, ID, value >> 8, value & 0xFF, 0 };
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
  if(r != ACK && failed < 5){ messageTX(ID, commandTYPE, value); failed++; mistakes++;}
  if(r == ACK) { failed = 0; return ACK; }
  if(r != ACK && failed >= 5) return FAIL;
}

int messageTX(byte ID, byte theSubject) { 
 byte bytesSend[4] = { 255, ID, theSubject, 0 };
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
  if(r != ACK && failed < 5){ messageTX(ID, theSubject); failed++; }
  if(r == ACK) { failed = 0; return ACK; }
  if(r != ACK && failed >= 5) return FAIL;
}

// RECEIVING FUNCTIONS //////////////////////////////////////////////////////////////////

int bitRX() {                            
  unsigned long time = micros();                     // Save start time
  delayMicroseconds(readDELAY);
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
  int num;
  int r = FAIL;
  while (r == FAIL) r = startRX(); 
  if(r == REQ) { num = 4; }
  if(r != FAIL && r != REQ) { num = 5; } else return;
  byte bytesReceive[num];
  byte CRC = 0 ^ r;
  bytesReceive[0] = r;
  for (int i = 1; i < num; i++) {
    r = startRX();
    if (r == FAIL) return; 
    bytesReceive[i] = r;
    if (i < num - 1) CRC ^= bytesReceive[i];
  }
  if (bytesReceive[1] == nodeID && bytesReceive[num - 1] == CRC) { byteTX(ACK); return; }
  if (bytesReceive[1] == nodeID && bytesReceive[num - 1] != CRC) { byteTX(NAK); return; }
}
    
//// LOOP //////////////////////////////////////////////////////////////////
byte value = 2;

void loop() {
  if(receiver) {
    messageRX();
  } else {
    value = messageTX(63,'@',test++);
    delay(25);
  }
}
