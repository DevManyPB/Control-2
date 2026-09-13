#include <OneWire.h>
#include <DallasTemperature.h>
#include <ESP32Servo.h>
#include "driver/gpio.h"

// ==========================================
// ASIGNACIÓN DE PINES HARDWARE (ESP32 38 PINES)
// ==========================================
const int PIN_SENSOR_AGUA = 15;     // D15 (Sensor 1 - Agua / Reactor)
const int PIN_SENSOR_AIRE = 13;     // D13 (Sensor 2 - Ambiente / Disipador)
const int PELTIER_PWM_PIN = 25;     // D25 (Control PWM MOSFET Peltier)
const int SERVO_PIN       = 27;     // D27 (Señal PWM Servomotor MG996R - Escudo Orbital)

// ==========================================
// INSTANCIAS DE SENSORES Y ACTUADORES
// ==========================================
OneWire oneWireAgua(PIN_SENSOR_AGUA);
DallasTemperature sensorAgua(&oneWireAgua);

OneWire oneWireAire(PIN_SENSOR_AIRE);
DallasTemperature sensorAire(&oneWireAire);

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
  
  // Activar resistencias pull-up internas por hardware en ambos buses 1-Wire
  pinMode(PIN_SENSOR_AGUA, INPUT_PULLUP);
  pinMode(PIN_SENSOR_AIRE, INPUT_PULLUP);
  gpio_pullup_en((gpio_num_t)PIN_SENSOR_AGUA);
  gpio_pullup_en((gpio_num_t)PIN_SENSOR_AIRE);

  sensorAgua.begin();
  sensorAire.begin();
  
  sensorAgua.setWaitForConversion(true);
  sensorAire.setWaitForConversion(true);
  sensorAgua.setResolution(10);
  sensorAire.setResolution(10);
  
  // Configuración PWM Peltier (1 kHz, 8 bits de resolución: 0-255)
  ledcAttach(PELTIER_PWM_PIN, 1000, 8);
  ledcWrite(PELTIER_PWM_PIN, 0);

  // Configuración Servomotor MG996R (50 Hz estándar)
  servoCortina.setPeriodHertz(50);
  servoCortina.attach(SERVO_PIN, 500, 2500); // 500us a 2500us para rango completo 180°
  servoCortina.write(0);                     // Posición inicial: 0° (Escudo Abierto / Fotosíntesis)
}

void loop() {
  // ==========================================
  // LECTURA DE COMANDOS DESDE EL BACKEND
  // ==========================================
  if (Serial.available() > 0) {
    String cmd = Serial.readStringUntil('\n');
    cmd.trim();

    if (cmd == "S") {
      // Iniciar prueba escalón por defecto (60% PWM)
      is_testing = true;
      start_time = millis();
      pwm_actual = 153;
      ledcWrite(PELTIER_PWM_PIN, pwm_actual);
    } 
    else if (cmd == "X") {
      // Paro de emergencia total
      is_testing = false;
      pwm_actual = 0;
      ledcWrite(PELTIER_PWM_PIN, 0);
      servo_angle_actual = 0;
      servoCortina.write(0);
    }
    else if (cmd.startsWith("M:")) {
      // Comando de PWM manual (Ej: "M:200" o "M:0")
      int val = cmd.substring(2).toInt();
      pwm_actual = constrain(val, 0, 255);
      ledcWrite(PELTIER_PWM_PIN, pwm_actual);
      if (!is_testing) {
        is_testing = true;
        start_time = millis();
      }
    }
    else if (cmd.startsWith("C:")) {
      // Comando de Servo Cortina (Ej: "C:90" o "C:180")
      int angle = cmd.substring(2).toInt();
      servo_angle_actual = constrain(angle, 0, 180);
      servoCortina.write(servo_angle_actual);
    }
  }

  // ==========================================
  // TELEMETRÍA PERIÓDICA (CADA 2 SEGUNDOS)
  // ==========================================
  if (is_testing) {
    if (millis() - last_read >= 2000) {
      last_read = millis();
      
      // Lectura de temperaturas
      sensorAgua.requestTemperatures();
      sensorAire.requestTemperatures();
      
      float temp1 = sensorAgua.getTempCByIndex(0);
      float temp2 = sensorAire.getTempCByIndex(0);

      // Si ambos sensores están conectados en paralelo al pin D15
      if (sensorAgua.getDeviceCount() >= 2 && (temp2 == DEVICE_DISCONNECTED_C || temp2 <= -100.0)) {
        temp2 = sensorAgua.getTempCByIndex(1);
      }
      // Si solo hay un sensor y se conectó al pin D13 en vez de D15
      if ((temp1 == DEVICE_DISCONNECTED_C || temp1 <= -100.0) && temp2 > -100.0 && temp2 != DEVICE_DISCONNECTED_C) {
        temp1 = temp2;
      }
      
      float t = (millis() - start_time) / 1000.0;
      
      // Formato CSV estándar: tiempo,pwm,temp_agua,temp_ambiente,angulo_servo
      Serial.print(t, 2);
      Serial.print(",");
      Serial.print(pwm_actual);
      Serial.print(",");
      Serial.print(temp1, 2);
      Serial.print(",");
      Serial.print(temp2, 2);
      Serial.print(",");
      Serial.println(servo_angle_actual);
    }
  }
}
