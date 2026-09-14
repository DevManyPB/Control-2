#include <Arduino.h>
#include <OneWire.h>
#include <DallasTemperature.h>
#include <DHT.h>
#include <ESP32Servo.h>
#include "driver/gpio.h"

// ========================================================
// ASIGNACIÓN DE PINES HARDWARE (ESP32) - ALUNA PBR-02
// Sensor 1: Agua / Reactor -> Pin D15 (GPIO 15)
// Sensor 2: Ambiente       -> Pin D13 (GPIO 13)
// Actuador Peltier (PWM)   -> Pin D25 (GPIO 25)
// Actuador Servomotor MG996R -> Pin D27 (GPIO 27)
// ========================================================
const int PIN_SENSOR_AGUA_15 = 15; // D15: Sensor de Agua (DS18B20) [PRINCIPAL]
const int PIN_SENSOR_AGUA_14 = 14; // D14: Canal alternativo
const int PIN_SENSOR_AGUA_32 = 32; // D32: Canal alternativo

const int PIN_SENSOR_AIRE_13 = 13; // D13: Sensor Ambiente (DS18B20 / DHT22) [PRINCIPAL]
const int PIN_DHT_4          = 4;  // D4:  Canal alternativo DHT22

const int PELTIER_PWM_PIN    = 25; // D25: Control MOSFET Peltier
const int SERVO_PIN          = 27; // D27: Servomotor Escudo Orbital

#define DHTTYPE DHT22

// --- Sensores 1-Wire DS18B20 ---
OneWire oneWireAgua15(PIN_SENSOR_AGUA_15);
DallasTemperature sensorAgua15(&oneWireAgua15);

OneWire oneWireAgua14(PIN_SENSOR_AGUA_14);
DallasTemperature sensorAgua14(&oneWireAgua14);

OneWire oneWireAire13(PIN_SENSOR_AIRE_13);
DallasTemperature sensorAire13(&oneWireAire13);

// --- Sensores DHT22 ---
DHT dht13(PIN_SENSOR_AIRE_13, DHTTYPE);
DHT dht4(PIN_DHT_4, DHTTYPE);

Servo servoCortina;

unsigned long last_read = 0;
bool is_testing = false;
unsigned long start_time = 0;
int pwm_actual = 0;
int servo_angle_actual = 0;

void setup() {
  Serial.begin(115200);
  delay(500);

  // Pull-ups para pines 1-Wire
  pinMode(PIN_SENSOR_AGUA_15, INPUT_PULLUP);
  pinMode(PIN_SENSOR_AGUA_14, INPUT_PULLUP);
  pinMode(PIN_SENSOR_AIRE_13, INPUT_PULLUP);
  gpio_pullup_en((gpio_num_t)PIN_SENSOR_AGUA_15);
  gpio_pullup_en((gpio_num_t)PIN_SENSOR_AGUA_14);
  gpio_pullup_en((gpio_num_t)PIN_SENSOR_AIRE_13);

  sensorAgua15.begin();
  sensorAgua14.begin();
  sensorAire13.begin();

  sensorAgua15.setWaitForConversion(true);
  sensorAgua14.setWaitForConversion(true);
  sensorAire13.setWaitForConversion(true);

  sensorAgua15.setResolution(10);
  sensorAgua14.setResolution(10);
  sensorAire13.setResolution(10);

  // Inicializar DHT22
  dht13.begin();
  dht4.begin();

  // PWM Peltier en D25 (1 kHz, 8 bits)
  pinMode(PELTIER_PWM_PIN, OUTPUT);
  digitalWrite(PELTIER_PWM_PIN, LOW);
  ledcAttach(PELTIER_PWM_PIN, 1000, 8);
  ledcWrite(PELTIER_PWM_PIN, 0);

  // Servomotor en D27 (50 Hz)
  servoCortina.setPeriodHertz(50);
  servoCortina.attach(SERVO_PIN, 500, 2500);
  servoCortina.write(0);

  Serial.println("==================================================");
  Serial.println("   ALUNA PBR-02 | ARQUITECTURA D15 + D13          ");
  Serial.println("   S1 (Agua): Pin D15 (DS18B20)                   ");
  Serial.println("   S2 (Ambiente): Pin D13 (DS18B20 / DHT22)       ");
  Serial.println("   Peltier: D25 | Servo Cortina: D27              ");
  Serial.println("==================================================");
}

void aplicarPeltierPWM(int val) {
  pwm_actual = constrain(val, 0, 255);
  ledcWrite(PELTIER_PWM_PIN, pwm_actual);
  analogWrite(PELTIER_PWM_PIN, pwm_actual);
}

void loop() {
  // ==========================================
  // LECTURA DE COMANDOS DESDE LA WEB / SERIAL
  // ==========================================
  if (Serial.available() > 0) {
    String cmd = Serial.readStringUntil('\n');
    cmd.trim();

    if (cmd == "S" || cmd == "s") {
      is_testing = true;
      start_time = millis();
      aplicarPeltierPWM(153);
      Serial.println(">>> ENSAYO INICIADO: PWM = 153 (60%)");
    } 
    else if (cmd == "X" || cmd == "x") {
      is_testing = false;
      aplicarPeltierPWM(0);
      servo_angle_actual = 0;
      servoCortina.write(0);
      Serial.println(">>> PARO TOTAL EJECUTADO (PWM = 0, SERVO = 0°)");
    }
    else if (cmd.startsWith("M:")) {
      int val = cmd.substring(2).toInt();
      aplicarPeltierPWM(val);
      if (!is_testing) {
        is_testing = true;
        start_time = millis();
      }
      Serial.print(">>> PWM ACTUALIZADO: ");
      Serial.println(pwm_actual);
    }
    else if (cmd.startsWith("C:")) {
      int angle = cmd.substring(2).toInt();
      servo_angle_actual = constrain(angle, 0, 180);
      servoCortina.write(servo_angle_actual);
      Serial.print(">>> SERVO CORTINA: ");
      Serial.println(servo_angle_actual);
    }
  }

  // ==========================================
  // TELEMETRÍA PERIÓDICA (CADA 2 SEGUNDOS)
  // ==========================================
  if (millis() - last_read >= 2000) {
    last_read = millis();

    // ----------------------------------------------------
    // 1. Lectura Sensor 1 (Agua): D15 primero, fallback D14
    // ----------------------------------------------------
    sensorAgua15.requestTemperatures();
    float temp_agua = sensorAgua15.getTempCByIndex(0);
    if (temp_agua == DEVICE_DISCONNECTED_C || temp_agua <= -100.0) {
      sensorAgua14.requestTemperatures();
      float t14 = sensorAgua14.getTempCByIndex(0);
      if (t14 > -100.0 && t14 != DEVICE_DISCONNECTED_C) {
        temp_agua = t14;
      }
    }

    // ----------------------------------------------------
    // 2. Lectura Sensor 2 (Ambiente en D13):
    //    Primero intentamos DHT22 en D13. Si no hay datos,
    //    probamos DS18B20 en D13. Fallback a DHT22 en D4.
    // ----------------------------------------------------
    float temp_aire = -127.0;
    float hum_aire  = 0.0;

    // Intento 2A: DHT22 en D13
    float t_dht13 = dht13.readTemperature();
    float h_dht13 = dht13.readHumidity();
    if (!isnan(t_dht13) && !isnan(h_dht13) && t_dht13 > -40.0 && t_dht13 < 80.0) {
      temp_aire = t_dht13;
      hum_aire  = h_dht13;
    } else {
      // Intento 2B: DS18B20 en D13
      sensorAire13.requestTemperatures();
      float t_ds13 = sensorAire13.getTempCByIndex(0);
      if (t_ds13 > -100.0 && t_ds13 != DEVICE_DISCONNECTED_C) {
        temp_aire = t_ds13;
        hum_aire  = 0.0;
      } else {
        // Intento 2C: DHT22 en D4 (por si está en D4)
        float t_dht4 = dht4.readTemperature();
        float h_dht4 = dht4.readHumidity();
        if (!isnan(t_dht4) && !isnan(h_dht4) && t_dht4 > -40.0 && t_dht4 < 80.0) {
          temp_aire = t_dht4;
          hum_aire  = h_dht4;
        } else if (sensorAgua15.getDeviceCount() >= 2) {
          // Ambos DS18B20 en paralelo en D15
          float t_ds15_2 = sensorAgua15.getTempCByIndex(1);
          if (t_ds15_2 > -100.0 && t_ds15_2 != DEVICE_DISCONNECTED_C) {
            temp_aire = t_ds15_2;
          }
        }
      }
    }

    if (isnan(temp_aire)) temp_aire = -127.0;
    if (isnan(hum_aire))  hum_aire  = 0.0;

    float t = is_testing ? ((millis() - start_time) / 1000.0) : 0.0;

    // Formato CSV estándar: tiempo,pwm,temp_agua,temp_ambiente,angulo_servo,humedad
    Serial.print(t, 2);
    Serial.print(",");
    Serial.print(pwm_actual);
    Serial.print(",");
    Serial.print(temp_agua, 2);
    Serial.print(",");
    Serial.print(temp_aire, 2);
    Serial.print(",");
    Serial.print(servo_angle_actual);
    Serial.print(",");
    Serial.println(hum_aire, 1);
  }
}
