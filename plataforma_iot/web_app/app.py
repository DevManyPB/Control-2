from flask import Flask, jsonify, request
from flask_cors import CORS
import serial
import serial.tools.list_ports
import threading
import time
import os
import re
import subprocess
from collections import deque
import numpy as np
from scipy.optimize import curve_fit

app = Flask(__name__)
CORS(app)

serial_logs = deque(maxlen=50)

# ========================================================
# RUTAS DE COMPILACIÓN ARDUINO-CLI Y FIRMWARE
# ========================================================
ARDUINO_CLI_PATH = "/home/jhon/.local/bin/arduino-cli"
BUILD_DIR = "/home/jhon/Documentos/Control2/plataforma_iot/esp32_firmware/build_cache"
SKETCH_PATH = os.path.join(BUILD_DIR, "build_cache.ino")
FIRMWARE_DIR = "/home/jhon/Documentos/Control2/plataforma_iot/esp32_firmware"

# ========================================================
# VARIABLES DE ESTADO Y TELEMETRÍA
# ========================================================
recorded_data = {
    "time": [],
    "pwm": [],
    "temp1": [],        # Sensor 1: Agua / Reactor (DS18B20)
    "temp2": [],        # Sensor 2: Ambiente / Aire (DHT22)
    "humidity": [],     # Humedad Relativa Ambiente (DHT22)
    "servo_angle": []   # Ángulo Cortina Escudo Orbital (0° a 180°)
}

latest_readings = {
    "temp1": None,
    "temp2": None,
    "humidity": None,
    "pwm": 0,
    "servo_angle": 0,
    "time": 0.0,
    "raw": ""
}

ser = None
is_testing = False

# Configuración del Lazo de Control PI
control_config = {
    "mode": "manual",       # "manual", "step", "pi_auto"
    "setpoint": 21.0,       # Consigna óptima Tetraselmis chuii (20-22 °C)
    "kp": 25.0,             # Ganancia Proporcional inicial
    "ki": 0.08,             # Ganancia Integral inicial
    "integral_sum": 0.0,
    "last_control_time": None,
    "current_pwm": 0,
    "current_servo": 0
}

# ========================================================
# HILO DE LECTURA SERIAL Y CONTROL PI EN TIEMPO REAL
# ========================================================
def read_serial():
    global recorded_data, ser, is_testing, control_config, latest_readings
    while True:
        if ser and ser.is_open:
            try:
                line = ser.readline().decode('utf-8', errors='ignore').strip()
                if line:
                    serial_logs.append(line)
                    latest_readings["raw"] = line

                    # CASO 1: Formato CSV estándar (esp32_firmware.ino / step_response.ino)
                    if ',' in line:
                        parts = line.split(',')
                        if len(parts) >= 3:
                            try:
                                t = float(parts[0])
                                p = float(parts[1]) if len(parts) >= 2 else 0.0
                                t1 = float(parts[2])
                                t2 = float(parts[3]) if len(parts) >= 4 else -127.0
                                angle = float(parts[4]) if len(parts) >= 5 else control_config["current_servo"]
                                hum = float(parts[5]) if len(parts) >= 6 else (latest_readings.get("humidity") or 0.0)

                                latest_readings["time"] = t
                                latest_readings["pwm"] = p
                                latest_readings["temp1"] = t1
                                latest_readings["temp2"] = t2
                                latest_readings["humidity"] = hum
                                latest_readings["servo_angle"] = angle

                                recorded_data["time"].append(t)
                                recorded_data["pwm"].append(p)
                                recorded_data["temp1"].append(t1)
                                recorded_data["temp2"].append(t2)
                                recorded_data["humidity"].append(hum)
                                recorded_data["servo_angle"].append(angle)

                                if control_config["mode"] == "pi_auto" and t1 > -50 and t1 < 80:
                                    ejecutar_control_pi(t1, t2)
                            except ValueError:
                                pass

                    # CASO 2: Formato Diagnóstico (test_sensores.ino)
                    elif "S1 (" in line or "S2 (" in line:
                        t1 = None
                        t2 = None
                        if "S1 (" in line:
                            s1_part = line.split("S1")[1].split("|")[0]
                            if "DESCONECTADO" in s1_part or "-127" in s1_part:
                                t1 = -127.0
                            elif "85" in s1_part or "INICIALIZANDO" in s1_part:
                                t1 = 85.0
                            else:
                                val_str = s1_part.split(":")[-1] if ":" in s1_part else s1_part
                                m = re.search(r"[-+]?\d+(?:\.\d+)?", val_str)
                                if m: t1 = float(m.group())

                        if "S2 (" in line:
                            s2_part = line.split("S2")[1]
                            if "DESCONECTADO" in s2_part or "-127" in s2_part:
                                t2 = -127.0
                            elif "85" in s2_part or "INICIALIZANDO" in s2_part:
                                t2 = 85.0
                            else:
                                val_str = s2_part.split(":")[-1] if ":" in s2_part else s2_part
                                m = re.search(r"[-+]?\d+(?:\.\d+)?", val_str)
                                if m: t2 = float(m.group())

                        if t1 is not None:
                            latest_readings["temp1"] = t1
                        if t2 is not None:
                            latest_readings["temp2"] = t2

                        now_t = len(recorded_data["time"]) * 1.5
                        recorded_data["time"].append(now_t)
                        recorded_data["pwm"].append(0)
                        recorded_data["temp1"].append(t1 if t1 is not None else -127.0)
                        recorded_data["temp2"].append(t2 if t2 is not None else -127.0)
                        recorded_data["servo_angle"].append(0)
            except Exception as e:
                pass
        time.sleep(0.05)

def ejecutar_control_pi(temp_agua, temp_ambiente):
    global ser, control_config
    now = time.time()
    if control_config["last_control_time"] is None:
        control_config["last_control_time"] = now
        return

    dt = now - control_config["last_control_time"]
    if dt < 1.0: # Ejecutar a ritmo de 1 a 2 segundos
        return
    control_config["last_control_time"] = now

    setpoint = control_config["setpoint"]
    # Error térmico: si T_agua > setpoint, el error es positivo -> más enfriamiento
    error = temp_agua - setpoint

    # Término Proporcional
    P = control_config["kp"] * error

    # Término Integral con Anti-Windup
    control_config["integral_sum"] += control_config["ki"] * error * dt
    control_config["integral_sum"] = max(0.0, min(255.0, control_config["integral_sum"]))
    I = control_config["integral_sum"]

    # Esfuerzo de control total para el Peltier (0 a 255)
    u_peltier = int(max(0, min(255, P + I)))
    control_config["current_pwm"] = u_peltier

    # ========================================================
    # LÓGICA BIOMIMÉTICA DEL FRAILEJÓN (ESCUDO ORBITAL SERVO)
    # ========================================================
    # Zona 1: Normal (T <= 22°C): Cortina abierta al 100% (0°) para fotosíntesis
    # Zona 2: Alerta Térmica (T > 22°C con Peltier > 80%): Despliegue progresivo
    # Zona 3: Crítica (T >= 24°C): Cortina cerrada al 100% (180°) reflejando calor
    if temp_agua <= 22.0:
        target_angle = 0
    elif temp_agua >= 24.0:
        target_angle = 180
    else:
        # Entre 22°C y 24°C: interpolar de 0° a 180°
        target_angle = int((temp_agua - 22.0) / 2.0 * 180.0)

    control_config["current_servo"] = target_angle

    # Enviar comandos actualizados a la ESP32
    try:
        ser.write(f"M:{u_peltier}\n".encode('utf-8'))
        ser.write(f"C:{target_angle}\n".encode('utf-8'))
    except Exception:
        pass

thread = threading.Thread(target=read_serial, daemon=True)
thread.start()

# ========================================================
# ENDPOINTS REST DE LA API
# ========================================================
@app.route('/ports')
def get_ports():
    ports = [port.device for port in serial.tools.list_ports.comports()]
    return jsonify(ports)

@app.route('/connect', methods=['POST'])
def connect():
    global ser
    port = request.json.get('port')
    try:
        if ser and ser.is_open:
            ser.close()
        ser = serial.Serial(port, 115200, timeout=1)
        return jsonify({"status": "success", "port": port})
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)})

@app.route('/disconnect', methods=['POST'])
def disconnect():
    global ser, is_testing
    try:
        if ser and ser.is_open:
            ser.write(b'X\n')
            ser.close()
    except Exception:
        pass
    ser = None
    is_testing = False
    return jsonify({"status": "success", "message": "Desconectado"})

@app.route('/status')
def get_status():
    return jsonify({
        "connected": ser is not None and ser.is_open,
        "port": ser.port if (ser and ser.is_open) else None,
        "is_testing": is_testing
    })

@app.route('/start', methods=['POST'])
def start_test():
    global recorded_data, ser, is_testing, control_config
    if ser and ser.is_open:
        recorded_data = {"time": [], "pwm": [], "temp1": [], "temp2": [], "servo_angle": []}
        control_config["integral_sum"] = 0.0
        control_config["last_control_time"] = None
        
        # Enviar comando de arranque
        ser.write(b'S\n')
        is_testing = True
        return jsonify({"status": "success"})
    return jsonify({"status": "error", "message": "Puerto Serie no conectado"})

@app.route('/stop', methods=['POST'])
def stop_test():
    global ser, is_testing, control_config
    if ser and ser.is_open:
        ser.write(b'X\n')
        is_testing = False
        control_config["mode"] = "manual"
        control_config["current_pwm"] = 0
        control_config["current_servo"] = 0
        return jsonify({"status": "success"})
    return jsonify({"status": "error", "message": "Puerto Serie no conectado"})

@app.route('/set_pwm', methods=['POST'])
def set_pwm():
    global ser, control_config
    val = request.json.get('pwm', 0)
    val = max(0, min(255, int(val)))
    control_config["current_pwm"] = val
    if ser and ser.is_open:
        ser.write(f"M:{val}\n".encode('utf-8'))
        return jsonify({"status": "success", "pwm": val})
    return jsonify({"status": "error", "message": "Puerto serie no conectado"})

@app.route('/set_servo', methods=['POST'])
def set_servo():
    global ser, control_config
    angle = request.json.get('angle', 0)
    angle = max(0, min(180, int(angle)))
    control_config["current_servo"] = angle
    if ser and ser.is_open:
        ser.write(f"C:{angle}\n".encode('utf-8'))
        return jsonify({"status": "success", "angle": angle})
    return jsonify({"status": "error", "message": "Puerto serie no conectado"})

@app.route('/api/send_cmd', methods=['POST'])
def send_cmd():
    global ser
    cmd = request.json.get('cmd', '') if request.json else ''
    if ser and ser.is_open and cmd:
        try:
            ser.write(f"{cmd}\n".encode('utf-8'))
            return jsonify({"status": "success", "sent": cmd})
        except Exception as e:
            return jsonify({"status": "error", "message": str(e)})
    return jsonify({"status": "error", "message": "Puerto serie no conectado o comando vacio"})

@app.route('/config_pi', methods=['GET', 'POST'])
def config_pi():
    global control_config
    if request.method == 'POST':
        data = request.json
        if "mode" in data: control_config["mode"] = data["mode"]
        if "setpoint" in data: control_config["setpoint"] = float(data["setpoint"])
        if "kp" in data: control_config["kp"] = float(data["kp"])
        if "ki" in data: control_config["ki"] = float(data["ki"])
        if "reset_integral" in data and data["reset_integral"]:
            control_config["integral_sum"] = 0.0
        return jsonify({"status": "success", "config": control_config})
    return jsonify(control_config)

@app.route('/data')
def get_data():
    return jsonify({
        "telemetry": recorded_data,
        "latest": latest_readings,
        "control": control_config,
        "serial_logs": list(serial_logs)
    })

# ========================================================
# MODELADO FOPDT Y SINTONIZACIÓN COHEN-COON
# ========================================================
def fopdt(t, K, tau, L):
    if len(recorded_data["temp1"]) == 0:
        return np.zeros_like(t)
    y0 = recorded_data["temp1"][0]
    dU = control_config.get("current_pwm", 153.0)
    if dU == 0: dU = 153.0
    y = np.zeros_like(t)
    for i, t_i in enumerate(t):
        if t_i <= L:
            y[i] = y0
        else:
            y[i] = y0 + K * dU * (1 - np.exp(-(t_i - L) / tau))
    return y

@app.route('/calculate')
def calculate_pi():
    if len(recorded_data["time"]) < 10:
        return jsonify({"status": "error", "message": "Faltan datos. Deja correr la prueba al menos 30 segundos."})
    
    t = np.array(recorded_data["time"])
    y = np.array(recorded_data["temp1"])
    
    dU = control_config.get("current_pwm", 153.0)
    if dU == 0: dU = 153.0
    K_guess = (y[-1] - y[0]) / dU
    bounds = ([-np.inf, 1.0, 0.0], [np.inf, 2000.0, 500.0])
    
    try:
        popt, _ = curve_fit(fopdt, t, y, p0=[K_guess, 50.0, 5.0], bounds=bounds)
        K, tau, L = popt
        
        abs_K = abs(K)
        if abs_K < 1e-5: abs_K = 1e-5
        if L < 0.1: L = 0.1
        
        # Reglas Cohen-Coon para Control PI
        Kp = (tau / (abs_K * L)) * (0.9 + (L / (12 * tau)))
        Ti = L * ((30 * tau + 3 * L) / (9 * tau + 20 * L))
        Ki = Kp / Ti
        
        # Actualizar automáticamente en la configuración
        control_config["kp"] = round(float(Kp), 4)
        control_config["ki"] = round(float(Ki), 4)

        fitted_y = fopdt(t, K, tau, L)
        
        return jsonify({
            "status": "success",
            "K": round(K, 4), "tau": round(tau, 2), "L": round(L, 2),
            "Kp": round(Kp, 4), "Ki": round(Ki, 4),
            "fit_time": t.tolist(), "fit_temp": fitted_y.tolist()
        })
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)})

# ========================================================
# ENDPOINTS DEL ESTUDIO DE CÓDIGO & COMPILADOR ESP32 (WEB IDE)
# ========================================================
@app.route('/api/ide/templates', methods=['GET'])
def get_ide_templates():
    templates = []
    
    # 1. Firmware Oficial ALUNA PBR-02
    aluna_path = os.path.join(FIRMWARE_DIR, "esp32_firmware.ino")
    aluna_code = ""
    if os.path.exists(aluna_path):
        with open(aluna_path, 'r', encoding='utf-8') as f:
            aluna_code = f.read()
            
    templates.append({
        "id": "aluna_firmware",
        "title": "🧬 1. Firmware Oficial ALUNA PBR-02",
        "desc": "Lazo PI, PWM 1kHz para Peltier, Servomotor MG996R y telemetría de 5 canales.",
        "badge": "Producción",
        "code": aluna_code
    })

    # 2. Diagnóstico de Sensores
    sensor_path = os.path.join(FIRMWARE_DIR, "test_sensores", "test_sensores.ino")
    sensor_code = ""
    if os.path.exists(sensor_path):
        with open(sensor_path, 'r', encoding='utf-8') as f:
            sensor_code = f.read()
            
    templates.append({
        "id": "test_sensores",
        "title": "🔬 2. Diagnóstico Dual de Sensores",
        "desc": "Lectura independiente D15 (Agua) y D13 (Aire), escaneo ROM y comandos seriales ('1', '2', 'B').",
        "badge": "Diagnóstico",
        "code": sensor_code
    })

    # 3. Respuesta al Escalón
    step_path = os.path.join(FIRMWARE_DIR, "step_response", "step_response.ino")
    step_code = ""
    if os.path.exists(step_path):
        with open(step_path, 'r', encoding='utf-8') as f:
            step_code = f.read()
            
    templates.append({
        "id": "step_response",
        "title": "⚡ 3. Respuesta al Escalón (FOPDT)",
        "desc": "Ensayo térmico en lazo abierto con escalón de 60% PWM para identificación matemática.",
        "badge": "Modelado",
        "code": step_code
    })

    # 4. Blink / Sanity Check ESP32
    blink_code = """// Sanity Check y Test Básico para ESP32
// ALUNA PBR-02
void setup() {
  Serial.begin(115200);
  pinMode(2, OUTPUT); // LED integrado o GPIO 2
  Serial.println("==================================");
  Serial.println(" ESP32 INICIADO CORRECTAMENTE ");
  Serial.println(" Reloj: 240 MHz | Baud: 115200");
  Serial.println("==================================");
}

void loop() {
  digitalWrite(2, HIGH);
  Serial.println("[ESP32 VIVO] LED ON  - Pulso Activo");
  delay(1000);
  digitalWrite(2, LOW);
  Serial.println("[ESP32 VIVO] LED OFF - Pulso Reposo");
  delay(1000);
}
"""
    templates.append({
        "id": "blink_test",
        "title": "💡 4. Test Básico ESP32 (Blink / Sanity Check)",
        "desc": "Verificación de inicialización del microcontrolador y comunicación serial a 115200 baudios.",
        "badge": "Básico",
        "code": blink_code
    })

    # 5. Código en Blanco
    blank_code = """// Código Libre C++ / Arduino para ESP32
// Proyecto ALUNA PBR-02

void setup() {
  Serial.begin(115200);
  // Inicialización de pines y periféricos
}

void loop() {
  // Lógica principal de ejecución
}
"""
    templates.append({
        "id": "blank",
        "title": "📝 5. Sketch en Blanco (Editor Libre)",
        "desc": "Plantilla vacía para escribir o pegar cualquier código C++/Arduino personalizado.",
        "badge": "Libre",
        "code": blank_code
    })

    return jsonify({"status": "success", "templates": templates})

@app.route('/api/ide/compile', methods=['POST'])
def ide_compile():
    data = request.json or {}
    code = data.get('code', '')
    fqbn = data.get('fqbn', 'esp32:esp32:esp32')

    if not code.strip():
        return jsonify({"status": "error", "message": "El código está vacío."}), 400

    try:
        os.makedirs(BUILD_DIR, exist_ok=True)
        with open(SKETCH_PATH, 'w', encoding='utf-8') as f:
            f.write(code)

        cmd = [
            ARDUINO_CLI_PATH,
            "compile",
            "--fqbn", fqbn,
            SKETCH_PATH
        ]
        res = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, timeout=120)
        output = (res.stdout or "") + ("\n" + res.stderr if res.stderr else "")

        if res.returncode == 0:
            return jsonify({
                "status": "success",
                "message": output.strip(),
                "returncode": res.returncode
            })
        else:
            return jsonify({
                "status": "error",
                "message": output.strip(),
                "returncode": res.returncode
            }), 400
    except subprocess.TimeoutExpired:
        return jsonify({"status": "error", "message": "Tiempo de compilación excedido (Timeout > 120s)."}), 500
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500

@app.route('/api/ide/upload', methods=['POST'])
def ide_upload():
    global ser, is_testing
    data = request.json or {}
    code = data.get('code', '')
    fqbn = data.get('fqbn', 'esp32:esp32:esp32')
    port = data.get('port')

    if not port:
        ports = [p.device for p in serial.tools.list_ports.comports()]
        if ports:
            port = ports[0]
        else:
            return jsonify({"status": "error", "message": "No se detectó ningún puerto serie ESP32 conectado."}), 400

    if not code.strip():
        return jsonify({"status": "error", "message": "El código está vacío."}), 400

    # Cerrar puerto serial de telemetría de forma limpia para liberar /dev/ttyUSB*
    saved_port = port
    if ser and ser.is_open:
        saved_port = ser.port
        try:
            ser.close()
        except Exception:
            pass
        ser = None
        time.sleep(0.5)

    try:
        os.makedirs(BUILD_DIR, exist_ok=True)
        with open(SKETCH_PATH, 'w', encoding='utf-8') as f:
            f.write(code)

        cmd = [
            ARDUINO_CLI_PATH,
            "compile",
            "--upload",
            "-p", port,
            "--fqbn", fqbn,
            SKETCH_PATH
        ]
        res = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, timeout=120)
        output = (res.stdout or "") + ("\n" + res.stderr if res.stderr else "")

        # Reabrir puerto serial tras el flasheo
        time.sleep(1.0)
        try:
            ser = serial.Serial(saved_port, 115200, timeout=1)
        except Exception:
            pass

        if res.returncode == 0:
            return jsonify({
                "status": "success",
                "message": output.strip(),
                "returncode": res.returncode
            })
        else:
            return jsonify({
                "status": "error",
                "message": output.strip(),
                "returncode": res.returncode
            }), 400
    except subprocess.TimeoutExpired:
        try:
            ser = serial.Serial(saved_port, 115200, timeout=1)
        except Exception:
            pass
        return jsonify({"status": "error", "message": "Tiempo de carga excedido (Timeout > 120s)."}), 500
    except Exception as e:
        try:
            ser = serial.Serial(saved_port, 115200, timeout=1)
        except Exception:
            pass
        return jsonify({"status": "error", "message": str(e)}), 500

if __name__ == '__main__':
    app.run(debug=True, port=5000, use_reloader=False)
