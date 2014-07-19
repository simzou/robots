#define LPLUS 6
#define LMINUS 7
#define RPLUS 8
#define RMINUS 9
#define IR 4
  
void initPins()
{
  pinMode(LPLUS, OUTPUT);
  pinMode(LMINUS, OUTPUT);
  pinMode(RPLUS, OUTPUT);
  pinMode(RMINUS, OUTPUT);
  
  pinMode(IR, INPUT);
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

void rotateRight() {
  digitalWrite(LPLUS, HIGH);
  digitalWrite(LMINUS, LOW);
  digitalWrite(RPLUS, LOW);
  digitalWrite(RMINUS, HIGH);
}

uint16_t collectData() {
  uint16_t data = 0;
  for (int i = 0; i <15000; ++i) {
    uint16_t raw = analogRead(IR);
    if (raw > 800) {
      data += 1;
    }
  }
  return data;
}
