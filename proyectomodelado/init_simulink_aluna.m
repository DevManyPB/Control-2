%% =========================================================================
%% INIT_SIMULINK_ALUNA.m
%% Script de Inicialización de Parámetros para el Modelo Simulink ALUNA PBR-02
%% Proyecto: ALUNA PBR-02 "Aluna Duna" — Control II (2026-II)
%% =========================================================================

clear; clc;
fprintf('======================================================\n');
fprintf('  INICIALIZANDO PARÁMETROS DEL BIORREACTOR ALUNA PBR\n');
fprintf('======================================================\n\n');

%% 1. Cargar Parámetros Físicos y Cinéticos Consolidados
if exist('parametros_modelo', 'file') == 2
    p = parametros_modelo();
    fprintf('✔ Parámetros base cargados desde parametros_modelo.m\n');
else
    error('No se encontró parametros_modelo.m en el path.');
end

%% 2. Parámetros de Simulación y Solver
sim_time_hours = 72;             % [h] Tiempo total de simulación (3 días)
sim_time_sec   = sim_time_hours * 3600; % [s]
dt_sim_hours   = 0.01;           % [h] Paso de simulación base

%% 3. Condiciones Iniciales del Estado x = [X; S; Q; T]
X0 = 0.5;                        % [g/L] Biomasa inicial de Chlorella vulgaris
S0 = 5.0;                        % [mmol/L] Sustrato de carbono inicial (TIC)
Q0 = 5.0;                        % [mmol C / g biomasa] Cuota celular inicial
T0 = 28.0;                       % [°C] Temperatura inicial del cultivo

x0 = [X0, S0, Q0, T0];

%% 4. Referencias y Setpoints de Control
T_sp = 26.5;                     % [°C] Setpoint óptimo de temperatura
pH_sp = 7.6;                     % [adimensional] Setpoint de pH

%% 5. Parámetros de los Filtros Digitales (DSP)
% --- Filtro IIR (EMA) para Temperatura ---
alpha_iir = 0.1;                 % Factor de suavizado exponencial
num_iir   = [alpha_iir];         % Numerador H(z)
den_iir   = [1, -(1 - alpha_iir)]; % Denominador H(z)

% --- Filtro Promedio Móvil (MA) para Radiación Solar ---
N_ma      = 15;                  % Ventana de muestras
num_ma    = ones(1, N_ma) / N_ma;
den_ma    = [1];

% --- Filtro Sorted Trimmed Mean (STM) para pH ---
W_stm     = 21;                  % Ventana de 21 muestras
trim_stm  = 0.20;                % 20% de recorte (10% inferior, 10% superior)

% --- Filtro Analógico RC Anti-aliasing ---
R_rc = 10000;                    % [Ohm] 10 kΩ
C_rc = 5.3e-6;                   % [F] 5.3 µF
fc_rc = 1 / (2 * pi * R_rc * C_rc); % ~3 Hz

%% 6. Parámetros del Actuador Peltier (TEC1-12706)
alpha_te = 0.05;                 % [V/K] Coeficiente Seebeck efectivo
R_te     = 2.0;                  % [Ohm] Resistencia eléctrica interna
K_te     = 0.5;                  % [W/K] Conductancia térmica del módulo
Ie_max   = 4.0;                  % [A] Límite estricto de corriente (anti-Joule)

%% 7. Parámetros de la Camisa Aislante Conmutable
U_abierta = p.U0;                % [W/(m²·K)] Camisa abierta (disipación libre)
U_cerrada = p.U1;                % [W/(m²·K)] Camisa aislada (retención térmica)

fprintf('✔ Condiciones iniciales: X0 = %.1f g/L, S0 = %.1f mmol/L, Q0 = %.1f, T0 = %.1f °C\n', X0, S0, Q0, T0);
fprintf('✔ Setpoint térmico: %.1f °C | Límite Peltier: %.1f A\n', T_sp, Ie_max);
fprintf('✔ Filtros DSP parametrizados: IIR (alpha=%.2f), MA (N=%d), STM (W=%d)\n\n', alpha_iir, N_ma, W_stm);
fprintf('======================================================\n');
fprintf('  Workspace listo para ejecutar el modelo de Simulink!\n');
fprintf('======================================================\n');
