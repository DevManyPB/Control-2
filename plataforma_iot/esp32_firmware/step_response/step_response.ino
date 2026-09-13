#include <OneWire.h>
#include <DallasTemperature.h>
#include "driver/gpio.h"

// ========================================================
// ASIGNACIÓN DE PINES HARDWARE - ALUNA PBR-02
// Ensayo de Respuesta al Escalón (FOPDT Térmico)
// ========================================================
const int PIN_SENSOR_AGUA = 15;  // D15 (Sensor Único - Agua / Reactor)
const int PELTIER_PWM_PIN = 25;  // D25 (Control MOSFET Peltier)

OneWire oneWireAgua(PIN_SENSOR_AGUA);
DallasTemperature sensorAgua(&oneWireAgua);

const int POTENCIA_ESCALON = 153; // Escalón 60% (153/255)
int pwm_actual = 0;
bool prueba_iniciada = false;

unsigned long tiempo_inicio = 0;
unsigned long tiempo_anterior = 0;
const unsigned long INTERVALO_MUESTREO = 1000; // 1 muestra por segundo

void setup() {
  Serial.begin(115200);
  delay(500);
  
  // Activar resistencia pull-up interna
  pinMode(PIN_SENSOR_AGUA, INPUT_PULLUP);
  gpio_pullup_en((gpio_num_t)PIN_SENSOR_AGUA);

  sensorAgua.begin();
  sensorAgua.setWaitForConversion(true);
  sensorAgua.setResolution(10); // 187 ms por conversión (rápido y estable)

  // Configuración PWM ESP32
  ledcAttach(PELTIER_PWM_PIN, 1000, 8);
  ledcWrite(PELTIER_PWM_PIN, 0);

  Serial.println("==================================================");
  Serial.println("   ALUNA PBR-02 | ENSAYO DE RESPUESTA AL ESCALON  ");
  Serial.println("   Sensor único: Pin D15 | Escalón Peltier: D25   ");
  Serial.println("==================================================");
  Serial.println("Comando 'S' -> Aplicar escalón (PWM = 153 / 60%)");
  Serial.println("Comando 'X' -> Detener ensayo y apagar Peltier");
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
      Serial.println("\n--- ENSAYO FOPDT INICIADO ---");
      Serial.println("Tiempo_s,PWM,Temp_Agua,Temp_Aux,Servo");
    } else if (c == 'X' || c == 'x') {
      prueba_iniciada = false;
      pwm_actual = 0;
      ledcWrite(PELTIER_PWM_PIN, 0);
      Serial.println("\n--- ENSAYO DETENIDO (PWM = 0) ---");
    }
  }

  if (prueba_iniciada) {
    unsigned long ahora = millis();
    if (ahora - tiempo_anterior >= INTERVALO_MUESTREO) {
      tiempo_anterior = ahora;

      sensorAgua.requestTemperatures();
      float t1 = sensorAgua.getTempCByIndex(0);
      float t_seg = (ahora - tiempo_inicio) / 1000.0;

      // Telemetría CSV estándar compatible con la plataforma web:
      // tiempo,pwm,temp_agua,temp_aux,servo
      Serial.print(t_seg, 1);
      Serial.print(",");
      Serial.print(pwm_actual);
      Serial.print(",");
      Serial.print(t1, 2);
      Serial.print(",");
      Serial.print(t1, 2);
      Serial.println(",0");
    }
  }
}
