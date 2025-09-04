int phPin = A0;
int relay1 = 8;
int relay2 = 7;

float phValue = 0;

unsigned long relay1StartTime = 0;
unsigned long relay2StartTime = 0;
const unsigned long relayDuration = 5000;
bool relay1Active = false;
bool relay2Active = false;

void setup() {
  Serial.begin(9600);
  pinMode(relay1, OUTPUT);
  pinMode(relay2, OUTPUT);

  digitalWrite(relay1, HIGH);  // OFF initially (active-low relay)
  digitalWrite(relay2, HIGH);
}

void loop() {
  unsigned long currentMillis = millis();

  // Serial command handler
  if (Serial.available()) {
    String command = Serial.readStringUntil('\n');
    command.trim();

    if (command == "Increase") {
      digitalWrite(relay1, LOW);  // Turn ON relay1
      relay1StartTime = currentMillis;
      relay1Active = true;
    } 
    else if (command == "Reduce") {
      digitalWrite(relay2, LOW);  // Turn ON relay2
      relay2StartTime = currentMillis;
      relay2Active = true;
    }
  }

  //  Turn off relays after 5s
  if (relay1Active && currentMillis - relay1StartTime >= relayDuration) {
    digitalWrite(relay1, HIGH);  // OFF
    relay1Active = false;
  }
  if (relay2Active && currentMillis - relay2StartTime >= relayDuration) {
    digitalWrite(relay2, HIGH);  // OFF
    relay2Active = false;
  }

  //  pH reading only if no relay is ON
  if (!relay1Active && !relay2Active) {
    int sensorValue = analogRead(phPin);
    float voltage = sensorValue * (5.0 / 1023.0);
    phValue = 7 + ((2.5 - voltage) / 0.18)-1.0;

    Serial.println(phValue);
    delay(2000);  // Delay only if measuring pH
  }
}
