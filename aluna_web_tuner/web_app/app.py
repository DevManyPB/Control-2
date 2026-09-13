from flask import Flask, jsonify, request
from flask_cors import CORS
import serial
import serial.tools.list_ports
import threading
import time
import numpy as np
from scipy.optimize import curve_fit

app = Flask(__name__)
CORS(app)

# ========================================================
# VARIABLES DE ESTADO Y TELEMETRÍA
# ========================================================
recorded_data = {
    "time": [],
    "pwm": [],
    "temp1": [],        # Sensor 1: Agua (Reactor)
    "temp2": [],        # Sensor 2: Ambiente (Disipador)
    "servo_angle": []   # Ángulo Cortina Escudo Orbital (0° a 180°)
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
    global recorded_data, ser, is_testing, control_config
    while True:
        if ser and ser.is_open and is_testing:
            try:
                line = ser.readline().decode('utf-8', errors='ignore').strip()
                if line:
                    parts = line.split(',')
                    # Formato esperado: t, pwm, temp1, temp2, servo_angle
                    if len(parts) >= 4:
                        t = float(parts[0])
                        p = float(parts[1])
                        t1 = float(parts[2])
                        t2 = float(parts[3])
                        angle = float(parts[4]) if len(parts) >= 5 else control_config["current_servo"]

                        # Filtro básico de lectura válida (ignorar lecturas de desconexión transitoria)
                        if t1 > -50 and t1 < 80:
                            recorded_data["time"].append(t)
                            recorded_data["pwm"].append(p)
                            recorded_data["temp1"].append(t1)
                            recorded_data["temp2"].append(t2)
                            recorded_data["servo_angle"].append(angle)

                            # Si está en modo PI Automático, ejecutar algoritmo de control
                            if control_config["mode"] == "pi_auto":
                                ejecutar_control_pi(t1, t2)
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
        return jsonify({"status": "success"})
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)})

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
        "control": control_config
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

if __name__ == '__main__':
    app.run(debug=True, port=5000, use_reloader=False)
