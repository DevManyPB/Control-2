#include <Arduino.h>
#include <OneWire.h>
#include <DallasTemperature.h>
#include <DHT.h>
#include <ESP32Servo.h>
#include "driver/gpio.h"

// ==========================================
// ASIGNACIÓN DE PINES HARDWARE (ESP32)
// ALUNA PBR-02 (Arquitectura Híbrida DS18B20 + DHT22)
// ==========================================
const int PIN_SENSOR_AGUA_15 = 15; // D15: Sensor de Agua / Reactor (DS18B20)
const int PIN_SENSOR_AGUA_32 = 32; // D32: Canal alternativo de Agua
const int PIN_DHT_4          = 4;  // D4: Sensor Ambiente DHT22 (Data)
const int PIN_DHT_13         = 13; // D13: Canal alternativo DHT22
const int PELTIER_PWM_PIN    = 25; // D25: Control PWM MOSFET Celda Peltier
const int SERVO_PIN          = 27; // D27: Servomotor MG996R Escudo Orbital

#define DHTTYPE DHT22

// ==========================================
// INSTANCIAS DE HARDWARE
// ==========================================
OneWire oneWireAgua15(PIN_SENSOR_AGUA_15);
DallasTemperature sensorAgua15(&oneWireAgua15);

OneWire oneWireAgua32(PIN_SENSOR_AGUA_32);
DallasTemperature sensorAgua32(&oneWireAgua32);

DHT dht4(PIN_DHT_4, DHTTYPE);
DHT dht13(PIN_DHT_13, DHTTYPE);

Servo servoCortina;

// ==========================================
// VARIABLES DE ESTADO Y TELEMETRÍA
// ==========================================
unsigned long last_read = 0;
bool is_testing = false;
unsigned long start_time = 0;
int pwm_actual = 0;         // 0 a 255
int servo_angle_actual = 0; // 0° (Abierto) a 180° (Cerrado)

void setup() {
  Serial.begin(115200);
  delay(500);
  
  // Activar pull-ups internos para el DS18B20
  pinMode(PIN_SENSOR_AGUA_15, INPUT_PULLUP);
  pinMode(PIN_SENSOR_AGUA_32, INPUT_PULLUP);
  gpio_pullup_en((gpio_num_t)PIN_SENSOR_AGUA_15);
  gpio_pullup_en((gpio_num_t)PIN_SENSOR_AGUA_32);

  sensorAgua15.begin();
  sensorAgua32.begin();
  sensorAgua15.setWaitForConversion(true);
  sensorAgua32.setWaitForConversion(true);
  sensorAgua15.setResolution(10); // 187 ms por conversión (rápido y ultra estable)
  sensorAgua32.setResolution(10);

  // Inicializar sensor DHT22 en D4 y D13
  dht4.begin();
  dht13.begin();
  
  // Configuración PWM Peltier en D25 (1 kHz, 8 bits: 0-255)
  ledcAttach(PELTIER_PWM_PIN, 1000, 8);
  ledcWrite(PELTIER_PWM_PIN, 0);

  // Configuración Servomotor MG996R en D27 (50 Hz estándar)
  servoCortina.setPeriodHertz(50);
  servoCortina.attach(SERVO_PIN, 500, 2500);
  servoCortina.write(0); // 0° = Escudo Abierto (Fotosíntesis)

  Serial.println("==================================================");
  Serial.println("   ALUNA PBR-02 | SISTEMA TÉRMICO HÍBRIDO         ");
  Serial.println("   S1: DS18B20 (Agua en D15/D32)                  ");
  Serial.println("   S2: DHT22 (Ambiente & Humedad en D4/D13)       ");
  Serial.println("   Peltier PWM: Pin D25 | Servo Escudo: Pin D27   ");
  Serial.println("==================================================");
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
      pwm_actual = 153;
      ledcWrite(PELTIER_PWM_PIN, pwm_actual);
      Serial.println(">>> ENSAYO INICIADO: PWM = 153 (60%)");
    } 
    else if (cmd == "X" || cmd == "x") {
      is_testing = false;
      pwm_actual = 0;
      ledcWrite(PELTIER_PWM_PIN, 0);
      servo_angle_actual = 0;
      servoCortina.write(0);
      Serial.println(">>> PARO TOTAL EJECUTADO (PWM = 0, SERVO = 0°)");
    }
    else if (cmd.startsWith("M:")) {
      int val = cmd.substring(2).toInt();
      pwm_actual = constrain(val, 0, 255);
      ledcWrite(PELTIER_PWM_PIN, pwm_actual);
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
  if (is_testing) {
    if (millis() - last_read >= 2000) {
      last_read = millis();
      
      // 1. Lectura Sensor 1 (DS18B20 Agua): D15 primero, fallback a D32
      sensorAgua15.requestTemperatures();
      float temp_agua = sensorAgua15.getTempCByIndex(0);
      if (temp_agua == DEVICE_DISCONNECTED_C || temp_agua <= -100.0) {
        sensorAgua32.requestTemperatures();
        float temp32 = sensorAgua32.getTempCByIndex(0);
        if (temp32 > -100.0 && temp32 != DEVICE_DISCONNECTED_C) {
          temp_agua = temp32;
        }
      }

      // 2. Lectura Sensor 2 (DHT22 Ambiente): D4 primero, fallback a D13
      float temp_aire = dht4.readTemperature();
      float hum_aire  = dht4.readHumidity();
      if (isnan(temp_aire) || isnan(hum_aire)) {
        temp_aire = dht13.readTemperature();
        hum_aire  = dht13.readHumidity();
      }
      if (isnan(temp_aire)) temp_aire = -127.0;
      if (isnan(hum_aire))  hum_aire  = 0.0;
      
      float t = (millis() - start_time) / 1000.0;
      
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
}
