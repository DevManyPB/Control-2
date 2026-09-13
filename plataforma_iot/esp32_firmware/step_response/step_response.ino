#include <OneWire.h>
#include <DallasTemperature.h>
#include "driver/gpio.h"

// ========================================================
// ASIGNACIÓN DE PINES HARDWARE - ALUNA PBR-02
// Ensayo de Respuesta al Escalón (FOPDT Dual)
// ========================================================
const int PIN_SENSOR_AGUA_15 = 15; // D15 (Canal primario Agua)
const int PIN_SENSOR_AGUA_32 = 32; // D32 (Canal alternativo Agua)
const int PIN_SENSOR_AIRE_13 = 13; // D13 (Canal Ambiente / Disipador)
const int PELTIER_PWM_PIN    = 25; // D25 (Control MOSFET Peltier)

OneWire oneWireAgua15(PIN_SENSOR_AGUA_15);
DallasTemperature sensorAgua15(&oneWireAgua15);

OneWire oneWireAgua32(PIN_SENSOR_AGUA_32);
DallasTemperature sensorAgua32(&oneWireAgua32);

OneWire oneWireAire13(PIN_SENSOR_AIRE_13);
DallasTemperature sensorAire13(&oneWireAire13);

const int POTENCIA_ESCALON = 153; // Escalón 60% (153/255)
int pwm_actual = 0;
bool prueba_iniciada = false;

unsigned long tiempo_inicio = 0;
unsigned long tiempo_anterior = 0;
const unsigned long INTERVALO_MUESTREO = 1000; // 1 muestra por segundo

void setup() {
  Serial.begin(115200);
  delay(500);
  
  // Activar resistencias pull-up internas
  pinMode(PIN_SENSOR_AGUA_15, INPUT_PULLUP);
  pinMode(PIN_SENSOR_AGUA_32, INPUT_PULLUP);
  pinMode(PIN_SENSOR_AIRE_13, INPUT_PULLUP);
  gpio_pullup_en((gpio_num_t)PIN_SENSOR_AGUA_15);
  gpio_pullup_en((gpio_num_t)PIN_SENSOR_AGUA_32);
  gpio_pullup_en((gpio_num_t)PIN_SENSOR_AIRE_13);

  sensorAgua15.begin();
  sensorAgua32.begin();
  sensorAire13.begin();
  sensorAgua15.setWaitForConversion(true);
  sensorAgua32.setWaitForConversion(true);
  sensorAire13.setWaitForConversion(true);
  sensorAgua15.setResolution(10); // 187 ms por conversión
  sensorAgua32.setResolution(10);
  sensorAire13.setResolution(10);

  // Configuración PWM ESP32
  ledcAttach(PELTIER_PWM_PIN, 1000, 8);
  ledcWrite(PELTIER_PWM_PIN, 0);

  Serial.println("==================================================");
  Serial.println("   ALUNA PBR-02 | ENSAYO DE RESPUESTA AL ESCALON  ");
  Serial.println("   S1 (Agua): D15/D32 | S2 (Aire): D13 | PWM: D25  ");
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
      Serial.println("Tiempo_s,PWM,Temp_Agua,Temp_Ambiente,Servo");
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

      // Lectura Sensor 1 (Agua)
      sensorAgua15.requestTemperatures();
      float t1 = sensorAgua15.getTempCByIndex(0);
      if (t1 == DEVICE_DISCONNECTED_C || t1 <= -100.0) {
        sensorAgua32.requestTemperatures();
        float t32 = sensorAgua32.getTempCByIndex(0);
        if (t32 > -100.0 && t32 != DEVICE_DISCONNECTED_C) {
          t1 = t32;
        }
      }

      // Lectura Sensor 2 (Ambiente)
      sensorAire13.requestTemperatures();
      float t2 = sensorAire13.getTempCByIndex(0);
      if (sensorAgua15.getDeviceCount() >= 2 && (t2 == DEVICE_DISCONNECTED_C || t2 <= -100.0)) {
        t2 = sensorAgua15.getTempCByIndex(1);
      }

      float t_seg = (ahora - tiempo_inicio) / 1000.0;

      // Telemetría CSV estándar compatible con la plataforma web:
      // tiempo,pwm,temp_agua,temp_ambiente,servo
      Serial.print(t_seg, 1);
      Serial.print(",");
      Serial.print(pwm_actual);
      Serial.print(",");
      Serial.print(t1, 2);
      Serial.print(",");
      Serial.print(t2, 2);
      Serial.println(",0");
    }
  }
}
