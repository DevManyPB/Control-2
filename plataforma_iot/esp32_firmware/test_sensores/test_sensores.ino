#include <OneWire.h>
#include <DallasTemperature.h>
#include "driver/gpio.h"

// ========================================================
// PINES DEDICADOS PARA CADA SENSOR DS18B20
// ========================================================
const int PIN_SENSOR_1 = 15; // D15: Sensor 1 (Agua / Reactor)
const int PIN_SENSOR_2 = 13; // D13: Sensor 2 (Ambiente / Disipador)

OneWire bus1(PIN_SENSOR_1);
DallasTemperature sensor1(&bus1);

OneWire bus2(PIN_SENSOR_2);
DallasTemperature sensor2(&bus2);

// Modo de prueba: 'B' = Ambos, '1' = Solo Sensor 1, '2' = Solo Sensor 2
char test_mode = 'B';
unsigned long last_print = 0;
unsigned long start_time = 0;

void setup() {
  Serial.begin(115200);
  delay(1000);

  Serial.println("\n==================================================");
  Serial.println("   ALUNA PBR-02 | BANCO DE PRUEBA DE SENSORES    ");
  Serial.println("==================================================");

  // Forzar activación de pull-up interno por hardware
  pinMode(PIN_SENSOR_1, INPUT_PULLUP);
  pinMode(PIN_SENSOR_2, INPUT_PULLUP);
  gpio_pullup_en((gpio_num_t)PIN_SENSOR_1);
  gpio_pullup_en((gpio_num_t)PIN_SENSOR_2);

  sensor1.begin();
  sensor2.begin();

  sensor1.setWaitForConversion(true);
  sensor2.setWaitForConversion(true);

  // Escaneo inicial de hardware
  escanearHardware();
  
  Serial.println("\n--- COMANDOS DISPONIBLES EN CONSOLA ---");
  Serial.println(" Envia '1' -> Probar SOLO Sensor 1 (Pin D15)");
  Serial.println(" Envia '2' -> Probar SOLO Sensor 2 (Pin D13)");
  Serial.println(" Envia 'B' -> Probar AMBOS sensores simultaneamente");
  Serial.println(" Envia 'S' -> Re-escanear hardware y direcciones ROM");
  Serial.println("----------------------------------------\n");

  start_time = millis();
}

void loop() {
  // Lectura de comandos por Serial
  if (Serial.available() > 0) {
    char c = Serial.read();
    if (c == '1' || c == '2' || c == 'B' || c == 'b') {
      test_mode = toupper(c);
      Serial.print(">>> Modo cambiado a: ");
      if (test_mode == '1') Serial.println("SOLO SENSOR 1 (Pin D15)");
      else if (test_mode == '2') Serial.println("SOLO SENSOR 2 (Pin D13)");
      else Serial.println("AMBOS SENSORES (D15 + D13)");
    } else if (c == 'S' || c == 's') {
      escanearHardware();
    }
  }

  // Muestreo cada 1.5 segundos
  if (millis() - last_print >= 1500) {
    last_print = millis();
    float t = (millis() - start_time) / 1000.0;

    // --- LECTURA SENSOR 1 ---
    sensor1.requestTemperatures();
    float t1 = sensor1.getTempCByIndex(0);

    // --- LECTURA SENSOR 2 ---
    sensor2.requestTemperatures();
    float t2 = sensor2.getTempCByIndex(0);

    // Reporte según el modo seleccionado
    if (test_mode == '1') {
      imprimirDiagnosticoSensor(1, PIN_SENSOR_1, t1);
    } else if (test_mode == '2') {
      imprimirDiagnosticoSensor(2, PIN_SENSOR_2, t2);
    } else {
      // Modo Ambos: Imprimir formato amigable y formato CSV
      imprimirDobleSensor(t, t1, t2);
    }
  }
}

void imprimirDiagnosticoSensor(int id, int pin, float temp) {
  Serial.print("[SENSOR ");
  Serial.print(id);
  Serial.print(" - Pin D");
  Serial.print(pin);
  Serial.print("] -> ");

  if (temp == DEVICE_DISCONNECTED_C || temp <= -100.0) {
    Serial.println("ERROR -127.00 °C: ¡SENSOR NO DETECTADO! (Verifica resistencia de 4.7k o cable suelto)");
  } else if (temp == 85.0) {
    Serial.println("AVISO +85.00 °C: Reset de encendido (No ha completado la primera conversion de temperatura)");
  } else {
    Serial.print("Temperatura: ");
    Serial.print(temp, 2);
    Serial.print(" °C | Estado: OK (Senal estable)");
    if (temp >= 28.0) Serial.print(" [Sensando calor corporal o fuente]");
    Serial.println();
  }
}

void imprimirDobleSensor(float t, float t1, float t2) {
  // Salida detallada en consola
  Serial.print("t: ");
  Serial.print(t, 1);
  Serial.print("s | S1 (D15 Agua): ");
  if (t1 == DEVICE_DISCONNECTED_C) Serial.print("DESCONECTADO (-127)");
  else { Serial.print(t1, 2); Serial.print(" °C"); }

  Serial.print(" | S2 (D13 Aire): ");
  if (t2 == DEVICE_DISCONNECTED_C) Serial.println("DESCONECTADO (-127)");
  else { Serial.print(t2, 2); Serial.println(" °C"); }

  // Si ambos estan conectados, calcular diferencia
  if (t1 > -50 && t2 > -50) {
    float diff = abs(t2 - t1);
    if (diff < 0.5) {
      Serial.print("   -> [CALIBRACION]: Sensores en equilibrio térmico (Diferencia: ");
      Serial.print(diff, 2);
      Serial.println(" °C)");
    }
  }
}

void escanearHardware() {
  Serial.println("\n>>> ESCANEANDO BUSES 1-WIRE...");
  
  // Escaneo Pin D15
  byte addr1[8];
  Serial.print("   Pin D15 (Sensor 1): ");
  bus1.reset_search();
  if (bus1.search(addr1)) {
    Serial.print("¡SENSOR DETECTADO! ROM: ");
    for (int i = 0; i < 8; i++) {
      if (addr1[i] < 16) Serial.print("0");
      Serial.print(addr1[i], HEX);
      Serial.print(" ");
    }
    Serial.println();
  } else {
    Serial.println("NO se detecto dispositivo. Verifica cable amarillo o resistencia pull-up.");
  }

  // Escaneo Pin D13
  byte addr2[8];
  Serial.print("   Pin D13 (Sensor 2): ");
  bus2.reset_search();
  if (bus2.search(addr2)) {
    Serial.print("¡SENSOR DETECTADO! ROM: ");
    for (int i = 0; i < 8; i++) {
      if (addr2[i] < 16) Serial.print("0");
      Serial.print(addr2[i], HEX);
      Serial.print(" ");
    }
    Serial.println();
  } else {
    Serial.println("NO se detecto dispositivo. Verifica cable amarillo o conexion a D13.");
  }
  Serial.println("==================================================\n");
}
