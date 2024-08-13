#include <LiquidCrystal.h>
#include <IRremote.h>

// Initialize the LiquidCrystal library with the LCD pins
LiquidCrystal lcd(7, 8, 9, 10, 11, 12); // RS, E, D4, D5, D6, D7

void checkCommand(int button); 
void resetInputs();
void wrongPass(int s);
void beginFan();
void beginSensor();

// Receiver Pin
#define IR_RECEIVE_PIN 13

// Define pins for LEDs
const int greenLedPin = A2;
const int yellowLedPin = A1;
const int redLedPin = A0;

// Define L293D pin
const int trigPin = 2;
const int echoPin = 3;
const int motorPin = 4;
const int buzzer = 5;

// Define remote controller data
const int KEY =  22; // (IR_BUTTON_0)
const int  IR_BUTTON_1 = 12;
const int  IR_BUTTON_2  = 24;
const int  IR_BUTTON_3 = 94;
const int  IR_BUTTON_4 = 8;
const int  IR_BUTTON_5 = 28;
const int  IR_BUTTON_6 = 90;
const int  IR_BUTTON_7 = 66;
const int  IR_BUTTON_8 = 82;
const int  IR_BUTTON_9 = 74;



// Code sequence to disarm the alarm 
const int disarmCodeLength = 4;
const int disarmCode[disarmCodeLength] = {IR_BUTTON_3, IR_BUTTON_3, IR_BUTTON_3, IR_BUTTON_3};
int disarmCodeIndex = 0;
int numberOfInputs = 0;
int userCode[disarmCodeLength] = {0, 0, 0, 0};

bool key = false;
bool correct = false;
bool incorrect = false;
int tries = 0;

// Countdown timer variables
unsigned long previousMillis = 0;
const long interval = 1000; // 1 second
int seconds = 15; 
boolean alarmActive = true;
bool granted = false;

// Delay between button 'A' presses
unsigned long buttonDelayMillis = 500; // Adjust as needed

//sensor
long duration;
float distanceInch;
int timer;

const int ENABLE = 4;
const int DIRA = A3;
const int DIRB = A4;

void setup() {

  IrReceiver.begin(IR_RECEIVE_PIN);

  // Set the pinMode for LEDs 
  pinMode(greenLedPin, OUTPUT);
  pinMode(yellowLedPin, OUTPUT);
  pinMode(redLedPin, OUTPUT);

  // Set the L293D pinModes
  pinMode(trigPin, OUTPUT);
  pinMode(echoPin, INPUT);
  pinMode(buzzer, OUTPUT);

  //pinMode(motorPin, OUTPUT);
  pinMode(ENABLE,OUTPUT);
  pinMode(DIRA,OUTPUT);
  pinMode(DIRB,OUTPUT);
  
  // Initialize the LCD with 16 columns and 2 rows
  lcd.begin(16, 2);
  lcd.print("Enter PIN");
  delay(2000);
  lcd.clear();
  lcd.setCursor(0, 0);
  // Display initial time on the LCD
  lcd.print("TIME: 15");
  delay(2000);
  
}

void loop() {

    if(tries == 2){
      digitalWrite(redLedPin, HIGH);
      lcd.setCursor(0, 0);
      lcd.print("FAILED!!");
      beginSensor();
      
      
      
    }else{
        if(IrReceiver.decode()){ // returns true if receive data 
          int command = IrReceiver.decodedIRData.command;

          IrReceiver.resume();
        
          if(command != KEY){
            userCode[numberOfInputs] = command;

            // checkCommand(command);
            if(numberOfInputs < 3){
              numberOfInputs++;
            }

        }else{
            key = true;
        }

      }

      // Update the countdown timer
      unsigned long currentMillis = millis();
      if (alarmActive && currentMillis - previousMillis >= interval) {
        previousMillis = currentMillis;
        seconds--;

        // Check if seconds is negative
        if (seconds < 0 ) {
          // Timer expired, activate red LED and display "DENIED"
          alarmActive = false;
          digitalWrite(redLedPin, HIGH);
          lcd.clear();
          lcd.setCursor(0, 0);
          lcd.print("Access DENIED");
          delay(2000); // Display "Access DENIED" for 2 seconds
          lcd.clear();
          tries++;
          
        }
      }
      
      if(!granted){
        if(!alarmActive){

          if(tries < 2){ 
            wrongPass(seconds);
          }else{
            lcd.clear();
            delay(1000);
          }
            
        }else{
          // Display countdown and code on LCD
          lcd.setCursor(6, 0);
          lcd.print(seconds < 10 ? " " : ""); 
          lcd.print(seconds);
        }
      }
      
      

      if(key){

        for(int i = 0; i<disarmCodeLength; i++){
          if( userCode[i] == disarmCode[i]){
            disarmCodeIndex ++;
          }
        }

        if (disarmCodeIndex == disarmCodeLength) {
          correct = true ;
        }else{
          incorrect = true;
        }

        key = false;
        
      }


      // Check if the correct code was entered
      if (correct) {
        alarmActive = false;
        granted = true;
        digitalWrite(greenLedPin, HIGH);
        lcd.clear();
        lcd.setCursor(0, 0);
        delay(2000);
        lcd.clear();
        lcd.print("Access GRANTED");
        delay(1500);

        //begin fan portion
        lcd.clear();
        lcd.setCursor(0, 0);
        delay(1000);
        lcd.print("Fan Initializing...");
        delay(3000);
        beginFan();
        correct = false;


      }else{
        if(incorrect){
                  
          digitalWrite(yellowLedPin, HIGH);
          delay(1000); // Display "Incorrect" for 1 second
          digitalWrite(yellowLedPin, LOW);
          
          
          resetInputs();
        }
    
      }

      if(!correct && !incorrect && granted){
        beginFan();
      }


  }

   

 }


void resetInputs() {
  for (int i = 0; i < disarmCodeLength; i++) {
    userCode[i] = 0;
  }
  disarmCodeIndex = 0;
  numberOfInputs = 0;
  incorrect = false;
  correct = false;
  
}

void wrongPass(int s){
  if(s < 0){
    int s = 5;
    lcd.setCursor(0, 0);
    lcd.print("TIME: 5"); // Reset timer to 15 seconds
    while(s >= 0){
      lcd.setCursor(6, 0);
      lcd.print(s < 10 ? " " : ""); // Add a leading space if seconds is single-digit
      lcd.print(s);
      s--;
      delay(1000);
      //add beeping method
      //beginSensor();
    }
    lcd.clear();
    lcd.setCursor(0, 0);
    lcd.print("Try Again");
    delay(2000);
    lcd.clear();
    lcd.setCursor(0, 0);
    lcd.print("TIME: 15");
    alarmActive = true;
    seconds = 15;
    digitalWrite(redLedPin, LOW);
    resetInputs();
  }
  

}

void beginFan(){

  long duration, distance;
  digitalWrite(trigPin, LOW);
  delayMicroseconds(2);
  

  digitalWrite(trigPin, HIGH);
  delayMicroseconds(10);
  digitalWrite(trigPin, LOW);

  duration = pulseIn(echoPin, HIGH);
  distance = (duration * 0.0344) / 2;

  int level = map(distance, 5, 30.5, 6, 1);

  level = constrain(level,1,6);
  int speedValues[] = {26, 51, 102, 153, 204, 255};
  int speed = speedValues[level-1];

  //to start fan
  //analogWrite(motorPin, speed);
  digitalWrite(DIRA,HIGH); //one way
  digitalWrite(DIRB,LOW);
  analogWrite(ENABLE,speed); //enable on
  

  float voltage = (float)speed / 255.0 * 9.0;

  lcd.setCursor(0, 0);
  lcd.print("Fan Level: ");
  lcd.print(level);
  lcd.print("    ");  // Clear any trailing characters
  lcd.setCursor(0, 1);
  lcd.print("Voltage: ");
  lcd.print(voltage, 1);
  lcd.print("V   ");  // Clear any trailing characters

  delay(200);

}

void beginSensor(){

  digitalWrite(trigPin, LOW);
  delayMicroseconds(2);
  digitalWrite(trigPin, HIGH);
  delayMicroseconds(10);
  digitalWrite(trigPin, LOW);

  duration = pulseIn(echoPin, HIGH);

  distanceInch = duration * 0.0133 /2;

  if(distanceInch < 12){
     digitalWrite(buzzer, HIGH);
    delay(50);
    digitalWrite(buzzer, LOW);
  }else{
    digitalWrite(buzzer, LOW);
  }
  timer = distanceInch * 10;

  delay(timer);

}






void checkCommand(int button) {
  if(disarmCodeIndex < disarmCodeLength){
    if (button == disarmCode[disarmCodeIndex]) {
      disarmCodeIndex++;
      } else {
        // Delay between button presses
        disarmCodeIndex = 0;
       
      }
  }
  
}

