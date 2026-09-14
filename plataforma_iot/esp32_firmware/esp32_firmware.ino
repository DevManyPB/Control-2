#include <Arduino.h>
#include <OneWire.h>
#include <DallasTemperature.h>
#include <DHT.h>
#include <ESP32Servo.h>
#include "driver/gpio.h"

// ========================================================
// ASIGNACIÓN DE PINES HARDWARE (ESP32)
// ALUNA PBR-02 (Arquitectura Híbrida DS18B20 + DHT22)
// ========================================================
int pin_ds18b20_activo = 14; // D14: Canal principal Agua (DS18B20)
int pin_dht_activo     = 4;  // D4:  Canal principal Ambiente (DHT22)
const int PELTIER_PWM_PIN = 25; // D25: Control PWM MOSFET Celda Peltier
const int SERVO_PIN       = 27; // D27: Servomotor MG996R Escudo Orbital

#define DHTTYPE DHT22

OneWire oneWireBus(pin_ds18b20_activo);
DallasTemperature sensorAgua(&oneWireBus);
DHT sensorDHT(pin_dht_activo, DHTTYPE);
Servo servoCortina;

// Lista de pines candidatos para escaneo automático
const int PINES_CANDIDATOS[] = {14, 15, 13, 12, 4, 32, 33, 27, 26, 21, 22, 23, 19, 18, 5, 2};
const int NUM_CANDIDATOS = sizeof(PINES_CANDIDATOS) / sizeof(PINES_CANDIDATOS[0]);

unsigned long last_read = 0;
bool is_testing = false;
unsigned long start_time = 0;
int pwm_actual = 0;
int servo_angle_actual = 0;

void escanearHardware() {
  Serial.println("\n==================================================");
  Serial.println("   ALUNA PBR-02 | DIAGNÓSTICO AVANZADO DE PINES   ");
  Serial.println("==================================================");
  
  bool encontrado_ds18b20 = false;
  bool encontrado_dht22 = false;

  for (int i = 0; i < NUM_CANDIDATOS; i++) {
    int pin = PINES_CANDIDATOS[i];
    
    // Test 1: Nivel lógico en reposo (sin pull-up interno)
    pinMode(pin, INPUT);
    delay(5);
    int raw_level = digitalRead(pin);

    // Test 2: Nivel con pull-up interno
    pinMode(pin, INPUT_PULLUP);
    gpio_pullup_en((gpio_num_t)pin);
    delay(5);
    int pullup_level = digitalRead(pin);

    // Test 3: Búsqueda 1-Wire (DS18B20)
    OneWire ow(pin);
    uint8_t addr[8];
    uint8_t reset_res = ow.reset();
    bool ds_found = false;
    if (reset_res == 1) {
      if (ow.search(addr)) {
        ds_found = true;
      }
      ow.reset_search();
    }

    // Diagnóstico individual por pin
    Serial.print("GPIO ");
    if (pin < 10) Serial.print(" ");
    Serial.print(pin);
    Serial.print(" (D");
    Serial.print(pin);
    Serial.print("): Raw=");
    Serial.print(raw_level ? "HIGH" : "LOW ");
    Serial.print(" | Pullup=");
    Serial.print(pullup_level ? "HIGH" : "LOW ");

    if (ds_found) {
      Serial.print(" | >>> [DS18B20 DETECTADO] Chip: 0x");
      Serial.print(addr[0], HEX);
      Serial.println(" <<<");
      if (!encontrado_ds18b20) {
        pin_ds18b20_activo = pin;
        encontrado_ds18b20 = true;
      }
    } else if (reset_res == 1) {
      Serial.println(" | [1-Wire Presencia OK pero sin ROM]");
      if (!encontrado_ds18b20) {
        pin_ds18b20_activo = pin;
        encontrado_ds18b20 = true;
      }
    } else {
      if (raw_level == 0 && pullup_level == 0) {
        Serial.println(" | [Cortocircuito a GND]");
      } else if (raw_level == 0 && pullup_level == 1) {
        Serial.println(" | [Sin pullup externo / Abierto]");
      } else {
        Serial.println(" | [Línea en HIGH]");
      }
    }
  }

  // Escaneo DHT22 en pines típicos
  const int PINES_DHT_TEST[] = {4, 13, 14, 15, 32, 33, 27};
  for (int j = 0; j < 7; j++) {
    int p = PINES_DHT_TEST[j];
    DHT test_dht(p, DHTTYPE);
    test_dht.begin();
    delay(20);
    float t = test_dht.readTemperature();
    float h = test_dht.readHumidity();
    if (!isnan(t) && !isnan(h) && t > -40.0 && t < 80.0) {
      Serial.print(">>> [DHT22 DETECTADO] en GPIO ");
      Serial.print(p);
      Serial.print(" -> Temp: ");
      Serial.print(t, 1);
      Serial.print(" °C | Hum: ");
      Serial.print(h, 1);
      Serial.println(" %");
      if (!encontrado_dht22) {
        pin_dht_activo = p;
        encontrado_dht22 = true;
      }
    }
  }

  Serial.println("--------------------------------------------------");
  Serial.print(">>> ASIGNACIÓN FINAL: Agua DS18B20 en D");
  Serial.print(pin_ds18b20_activo);
  Serial.print(" | Ambiente DHT22 en D");
  Serial.println(pin_dht_activo);
  Serial.println("==================================================\n");

  // Re-inicializar buses activos
  oneWireBus.begin(pin_ds18b20_activo);
  pinMode(pin_ds18b20_activo, INPUT_PULLUP);
  gpio_pullup_en((gpio_num_t)pin_ds18b20_activo);
  sensorAgua.begin();
  sensorAgua.setWaitForConversion(true);
  sensorAgua.setResolution(10);

  sensorDHT = DHT(pin_dht_activo, DHTTYPE);
  sensorDHT.begin();
}

void setup() {
  Serial.begin(115200);
  delay(500);

  // Configuración PWM Peltier en D25 (1 kHz, 8 bits: 0-255)
  ledcAttach(PELTIER_PWM_PIN, 1000, 8);
  ledcWrite(PELTIER_PWM_PIN, 0);

  // Configuración Servomotor MG996R en D27 (50 Hz estándar)
  servoCortina.setPeriodHertz(50);
  servoCortina.attach(SERVO_PIN, 500, 2500);
  servoCortina.write(0); // 0° = Escudo Abierto

  // Ejecutar escáner de hardware
  escanearHardware();
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
    else if (cmd == "SCAN" || cmd == "scan") {
      escanearHardware();
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
  if (millis() - last_read >= 2000) {
    last_read = millis();
    
    // 1. Lectura Sensor 1 (DS18B20 Agua)
    sensorAgua.requestTemperatures();
    float temp_agua = sensorAgua.getTempCByIndex(0);

    // Fallback rápido si no lee en el pin activo
    if (temp_agua == DEVICE_DISCONNECTED_C || temp_agua <= -100.0) {
      if (pin_ds18b20_activo != 14) {
        OneWire ow14(14);
        DallasTemperature s14(&ow14);
        pinMode(14, INPUT_PULLUP);
        gpio_pullup_en((gpio_num_t)14);
        s14.begin();
        s14.requestTemperatures();
        float t14 = s14.getTempCByIndex(0);
        if (t14 > -100.0 && t14 != DEVICE_DISCONNECTED_C) {
          temp_agua = t14;
          pin_ds18b20_activo = 14;
        }
      } else if (pin_ds18b20_activo != 15) {
        OneWire ow15(15);
        DallasTemperature s15(&ow15);
        pinMode(15, INPUT_PULLUP);
        gpio_pullup_en((gpio_num_t)15);
        s15.begin();
        s15.requestTemperatures();
        float t15 = s15.getTempCByIndex(0);
        if (t15 > -100.0 && t15 != DEVICE_DISCONNECTED_C) {
          temp_agua = t15;
          pin_ds18b20_activo = 15;
        }
      }
    }

    // 2. Lectura Sensor 2 (DHT22 Ambiente)
    float temp_aire = sensorDHT.readTemperature();
    float hum_aire  = sensorDHT.readHumidity();
    if (isnan(temp_aire) || isnan(hum_aire)) {
      // Probar fallback a D13 si activo es D4, o viceversa
      int alt_pin = (pin_dht_activo == 4) ? 13 : 4;
      DHT dhtAlt(alt_pin, DHTTYPE);
      dhtAlt.begin();
      float ta = dhtAlt.readTemperature();
      float ha = dhtAlt.readHumidity();
      if (!isnan(ta) && !isnan(ha)) {
        temp_aire = ta;
        hum_aire = ha;
        pin_dht_activo = alt_pin;
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
