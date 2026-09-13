#include <OneWire.h>
#include <DallasTemperature.h>
#include <ESP32Servo.h>
#include "driver/gpio.h"

// ==========================================
// ASIGNACIÓN DE PINES HARDWARE (ESP32)
// ALUNA PBR-02 (Control Térmico Monocanal)
// Soporta sensor único conectado a D15 o D13
// ==========================================
const int PIN_SENSOR_D15  = 15;     // D15 (Canal Principal de Temperatura)
const int PIN_SENSOR_D13  = 13;     // D13 (Canal Alternativo / Fallback)
const int PELTIER_PWM_PIN = 25;     // D25 (Control PWM MOSFET Celda Peltier)
const int SERVO_PIN       = 27;     // D27 (Servomotor MG996R Escudo Orbital)

// ==========================================
// INSTANCIAS DE HARDWARE
// ==========================================
OneWire oneWire15(PIN_SENSOR_D15);
DallasTemperature sensor15(&oneWire15);

OneWire oneWire13(PIN_SENSOR_D13);
DallasTemperature sensor13(&oneWire13);

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
  
  // Activar resistencias pull-up internas
  pinMode(PIN_SENSOR_D15, INPUT_PULLUP);
  pinMode(PIN_SENSOR_D13, INPUT_PULLUP);
  gpio_pullup_en((gpio_num_t)PIN_SENSOR_D15);
  gpio_pullup_en((gpio_num_t)PIN_SENSOR_D13);

  sensor15.begin();
  sensor13.begin();
  sensor15.setWaitForConversion(true);
  sensor13.setWaitForConversion(true);
  sensor15.setResolution(10); // 187 ms por conversión (rápido y ultra estable)
  sensor13.setResolution(10);
  
  // Configuración PWM Peltier (1 kHz, 8 bits: 0-255)
  ledcAttach(PELTIER_PWM_PIN, 1000, 8);
  ledcWrite(PELTIER_PWM_PIN, 0);

  // Configuración Servomotor MG996R (50 Hz estándar)
  servoCortina.setPeriodHertz(50);
  servoCortina.attach(SERVO_PIN, 500, 2500);
  servoCortina.write(0); // 0° = Escudo Abierto (Fotosíntesis)

  Serial.println("==================================================");
  Serial.println("   ALUNA PBR-02 | SISTEMA DE CONTROL TÉRMICO PI   ");
  Serial.println("   Detección automática de sensor en D15 / D13    ");
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
      // Iniciar prueba escalón por defecto (60% PWM)
      is_testing = true;
      start_time = millis();
      pwm_actual = 153;
      ledcWrite(PELTIER_PWM_PIN, pwm_actual);
      Serial.println(">>> ENSAYO INICIADO: PWM = 153 (60%)");
    } 
    else if (cmd == "X" || cmd == "x") {
      // Paro total de emergencia
      is_testing = false;
      pwm_actual = 0;
      ledcWrite(PELTIER_PWM_PIN, 0);
      servo_angle_actual = 0;
      servoCortina.write(0);
      Serial.println(">>> PARO TOTAL EJECUTADO (PWM = 0, SERVO = 0°)");
    }
    else if (cmd.startsWith("M:")) {
      // Control directo de potencia Peltier (M:0 a M:255)
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
      // Control angular del servomotor (C:0 a C:180)
      int angle = cmd.substring(2).toInt();
      servo_angle_actual = constrain(angle, 0, 180);
      servoCortina.write(servo_angle_actual);
      Serial.print(">>> SERVO CORTINA: ");
      Serial.println(servo_angle_actual);
    }
  }

  // ==========================================
  // TELEMETRÍA PERIÓDICA (CADA 1.5 SEGUNDOS)
  // ==========================================
  if (is_testing) {
    if (millis() - last_read >= 1500) {
      last_read = millis();
      
      // 1. Intentar lectura en D15
      sensor15.requestTemperatures();
      float temp = sensor15.getTempCByIndex(0);

      // 2. Si D15 no responde, buscar en D13 automáticamente
      if (temp == DEVICE_DISCONNECTED_C || temp <= -100.0) {
        sensor13.requestTemperatures();
        float temp13 = sensor13.getTempCByIndex(0);
        if (temp13 > -100.0 && temp13 != DEVICE_DISCONNECTED_C) {
          temp = temp13;
        }
      }
      
      float t = (millis() - start_time) / 1000.0;
      
      // Formato CSV estándar: tiempo,pwm,temp_agua,temp_aux,angulo_servo
      Serial.print(t, 2);
      Serial.print(",");
      Serial.print(pwm_actual);
      Serial.print(",");
      Serial.print(temp, 2);
      Serial.print(",");
      Serial.print(temp, 2); // Duplicado para retrocompatibilidad
      Serial.print(",");
      Serial.println(servo_angle_actual);
    }
  }
}
