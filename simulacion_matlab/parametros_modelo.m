function p = parametros_modelo()
% PARAMETROS_MODELO  Parámetros consolidados del sistema de cultivo.
%
%   Notación: Vía A — ALUNA (X en g/L, S/TIC en mmol/L, T en °C).
%   Conversión desde Vía B (literatura, células):
%       X[g/L] ≈ 0.02 × X[10^9 cél/L]   ⟹   1 g biomasa ≈ 50×10^9 células
%
%   ⚠ ADVERTENCIA: estos son valores de ARRANQUE tomados de literatura para
%   Chlorella vulgaris. La guía (§8.11) exige refinar/validar con ensayo
%   experimental propio antes de reportarlos como definitivos.
%
%   Fuentes:
%     [1] Tebbani, Lopes, Filali, Dumur, Pareau (2014) — vía Abu-Reesh (2025),
%         Arabian J. Sci. Eng. 50:3779-3792, Tabla 1.
%     [2] Abu-Reesh, I.M. (2025) — análisis de sensibilidad.
%     [3] Filali et al. (2011) — IFAC Proceedings 44(1) 10603-10608.
%     [4] Kumar, Brar, Kumari, Vivekanand, Pareek (2025) 3 Biotech 15:274.
%     [5] Guía de curso (ModelomatemáticoGUIA), §8, §14.

    %% ================================================================
    %  1. CINÉTICA DE CRECIMIENTO — Droop + Steele + f(T)
    % =================================================================
    % μ(Q,I,T) = μ*_max · (1 − Qmin/Q) · f(I) · f(T)
    %
    % Justificación de la forma multiplicativa:
    %   La guía (§8.3) propone μ = μmax·f(I)·f(N)·f(CO₂)·f(T)·f(pH).
    %   La guía (§8.5) introduce Droop puro μ = μ*_max·(1−Qmin/Q).
    %   Aquí se combinan: Droop reemplaza f(N) y f(CO₂) (la cuota Q ya
    %   integra la disponibilidad interna de carbono), y se multiplican
    %   los factores f(I) y f(T) que son ambientales y externos.
    %   ➤ DECLARADO: este acoplamiento NO está explícito en §8.11;
    %     es decisión propia del modelo.

    p.mu_max_star = 1.1;    % [h⁻¹] Tasa máxima asintótica de Droop.
                            % Fuente: [1] Tabla 1 (mu_max = 1.1 h⁻¹).
                            % La tasa efectiva real ≈ 0.196 h⁻¹ (td ≈ 3.5 h).
                            % NO reinterpretar como día⁻¹.

    p.Qmin = 1.0;          % [mmol C / g biomasa] Cuota mínima de subsistencia.
                            % Estimado de orden de magnitud para Chlorella.
                            % ➤ DECLARADO: sin fuente directa, debe calibrarse.

    p.Q0   = 5.0;          % [mmol C / g biomasa] Cuota interna inicial (arranque).
                            % Se asume Q0 >> Qmin para cultivo en buena condición.

    %% ================================================================
    %  2. ABSORCIÓN DE SUSTRATO — cinética Monod para ρ(S)
    % =================================================================
    p.rho_max = 2.0;       % [mmol C / (g biomasa · h)] Tasa máxima de absorción.
                            % Estimado razonable para Chlorella.
                            % ➤ DECLARADO: ajustar con ensayo propio.

    p.KS = 0.5;            % [mmol/L] Constante de media saturación de sustrato.
                            % Orden de magnitud típico para CO₂ disuelto.

    p.kd = 0.005;          % [h⁻¹] Tasa de decaimiento/respiración.
                            % ➤ DECLARADO: NO reportada en [1]; valor asumido
                            % de literatura general para microalgas.

    %% ================================================================
    %  3. RENDIMIENTO Y SUSTRATO
    % =================================================================
    p.Y = 24.2;            % [g biomasa / mol TIC] Convertido desde Y=1211
                            % (10⁹ cél/mol TIC) de [1], usando conversión:
                            %   1211 × 0.02 = 24.22 g/mol TIC.
                            % Nota: Filali reporta Yr = 4353 ≈ 87.1 g/mol TIC
                            % (3.6× diferente). Se usa Abu-Reesh por consistencia
                            % con el set completo de parámetros (KLa, KE, KCL).

    p.Sin = 5.0;           % [mmol/L] Concentración de sustrato en la alimentación.
                            % Aplica solo en modo continuo (D > 0).
                            % ➤ DECLARADO: valor de arranque.

    p.conversion_biomasa = 0.02;  % [g/L por cada 10⁹ cél/L] (Abu-Reesh Ec. 12)

    %% ================================================================
    %  4. TRANSFERENCIA DE MASA GAS-LÍQUIDO (CO₂) [1][2]
    % =================================================================
    p.KLa = 1.4;           % [h⁻¹] Coeficiente global de transferencia CO₂.
                            % *** PARÁMETRO MÁS SENSIBLE DEL MODELO ***
                            % ±30% en KLa mueve la biomasa en equilibrio ~19-14%
                            % (análisis de sensibilidad de [2]).

    p.H_henry = 29;        % [atm·L/mol] Constante de Henry para CO₂ a 303 K.
    p.T_calibracion_K = 303;  % [K] → ~30 °C.

    %% ================================================================
    %  5. TEMPERATURA — parámetros cardinales para f(T) [4][5]
    % =================================================================
    %   f(T) — modelo cardinal tipo Rosso/CTMI:
    %   ➤ DECLARADO: f(T) NO está definida en ningún documento del curso.
    %   Se elige la forma funcional cardinal (ver f_temperatura.m) y se
    %   justifican los tres parámetros así:
    %
    %   Tmin = 10 °C   — estimado, sin literatura directa. Declarado como
    %                    supuesto conservador (Chlorella tolera hasta ~5°C
    %                    pero con crecimiento despreciable).
    %   Topt = 28 °C   — justificado: Chlorella-específico > mesófilo genérico.
    %                    Kumar et al. [4] reportan 15-26 °C para mesófilas en
    %                    general, pero estudios de Chlorella vulgaris reportan
    %                    Topt hasta 28-30 °C. Se elige 28 °C como valor
    %                    intermedio conservador.
    %   Tmax = 35 °C   — umbral letal dado por la guía (§8.8), restricción
    %                    dura. Coherente con reportes de inhibición marcada
    %                    >30 °C para Chlorella.

    p.Tmin = 10.0;          % [°C]
    p.Topt = 28.0;          % [°C]
    p.Tmax = 35.0;          % [°C] — RESTRICCIÓN DURA (letal)
    p.Tsp  = 26.5;          % [°C] — setpoint de referencia (guía §8.8)

    %% ================================================================
    %  6. LUZ — modelo de Steele (§8.4)
    % =================================================================
    %   f(I) = (I/Iopt) · exp(1 − I/Iopt)
    %   "Más fácil de calibrar porque Iopt se lee directo de la curva"

    p.Iopt = 200;          % [µmol fotón m⁻² s⁻¹] Irradiancia óptima.
                            % Valor representativo para Chlorella en
                            % reactor de pared delgada.

    %% ================================================================
    %  7. PARÁMETROS TÉRMICOS DEL REACTOR (§14.6)
    % =================================================================
    % Balance térmico:
    %   (ρVcp + Cmasa)·dT/dt = αs·As·G + Q̇_LED + Q̇_met
    %                         − U(s)·As·(T−T∞) − ṁev·hfg − Q̇_Pelt

    % --- Reactor ---
    p.rho_agua  = 998;      % [kg/m³] Densidad del agua (~cultivo diluido)
    p.V         = 2.0e-3;   % [m³] = 2 L — volumen del reactor
    p.cp        = 4186;     % [J/(kg·K)] Calor específico del agua
    p.As        = 0.04;     % [m²] Área de superficie del reactor
    p.Asup      = 0.01;     % [m²] Área de superficie libre (evaporación)

    % --- Capacidad térmica total ---
    p.rhoVcp = p.rho_agua * p.V * p.cp;   % [J/K] ≈ 8.37 kJ/K para 2 L
    p.Cmasa  = 500;         % [J/K] Capacidad térmica de la camisa de agua.
                            % ➤ DECLARADO: estimado (masa agua camisa × cp).
                            % Calibrar experimentalmente (paso 5 del plan).

    % --- Coeficientes de transferencia de calor ---
    % U(s) = [1/hint + epar/kpar + s·eais/kais + 1/hext]⁻¹
    p.hint  = 500;          % [W/(m²·K)] Convección interna (cultivo agitado)
    p.hext  = 10;           % [W/(m²·K)] Convección externa (aire natural)
    p.epar  = 3e-3;         % [m] Espesor de la pared del reactor
    p.kpar  = 1.0;          % [W/(m·K)] Conductividad de la pared (acrílico)
    p.eais  = 10e-3;        % [m] Espesor del aislamiento
    p.kais  = 0.04;         % [W/(m·K)] Conductividad del aislante (espuma)

    % Calcular U(0) y U(1) analíticamente
    R_base = 1/p.hint + p.epar/p.kpar + 1/p.hext;
    R_ais  = p.eais / p.kais;
    p.U0 = 1 / R_base;             % [W/(m²·K)] camisa abierta (s=0)
    p.U1 = 1 / (R_base + R_ais);   % [W/(m²·K)] camisa cerrada (s=1)

    % Constantes de tiempo térmicas
    Ctotal = p.rhoVcp + p.Cmasa;
    p.tauT0 = Ctotal / (p.U0 * p.As);  % [s] camisa abierta
    p.tauT1 = Ctotal / (p.U1 * p.As);  % [s] camisa cerrada
    p.ratio_tau = p.tauT1 / p.tauT0;   % Métrica de eficacia del aislamiento

    % --- Ganancias térmicas ---
    p.alpha_s = 0.3;        % [-] Absortividad solar de la superficie del reactor
    p.Qmet_coeff = 0.5;     % [W/(g/L)] Calor metabólico por unidad de biomasa
    p.QLED = 2.0;           % [W] Calor disipado por LEDs de iluminación

    % --- Evaporación (modelo de Dalton simplificado) ---
    p.kev  = 1.5e-8;        % [kg/(m²·s·Pa)] Coeficiente de evaporación
    p.hfg  = 2.26e6;        % [J/kg] Entalpía de vaporización del agua
    p.phi  = 0.60;          % [-] Humedad relativa del ambiente

    % --- Módulo Peltier (§14.6) ---
    %   Q̇_Pelt = αTE·Ie·Tc − ½·Ie²·RTE − KTE·ΔT
    %   ⚠ Existe una corriente óptima: "más corriente no es más frío"
    p.alpha_TE = 0.05;      % [V/K] Coeficiente Seebeck del Peltier
    p.RTE      = 2.0;       % [Ω] Resistencia eléctrica del módulo
    p.KTE      = 0.5;       % [W/K] Conductancia térmica del módulo
    p.Ie_max   = 4.0;       % [A] Corriente máxima del Peltier

    % Corriente óptima (derivada de Q̇_Pelt respecto a Ie, igualada a cero):
    %   dQ̇/dIe = αTE·Tc − Ie·RTE = 0 → Ie_opt = αTE·Tc / RTE
    %   Usando Tc ≈ Tsp + 273.15 K:
    Tc_ref = p.Tsp + 273.15;
    p.Ie_opt = p.alpha_TE * Tc_ref / p.RTE;  % [A] ~7.5 A teórico, 
                                               % pero limitado por Ie_max

    %% ================================================================
    %  8. AMBIENTE / PERTURBACIONES
    % =================================================================
    p.Tamb = 30.0;          % [°C] Temperatura ambiente nominal (clima Caribe)
    p.G_max = 800;          % [W/m²] Irradiancia solar máxima (mediodía)
    p.I_LED = 150;          % [µmol fotón m⁻² s⁻¹] Intensidad de LEDs

    %% ================================================================
    %  9. OPERACIÓN
    % =================================================================
    p.D = 0.0;              % [h⁻¹] Tasa de dilución (0 = modo batch)
    p.X0 = 0.5;             % [g/L] Biomasa inicial
    p.S0 = 4.0;             % [mmol/L] Sustrato inicial
    p.T0 = 28.0;            % [°C] Temperatura inicial del cultivo

    %% ================================================================
    %  10. CONTROL
    % =================================================================
    % Supervisor — histéresis para conmutación de camisa
    p.Delta_T = 1.0;        % [°C] Banda de histéresis del supervisor

    % PID — ganancias iniciales (para s=0, camisa abierta)
    % Se ajustan por gain scheduling al conmutar s.
    p.Kp_s0 = 2.0;          % Ganancia proporcional (camisa abierta)
    p.Ki_s0 = 0.3;          % Ganancia integral
    p.Kd_s0 = 0.5;          % Ganancia derivativa

    % Gain scheduling: factor de escala al cerrar camisa
    % Como τT(1) > τT(0), el sistema es más lento → reducir ganancias
    p.gain_factor_s1 = p.tauT0 / p.tauT1;  % < 1

    % Feedforward de irradiancia
    p.Kff = 0.005;          % [A·m²/W] Ganancia feedforward

    %% ================================================================
    %  IMPRESIÓN DE RESUMEN
    % =================================================================
    fprintf('=== PARÁMETROS DEL MODELO ===\n');
    fprintf('  μ*_max = %.2f h⁻¹\n', p.mu_max_star);
    fprintf('  Qmin   = %.1f mmol/g\n', p.Qmin);
    fprintf('  KS     = %.2f mmol/L\n', p.KS);
    fprintf('  kd     = %.4f h⁻¹\n', p.kd);
    fprintf('  Y      = %.1f g/mol TIC\n', p.Y);
    fprintf('  KLa    = %.1f h⁻¹ (*** más sensible ***)\n', p.KLa);
    fprintf('  Tmin/Topt/Tmax = %.0f/%.0f/%.0f °C\n', p.Tmin, p.Topt, p.Tmax);
    fprintf('  Tsp    = %.1f °C\n', p.Tsp);
    fprintf('  U(s=0) = %.2f W/(m²·K)\n', p.U0);
    fprintf('  U(s=1) = %.2f W/(m²·K)\n', p.U1);
    fprintf('  τT(s=0) = %.1f s = %.2f h\n', p.tauT0, p.tauT0/3600);
    fprintf('  τT(s=1) = %.1f s = %.2f h\n', p.tauT1, p.tauT1/3600);
    fprintf('  τT(1)/τT(0) = %.2f (eficacia aislamiento)\n', p.ratio_tau);
    fprintf('  Ie_óptima = %.2f A (limitada a %.1f A)\n', p.Ie_opt, p.Ie_max);
    fprintf('==============================\n');
end
