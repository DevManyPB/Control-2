#include <OneWire.h>
#include <DallasTemperature.h>
#include "driver/gpio.h"

// ========================================================
// ASIGNACIÓN DE PINES HARDWARE - ALUNA PBR-02
// ========================================================
const int PIN_SENSOR_AGUA = 15;  // D15 (Sensor 1 - Agua / Reactor)
const int PIN_SENSOR_AIRE = 13;  // D13 (Sensor 2 - Ambiente / Disipador)
const int PELTIER_PWM_PIN = 25;  // D25 (Control MOSFET Peltier)

OneWire oneWireAgua(PIN_SENSOR_AGUA);
DallasTemperature sensorAgua(&oneWireAgua);

OneWire oneWireAire(PIN_SENSOR_AIRE);
DallasTemperature sensorAire(&oneWireAire);

const int POTENCIA_ESCALON = 153; // Escalón 60% (153/255)
int pwm_actual = 0;
bool prueba_iniciada = false;

unsigned long tiempo_inicio = 0;
unsigned long tiempo_anterior = 0;
const unsigned long INTERVALO_MUESTREO = 1000; // 1 segundo

void setup() {
  Serial.begin(115200);
  
  // Activar resistencias pull-up internas
  pinMode(PIN_SENSOR_AGUA, INPUT_PULLUP);
  pinMode(PIN_SENSOR_AIRE, INPUT_PULLUP);
  gpio_pullup_en((gpio_num_t)PIN_SENSOR_AGUA);
  gpio_pullup_en((gpio_num_t)PIN_SENSOR_AIRE);

  sensorAgua.begin();
  sensorAire.begin();
  sensorAgua.setWaitForConversion(true);
  sensorAire.setWaitForConversion(true);

  // ESP32 Core 3.x PWM
  ledcAttach(PELTIER_PWM_PIN, 1000, 8);
  ledcWrite(PELTIER_PWM_PIN, 0);

  Serial.println("==================================================");
  Serial.println("   ALUNA PBR-02 | ENSAYO DE RESPUESTA AL ESCALON  ");
  Serial.println("==================================================");
  Serial.println("Envia 'S' por monitor serial para aplicar el escalon (PWM = 153 / 60%)");
  Serial.println("Envia 'X' para detener y apagar");
  Serial.println("--------------------------------------------------");
}

void loop() {
  if (Serial.available() > 0) {
    char c = Serial.read();
    if (c == 'S' || c == 's') {
      prueba_iniciada = true;
      pwm_actual = POTENCIA_ESCALON;
      ledcWrite(PELTIER_PWM_PIN, pwm_actual);
      tiempo_inicio = millis();
      tiempo_anterior = millis();
      Serial.println("\n--- PRUEBA INICIADA ---");
      Serial.println("Tiempo_s,PWM,Temp_Agua,Temp_Ambiente");
    } else if (c == 'X' || c == 'x') {
      prueba_iniciada = false;
      pwm_actual = 0;
      ledcWrite(PELTIER_PWM_PIN, 0);
      Serial.println("\n--- PRUEBA DETENIDA (PWM = 0) ---");
    }
  }

  if (prueba_iniciada) {
    unsigned long ahora = millis();
    if (ahora - tiempo_anterior >= INTERVALO_MUESTREO) {
      tiempo_anterior = ahora;

      sensorAgua.requestTemperatures();
      sensorAire.requestTemperatures();
      float t1 = sensorAgua.getTempCByIndex(0);
      float t2 = sensorAire.getTempCByIndex(0);

      float t_seg = (ahora - tiempo_inicio) / 1000.0;

      // Telemetría CSV
      Serial.print(t_seg, 1);
      Serial.print(",");
      Serial.print(pwm_actual);
      Serial.print(",");
      Serial.print(t1, 2);
      Serial.print(",");
      Serial.println(t2, 2);
    }
  }
}
