function [t_out, x_out, logs] = simular_refinado(t_span, x0, p, opts)
% SIMULAR_REFINADO  Motor de simulación con 3 refinamientos opcionales.
%
%   [t_out, x_out, logs] = simular_refinado(t_span, x0, p, opts)
%
%   Refinamientos controlados por opts:
%     opts.Qmet_refinado   — (bool) Q_met ∝ (μ·X + kd·X) en vez de ∝ X
%     opts.dVdt_activo     — (bool) Dinámica de volumen por evaporación (5ª ODE)
%     opts.puente_termico  — (bool) Conducción bidireccional del Peltier
%
%   Si opts.dVdt_activo = true:
%     x0 debe tener 5 elementos: [X0; S0; Q0; T0; V0]
%     x_out tendrá 5 columnas
%
%   Integración: Euler mejorado (Heun) con paso fijo.
%   Control: Supervisor + PID con gain scheduling + feedforward.
%
%   Diferencias respecto a simular_sistema.m:
%     1. Registra flujos de calor individuales (para dashboard)
%     2. Signo CORREGIDO del término KTE en el modelo Peltier
%     3. Soporta las 3 opciones de refinamiento

    %% ================================================================
    %  VALORES POR DEFECTO
    % =================================================================
    if nargin < 4, opts = struct(); end
    if ~isfield(opts, 'Qmet_refinado'),  opts.Qmet_refinado  = false; end
    if ~isfield(opts, 'dVdt_activo'),    opts.dVdt_activo    = false; end
    if ~isfield(opts, 'puente_termico'), opts.puente_termico = false; end

    %% ================================================================
    %  COEFICIENTES DEL Q_MET REFINADO
    % =================================================================
    %   Q_met_refinado = (Y_Q · μ + m_Q) · X · V_litros  [W]
    %
    %   Y_Q = 3.0 [W·h/g]  — calor asociado al crecimiento
    %   m_Q = 0.2 [W/(g/L)] — calor de mantenimiento basal
    %
    %   Calibración: a μ = 0.1 h⁻¹ nominal:
    %     Y_Q·0.1 + m_Q = 3.0·0.1 + 0.2 = 0.5 W/(g/L)
    %     ≡ Qmet_coeff original (0.5)  ✓ Coinciden en el punto nominal
    Y_Q = 3.0;
    m_Q = 0.2;

    %% ================================================================
    %  INICIALIZACIÓN
    % =================================================================
    N  = length(t_span);
    dt = t_span(2) - t_span(1);

    n_states = 4;
    if opts.dVdt_activo, n_states = 5; end

    x_out = zeros(N, n_states);
    x_out(1, :) = x0(1:n_states)';

    % --- Logs de control y flujos de calor ---
    logs.s_log       = zeros(N, 1);
    logs.Ie_log      = zeros(N, 1);
    logs.G_log       = zeros(N, 1);
    logs.mu_log      = zeros(N, 1);
    logs.error_log   = zeros(N, 1);
    logs.V_log       = zeros(N, 1);
    % Flujos de calor individuales [W]
    logs.Q_solar_log = zeros(N, 1);
    logs.Q_LED_log   = zeros(N, 1);
    logs.Q_met_log   = zeros(N, 1);
    logs.Q_pared_log = zeros(N, 1);
    logs.Q_evap_log  = zeros(N, 1);
    logs.Q_pelt_log  = zeros(N, 1);

    % Estado del PID
    integral_err = 0;
    error_prev   = 0;

    % Estado del supervisor
    s = 0;  % Camisa inicialmente abierta

    %% ================================================================
    %  BUCLE PRINCIPAL — Heun con lógica de control
    % =================================================================
    for k = 1:N-1
        t = t_span(k);

        % --- Desempaquetar estados ---
        X = max(x_out(k, 1), 1e-10);
        S = max(x_out(k, 2), 0);
        Q = max(x_out(k, 3), p.Qmin + 1e-6);
        T = x_out(k, 4);
        if opts.dVdt_activo
            V_act = max(x_out(k, 5), 0.1 * p.V);
        else
            V_act = p.V;
        end

        % --- Irradiancia y PAR ---
        G    = perfil_irradiancia(t, p.G_max);
        hora = mod(t, 24);
        if hora >= 6 && hora <= 18
            I_par = G * 2.1 + p.I_LED;
        else
            I_par = p.I_LED;
        end

        % --- Tasas biológicas ---
        mu_droop = p.mu_max_star * (1 - p.Qmin / Q);
        fI       = f_luz_steele(I_par, p.Iopt);
        fT       = f_temperatura(T, p.Tmin, p.Topt, p.Tmax);
        mu       = mu_droop * fI * fT;
        rho_s    = p.rho_max * S / (p.KS + S);

        % =============================================================
        %  SUPERVISOR (máquina de estados con histéresis)
        % =============================================================
        es_noche = (hora < 6) || (hora > 18);
        if T < (p.Tsp - p.Delta_T) || es_noche
            s = 1;   % Cerrar camisa
        elseif T > (p.Tsp + p.Delta_T) && ~es_noche
            s = 0;   % Abrir camisa
        end

        % =============================================================
        %  PID con gain scheduling + feedforward
        % =============================================================
        error_T = T - p.Tsp;

        if s == 0
            Kp = p.Kp_s0;  Ki = p.Ki_s0;  Kd = p.Kd_s0;
        else
            Kp = p.Kp_s0 * p.gain_factor_s1;
            Ki = p.Ki_s0 * p.gain_factor_s1;
            Kd = p.Kd_s0 * p.gain_factor_s1;
        end

        integral_err = integral_err + error_T * dt;
        integral_err = max(-10, min(10, integral_err));   % Anti-windup
        deriv_err    = (error_T - error_prev) / dt;
        error_prev   = error_T;

        u_pid = Kp * error_T + Ki * integral_err + Kd * deriv_err;
        u_ff  = p.Kff * G;
        Ie    = max(0, min(p.Ie_max, u_pid + u_ff));

        % =============================================================
        %  FLUJOS DE CALOR
        % =============================================================
        U = (1 - s) * p.U0 + s * p.U1;

        Q_solar = p.alpha_s * p.As * G;
        Q_LED   = p.QLED;

        % --- Q_met: original o refinado ---
        V_litros = V_act * 1000;   % m³ → L
        if opts.Qmet_refinado
            %   Q_met = (Y_Q·μ + m_Q) · X · V_litros  [W]
            Q_met = (Y_Q * mu + m_Q) * X * V_litros;
        else
            Q_met = p.Qmet_coeff * X * V_litros;
        end

        Q_pared = U * p.As * (T - p.Tamb);

        % Evaporación (Dalton)
        dp_vap = max(0, psat_agua(T) - p.phi * psat_agua(p.Tamb));
        m_ev   = p.kev * p.Asup * dp_vap;
        Q_evap = m_ev * p.hfg;

        % --- Peltier (signo CORREGIDO) ---
        %   Descomposición en término activo y conducción pasiva:
        %
        %   Q_activo    = αTE·Ie·Tc − ½Ie²·RTE   (Seebeck − Joule)
        %   Q_conducción = KTE·(T − Tamb)          (positivo = calor SALE)
        %
        %   Convención de signo estándar (Rowe, 2006):
        %     Q_c = α·I·Tc − ½I²R − K·(Th−Tc)
        %   con Th=Tamb, Tc=T → −K·(Tamb−T) = +K·(T−Tamb)
        Tc_K         = T + 273.15;
        Q_pelt_activo = p.alpha_TE * Ie * Tc_K - 0.5 * Ie^2 * p.RTE;
        Q_conduccion  = p.KTE * (T - p.Tamb);

        if opts.puente_termico
            % Bidireccional: Q_pelt puede ser negativo (calor entra al cultivo)
            Q_pelt = Q_pelt_activo + Q_conduccion;
        else
            % Original: solo enfriamiento neto
            Q_pelt = max(Q_pelt_activo + Q_conduccion, 0);
        end

        % =============================================================
        %  REGISTRAR LOGS
        % =============================================================
        logs.s_log(k)       = s;
        logs.Ie_log(k)      = Ie;
        logs.G_log(k)       = G;
        logs.mu_log(k)      = mu;
        logs.error_log(k)   = error_T;
        logs.V_log(k)       = V_act;
        logs.Q_solar_log(k) = Q_solar;
        logs.Q_LED_log(k)   = Q_LED;
        logs.Q_met_log(k)   = Q_met;
        logs.Q_pared_log(k) = Q_pared;
        logs.Q_evap_log(k)  = Q_evap;
        logs.Q_pelt_log(k)  = Q_pelt;

        % =============================================================
        %  HEUN — paso predictor
        % =============================================================
        k1 = computar_derivadas(t, X, S, Q, T, V_act, ...
                mu, rho_s, m_ev, G, Q_solar, Q_LED, Q_met, ...
                Q_pared, Q_evap, Q_pelt, p, opts);

        x_pred = x_out(k, :)' + dt * k1;

        % Clamp predictor
        x_pred(1) = max(x_pred(1), 1e-10);
        x_pred(2) = max(x_pred(2), 0);
        x_pred(3) = max(x_pred(3), p.Qmin + 1e-6);
        if opts.dVdt_activo
            x_pred(5) = max(x_pred(5), 0.1 * p.V);
        end

        % =============================================================
        %  HEUN — paso corrector
        % =============================================================
        % Recomputar tasas en (t+dt, x_pred) con las mismas señales de control
        X2 = x_pred(1);  S2 = x_pred(2);  Q2 = x_pred(3);  T2 = x_pred(4);
        if opts.dVdt_activo, V2 = x_pred(5); else, V2 = p.V; end

        G2    = perfil_irradiancia(t + dt, p.G_max);
        hora2 = mod(t + dt, 24);
        if hora2 >= 6 && hora2 <= 18
            I_par2 = G2 * 2.1 + p.I_LED;
        else
            I_par2 = p.I_LED;
        end

        mu2   = p.mu_max_star * (1 - p.Qmin / Q2) ...
              * f_luz_steele(I_par2, p.Iopt) ...
              * f_temperatura(T2, p.Tmin, p.Topt, p.Tmax);
        rho2  = p.rho_max * S2 / (p.KS + S2);

        V2_L = V2 * 1000;
        if opts.Qmet_refinado
            Qmet2 = (Y_Q * mu2 + m_Q) * X2 * V2_L;
        else
            Qmet2 = p.Qmet_coeff * X2 * V2_L;
        end

        U2       = (1 - s) * p.U0 + s * p.U1;
        Qsol2    = p.alpha_s * p.As * G2;
        Qpar2    = U2 * p.As * (T2 - p.Tamb);
        dpv2     = max(0, psat_agua(T2) - p.phi * psat_agua(p.Tamb));
        mev2     = p.kev * p.Asup * dpv2;
        Qevp2    = mev2 * p.hfg;

        Tc2      = T2 + 273.15;
        Qpa2     = p.alpha_TE * Ie * Tc2 - 0.5 * Ie^2 * p.RTE;
        Qcond2   = p.KTE * (T2 - p.Tamb);
        if opts.puente_termico
            Qpelt2 = Qpa2 + Qcond2;
        else
            Qpelt2 = max(Qpa2 + Qcond2, 0);
        end

        k2 = computar_derivadas(t + dt, X2, S2, Q2, T2, V2, ...
                mu2, rho2, mev2, G2, Qsol2, Q_LED, Qmet2, ...
                Qpar2, Qevp2, Qpelt2, p, opts);

        % =============================================================
        %  HEUN — actualización
        % =============================================================
        x_new = x_out(k, :)' + 0.5 * dt * (k1 + k2);

        % Clamp final
        x_new(1) = max(x_new(1), 0);
        x_new(2) = max(x_new(2), 0);
        x_new(3) = max(x_new(3), p.Qmin);
        if opts.dVdt_activo
            x_new(5) = max(x_new(5), 0.1 * p.V);
        end

        x_out(k+1, :) = x_new';
    end

    %% ================================================================
    %  REGISTRAR ÚLTIMO PUNTO
    % =================================================================
    logs.s_log(N)       = s;
    logs.Ie_log(N)      = Ie;
    logs.G_log(N)       = perfil_irradiancia(t_span(N), p.G_max);
    logs.mu_log(N)      = logs.mu_log(N-1);
    logs.error_log(N)   = x_out(N, 4) - p.Tsp;
    if opts.dVdt_activo
        logs.V_log(N) = x_out(N, 5);
    else
        logs.V_log(N) = p.V;
    end
    logs.Q_solar_log(N) = logs.Q_solar_log(N-1);
    logs.Q_LED_log(N)   = logs.Q_LED_log(N-1);
    logs.Q_met_log(N)   = logs.Q_met_log(N-1);
    logs.Q_pared_log(N) = logs.Q_pared_log(N-1);
    logs.Q_evap_log(N)  = logs.Q_evap_log(N-1);
    logs.Q_pelt_log(N)  = logs.Q_pelt_log(N-1);

    t_out = t_span(:);
end


%% ====================================================================
%  FUNCIÓN LOCAL: computar derivadas del sistema
% =====================================================================
function dxdt = computar_derivadas(~, X, S, Q, T, V, ...
        mu, rho_s, m_ev, ~, Q_solar, Q_LED, Q_met, ...
        Q_pared, Q_evap, Q_pelt, p, opts)
% COMPUTAR_DERIVADAS  Calcula dx/dt para el sistema de 4 ó 5 ODEs.
%
%   Todas las tasas biológicas y flujos térmicos ya están computados
%   externamente — esta función solo ensambla las derivadas.

    % --- ODEs biológicas ---
    dXdt = mu * X - p.D * X - p.kd * X;
    dSdt = p.D * (p.Sin - S) - rho_s * X;
    dQdt = rho_s - mu * Q;

    % --- ODE térmica ---
    %   (ρ·V·cp + Cmasa) · dT/dt = Q_solar + Q_LED + Q_met
    %                              − Q_pared − Q_evap − Q_pelt
    Ctotal = p.rho_agua * V * p.cp + p.Cmasa;
    dTdt = (Q_solar + Q_LED + Q_met - Q_pared - Q_evap - Q_pelt) ...
           / Ctotal * 3600;   % [°C/h]  (flujos en W, tiempo en h)

    % --- Dinámica de volumen (si activa) ---
    if opts.dVdt_activo
        dVdt = -m_ev / p.rho_agua * 3600;   % [m³/h]

        % Efecto de concentración por pérdida de volumen:
        %   N_X = X·V (masa total) → d(X·V)/dt = V·dX/dt + X·dV/dt
        %   → dX/dt corregido = dX/dt_bio − (X/V)·dV/dt
        %   Como dV/dt < 0, el término −(X/V)·dV/dt > 0 → concentra
        dXdt = dXdt - (X / V) * dVdt;
        dSdt = dSdt - (S / V) * dVdt;

        dxdt = [dXdt; dSdt; dQdt; dTdt; dVdt];
    else
        dxdt = [dXdt; dSdt; dQdt; dTdt];
    end
end
