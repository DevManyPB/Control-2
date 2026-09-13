%% SIMULACION_PRINCIPAL.m
%  Simulación completa del biorreactor con control térmico.
%
%  Reto individual: camisa aislante variable + Peltier ("frailejón artificial")
%
%  Ejecuta 4 escenarios:
%    1. Lazo abierto, camisa abierta (s=0) — caracterización τT(0)
%    2. Lazo abierto, camisa cerrada (s=1) — caracterización τT(1)
%    3. Control completo: supervisor + PID + feedforward
%    4. Análisis de sensibilidad térmica
%
%  Vector de estados: x = [X, S, Q, T]ᵀ
%  Estado discreto:   s ∈ {0, 1} (camisa aislante)
%
%  Vacíos llenados:
%    1. dS/dt = D·(Sin − S) − ρ(S)·X  (no en §8.11, reconstruido)
%    2. f(T) = modelo cardinal CTMI     (no en ningún documento)
%
%  Autor: Estudiante — Reto térmico ALUNA
%  Fecha: Agosto 2026

clear; clc; close all;
fprintf('╔══════════════════════════════════════════════════════════════╗\n');
fprintf('║  SIMULACIÓN: Camisa Aislante Variable + Peltier            ║\n');
fprintf('║  "Frailejón Artificial" — Control Térmico de Biorreactor   ║\n');
fprintf('╚══════════════════════════════════════════════════════════════╝\n\n');

%% ====================================================================
%  0. CARGAR PARÁMETROS
% =====================================================================
p = parametros_modelo();

% Condiciones iniciales: [X0, S0, Q0, T0]
x0 = [p.X0; p.S0; p.Q0; p.T0];

% Horizonte de simulación
t_final = 72;         % [h] = 3 días (3 ciclos día/noche completos)
dt = 0.01;            % [h] Paso de integración (36 s)
t_span = 0:dt:t_final;
N = length(t_span);

%% ====================================================================
%  1. ESCENARIO A: LAZO ABIERTO — CAMISA ABIERTA (s=0)
% =====================================================================
fprintf('\n▸ Escenario A: Lazo abierto, camisa ABIERTA (s=0)...\n');

[t_A, x_A, logs_A] = simular_sistema(t_span, x0, p, ...
    'modo', 'lazo_abierto', 's_fijo', 0, 'Ie_fijo', 0);

fprintf('  τT(0) teórico = %.1f s = %.2f h\n', p.tauT0, p.tauT0/3600);
fprintf('  T final = %.2f °C\n', x_A(end, 4));

%% ====================================================================
%  2. ESCENARIO B: LAZO ABIERTO — CAMISA CERRADA (s=1)
% =====================================================================
fprintf('\n▸ Escenario B: Lazo abierto, camisa CERRADA (s=1)...\n');

[t_B, x_B, logs_B] = simular_sistema(t_span, x0, p, ...
    'modo', 'lazo_abierto', 's_fijo', 1, 'Ie_fijo', 0);

fprintf('  τT(1) teórico = %.1f s = %.2f h\n', p.tauT1, p.tauT1/3600);
fprintf('  T final = %.2f °C\n', x_B(end, 4));
fprintf('  Ratio τT(1)/τT(0) = %.2f (eficacia del aislamiento)\n', p.ratio_tau);

%% ====================================================================
%  3. ESCENARIO C: CONTROL COMPLETO (Supervisor + PID + Feedforward)
% =====================================================================
fprintf('\n▸ Escenario C: Control completo...\n');

[t_C, x_C, logs_C] = simular_sistema(t_span, x0, p, ...
    'modo', 'control_completo');

% Estadísticas de control
T_C = x_C(:, 4);
error_rms = sqrt(mean((T_C - p.Tsp).^2));
T_max_alcanzada = max(T_C);
tiempo_en_zona = sum(abs(T_C - p.Tsp) <= 2.0) / N * 100; % ±2°C
conmutaciones = sum(abs(diff(logs_C.s_log)));

fprintf('  Error RMS de temperatura = %.3f °C\n', error_rms);
fprintf('  T máxima alcanzada = %.2f °C (límite: %.0f °C)\n', ...
    T_max_alcanzada, p.Tmax);
fprintf('  Tiempo en zona ±2°C del SP = %.1f%%\n', tiempo_en_zona);
fprintf('  Conmutaciones de camisa = %d\n', conmutaciones);

%% ====================================================================
%  4. GRÁFICAS — Escenarios A y B (Lazo Abierto)
% =====================================================================
fprintf('\n▸ Generando gráficas...\n');

% --- Figura 1: Comparación térmica lazo abierto ---
figure('Name', 'Lazo Abierto: Comparación Térmica', ...
       'Position', [50 50 1200 800], 'Color', 'w');

subplot(2,2,1);
plot(t_A, x_A(:,4), 'b-', 'LineWidth', 1.5); hold on;
plot(t_B, x_B(:,4), 'r-', 'LineWidth', 1.5);
yline(p.Tsp, 'k--', 'LineWidth', 1, 'Label', 'T_{sp}');
yline(p.Tmax, 'r--', 'LineWidth', 1, 'Label', 'T_{max} (letal)');
xlabel('Tiempo [h]'); ylabel('Temperatura [°C]');
title('Temperatura del Cultivo — Lazo Abierto');
legend('s=0 (sin aislamiento)', 's=1 (con aislamiento)', ...
       'Location', 'best');
grid on;

subplot(2,2,2);
plot(t_A, x_A(:,1), 'b-', 'LineWidth', 1.5); hold on;
plot(t_B, x_B(:,1), 'r-', 'LineWidth', 1.5);
xlabel('Tiempo [h]'); ylabel('Biomasa X [g/L]');
title('Crecimiento de Biomasa');
legend('s=0', 's=1', 'Location', 'best');
grid on;

subplot(2,2,3);
plot(t_A, x_A(:,2), 'b-', 'LineWidth', 1.5); hold on;
plot(t_B, x_B(:,2), 'r-', 'LineWidth', 1.5);
xlabel('Tiempo [h]'); ylabel('Sustrato S [mmol/L]');
title('Consumo de Sustrato');
legend('s=0', 's=1', 'Location', 'best');
grid on;

subplot(2,2,4);
plot(t_A, x_A(:,3), 'b-', 'LineWidth', 1.5); hold on;
plot(t_B, x_B(:,3), 'r-', 'LineWidth', 1.5);
xlabel('Tiempo [h]'); ylabel('Cuota Q [mmol/g]');
title('Cuota Interna (Droop)');
legend('s=0', 's=1', 'Location', 'best');
grid on;

sgtitle('Escenarios A y B — Lazo Abierto (sin control)', ...
    'FontSize', 14, 'FontWeight', 'bold');

% --- Figura 2: Control completo ---
figure('Name', 'Control Completo', ...
       'Position', [100 50 1400 900], 'Color', 'w');

% 2a. Temperatura con control
subplot(3,2,1);
plot(t_C, x_C(:,4), 'Color', [0.0 0.5 0.0], 'LineWidth', 1.5); hold on;
yline(p.Tsp, 'k--', 'LineWidth', 1, 'Label', 'T_{sp}');
yline(p.Tmax, 'r--', 'LineWidth', 1, 'Label', 'T_{max}');
fill_x = [t_C', fliplr(t_C')];
fill_y = [ones(1,N)*(p.Tsp-2), ones(1,N)*(p.Tsp+2)];
fill(fill_x, fill_y, [0.5 1.0 0.5], 'FaceAlpha', 0.15, 'EdgeColor', 'none');
xlabel('Tiempo [h]'); ylabel('T [°C]');
title(sprintf('Temperatura — Error RMS = %.3f °C', error_rms));
grid on;

% 2b. Estado de la camisa
subplot(3,2,2);
stairs(t_C, logs_C.s_log, 'Color', [0.8 0.2 0.0], 'LineWidth', 2);
xlabel('Tiempo [h]'); ylabel('s');
title(sprintf('Estado de Camisa (conmutaciones: %d)', conmutaciones));
ylim([-0.1, 1.1]); yticks([0 1]);
yticklabels({'Abierta (0)', 'Cerrada (1)'});
grid on;

% 2c. Corriente Peltier
subplot(3,2,3);
plot(t_C, logs_C.Ie_log, 'Color', [0.0 0.3 0.8], 'LineWidth', 1.2);
hold on;
yline(p.Ie_opt, 'm--', 'LineWidth', 1, 'Label', 'I_{e,ópt}');
yline(p.Ie_max, 'r--', 'LineWidth', 1, 'Label', 'I_{e,max}');
xlabel('Tiempo [h]'); ylabel('I_e [A]');
title('Corriente del Peltier');
grid on;

% 2d. Irradiancia
subplot(3,2,4);
plot(t_C, logs_C.G_log, 'Color', [1.0 0.6 0.0], 'LineWidth', 1.5);
xlabel('Tiempo [h]'); ylabel('G [W/m²]');
title('Irradiancia Solar');
grid on;

% 2e. Biomasa
subplot(3,2,5);
plot(t_C, x_C(:,1), 'Color', [0.0 0.5 0.0], 'LineWidth', 1.5);
xlabel('Tiempo [h]'); ylabel('X [g/L]');
title('Biomasa con Control Térmico');
grid on;

% 2f. Sustrato y Cuota
subplot(3,2,6);
yyaxis left;
plot(t_C, x_C(:,2), 'b-', 'LineWidth', 1.5);
ylabel('Sustrato S [mmol/L]');
yyaxis right;
plot(t_C, x_C(:,3), 'r-', 'LineWidth', 1.5);
ylabel('Cuota Q [mmol/g]');
xlabel('Tiempo [h]');
title('Sustrato y Cuota Interna');
grid on;

sgtitle(sprintf(['Control Completo: Supervisor + PID + Feedforward\n', ...
    'T_{sp} = %.1f°C | Tiempo en zona = %.1f%%'], ...
    p.Tsp, tiempo_en_zona), 'FontSize', 14, 'FontWeight', 'bold');

%% ====================================================================
%  5. FIGURA 3: Caracterización de f(T) y f(I)
% =====================================================================
figure('Name', 'Factores f(T) y f(I)', ...
       'Position', [150 100 1000 400], 'Color', 'w');

subplot(1,2,1);
T_vec = linspace(0, 45, 500);
fT_vec = f_temperatura(T_vec, p.Tmin, p.Topt, p.Tmax);
plot(T_vec, fT_vec, 'r-', 'LineWidth', 2); hold on;
xline(p.Tmin, 'b--', 'T_{min}', 'LineWidth', 1);
xline(p.Topt, 'g--', 'T_{opt}', 'LineWidth', 1);
xline(p.Tmax, 'r--', 'T_{max}', 'LineWidth', 1);
xline(p.Tsp, 'k:', 'T_{sp}', 'LineWidth', 1.5);
xlabel('Temperatura [°C]'); ylabel('f(T) [-]');
title('Factor Cardinal de Temperatura (CTMI)');
subtitle('VACÍO #2: forma funcional elegida y declarada');
grid on; ylim([-0.05 1.1]);

subplot(1,2,2);
I_vec = linspace(0, 1000, 500);
fI_vec = f_luz_steele(I_vec, p.Iopt);
plot(I_vec, fI_vec, 'Color', [1.0 0.6 0.0], 'LineWidth', 2); hold on;
xline(p.Iopt, 'g--', 'I_{opt}', 'LineWidth', 1);
xlabel('Irradiancia [µmol m^{-2} s^{-1}]'); ylabel('f(I) [-]');
title('Factor de Luz (Steele, §8.4)');
grid on; ylim([-0.05 1.1]);

sgtitle('Factores Ambientales del Crecimiento', ...
    'FontSize', 14, 'FontWeight', 'bold');

%% ====================================================================
%  6. ANÁLISIS DE SENSIBILIDAD TÉRMICA (§6 del plan)
% =====================================================================
fprintf('\n▸ Análisis de sensibilidad (±30%% en parámetros clave)...\n');

params_sensibilidad = {'U0', 'U1', 'Cmasa', 'RTE'};
perturbaciones = [0.7, 1.0, 1.3];  % -30%, nominal, +30%
nombres_pert = {'-30%', 'Nominal', '+30%'};

figure('Name', 'Análisis de Sensibilidad', ...
       'Position', [200 50 1400 700], 'Color', 'w');

for ip = 1:length(params_sensibilidad)
    subplot(2, 2, ip);
    
    for jp = 1:length(perturbaciones)
        p_mod = p;  % Copia de parámetros
        
        % Aplicar perturbación
        switch params_sensibilidad{ip}
            case 'U0'
                p_mod.U0 = p.U0 * perturbaciones(jp);
            case 'U1'
                p_mod.U1 = p.U1 * perturbaciones(jp);
            case 'Cmasa'
                p_mod.Cmasa = p.Cmasa * perturbaciones(jp);
                % Recalcular capacidad total
                p_mod.rhoVcp = p_mod.rho_agua * p_mod.V * p_mod.cp;
            case 'RTE'
                p_mod.RTE = p.RTE * perturbaciones(jp);
        end
        
        % Simular
        [~, x_sens, ~] = simular_sistema(t_span, x0, p_mod, ...
            'modo', 'control_completo');
        
        % Graficar temperatura
        colores = {[0.3 0.3 1.0], [0.0 0.0 0.0], [1.0 0.3 0.3]};
        estilos = {'--', '-', '--'};
        plot(t_span, x_sens(:,4), estilos{jp}, ...
            'Color', colores{jp}, 'LineWidth', 1.5); hold on;
    end
    
    yline(p.Tsp, 'k:', 'LineWidth', 1);
    yline(p.Tmax, 'r:', 'LineWidth', 1);
    xlabel('Tiempo [h]'); ylabel('T [°C]');
    title(sprintf('Sensibilidad a %s', params_sensibilidad{ip}));
    legend(nombres_pert{:}, 'Location', 'best');
    grid on;
end

sgtitle({'Análisis de Sensibilidad — ±30% en parámetros clave', ...
    '(plantilla tipo Tabla 3 de Abu-Reesh [2])'}, ...
    'FontSize', 14, 'FontWeight', 'bold');

%% ====================================================================
%  7. FIGURA 5: Constantes de tiempo y eficacia del aislamiento
% =====================================================================
figure('Name', 'Constantes de Tiempo Térmicas', ...
       'Position', [250 150 600 400], 'Color', 'w');

bar_data = [p.tauT0/3600, p.tauT1/3600];
b = bar(categorical({'s=0 (Abierta)', 's=1 (Cerrada)'}), bar_data);
b.FaceColor = 'flat';
b.CData(1,:) = [0.3 0.5 1.0];
b.CData(2,:) = [1.0 0.3 0.3];
ylabel('\tau_T [h]');
title(sprintf('Constantes de Tiempo Térmicas — Ratio = %.2f', p.ratio_tau));
subtitle('τ_T(1)/τ_T(0): cuantifica la eficacia del aislamiento variable');
grid on;

% Anotar valores
text(1, bar_data(1)*1.05, sprintf('%.2f h', bar_data(1)), ...
    'HorizontalAlignment', 'center', 'FontWeight', 'bold');
text(2, bar_data(2)*1.05, sprintf('%.2f h', bar_data(2)), ...
    'HorizontalAlignment', 'center', 'FontWeight', 'bold');

%% ====================================================================
%  8. RESUMEN EN CONSOLA
% =====================================================================
fprintf('\n');
fprintf('╔══════════════════════════════════════════════════════════════╗\n');
fprintf('║                   RESUMEN DE RESULTADOS                    ║\n');
fprintf('╠══════════════════════════════════════════════════════════════╣\n');
fprintf('║  TÉRMICO                                                   ║\n');
fprintf('║    τT(s=0) = %8.2f h (camisa abierta)                    ║\n', p.tauT0/3600);
fprintf('║    τT(s=1) = %8.2f h (camisa cerrada)                    ║\n', p.tauT1/3600);
fprintf('║    Ratio   = %8.2f   (eficacia aislamiento)              ║\n', p.ratio_tau);
fprintf('║                                                            ║\n');
fprintf('║  CONTROL (72 h, 3 ciclos día/noche)                        ║\n');
fprintf('║    Error RMS T     = %6.3f °C                              ║\n', error_rms);
fprintf('║    T máx alcanzada = %6.2f °C (límite: %2.0f °C)            ║\n', ...
    T_max_alcanzada, p.Tmax);
fprintf('║    Tiempo en zona  = %6.1f %%                               ║\n', tiempo_en_zona);
fprintf('║    Conmutaciones   = %4d                                   ║\n', conmutaciones);
fprintf('║                                                            ║\n');
fprintf('║  BIOLÓGICO (valores finales a t=%d h)                      ║\n', t_final);
fprintf('║    Biomasa X  = %6.3f g/L                                  ║\n', x_C(end,1));
fprintf('║    Sustrato S = %6.3f mmol/L                               ║\n', x_C(end,2));
fprintf('║    Cuota Q    = %6.3f mmol/g                               ║\n', x_C(end,3));
fprintf('║                                                            ║\n');
fprintf('║  VACÍOS LLENADOS                                           ║\n');
fprintf('║    #1: dS/dt = D(Sin−S) − ρ(S)·X     ✓ Reconstruido       ║\n');
fprintf('║    #2: f(T) = CTMI cardinal (Rosso)   ✓ Declarado          ║\n');
fprintf('╚══════════════════════════════════════════════════════════════╝\n');

fprintf('\n✓ Simulación completa. Se generaron 5 figuras.\n');
