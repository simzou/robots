#define LPLUS 6
#define LMINUS 7
#define RPLUS 8
#define RMINUS 9
#define IR 4

int data;
  
void setup()
{
  Serial.begin(9600);
  pinMode(LPLUS, OUTPUT);
  pinMode(LMINUS, OUTPUT);
  pinMode(RPLUS, OUTPUT);
  pinMode(RMINUS, OUTPUT);
  
  int time = 3000;
  int data;
  forward();
  int t = millis();
  while (millis()  - t < time)
  {
    int dataToAdd = 710 - analogRead(IR);
    Serial.println(dataToAdd);
    data += dataToAdd;
    
  }
  halt();
  Serial.println(data);
}


void forward(){
  digitalWrite(LPLUS, HIGH);
  digitalWrite(LMINUS, LOW);
  digitalWrite(RPLUS, HIGH);
  digitalWrite(RMINUS, LOW);
}


void backward(){
  digitalWrite(LPLUS, LOW);
  digitalWrite(LMINUS, HIGH);
  digitalWrite(RPLUS, LOW);
  digitalWrite(RMINUS, HIGH);
}

void rotateLeft() {
  digitalWrite(LPLUS, LOW);
  digitalWrite(LMINUS, HIGH);
  digitalWrite(RPLUS, HIGH);
  digitalWrite(RMINUS, LOW);
}

void halt()
{
  digitalWrite(LPLUS, LOW);
  digitalWrite(LMINUS, LOW);
  digitalWrite(RPLUS, LOW);
  digitalWrite(RMINUS, LOW);
}


void loop()
{

}
