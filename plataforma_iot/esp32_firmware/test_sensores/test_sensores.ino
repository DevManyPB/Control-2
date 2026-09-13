#include <Arduino.h>
#include <OneWire.h>
#include <DallasTemperature.h>
#include <DHT.h>
#include "driver/gpio.h"

// ========================================================
// ALUNA PBR-02 | BANCO DE PRUEBAS DE SENSORES HÍBRIDOS
// Sensor 1: DS18B20 (Agua / Reactor en D15 o D32)
// Sensor 2: DHT22 (Ambiente & Humedad en D4 o D13)
// ========================================================

const int PIN_DS18B20_15 = 15; // D15: Sensor de Agua (DS18B20)
const int PIN_DS18B20_32 = 32; // D32: Alternativo Agua (DS18B20)
const int PIN_DHT_4      = 4;  // D4: Sensor Ambiente (DHT22)
const int PIN_DHT_13     = 13; // D13: Alternativo DHT22

#define DHTTYPE DHT22

OneWire bus15(PIN_DS18B20_15);
DallasTemperature sensorAgua15(&bus15);

OneWire bus32(PIN_DS18B20_32);
DallasTemperature sensorAgua32(&bus32);

DHT dht4(PIN_DHT_4, DHTTYPE);
DHT dht13(PIN_DHT_13, DHTTYPE);

char test_mode = 'B'; // '1'=Solo DS18B20, '2'=Solo DHT22, 'B'=Ambos
unsigned long last_print = 0;
unsigned long start_time = 0;

void setup() {
  Serial.begin(115200);
  delay(1000);

  Serial.println("\n==================================================");
  Serial.println("   ALUNA PBR-02 | BANCO DE PRUEBAS HÍBRIDO        ");
  Serial.println("   Sensor 1: DS18B20 (Agua / Reactor D15/D32)     ");
  Serial.println("   Sensor 2: DHT22 (Ambiente / Humedad D4/D13)    ");
  Serial.println("==================================================");

  // Pull-up para DS18B20
  pinMode(PIN_DS18B20_15, INPUT_PULLUP);
  pinMode(PIN_DS18B20_32, INPUT_PULLUP);
  gpio_pullup_en((gpio_num_t)PIN_DS18B20_15);
  gpio_pullup_en((gpio_num_t)PIN_DS18B20_32);

  sensorAgua15.begin();
  sensorAgua32.begin();
  sensorAgua15.setResolution(10);
  sensorAgua32.setResolution(10);
  sensorAgua15.setWaitForConversion(true);
  sensorAgua32.setWaitForConversion(true);

  // Inicializar DHT22
  dht4.begin();
  dht13.begin();

  Serial.println("--- COMANDOS SERIALES DISPONIBLES ---");
  Serial.println(" '1' -> Probar solo DS18B20 (Agua)");
  Serial.println(" '2' -> Probar solo DHT22 (Ambiente)");
  Serial.println(" 'B' -> Probar ambos sensores");
  Serial.println("-------------------------------------\n");

  start_time = millis();
}

void loop() {
  if (Serial.available() > 0) {
    char c = Serial.read();
    if (c == '1' || c == '2' || c == 'B' || c == 'b') {
      test_mode = toupper(c);
      Serial.print(">>> [MODO CAMBIADO]: ");
      if (test_mode == '1') Serial.println("SOLO DS18B20 (Agua)");
      else if (test_mode == '2') Serial.println("SOLO DHT22 (Ambiente)");
      else Serial.println("AMBOS SENSORES");
    }
  }

  // Muestreo cada 2 segundos (el DHT22 requiere mínimo 2s entre muestras)
  if (millis() - last_print >= 2000) {
    last_print = millis();
    float t = (millis() - start_time) / 1000.0;

    float temp_agua = -127.0;
    float temp_aire = -127.0;
    float hum_aire  = 0.0;

    // 1. Lectura DS18B20 (Agua)
    if (test_mode == '1' || test_mode == 'B') {
      sensorAgua15.requestTemperatures();
      temp_agua = sensorAgua15.getTempCByIndex(0);
      if (temp_agua == DEVICE_DISCONNECTED_C || temp_agua <= -100.0) {
        sensorAgua32.requestTemperatures();
        float t32 = sensorAgua32.getTempCByIndex(0);
        if (t32 > -100.0 && t32 != DEVICE_DISCONNECTED_C) {
          temp_agua = t32;
        }
      }
    }

    // 2. Lectura DHT22 (Ambiente & Humedad)
    if (test_mode == '2' || test_mode == 'B') {
      temp_aire = dht4.readTemperature();
      hum_aire  = dht4.readHumidity();
      if (isnan(temp_aire) || isnan(hum_aire)) {
        temp_aire = dht13.readTemperature();
        hum_aire  = dht13.readHumidity();
      }
      if (isnan(temp_aire)) temp_aire = -127.0;
      if (isnan(hum_aire))  hum_aire  = 0.0;
    }

    // --- SALIDA TELEMÉTRICA CSV OFICIAL PARA LA WEB ---
    // Formato: tiempo,pwm,temp_agua,temp_ambiente,servo,humedad
    Serial.print(t, 1);
    Serial.print(",0,");
    Serial.print(temp_agua, 2);
    Serial.print(",");
    Serial.print(temp_aire, 2);
    Serial.print(",0,");
    Serial.println(hum_aire, 1);

    // --- DIAGNÓSTICO EN TIEMPO REAL PARA TERMINAL IDE ---
    Serial.print(">>> [BANCO] t=");
    Serial.print(t, 1);
    Serial.print("s | S1 DS18B20 (Agua): ");
    if (temp_agua <= -100.0) Serial.print("DESCONECTADO (-127)");
    else { Serial.print(temp_agua, 2); Serial.print(" °C [OK]"); }

    Serial.print(" | S2 DHT22 (Aire): ");
    if (temp_aire <= -100.0) Serial.print("ERROR / DESCONECTADO");
    else { 
      Serial.print(temp_aire, 2); 
      Serial.print(" °C | Hum: ");
      Serial.print(hum_aire, 1);
      Serial.print(" % [OK]");
    }
    Serial.println();
  }
}
