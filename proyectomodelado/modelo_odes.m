function dxdt = modelo_odes(t, x, p, s, Ie, G_actual, I_actual)
% MODELO_ODES  Sistema de 4 ODEs del biorreactor con control térmico.
%
%   dxdt = modelo_odes(t, x, p, s, Ie, G_actual, I_actual)
%
%   Vector de estados x = [X; S; Q; T]:
%     X — Biomasa [g/L]
%     S — Sustrato de carbono externo (TIC/CO₂ disuelto) [mmol/L]
%     Q — Cuota interna de carbono (Droop) [mmol C / g biomasa]
%     T — Temperatura del cultivo [°C]
%
%   Estado discreto (externo):
%     s — Estado de la camisa aislante {0 = abierta, 1 = cerrada}
%
%   Entradas de control (externas):
%     Ie       — Corriente del Peltier [A]
%     G_actual — Irradiancia solar [W/m²]
%     I_actual — Irradiancia PAR para fotosíntesis [µmol fotón m⁻² s⁻¹]
%
%   Parámetros:
%     p — Estructura de parámetros (ver parametros_modelo.m)

    %% Desempaquetar estados
    X = x(1);
    S = x(2);
    Q = x(3);
    T = x(4);
    
    % Protección numérica: evitar valores negativos
    X = max(X, 1e-10);
    S = max(S, 0);
    Q = max(Q, p.Qmin + 1e-6);
    
    %% ================================================================
    %  SUBMÓDULO BIOLÓGICO (X, S, Q)
    % =================================================================
    
    % --- Tasa de crecimiento μ(Q, I, T) ---
    % Acoplamiento multiplicativo: Droop × Steele × Cardinal
    % ➤ DECLARADO: este acoplamiento es decisión propia (ver §2.3 de la guía)
    
    mu_droop = p.mu_max_star * (1 - p.Qmin / Q);  % Droop (§8.5)
    fI = f_luz_steele(I_actual, p.Iopt);           % Steele (§8.4)
    fT = f_temperatura(T, p.Tmin, p.Topt, p.Tmax); % Cardinal (CTMI)
    
    mu = mu_droop * fI * fT;  % [h⁻¹] tasa de crecimiento efectiva
    
    % --- Tasa de absorción de sustrato ρ(S) ---
    rho = p.rho_max * S / (p.KS + S);  % [mmol/(g·h)] cinética Monod
    
    % --- dX/dt: Balance de biomasa (§8.2) ---
    %   dX/dt = μ·X − D·X − kd·X
    dXdt = mu * X - p.D * X - p.kd * X;
    
    % --- dS/dt: Balance de sustrato ---
    %   ➤ VACÍO DECLARADO: esta ecuación NO aparece en el sistema consolidado
    %   de §8.11 de la guía. Fue reconstruida a partir del balance de masa
    %   estándar para sustrato limitante:
    %     dS/dt = D·(Sin − S) − ρ(S)·X
    %   En modo batch (D=0): dS/dt = −ρ(S)·X
    dSdt = p.D * (p.Sin - S) - rho * X;
    
    % --- dQ/dt: Cuota interna Droop (§8.5) ---
    %   dQ/dt = ρ(S) − μ(Q)·Q
    %   La cuota aumenta por absorción y disminuye por dilución del
    %   crecimiento (el carbono interno se "reparte" entre células hijas).
    dQdt = rho - mu * Q;
    
    %% ================================================================
    %  SUBMÓDULO TÉRMICO (T) — §14.6
    % =================================================================
    
    % --- Coeficiente de transferencia según estado de camisa ---
    if s == 0
        U = p.U0;   % Camisa abierta
    else
        U = p.U1;   % Camisa cerrada (con aislamiento)
    end
    
    % --- Ganancias de calor ---
    
    % Absorción solar: αs · As · G(t)
    Q_solar = p.alpha_s * p.As * G_actual;  % [W]
    
    % Calor de LEDs (constante mientras estén encendidos)
    Q_LED = p.QLED;  % [W]
    
    % Calor metabólico (proporcional a biomasa activa)
    Q_met = p.Qmet_coeff * X * p.V * 1000;  % [W] (X en g/L, V en m³)
    % Factor 1000: g/L × m³ = g/L × 1000L = g → escala a W
    
    % --- Pérdidas de calor ---
    
    % Convección/conducción a través de las paredes:
    Q_pared = U * p.As * (T - p.Tamb);  % [W]
    
    % Evaporación (Dalton simplificada):
    %   ṁev = kev · Asup · (psat(T) − φ·psat(T∞))
    dp_vapor = psat_agua(T) - p.phi * psat_agua(p.Tamb);
    dp_vapor = max(dp_vapor, 0);  % No condensación en este modelo
    m_ev = p.kev * p.Asup * dp_vapor;  % [kg/s]
    Q_evap = m_ev * p.hfg;  % [W]
    
    % --- Módulo Peltier (§14.6) ---
    %   Q̇_Pelt = αTE·Ie·Tc − ½·Ie²·RTE − KTE·ΔT
    %   Tc = temperatura del lado frío ≈ T del cultivo [K]
    %   ΔT = T_caliente − T_frío ≈ T − Tamb (simplificación)
    %
    %   ⚠ Signo del término cuadrático: el efecto Joule ½Ie²RTE REDUCE
    %   la capacidad de enfriamiento. Existe una corriente óptima:
    %   Ie_opt = αTE·Tc / RTE. Más allá de esta, "más corriente no es más frío".
    
    Tc_K = T + 273.15;  % [K] lado frío (cultivo)
    deltaT_pelt = T - p.Tamb;  % [K] diferencia lado frío − caliente
    
    Q_pelt = p.alpha_TE * Ie * Tc_K ...
           - 0.5 * Ie^2 * p.RTE ...
           - p.KTE * deltaT_pelt;  % [W]
    Q_pelt = max(Q_pelt, 0);  % El Peltier no calienta en este contexto
    
    % --- dT/dt: Balance térmico ---
    %   (ρVcp + Cmasa) · dT/dt = Q_solar + Q_LED + Q_met
    %                           − Q_pared − Q_evap − Q_pelt
    
    Ctotal = p.rhoVcp + p.Cmasa;
    
    dTdt_en_Cs = (Q_solar + Q_LED + Q_met ...
                  - Q_pared - Q_evap - Q_pelt) / Ctotal;  % [°C/s]
    
    % Convertir a °C/h para consistencia con las ODEs biológicas
    dTdt = dTdt_en_Cs * 3600;  % [°C/h]
    
    %% Vector de derivadas
    dxdt = [dXdt; dSdt; dQdt; dTdt];
end
