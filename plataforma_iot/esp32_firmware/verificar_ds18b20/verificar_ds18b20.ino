#include <OneWire.h>
#include <DallasTemperature.h>
#include "driver/gpio.h"

const int PIN_15 = 15;
const int PIN_13 = 13;

OneWire ow15(PIN_15);
DallasTemperature dt15(&ow15);

OneWire ow13(PIN_13);
DallasTemperature dt13(&ow13);

void setup() {
  Serial.begin(115200);
  delay(1000);

  pinMode(PIN_15, INPUT_PULLUP);
  pinMode(PIN_13, INPUT_PULLUP);
  gpio_pullup_en((gpio_num_t)PIN_15);
  gpio_pullup_en((gpio_num_t)PIN_13);

  dt15.begin();
  dt13.begin();

  Serial.println("\n=== TEST DE DIAGNOSTICO DS18B20 (PINES 15 Y 13) ===");
}

void probarBus(int pin, OneWire &ow, DallasTemperature &dt, const char* nombre) {
  int nivel = digitalRead(pin);
  Serial.print("[");
  Serial.print(nombre);
  Serial.print(" - GPIO ");
  Serial.print(pin);
  Serial.print("] Nivel: ");
  if (nivel == HIGH) Serial.print("HIGH (3.3V) | ");
  else Serial.print("LOW (0V) | ");

  ow.reset_search();
  byte addr[8];
  if (ow.search(addr)) {
    if (addr[0] == 0x28) {
      Serial.print("DS18B20 ENCONTRADO! ROM: ");
      for (int i = 0; i < 8; i++) {
        if (addr[i] < 16) Serial.print("0");
        Serial.print(addr[i], HEX);
        Serial.print(" ");
      }
      dt.requestTemperatures();
      float temp = dt.getTempC(addr);
      Serial.print("| Temp: ");
      Serial.print(temp, 2);
      Serial.println(" C");
    } else {
      Serial.print("Dispositivo no reconocido (Familia: 0x");
      Serial.print(addr[0], HEX);
      Serial.println(") - Linea flotante o ruido");
    }
  } else {
    Serial.println("Sin dispositivos detectados.");
  }
}

void loop() {
  probarBus(PIN_15, ow15, dt15, "SENSOR 1");
  probarBus(PIN_13, ow13, dt13, "SENSOR 2");
  Serial.println("-----------------------------------------------------");
  delay(2000);
}
