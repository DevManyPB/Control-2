# ALUNA PBR-02: "Aluna Duna"
## Sistema de Control Térmico Biomimético para Fotobiorreactores (*Tetraselmis chuii*)
### Proyecto Capstone I -- Control II (2026-II) | Universidad del Magdalena

Plataforma de automatización y control térmico bioinspirada en el **Frailejón de la Sierra Nevada** (*Espeletia occulta* subsp. *glossophylla*) para el cultivo y protección de la microalga marina ***Tetraselmis chuii*** (consigna óptima: **20.0 °C – 22.0 °C**).

---

## 📂 Organización del Repositorio por Categorías

El repositorio se encuentra estructurado en **4 categorías principales**:

```text
Control2/
│
├── 📁 plataforma_iot/             # 🚀 Plataforma IoT de Adquisición, Actuación y Control
│   ├── esp32_firmware/            # Firmware C++ (ESP32: Doble DS18B20 + PWM Peltier + Servo MG996R)
│   ├── web_app/                   # Backend API en Python (Flask, SciPy, Lazo PI y Lógica Frailejón)
│   └── frontend/                  # Dashboard Sci-Fi en Astro v4 + Tailwind CSS + Plotly
│
├── 📁 simulacion_matlab/          # 🔬 Modelado Matemático y Simulación en MATLAB / Simulink
│   ├── aluna_pbr_simulink.slx     # Modelo de simulación física del biorreactor
│   ├── crear_modelo_simulink.m    # Script constructor del modelo continuo ODE
│   ├── modelo_odes.m              # Ecuaciones diferenciales del sistema (Biomasa, Sustrato, Temp)
│   ├── parametros_modelo.m        # Parámetros y constantes cinéticas/térmicas
│   └── simular_sistema.m          # Simulación y graficación de respuestas temporales
│
├── 📁 documentacion/              # 📄 Manuales Técnicos, Esquemáticos y Archivos para Overleaf
│   ├── Manual_Operacion_ALUNA.tex # Manual Maestro completo listo para Overleaf (pdfLaTeX)
│   ├── Tabla_Conexiones_ALUNA_PBR02.pdf # Tabla de conexiones lista para consultar/imprimir
│   ├── tabla_conexiones.html      # Versión web de la tabla de conexiones
│   └── latex/                     # Versiones adicionales y artículos IEEE
│       ├── Main_Articulo_IEEE.tex # Artículo en formato conferencia IEEE
│       └── Manual_Operacion_Legacy.tex # Versión preliminar del manual
│
└── 📁 presentaciones/             # 🎨 Diapositivas, Gráficos y Material de Divulgación
    ├── pecha_kucha/               # Presentación interactiva Pecha Kucha (20 diapositivas x 20s)
    ├── presentacion_aluna/        # Diapositivas web interactivas con recursos gráficos
    ├── mi_presentacion/           # Proyecto web de presentación alternativo
    └── pecha-kucha-aluna.zip      # Respaldo comprimido del material visual
```

---

## ⚡ Asignación de Pines Hardware en la ESP32 (38 Pines)

| Señal / Componente | Pin Físico | Fila / Ubicación | Función / Protocolo |
| :--- | :--- | :--- | :--- |
| **Sensor 1 (Agua / Reactor)** | **`D15`** | Fila Inferior, Pin 3 | Bus 1-Wire (Pull-up 4.7k$\Omega$ a 3V3) |
| **Sensor 2 (Ambiente / Disipador)** | **`D13`** | Fila Superior, Pin 3 | Bus 1-Wire (Pull-up interno activado) |
| **MOSFET Peltier (TEC1-12706)** | **`D25`** | Fila Superior, Pin 8 | PWM 1 kHz (0 a 255) |
| **Servo MG996R (Escudo Orbital)** | **`D27`** | Fila Superior, Pin 6 | PWM 50 Hz (0° = Abierto, 180° = Cerrado) |
| **Tierra de Control (Común)** | **`GND`** | Fila Superior / Inferior | **Masa común obligatoria** (ESP32 + MOSFET + Servo) |
| **Alimentación Lógica Sensores** | **`3V3`** | Fila Inferior, Pin 1 | 3.3V regulado de la ESP32 |

> [!WARNING]
> **Alimentación del Servomotor MG996R:**
> El servomotor debe recibir **5.0V a 6.0V externos (mínimo 2.5A)** mediante un reductor DC-DC tipo LM2596 conectado a la fuente principal. **NUNCA conectes el positivo del servo al 3V3 ni al VIN del ESP32.**

---

## 🚀 Guía Rápida de Uso

### 1. Iniciar el Backend (Python Flask API)
```bash
cd plataforma_iot
source venv/bin/activate
cd web_app
python3 app.py
```
*(Corre en `http://localhost:5000`)*

### 2. Iniciar el Frontend (Astro Dashboard)
En otra terminal:
```bash
cd plataforma_iot/frontend
npm run dev -- --host
```
*(Abre en tu navegador: `http://localhost:4321`)*

### 3. Compilar el Manual en Overleaf
1. Abre [Overleaf](https://www.overleaf.com) y crea un nuevo proyecto (*Blank Project*).
2. Copia todo el contenido del archivo `documentacion/Manual_Operacion_ALUNA.tex` y pégalo en Overleaf.
3. Compila con **pdfLaTeX** y descarga el documento oficial en PDF.
