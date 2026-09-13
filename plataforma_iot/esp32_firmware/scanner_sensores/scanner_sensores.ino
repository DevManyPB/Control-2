#include <OneWire.h>
#include <DallasTemperature.h>
#include "driver/gpio.h"

// Lista de pines GPIO disponibles en ESP32 para verificar
const int PINES[] = {15, 13, 4, 14, 16, 17, 18, 19, 21, 22, 23, 25, 26, 27, 32, 33};
const int NUM_PINES = sizeof(PINES) / sizeof(PINES[0]);

void setup() {
  Serial.begin(115200);
  delay(1500);
  Serial.println("\n\n========================================================");
  Serial.println("   ALUNA PBR-02 | ESCANER DIAGNOSTICO TOTAL DE PINES   ");
  Serial.println("========================================================");
}

void loop() {
  Serial.println("\n--------------------------------------------------------");
  Serial.println(">>> INICIANDO ESCANEO DE TODOS LOS PINES GPIO...");
  Serial.println("--------------------------------------------------------");

  bool encontrado = false;

  for (int i = 0; i < NUM_PINES; i++) {
    int pin = PINES[i];
    
    // 1. Verificar estado eléctrico del pin con pull-up interno
    pinMode(pin, INPUT_PULLUP);
    gpio_pullup_en((gpio_num_t)pin);
    delay(10);
    int estado_electrico = digitalRead(pin);

    // 2. Probar bus OneWire en este pin
    OneWire ow(pin);
    byte presencia = ow.reset();
    byte addr[8];
    bool tiene_rom = ow.search(addr);

    if (presencia == 1 || tiene_rom) {
      DallasTemperature dt(&ow);
      dt.begin();
      dt.requestTemperatures();
      float temp = dt.getTempCByIndex(0);

      Serial.print(">>> [EXITO] SENSOR DETECTADO EN PIN GPIO ");
      Serial.print(pin);
      Serial.print(" | Nivel logico: ");
      Serial.print(estado_electrico == HIGH ? "3.3V (OK)" : "0V (BAJO)");
      Serial.print(" | Presencia: SI");
      
      if (tiene_rom) {
        Serial.print(" | ROM: ");
        for (int k = 0; k < 8; k++) {
          if (addr[k] < 16) Serial.print("0");
          Serial.print(addr[k], HEX);
          Serial.print(" ");
        }
      }

      Serial.print(" | TEMP: ");
      if (temp == DEVICE_DISCONNECTED_C || temp <= -100) {
        Serial.println("ERROR -127°C (Falta resistencia 4.7k o conexion floja)");
      } else {
        Serial.print(temp, 2);
        Serial.println(" °C (¡LECTURA PERFECTA!)");
      }
      encontrado = true;
    } else {
      // Si el pin es el 15 o el 13, reportar diagnóstico detallado
      if (pin == 15 || pin == 13) {
        Serial.print("[DIAGNOSTICO] Pin GPIO ");
        Serial.print(pin);
        Serial.print(" (D");
        Serial.print(pin);
        Serial.print("): Nivel=");
        Serial.print(estado_electrico == HIGH ? "3.3V (Pull-up activo)" : "0V (¡PELIGRO: En corto a tierra o sin resistencia!)");
        Serial.println(" | Presencia: NO responde");
      }
    }
  }

  if (!encontrado) {
    Serial.println("\n[CONCLUSION]: Ningun sensor respondio en ningun pin GPIO.");
    Serial.println("Posibles causas:");
    Serial.println("1. Falta la resistencia de 4.7k entre el cable AMARILLO (Datos) y 3.3V (Rojo).");
    Serial.println("2. El cable NEGRO no esta conectado a GND de la ESP32.");
    Serial.println("3. El cable ROJO no esta conectado a 3V3 de la ESP32.");
    Serial.println("4. El sensor esta invertido o en terminales equivocados de la protoboard.");
  }

  Serial.println("--------------------------------------------------------");
  Serial.println("Esperando 4 segundos para el siguiente escaneo...");
  delay(4000);
}
