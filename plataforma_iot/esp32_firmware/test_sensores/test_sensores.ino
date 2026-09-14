#include <Arduino.h>
#include <OneWire.h>
#include <DallasTemperature.h>
#include <DHT.h>
#include "driver/gpio.h"

// ========================================================
// ALUNA PBR-02 | BANCO DE PRUEBAS DE SENSORES HÍBRIDOS
// Sensor 1: DS18B20 (Agua / Reactor en D15)
// Sensor 2: DHT22 o DS18B20 (Ambiente en D13)
// ========================================================

const int PIN_SENSOR_AGUA_15 = 15; // D15: Sensor de Agua (DS18B20)
const int PIN_SENSOR_AIRE_13 = 13; // D13: Sensor Ambiente (DS18B20 / DHT22)
const int PIN_SENSOR_AGUA_14 = 14; // D14: Alternativo
const int PIN_DHT_4          = 4;  // D4:  Alternativo DHT22

#define DHTTYPE DHT22

OneWire bus15(PIN_SENSOR_AGUA_15);
DallasTemperature sensorAgua15(&bus15);

OneWire bus13(PIN_SENSOR_AIRE_13);
DallasTemperature sensorAire13(&bus13);

OneWire bus14(PIN_SENSOR_AGUA_14);
DallasTemperature sensorAgua14(&bus14);

DHT dht13(PIN_SENSOR_AIRE_13, DHTTYPE);
DHT dht4(PIN_DHT_4, DHTTYPE);

char test_mode = 'B';
unsigned long last_print = 0;
unsigned long start_time = 0;

void setup() {
  Serial.begin(115200);
  delay(1000);

  Serial.println("\n==================================================");
  Serial.println("   ALUNA PBR-02 | BANCO DE PRUEBAS D15 & D13      ");
  Serial.println("   Sensor 1: DS18B20 en D15                       ");
  Serial.println("   Sensor 2: DS18B20 / DHT22 en D13               ");
  Serial.println("==================================================");

  pinMode(PIN_SENSOR_AGUA_15, INPUT_PULLUP);
  pinMode(PIN_SENSOR_AIRE_13, INPUT_PULLUP);
  pinMode(PIN_SENSOR_AGUA_14, INPUT_PULLUP);
  gpio_pullup_en((gpio_num_t)PIN_SENSOR_AGUA_15);
  gpio_pullup_en((gpio_num_t)PIN_SENSOR_AIRE_13);
  gpio_pullup_en((gpio_num_t)PIN_SENSOR_AGUA_14);

  sensorAgua15.begin();
  sensorAire13.begin();
  sensorAgua14.begin();
  sensorAgua15.setResolution(10);
  sensorAire13.setResolution(10);
  sensorAgua14.setResolution(10);
  sensorAgua15.setWaitForConversion(true);
  sensorAire13.setWaitForConversion(true);
  sensorAgua14.setWaitForConversion(true);

  dht13.begin();
  dht4.begin();

  start_time = millis();
}

void loop() {
  if (Serial.available() > 0) {
    char c = Serial.read();
    if (c == '1' || c == '2' || c == 'B' || c == 'b') {
      test_mode = toupper(c);
    }
  }

  if (millis() - last_print >= 2000) {
    last_print = millis();
    float t = (millis() - start_time) / 1000.0;

    float temp_agua = -127.0;
    float temp_aire = -127.0;
    float hum_aire  = 0.0;

    // 1. Lectura DS18B20 en D15
    if (test_mode == '1' || test_mode == 'B') {
      sensorAgua15.requestTemperatures();
      temp_agua = sensorAgua15.getTempCByIndex(0);
      if (temp_agua == DEVICE_DISCONNECTED_C || temp_agua <= -100.0) {
        sensorAgua14.requestTemperatures();
        float t14 = sensorAgua14.getTempCByIndex(0);
        if (t14 > -100.0 && t14 != DEVICE_DISCONNECTED_C) temp_agua = t14;
      }
    }

    // 2. Lectura Sensor 2 en D13 (DHT22 o DS18B20)
    if (test_mode == '2' || test_mode == 'B') {
      float t13 = dht13.readTemperature();
      float h13 = dht13.readHumidity();
      if (!isnan(t13) && !isnan(h13)) {
        temp_aire = t13;
        hum_aire  = h13;
      } else {
        sensorAire13.requestTemperatures();
        float t_ds = sensorAire13.getTempCByIndex(0);
        if (t_ds > -100.0 && t_ds != DEVICE_DISCONNECTED_C) {
          temp_aire = t_ds;
          hum_aire = 0.0;
        }
      }
    }

    // Salida CSV oficial
    Serial.print(t, 1);
    Serial.print(",0,");
    Serial.print(temp_agua, 2);
    Serial.print(",");
    Serial.print(temp_aire, 2);
    Serial.print(",0,");
    Serial.println(hum_aire, 1);
  }
}
