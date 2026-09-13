function [t_out, x_out, logs] = simular_sistema(t_span, x0, p, varargin)
% SIMULAR_SISTEMA  Integración numérica del biorreactor con control.
%
%   [t_out, x_out, logs] = simular_sistema(t_span, x0, p, Name, Value)
%
%   Modos de operación:
%     'lazo_abierto'    — Sin control, s e Ie fijos
%     'control_completo' — Supervisor + PID + Feedforward
%
%   Argumentos nombre-valor:
%     'modo'    — 'lazo_abierto' | 'control_completo' (default: 'control_completo')
%     's_fijo'  — Estado fijo de camisa para lazo abierto (default: 0)
%     'Ie_fijo' — Corriente fija del Peltier para lazo abierto (default: 0)
%
%   Integración: Euler mejorado (Heun) con paso fijo.
%   Justificación: paso dt = 0.01 h (36 s) captura bien la dinámica
%   térmica (τT ~ orden de horas) y permite lógica de control discreta
%   sin overhead de eventos de ode45.
%
%   Salidas:
%     t_out — Vector de tiempo [h]
%     x_out — Matriz N×4 de estados [X, S, Q, T]
%     logs  — Estructura con registros del control

    %% Parsear argumentos
    ip = inputParser;
    addParameter(ip, 'modo', 'control_completo', @ischar);
    addParameter(ip, 's_fijo', 0, @isnumeric);
    addParameter(ip, 'Ie_fijo', 0, @isnumeric);
    parse(ip, varargin{:});
    
    modo = ip.Results.modo;
    s_fijo = ip.Results.s_fijo;
    Ie_fijo = ip.Results.Ie_fijo;
    
    %% Inicializar
    N = length(t_span);
    dt = t_span(2) - t_span(1);
    
    x_out = zeros(N, 4);
    x_out(1, :) = x0';
    
    % Logs de control
    logs.s_log  = zeros(N, 1);  % Estado de camisa
    logs.Ie_log = zeros(N, 1);  % Corriente Peltier
    logs.G_log  = zeros(N, 1);  % Irradiancia
    logs.I_log  = zeros(N, 1);  % Irradiancia PAR
    logs.mu_log = zeros(N, 1);  % Tasa de crecimiento
    logs.Qpelt_log = zeros(N, 1);  % Calor Peltier
    logs.error_log = zeros(N, 1);  % Error de temperatura
    
    % Estado del PID
    integral_error = 0;
    error_prev = 0;
    
    % Estado del supervisor (con histéresis)
    s = 0;  % Camisa inicialmente abierta
    
    %% Bucle de integración (Euler mejorado / Heun)
    for k = 1:N-1
        t = t_span(k);
        x = x_out(k, :)';
        T_actual = x(4);
        
        % --- Perfil de irradiancia solar ---
        G = perfil_irradiancia(t, p.G_max);
        
        % --- Irradiancia PAR para fotosíntesis ---
        % Combinar luz solar (convertida a PAR) + LEDs
        % Factor de conversión solar→PAR ≈ 4.6 µmol/(W·s) × fracción PAR ≈ 2.1
        hora = mod(t, 24);
        if hora >= 6 && hora <= 18
            I_par = G * 2.1 + p.I_LED;  % Día: solar + LEDs
        else
            I_par = p.I_LED;             % Noche: solo LEDs
        end
        
        % --- Determinar s e Ie según modo ---
        switch modo
            case 'lazo_abierto'
                s = s_fijo;
                Ie = Ie_fijo;
                
            case 'control_completo'
                % ═══════════════════════════════════════════════════
                %  SUPERVISOR (máquina de estados con histéresis)
                % ═══════════════════════════════════════════════════
                %   s = 1 (cerrar) si T < Tsp − Δ  o  es de noche
                %   s = 0 (abrir)  si T > Tsp + Δ  y  hay irradiancia
                
                es_noche = (hora < 6) || (hora > 18);
                
                if T_actual < (p.Tsp - p.Delta_T) || es_noche
                    s = 1;  % Cerrar camisa (aislar, retener calor)
                elseif T_actual > (p.Tsp + p.Delta_T) && ~es_noche
                    s = 0;  % Abrir camisa (disipar calor)
                end
                % Si está en la banda muerta, mantiene el estado anterior
                
                % ═══════════════════════════════════════════════════
                %  LAZO PID con gain scheduling
                % ═══════════════════════════════════════════════════
                
                error_T = T_actual - p.Tsp;  % Error positivo = demasiado caliente
                
                % Gain scheduling según estado de camisa
                if s == 0
                    Kp = p.Kp_s0;
                    Ki = p.Ki_s0;
                    Kd = p.Kd_s0;
                else
                    % Camisa cerrada: sistema más lento → reducir ganancias
                    Kp = p.Kp_s0 * p.gain_factor_s1;
                    Ki = p.Ki_s0 * p.gain_factor_s1;
                    Kd = p.Kd_s0 * p.gain_factor_s1;
                end
                
                % PID discreto
                integral_error = integral_error + error_T * dt;
                
                % Anti-windup: limitar integral
                integral_error = max(-10, min(10, integral_error));
                
                derivada_error = (error_T - error_prev) / dt;
                error_prev = error_T;
                
                u_pid = Kp * error_T + Ki * integral_error + Kd * derivada_error;
                
                % ═══════════════════════════════════════════════════
                %  FEEDFORWARD de irradiancia
                % ═══════════════════════════════════════════════════
                u_ff = p.Kff * G;
                
                % Señal de control total
                Ie = u_pid + u_ff;
                
                % ═══════════════════════════════════════════════════
                %  SATURACIÓN DEL PELTIER
                % ═══════════════════════════════════════════════════
                % ⚠ Limitar a [0, Ie_max]. El Peltier solo enfría (Ie ≥ 0).
                % Además, más allá de Ie_opt la eficiencia cae (término
                % cuadrático −½Ie²RTE domina). Aún así permitimos hasta
                % Ie_max para no limitar artificialmente — el modelo físico
                % ya captura la pérdida de eficiencia.
                Ie = max(0, min(p.Ie_max, Ie));
                
            otherwise
                error('Modo no reconocido: %s', modo);
        end
        
        % --- Registrar logs ---
        logs.s_log(k)  = s;
        logs.Ie_log(k) = Ie;
        logs.G_log(k)  = G;
        logs.I_log(k)  = I_par;
        logs.error_log(k) = T_actual - p.Tsp;
        
        % --- Integración: método de Heun (Euler mejorado) ---
        % Paso predictor (Euler adelante)
        k1 = modelo_odes(t, x, p, s, Ie, G, I_par);
        x_pred = x + dt * k1;
        
        % Paso corrector (promedio de pendientes)
        k2 = modelo_odes(t + dt, x_pred, p, s, Ie, ...
            perfil_irradiancia(t + dt, p.G_max), I_par);
        x_new = x + 0.5 * dt * (k1 + k2);
        
        % Protección: no permitir estados negativos
        x_new(1) = max(x_new(1), 0);     % X ≥ 0
        x_new(2) = max(x_new(2), 0);     % S ≥ 0
        x_new(3) = max(x_new(3), p.Qmin); % Q ≥ Qmin
        
        x_out(k+1, :) = x_new';
    end
    
    % Registrar último punto
    logs.s_log(N)  = s;
    logs.Ie_log(N) = Ie;
    logs.G_log(N)  = perfil_irradiancia(t_span(N), p.G_max);
    logs.I_log(N)  = I_par;
    logs.error_log(N) = x_out(N, 4) - p.Tsp;
    
    t_out = t_span(:);
end
