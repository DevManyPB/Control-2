# ALUNA PBR-02: "Aluna Duna"
## Sistema de Control Térmico Biomimético para Fotobiorreactores (*Tetraselmis chuii*)
### Proyecto Capstone I - Control II (2026-II) | Universidad del Magdalena

Plataforma de automatización y control térmico bioinspirada en el **Frailejón de la Sierra Nevada** (*Espeletia occulta* subsp. *glossophylla*) para el cultivo y protección de la microalga marina ***Tetraselmis chuii*** (consigna óptima: **20.0 °C – 22.0 °C**).

---

## 📂 Estructura del Repositorio y Contenido de Carpetas

```text
Control2/
│
├── documentacion/                  # 📄 Manuales, esquemáticos, tablas y archivos LaTeX
│   ├── Manual_Operacion_ALUNA.tex  # Manual maestro completo en LaTeX listo para Overleaf
│   ├── Tabla_Conexiones_ALUNA_PBR02.pdf # Tabla de conexiones lista para imprimir/consultar
│   └── tabla_conexiones.html       # Versión web imprimible de la tabla de conexiones
│
├── aluna_web_tuner/                # 🚀 Plataforma IoT de Adquisición y Control en Tiempo Real
│   ├── esp32_firmware/             # Código C++ para la ESP32 (LEDC, DallasTemperature, ESP32Servo)
│   │   └── esp32_firmware.ino      # Firmware maestro (D15=Agua, D13=Aire, D25=Peltier, D27=Servo)
│   ├── web_app/                    # Backend en Python (Flask, SciPy, PySerial)
│   │   └── app.py                  # API REST, identificación FOPDT, lazo PI y lógica Frailejón
│   └── frontend/                   # Interfaz de Usuario Moderna (Astro v4 + Tailwind CSS + Plotly)
│       └── src/pages/index.astro   # Dashboard Sci-Fi con telemetría en vivo y mandos manuales/auto
│
├── proyectomodelado/               # 🔬 Modelado Matemático y Simulación en MATLAB / Simulink
│   ├── aluna_pbr_simulink.slx      # Modelo de simulación física del biorreactor
│   ├── crear_modelo_simulink.m     # Script constructor del modelo continuo ODE
│   ├── modelo_odes.m               # Ecuaciones diferenciales del sistema (Biomasa, Sustrato, Temp)
│   ├── parametros_modelo.m         # Constantes cinéticas y termodinámicas del sistema
│   └── simular_sistema.m           # Script de simulación y graficación de respuestas
│
├── pecha-kucha-aluna/              # 🎨 Presentación y Recursos Gráficos
│   ├── index.html                  # Presentación interactiva Pecha Kucha (20 diapositivas x 20s)
│   └── img/                        # Diagramas, fotografías de hardware y gráficas vectoriales
│
├── Manual_Operacion_ALUNA.tex      # Acceso directo al código LaTeX del manual para Overleaf
└── README.md                       # Índice maestro del proyecto
```

---

## ⚡ Asignación de Pines en la ESP32 (38 Pines)

| Componente | Pin ESP32 | Fila / Ubicación | Función / Protocolo |
| :--- | :--- | :--- | :--- |
| **Sensor 1 (Agua / Reactor)** | **`D15`** | Fila Inferior, Pin 3 | Bus 1-Wire (Pull-up 4.7k$\Omega$ a 3V3) |
| **Sensor 2 (Ambiente / Disipador)** | **`D13`** | Fila Superior, Pin 3 | Bus 1-Wire (Pull-up interno activo) |
| **MOSFET Peltier (TEC1-12706)** | **`D25`** | Fila Superior, Pin 8 | Señal PWM 1 kHz (8 bits: 0 a 255) |
| **Servo MG996R (Escudo Orbital)** | **`D27`** | Fila Superior, Pin 6 | Señal PWM 50 Hz (0° a 180°) |
| **Tierra de Control (Común)** | **`GND`** | Fila Superior / Inferior | **Masa común obligatoria** (ESP32 + MOSFET + Servo) |
| **Alimentación Lógica Sensores** | **`3V3`** | Fila Inferior, Pin 1 | 3.3V regulado de la ESP32 |

> [!WARNING]
> **Alimentación del Servomotor MG996R:**
> El servomotor debe alimentarse externamente a **5V o 6V** con al menos **2.5A** de capacidad (módulo reductor DC-DC conectado a la fuente de 12V/30V). **NUNCA conectes el positivo del servo al 3V3 ni al VIN del ESP32.**

---

## 🚀 Guía de Inicio Rápido

### 1. Iniciar el Backend (Python Flask API)
```bash
cd aluna_web_tuner
source venv/bin/activate
cd web_app
python3 app.py
```
*(Corre en `http://localhost:5000`)*

### 2. Iniciar el Frontend (Astro Dashboard)
En otra terminal:
```bash
cd aluna_web_tuner/frontend
npm run dev -- --host
```
*(Abre en tu navegador: `http://localhost:4321`)*

### 3. Cargar el Manual en Overleaf
Copia el contenido del archivo `documentacion/Manual_Operacion_ALUNA.tex` en un nuevo proyecto de Overleaf y compila con **pdfLaTeX** para descargar el manual completo en PDF.
