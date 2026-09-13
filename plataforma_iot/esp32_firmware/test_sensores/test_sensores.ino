#include <OneWire.h>
#include <DallasTemperature.h>
#include "driver/gpio.h"

// ========================================================
// ALUNA PBR-02 | BANCO DE PRUEBAS DE SENSORES DS18B20
// Soporta tanto pines dedicados (D15 y D13) como
// múltiples sensores en el mismo bus (D15 o D13 en paralelo).
// ========================================================

const int PIN_S1 = 15; // D15: Sensor 1 (Agua / Reactor)
const int PIN_S2 = 13; // D13: Sensor 2 (Ambiente / Disipador)

OneWire bus15(PIN_S1);
DallasTemperature sensors15(&bus15);

OneWire bus13(PIN_S2);
DallasTemperature sensors13(&bus13);

char test_mode = 'B'; // '1'=Solo D15, '2'=Solo D13, 'B'=Ambos
unsigned long last_print = 0;
unsigned long start_time = 0;

void escanearHardware();

void setup() {
  Serial.begin(115200);
  delay(1000);

  Serial.println("\n==================================================");
  Serial.println("   ALUNA PBR-02 | BANCO DE PRUEBAS DE SENSORES    ");
  Serial.println("   Detección inteligente en GPIO 15 y GPIO 13    ");
  Serial.println("==================================================");

  // Forzar activación de pull-up interno por hardware
  pinMode(PIN_S1, INPUT_PULLUP);
  pinMode(PIN_S2, INPUT_PULLUP);
  gpio_pullup_en((gpio_num_t)PIN_S1);
  gpio_pullup_en((gpio_num_t)PIN_S2);

  sensors15.begin();
  sensors13.begin();

  // Resolución de 10 bits (0.25 °C): conversión ultrarrápida (187 ms)
  // Evita caídas de tensión y timeouts de -127 °C
  sensors15.setResolution(10);
  sensors13.setResolution(10);
  sensors15.setWaitForConversion(true);
  sensors13.setWaitForConversion(true);

  escanearHardware();

  Serial.println("--- COMANDOS SERIALES DISPONIBLES ---");
  Serial.println(" '1' -> Probar solo canal D15");
  Serial.println(" '2' -> Probar solo canal D13");
  Serial.println(" 'B' -> Probar ambos canales");
  Serial.println(" 'S' -> Re-escanear direcciones ROM");
  Serial.println("-------------------------------------\n");

  start_time = millis();
}

void loop() {
  // Comandos por puerto serie desde la plataforma web o consola
  if (Serial.available() > 0) {
    char c = Serial.read();
    if (c == '1' || c == '2' || c == 'B' || c == 'b') {
      test_mode = toupper(c);
      Serial.print(">>> [MODO CAMBIADO]: ");
      if (test_mode == '1') Serial.println("SOLO SENSOR 1 (Pin D15)");
      else if (test_mode == '2') Serial.println("SOLO SENSOR 2 (Pin D13)");
      else Serial.println("AMBOS SENSORES");
    } else if (c == 'S' || c == 's') {
      escanearHardware();
    }
  }

  // Muestreo cada 1.5 segundos
  if (millis() - last_print >= 1500) {
    last_print = millis();
    float t = (millis() - start_time) / 1000.0;

    float t1 = DEVICE_DISCONNECTED_C; // -127.0
    float t2 = DEVICE_DISCONNECTED_C; // -127.0

    // 1. Lectura en Bus Pin D15
    if (test_mode == '1' || test_mode == 'B') {
      sensors15.requestTemperatures();
      int n15 = sensors15.getDeviceCount();
      if (n15 >= 1) {
        t1 = sensors15.getTempCByIndex(0);
        if (n15 >= 2 && test_mode == 'B') {
          // Si ambos sensores están conectados en paralelo al pin D15
          t2 = sensors15.getTempCByIndex(1);
        }
      }
    }

    // 2. Lectura en Bus Pin D13
    if ((test_mode == '2' || test_mode == 'B') && t2 == DEVICE_DISCONNECTED_C) {
      sensors13.requestTemperatures();
      int n13 = sensors13.getDeviceCount();
      if (n13 >= 1) {
        float temp13 = sensors13.getTempCByIndex(0);
        if (test_mode == '2') {
          t2 = temp13;
        } else {
          // Si el sensor 1 ya leyó en D15, asignar a S2
          if (t1 != DEVICE_DISCONNECTED_C) {
            t2 = temp13;
          } else {
            // Si solo se conectó a D13, asignarlo a S1 para poder probarlo
            t1 = temp13;
          }
        }
      }
    }

    // --- SALIDA TELEMÉTRICA CSV OFICIAL PARA LA WEB ---
    // Formato exacto: tiempo,pwm,temp1,temp2,servo
    Serial.print(t, 1);
    Serial.print(",0,");
    Serial.print(t1, 2);
    Serial.print(",");
    Serial.print(t2, 2);
    Serial.println(",0");

    // --- DIAGNÓSTICO DETALLADO PARA TERMINAL IDE ---
    Serial.print(">>> [BANCO PRUEBAS] t=");
    Serial.print(t, 1);
    Serial.print("s | S1 (D15): ");
    if (t1 == DEVICE_DISCONNECTED_C || t1 <= -100.0) {
      Serial.print("DESCONECTADO (-127)");
    } else if (t1 == 85.0) {
      Serial.print("INICIALIZANDO (+85)");
    } else {
      Serial.print(t1, 2);
      Serial.print(" °C [OK]");
    }

    Serial.print(" | S2 (D13): ");
    if (t2 == DEVICE_DISCONNECTED_C || t2 <= -100.0) {
      Serial.print("DESCONECTADO (-127)");
    } else if (t2 == 85.0) {
      Serial.print("INICIALIZANDO (+85)");
    } else {
      Serial.print(t2, 2);
      Serial.print(" °C [OK]");
    }
    Serial.println();
  }
}

void escanearHardware() {
  Serial.println("\n--------------------------------------------------");
  Serial.println(">>> ESCANEO DE HARDWARE Y DIRECCIONES ROM (1-WIRE)");
  Serial.println("--------------------------------------------------");

  // Pin D15
  Serial.print("[PIN D15 / GPIO 15]: ");
  bus15.reset_search();
  byte addr15[8];
  int count15_scan = 0;
  while (bus15.search(addr15)) {
    count15_scan++;
    Serial.print("\n  -> Sensor detectado #");
    Serial.print(count15_scan);
    Serial.print(" | ROM: ");
    for (int i = 0; i < 8; i++) {
      if (addr15[i] < 16) Serial.print("0");
      Serial.print(addr15[i], HEX);
      Serial.print(" ");
    }
    if (addr15[0] == 0x28) Serial.print("(DS18B20 Autentico)");
  }
  if (count15_scan == 0) {
    Serial.println("Sin dispositivos detectados.");
  } else {
    Serial.println();
  }

  // Pin D13
  Serial.print("[PIN D13 / GPIO 13]: ");
  bus13.reset_search();
  byte addr13[8];
  int count13_scan = 0;
  while (bus13.search(addr13)) {
    count13_scan++;
    Serial.print("\n  -> Sensor detectado #");
    Serial.print(count13_scan);
    Serial.print(" | ROM: ");
    for (int i = 0; i < 8; i++) {
      if (addr13[i] < 16) Serial.print("0");
      Serial.print(addr13[i], HEX);
      Serial.print(" ");
    }
    if (addr13[0] == 0x28) Serial.print("(DS18B20 Autentico)");
  }
  if (count13_scan == 0) {
    Serial.println("Sin dispositivos detectados.");
  } else {
    Serial.println();
  }

  Serial.println("--------------------------------------------------\n");
}
