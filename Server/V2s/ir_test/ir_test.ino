/*
* IR obstacle avoidance sensor testing
* feiticeir0@whatgeek.com.pt
* Free to share !
*/
int count;
void setup() {

 Serial.begin (9600);
 pinMode (9, INPUT); //Sensor output
}
void loop() {
Serial.print ("Sensor: ");
 Serial.println (digitalRead(9)); //print the sensor output
 delay (500); //wait half a second
}
