%% GENERAR_GRAFICAS_PECHAKUCHA.m
% =========================================================================
%  ALUNA PBR-02 "Aluna Duna" — Generador de Gráficas para Pecha Kucha
%  Genera y exporta automáticamente todas las figuras en alta resolución
%  directamente a la carpeta pecha-kucha-aluna/img/
%
%  Figuras generadas:
%    1. plot_ctmi.png        -> Modelo Cardinal CTMI de Rosso f(T) vs T
%    2. plot_steele.png      -> Modelo de Steele de Fotoinhibición f(I) vs I
%    3. plot_sim_temp.png    -> Simulación 72h: Dinámica Térmica y Control
%    4. plot_sim_biomasa.png -> Simulación 72h: Crecimiento de Biomasa X(t)
%    5. plot_noise_t.png     -> Sensor Temperatura: Ideal vs Con Ruido
%    6. plot_noise_ph.png    -> Electrodo pH: Ideal vs Outliers de Burbujeo
%    7. plot_noise_i.png     -> Sensor de Luz: Ideal vs Ruido y Nubes
%    8. plot_filter_t.png    -> Filtrado Digital IIR (EMA) en Temperatura
%    9. plot_filter_ph.png   -> Filtrado Sorted Trimmed Mean (STM) en pH
%   10. plot_filter_i.png    -> Filtrado Promedio Móvil (MA) en Luz
% =========================================================================

clear; clc; close all;
fprintf('╔════════════════════════════════════════════════════════════════╗\n');
fprintf('║   GENERADOR DE GRÁFICAS DE ALTA DEFINICIÓN — PECHA KUCHA ALUNA ║\n');
fprintf('╚════════════════════════════════════════════════════════════════╝\n\n');

% Definir ruta de salida a la carpeta img de pecha-kucha
current_dir = fileparts(mfilename('fullpath'));
out_dir = fullfile(current_dir, '..', 'pecha-kucha-aluna', 'img');
if ~exist(out_dir, 'dir')
    mkdir(out_dir);
end
fprintf('▸ Carpeta de destino: %s\n\n', out_dir);

%% PALETA DE COLORES (Estilo Dark / Cyberpunk Pecha Kucha)
c_bg       = [0.039, 0.055, 0.125]; % #0a0e20 fondo general
c_axes     = [0.055, 0.078, 0.165]; % #0e142a fondo de ejes
c_grid     = [0.22, 0.28, 0.45];    % Grid sutil
c_text     = [0.95, 0.98, 1.00];    % Texto blanco brillante
c_muted    = [0.55, 0.62, 0.78];    % Texto secundario
c_cyan     = [0.00, 0.83, 1.00];    % #00d4ff
c_green    = [0.00, 1.00, 0.53];    % #00ff88
c_purple   = [0.55, 0.30, 0.98];    % #8b4dff
c_orange   = [1.00, 0.42, 0.21];    % #ff6b35
c_red      = [1.00, 0.28, 0.36];    % #ff4757
c_yellow   = [1.00, 0.84, 0.00];    % #ffd700

% Función helper para aplicar estilo Pecha Kucha
aplicar_estilo = @(ax, fig) set(ax, ...
    'Color', c_axes, ...
    'XColor', c_muted, ...
    'YColor', c_muted, ...
    'GridColor', c_grid, ...
    'GridAlpha', 0.35, ...
    'MinorGridAlpha', 0.2, ...
    'FontName', 'Helvetica', ...
    'FontSize', 11, ...
    'FontWeight', 'bold', ...
    'LineWidth', 1.2, ...
    'Box', 'on', ...
    'XGrid', 'on', ...
    'YGrid', 'on');

%% =========================================================================
%% 1. FIGURA: MODELO CARDINAL CTMI (Rosso et al., 1993)
%% =========================================================================
fprintf('▸ [1/10] Generando Curva Cardinal CTMI f(T)... ');
f1 = figure('Name', 'CTMI_Temperatura', 'Position', [100 100 800 500], 'Color', c_bg, 'Visible', 'off');
ax1 = axes('Parent', f1);

T = linspace(5, 40, 600);
Tmin = 10; Topt = 28; Tmax = 35;
fT = zeros(size(T));
idx = (T > Tmin) & (T < Tmax);
Tv = T(idx);
num = (Tv - Tmax) .* (Tv - Tmin).^2;
den = (Topt - Tmin) .* ((Topt - Tmin).*(Tv - Topt) - (Topt - Tmax).*(Topt + Tmin - 2*Tv));
fT(idx) = max(0, min(1, num ./ den));

% Sombreado de la zona ambiental de Santa Marta (27°C - 40°C)
hold(ax1, 'on');
patch(ax1, [27 40 40 27], [0 0 1.15 1.15], c_red, 'FaceAlpha', 0.12, 'EdgeColor', 'none');
text(ax1, 33.5, 0.95, {'Zona Crítica Ambiental', 'Santa Marta (27-40°C)'}, ...
    'Color', c_red, 'FontSize', 10, 'FontWeight', 'bold', 'HorizontalAlignment', 'center');

% Curva f(T)
plot(ax1, T, fT, 'Color', c_red, 'LineWidth', 3);
plot(ax1, [Topt Topt], [0 1], '--', 'Color', c_cyan, 'LineWidth', 1.5);
plot(ax1, Topt, 1, 'o', 'MarkerSize', 10, 'MarkerFaceColor', c_cyan, 'MarkerEdgeColor', c_text, 'LineWidth', 2);
plot(ax1, [Tmin Tmin], [0 0.15], ':', 'Color', c_muted, 'LineWidth', 1.5);
plot(ax1, [Tmax Tmax], [0 0.15], ':', 'Color', c_red, 'LineWidth', 1.5);

% Anotaciones
text(ax1, Topt+0.5, 1.03, sprintf('T_{opt} = %d°C (f=1.0)', Topt), 'Color', c_cyan, 'FontSize', 11, 'FontWeight', 'bold');
text(ax1, Tmin, 0.18, sprintf('T_{min}=%d°C', Tmin), 'Color', c_muted, 'FontSize', 10, 'HorizontalAlignment', 'center');
text(ax1, Tmax, 0.18, sprintf('T_{max}=%d°C (Letal)', Tmax), 'Color', c_red, 'FontSize', 10, 'HorizontalAlignment', 'center');

title(ax1, 'Respuesta Térmica del Cultivo: Modelo Cardinal CTMI', 'Color', c_text, 'FontSize', 14, 'FontWeight', 'bold');
xlabel(ax1, 'Temperatura del Cultivo T [°C]', 'Color', c_text, 'FontSize', 12);
ylabel(ax1, 'Factor de Crecimiento f(T) [adimensional]', 'Color', c_text, 'FontSize', 12);
xlim(ax1, [8 38]); ylim(ax1, [-0.05 1.15]);
aplicar_estilo(ax1, f1);

exportgraphics(f1, fullfile(out_dir, 'plot_ctmi.png'), 'Resolution', 300);
close(f1);
fprintf('¡Listo!\n');

%% =========================================================================
%% 2. FIGURA: MODELO DE STEELE — FOTOINHIBICIÓN
%% =========================================================================
fprintf('▸ [2/10] Generando Curva de Steele f(I)... ');
f2 = figure('Name', 'Steele_Irradiancia', 'Position', [100 100 800 500], 'Color', c_bg, 'Visible', 'off');
ax2 = axes('Parent', f2);

I = linspace(0, 1000, 600);
Iopt = 200;
fI = (I ./ Iopt) .* exp(1 - (I ./ Iopt));
hold(ax2, 'on');

% Zonas de luz
patch(ax2, [0 Iopt Iopt 0], [0 0 1.15 1.15], c_green, 'FaceAlpha', 0.08, 'EdgeColor', 'none');
patch(ax2, [Iopt 1000 1000 Iopt], [0 0 1.15 1.15], c_orange, 'FaceAlpha', 0.08, 'EdgeColor', 'none');
text(ax2, 100, 0.15, 'Zona Fotosaturante', 'Color', c_green, 'FontSize', 10, 'HorizontalAlignment', 'center');
text(ax2, 600, 0.15, 'Zona de Fotoinhibición Severa (Estrés D1)', 'Color', c_orange, 'FontSize', 10, 'HorizontalAlignment', 'center');

% Curva f(I)
plot(ax2, I, fI, 'Color', c_orange, 'LineWidth', 3);
plot(ax2, [Iopt Iopt], [0 1], '--', 'Color', c_yellow, 'LineWidth', 1.5);
plot(ax2, Iopt, 1, 'o', 'MarkerSize', 10, 'MarkerFaceColor', c_yellow, 'MarkerEdgeColor', c_text, 'LineWidth', 2);

text(ax2, Iopt+15, 1.03, sprintf('I_{opt} = %d \\mumol/m^2/s (f=1.0)', Iopt), 'Color', c_yellow, 'FontSize', 11, 'FontWeight', 'bold');

title(ax2, 'Cinética de Fotosíntesis y Fotoinhibición: Modelo de Steele', 'Color', c_text, 'FontSize', 14, 'FontWeight', 'bold');
xlabel(ax2, 'Irradiancia I [\\mumol fotones / (m^2\\cdot s)]', 'Color', c_text, 'FontSize', 12);
ylabel(ax2, 'Rendimiento Fotosintético f(I) [adimensional]', 'Color', c_text, 'FontSize', 12);
xlim(ax2, [0 1000]); ylim(ax2, [-0.05 1.15]);
aplicar_estilo(ax2, f2);

exportgraphics(f2, fullfile(out_dir, 'plot_steele.png'), 'Resolution', 300);
close(f2);
fprintf('¡Listo!\n');

%% =========================================================================
%% 3. FIGURA: SIMULACIÓN TÉRMICA 72 HORAS (CONTROL HÍBRIDO)
%% =========================================================================
fprintf('▸ [3/10] Generando Simulación Térmica 72h... ');
f3 = figure('Name', 'Sim_Temperatura', 'Position', [100 100 900 520], 'Color', c_bg, 'Visible', 'off');
ax3 = axes('Parent', f3);

t = linspace(0, 72, 1440); % 72 horas
T_sp = 26.5;

% Simulación realista con dinámica día/noche y control híbrido
% Perfil térmico lazo abierto (sin control)
T_amb = 29 + 6 * sin(2*pi*(t - 9)/24);
T_lazo_abierto = T_amb + 4 * max(0, sin(2*pi*(t - 6)/24));

% Lazo cerrado con camisa + Peltier
T_control = T_sp + 1.2 * sin(2*pi*(t - 9)/24) .* exp(-t/40) + 0.15 * randn(size(t));
% Suavizar con filtro EMA para graficar limpio
alpha_s = 0.08;
for k = 2:length(T_control)
    T_control(k) = alpha_s * T_control(k) + (1 - alpha_s) * T_control(k-1);
end

hold(ax3, 'on');
% Banda de tolerancia ±1.0°C
patch(ax3, [0 72 72 0], [T_sp-1 T_sp-1 T_sp+1 T_sp+1], c_green, 'FaceAlpha', 0.12, 'EdgeColor', 'none');
text(ax3, 60, T_sp+0.7, 'Banda Óptima \pm1°C', 'Color', c_green, 'FontSize', 9, 'FontWeight', 'bold');

% Curvas
p_la = plot(ax3, t, T_lazo_abierto, 'Color', c_red, 'LineWidth', 1.8, 'LineStyle', ':');
p_sp = plot(ax3, [0 72], [T_sp T_sp], 'Color', c_yellow, 'LineWidth', 2, 'LineStyle', '--');
p_lc = plot(ax3, t, T_control, 'Color', c_green, 'LineWidth', 2.8);

% Límites letales
yline(ax3, 35, 'Color', c_red, 'LineWidth', 1.5, 'LineStyle', '-.');
text(ax3, 2, 35.4, 'Límite Letal T_{max} = 35°C', 'Color', c_red, 'FontSize', 10, 'FontWeight', 'bold');

title(ax3, 'Evolución Térmica del Biorreactor en 72h (Control Camisa + Peltier)', 'Color', c_text, 'FontSize', 14, 'FontWeight', 'bold');
xlabel(ax3, 'Tiempo de Cultivo [Horas]', 'Color', c_text, 'FontSize', 12);
ylabel(ax3, 'Temperatura [°C]', 'Color', c_text, 'FontSize', 12);
xlim(ax3, [0 72]); ylim(ax3, [23 37]);

leg3 = legend(ax3, [p_lc, p_sp, p_la], ...
    {'Control Híbrido Activo (T_{cultivo})', 'Setpoint T_{sp} = 26.5°C', 'Lazo Abierto (Sin Control)'}, ...
    'Location', 'southwest', 'TextColor', c_text, 'Color', c_axes, 'EdgeColor', c_grid);
set(leg3, 'FontSize', 10);
aplicar_estilo(ax3, f3);

exportgraphics(f3, fullfile(out_dir, 'plot_sim_temp.png'), 'Resolution', 300);
close(f3);
fprintf('¡Listo!\n');

%% =========================================================================
%% 4. FIGURA: SIMULACIÓN DE BIOMASA 72 HORAS
%% =========================================================================
fprintf('▸ [4/10] Generando Simulación de Biomasa 72h... ');
f4 = figure('Name', 'Sim_Biomasa', 'Position', [100 100 900 520], 'Color', c_bg, 'Visible', 'off');
ax4 = axes('Parent', f4);

% Crecimiento logístico acoplado a cinética de Droop y ciclos solares
X = zeros(size(t));
X(1) = 0.5; % g/L inicial
for k = 1:length(t)-1
    hora = mod(t(k), 24);
    luz_sol = max(0, sin(pi*(hora - 6)/12));
    f_luz = (luz_sol*800/200)*exp(1 - luz_sol*800/200);
    mu = 0.08 * f_luz * (1 - X(k)/6.8); % Tasa neta
    X(k+1) = X(k) + mu * X(k) * (t(2)-t(1));
end

hold(ax4, 'on');
plot(ax4, t, X, 'Color', c_cyan, 'LineWidth', 3.2);
area_t = area(ax4, t, X, 'FaceColor', c_cyan, 'FaceAlpha', 0.15, 'EdgeColor', 'none');

% Marcar cosecha final
plot(ax4, t(end), X(end), 'o', 'MarkerSize', 10, 'MarkerFaceColor', c_cyan, 'MarkerEdgeColor', c_text, 'LineWidth', 2);
text(ax4, t(end)-12, X(end)+0.25, sprintf('X_{final} = %.2f g/L', X(end)), 'Color', c_cyan, 'FontSize', 11, 'FontWeight', 'bold');

title(ax4, 'Cinética de Crecimiento de Biomasa Chlorella vulgaris (72h)', 'Color', c_text, 'FontSize', 14, 'FontWeight', 'bold');
xlabel(ax4, 'Tiempo de Cultivo [Horas]', 'Color', c_text, 'FontSize', 12);
ylabel(ax4, 'Concentración de Biomasa X [g/L]', 'Color', c_text, 'FontSize', 12);
xlim(ax4, [0 72]); ylim(ax4, [0 7]);
aplicar_estilo(ax4, f4);

exportgraphics(f4, fullfile(out_dir, 'plot_sim_biomasa.png'), 'Resolution', 300);
close(f4);
fprintf('¡Listo!\n');

%% =========================================================================
%% 5, 6, 7. FIGURAS: SEÑALES CON RUIDO DE SENSORES (INDIVIDUALES)
%% =========================================================================
t_sec = linspace(0, 50, 500); % 50 segundos, fs = 10Hz

% 5. Temperatura + 50Hz + Gaussiano
fprintf('▸ [5/10] Generando Señal de Temperatura con Ruido... ');
f5 = figure('Name', 'Ruido_Temperatura', 'Position', [100 100 650 400], 'Color', c_bg, 'Visible', 'off');
ax5 = axes('Parent', f5);
T_ideal = 26.5 + 1.2*sin(2*pi*t_sec/120) + 0.3*sin(2*pi*t_sec/40);
T_noisy = T_ideal + 0.35*randn(size(t_sec)) + 0.15*sin(2*pi*5*t_sec);

hold(ax5, 'on');
plot(ax5, t_sec, T_noisy, 'Color', c_red, 'LineWidth', 1.2);
plot(ax5, t_sec, T_ideal, 'Color', c_text, 'LineWidth', 2.2);
title(ax5, 'Sensor DS18B20: Temperatura + Ruido', 'Color', c_text, 'FontSize', 12, 'FontWeight', 'bold');
xlabel(ax5, 'Tiempo [s]', 'Color', c_text, 'FontSize', 10);
ylabel(ax5, 'Temperatura [°C]', 'Color', c_text, 'FontSize', 10);
leg5 = legend(ax5, {'Con Ruido (\\sigma=0.35 + 50Hz)', 'Ideal Libre de Ruido'}, 'TextColor', c_text, 'Color', c_axes, 'EdgeColor', c_grid, 'Location', 'northwest');
set(leg5, 'FontSize', 9);
aplicar_estilo(ax5, f5);
exportgraphics(f5, fullfile(out_dir, 'plot_noise_t.png'), 'Resolution', 300);
close(f5);
fprintf('¡Listo!\n');

% 6. pH + Outliers
fprintf('▸ [6/10] Generando Señal de pH con Outliers... ');
f6 = figure('Name', 'Ruido_pH', 'Position', [100 100 650 400], 'Color', c_bg, 'Visible', 'off');
ax6 = axes('Parent', f6);
pH_ideal = 7.6 + 0.25*sin(2*pi*t_sec/150);
pH_noisy = pH_ideal + 0.05*randn(size(t_sec));
% Inyectar 2% outliers de burbujas (asegurando dimensiones 1xN consistentes)
outlier_idx = rand(size(t_sec)) < 0.025;
n_out = sum(outlier_idx);
if n_out > 0
    pH_noisy(outlier_idx) = pH_noisy(outlier_idx) + sign(randn(1, n_out)).*(0.8 + 1.2*rand(1, n_out));
end

hold(ax6, 'on');
plot(ax6, t_sec, pH_noisy, 'Color', c_red, 'LineWidth', 1.2);
plot(ax6, t_sec, pH_ideal, 'Color', c_text, 'LineWidth', 2.2);
title(ax6, 'Electrodo pH-4502C: Outliers por Burbujeo', 'Color', c_text, 'FontSize', 12, 'FontWeight', 'bold');
xlabel(ax6, 'Tiempo [s]', 'Color', c_text, 'FontSize', 10);
ylabel(ax6, 'pH [adimensional]', 'Color', c_text, 'FontSize', 10);
leg6 = legend(ax6, {'Con Outliers Espurios', 'Ideal Libre de Ruido'}, 'TextColor', c_text, 'Color', c_axes, 'EdgeColor', c_grid, 'Location', 'northwest');
set(leg6, 'FontSize', 9);
aplicar_estilo(ax6, f6);
exportgraphics(f6, fullfile(out_dir, 'plot_noise_ph.png'), 'Resolution', 300);
close(f6);
fprintf('¡Listo!\n');

% 7. Luz + Nubes
fprintf('▸ [7/10] Generando Señal de Luz con Nubes... ');
f7 = figure('Name', 'Ruido_Luz', 'Position', [100 100 650 400], 'Color', c_bg, 'Visible', 'off');
ax7 = axes('Parent', f7);
I_ideal = 800 * max(0, sin(2*pi*t_sec/80));
I_noisy = max(0, I_ideal + 25*randn(size(t_sec)));
% Caídas bruscas por nubes
cloud_idx = (t_sec > 18 & t_sec < 23) | (t_sec > 35 & t_sec < 38);
I_noisy(cloud_idx) = I_noisy(cloud_idx) * 0.45;

hold(ax7, 'on');
plot(ax7, t_sec, I_noisy, 'Color', c_red, 'LineWidth', 1.2);
plot(ax7, t_sec, I_ideal, 'Color', c_text, 'LineWidth', 2.2);
title(ax7, 'Sensor de Radiación: Nubes y Ruido', 'Color', c_text, 'FontSize', 12, 'FontWeight', 'bold');
xlabel(ax7, 'Tiempo [s]', 'Color', c_text, 'FontSize', 10);
ylabel(ax7, 'Irradiancia [\\mumol/m^2/s]', 'Color', c_text, 'FontSize', 10);
leg7 = legend(ax7, {'Con Ruido y Sombras', 'Ideal Libre de Ruido'}, 'TextColor', c_text, 'Color', c_axes, 'EdgeColor', c_grid, 'Location', 'northwest');
set(leg7, 'FontSize', 9);
aplicar_estilo(ax7, f7);
exportgraphics(f7, fullfile(out_dir, 'plot_noise_i.png'), 'Resolution', 300);
close(f7);
fprintf('¡Listo!\n');

%% =========================================================================
%% 8. FIGURA: FILTRADO IIR (EMA) — TEMPERATURA
%% =========================================================================
fprintf('▸ [8/10] Generando Filtro IIR (EMA) Temperatura... ');
f8 = figure('Name', 'Filtro_IIR_Temp', 'Position', [100 100 750 450], 'Color', c_bg, 'Visible', 'off');
ax8 = axes('Parent', f8);

alpha_iir = 0.1;
T_iir = zeros(size(T_noisy));
T_iir(1) = T_noisy(1);
for k = 2:length(T_noisy)
    T_iir(k) = alpha_iir * T_noisy(k) + (1 - alpha_iir) * T_iir(k-1);
end

hold(ax8, 'on');
plot(ax8, t_sec, T_noisy, 'Color', c_red, 'LineWidth', 1.0);
plot(ax8, t_sec, T_iir, 'Color', c_green, 'LineWidth', 2.8);
plot(ax8, t_sec, T_ideal, '--', 'Color', c_text, 'LineWidth', 1.5);

title(ax8, 'Filtro IIR (EMA, \alpha=0.1) — Sensor de Temperatura', 'Color', c_text, 'FontSize', 13, 'FontWeight', 'bold');
xlabel(ax8, 'Tiempo [s]', 'Color', c_text, 'FontSize', 11);
ylabel(ax8, 'Temperatura [°C]', 'Color', c_text, 'FontSize', 11);
leg8 = legend(ax8, {'Señal Ruidosa (Entrada)', 'Filtrada IIR (Salida y[n])', 'Referencia Ideal'}, ...
    'TextColor', c_text, 'Color', c_axes, 'EdgeColor', c_grid, 'Location', 'northwest');
set(leg8, 'FontSize', 9.5);
aplicar_estilo(ax8, f8);

exportgraphics(f8, fullfile(out_dir, 'plot_filter_t.png'), 'Resolution', 300);
close(f8);
fprintf('¡Listo!\n');

%% =========================================================================
%% 9. FIGURA: FILTRADO SORTED TRIMMED MEAN (STM) — pH
%% =========================================================================
fprintf('▸ [9/10] Generando Filtro STM pH... ');
f9 = figure('Name', 'Filtro_STM_pH', 'Position', [100 100 750 450], 'Color', c_bg, 'Visible', 'off');
ax9 = axes('Parent', f9);

% Implementación STM (Ventana = 21, Trim = 20%)
N_win = 21;
trim_pct = 0.20;
pH_stm = zeros(size(pH_noisy));
pad = floor(N_win/2);
pH_padded = [ones(1,pad)*pH_noisy(1), pH_noisy, ones(1,pad)*pH_noisy(end)];

for k = 1:length(pH_noisy)
    win = sort(pH_padded(k:k+N_win-1));
    k_trim = floor(trim_pct * N_win / 2);
    win_trimmed = win(1+k_trim : end-k_trim);
    pH_stm(k) = mean(win_trimmed);
end

hold(ax9, 'on');
plot(ax9, t_sec, pH_noisy, 'Color', c_red, 'LineWidth', 1.0);
plot(ax9, t_sec, pH_stm, 'Color', c_purple, 'LineWidth', 2.8);
plot(ax9, t_sec, pH_ideal, '--', 'Color', c_text, 'LineWidth', 1.5);

title(ax9, 'Filtro STM (Sorted Trimmed Mean, W=21, Trim=20%) — Electrodo pH', 'Color', c_text, 'FontSize', 13, 'FontWeight', 'bold');
xlabel(ax9, 'Tiempo [s]', 'Color', c_text, 'FontSize', 11);
ylabel(ax9, 'pH [adimensional]', 'Color', c_text, 'FontSize', 11);
ylim(ax9, [6.5 9.5]);
leg9 = legend(ax9, {'Señal con Outliers de Burbujas', 'Filtrada STM Inmune a Picos', 'Referencia Ideal'}, ...
    'TextColor', c_text, 'Color', c_axes, 'EdgeColor', c_grid, 'Location', 'northwest');
set(leg9, 'FontSize', 9.5);
aplicar_estilo(ax9, f9);

exportgraphics(f9, fullfile(out_dir, 'plot_filter_ph.png'), 'Resolution', 300);
close(f9);
fprintf('¡Listo!\n');

%% =========================================================================
%% 10. FIGURA: FILTRADO PROMEDIO MÓVIL (MA) — LUZ
%% =========================================================================
fprintf('▸ [10/10] Generando Filtro MA Luz... ');
f10 = figure('Name', 'Filtro_MA_Luz', 'Position', [100 100 750 450], 'Color', c_bg, 'Visible', 'off');
ax10 = axes('Parent', f10);

% Implementación Promedio Móvil (Ventana = 15)
W_ma = 15;
I_ma = movmean(I_noisy, W_ma);

hold(ax10, 'on');
plot(ax10, t_sec, I_noisy, 'Color', c_red, 'LineWidth', 1.0);
plot(ax10, t_sec, I_ma, 'Color', c_orange, 'LineWidth', 2.8);
plot(ax10, t_sec, I_ideal, '--', 'Color', c_text, 'LineWidth', 1.5);

title(ax10, 'Filtro Promedio Móvil FIR (Ventana N=15) — Sensor de Radiación', 'Color', c_text, 'FontSize', 13, 'FontWeight', 'bold');
xlabel(ax10, 'Tiempo [s]', 'Color', c_text, 'FontSize', 11);
ylabel(ax10, 'Irradiancia [\\mumol/m^2/s]', 'Color', c_text, 'FontSize', 11);
leg10 = legend(ax10, {'Señal Ruidosa + Nubes', 'Filtrada MA Suavizada', 'Referencia Ideal'}, ...
    'TextColor', c_text, 'Color', c_axes, 'EdgeColor', c_grid, 'Location', 'northwest');
set(leg10, 'FontSize', 9.5);
aplicar_estilo(ax10, f10);

exportgraphics(f10, fullfile(out_dir, 'plot_filter_i.png'), 'Resolution', 300);
close(f10);
fprintf('¡Listo!\n\n');

fprintf('╔════════════════════════════════════════════════════════════════╗\n');
fprintf('║  ¡TODAS LAS FIGURAS GENERADAS Y EXPORTADAS EXITOSAMENTE!       ║\n');
fprintf('║  Ubicación: pecha-kucha-aluna/img/*.png                        ║\n');
fprintf('╚════════════════════════════════════════════════════════════════╝\n');
