%% =========================================================================
%% CREAR_MODELO_SIMULINK.m
%% Generador Automatizado del Modelo Simulink ALUNA PBR-02 "Aluna Duna"
%% Proyecto: Control II (2026-II) — Universidad del Magdalena
%% =========================================================================

function crear_modelo_simulink()
    fprintf('=================================================================\n');
    fprintf('  GENERANDO MODELO COMPLETO EN SIMULINK: aluna_pbr_simulink.slx\n');
    fprintf('=================================================================\n\n');

    % 1. Inicializar parámetros
    init_simulink_aluna;
    
    % Nombre del modelo
    model_name = 'aluna_pbr_simulink';
    
    % Cerrar si ya está abierto sin guardar cambios no deseados
    if bdIsLoaded(model_name)
        close_system(model_name, 0);
    end
    
    % Eliminar archivo previo si existe en disco
    slx_file = fullfile(pwd, [model_name '.slx']);
    if exist(slx_file, 'file')
        delete(slx_file);
        fprintf('▸ Archivo previo %s eliminado.\n', slx_file);
    end
    
    % Crear nuevo sistema
    new_system(model_name);
    open_system(model_name);
    
    % Configurar Solver y Tiempo de Simulación
    set_param(model_name, 'SolverType', 'Variable-step');
    set_param(model_name, 'Solver', 'ode45');
    set_param(model_name, 'StartTime', '0.0');
    set_param(model_name, 'StopTime', '72.0'); % 72 horas
    set_param(model_name, 'MaxStep', '0.05');
    set_param(model_name, 'SaveTime', 'on');
    set_param(model_name, 'SaveOutput', 'on');
    
    fprintf('▸ Construyendo bloques principales y subsistemas modulares...\n');

    %% =====================================================================
    %% 1. BLOQUE DE ENTORNO AMBIENTAL (Santa Marta)
    %% =====================================================================
    % Genera: G(t) [W/m²], I_par(t) [µmol/m²s], Tamb(t) [°C]
    sub_env = [model_name '/Entorno_Santa_Marta'];
    add_block('simulink/Ports & Subsystems/Subsystem', sub_env, 'Position', [50, 80, 200, 200]);
    
    % Eliminar puertos por defecto dentro del subsistema
    delete_line(sub_env, 'In1/1', 'Out1/1');
    delete_block([sub_env '/In1']);
    delete_block([sub_env '/Out1']);
    
    % Agregar MATLAB Function para perfil ambiental en función del tiempo
    fcn_env = [sub_env '/Generador_Perfiles'];
    add_block('simulink/User-Defined Functions/MATLAB Function', fcn_env, 'Position', [100, 50, 240, 130]);
    
    % Agregar Clock y Outports
    add_block('simulink/Sources/Clock', [sub_env '/Clock'], 'Position', [30, 80, 60, 100]);
    add_block('simulink/Ports & Subsystems/Out1', [sub_env '/G_solar'], 'Position', [320, 50, 350, 65]);
    add_block('simulink/Ports & Subsystems/Out1', [sub_env '/I_par'],   'Position', [320, 80, 350, 95]);
    add_block('simulink/Ports & Subsystems/Out1', [sub_env '/T_amb'],   'Position', [320, 110, 350, 125]);
    
    % Código de la función ambiental
    code_env = sprintf([...
        'function [G_solar, I_par, T_amb] = Generador_Perfiles(t_hours)\n', ...
        '%% Perfil ambiental diario de Santa Marta (ciclo 24h)\n', ...
        'hora = mod(t_hours, 24);\n', ...
        'if hora >= 6 && hora <= 18\n', ...
        '    luz = sin(pi * (hora - 6) / 12);\n', ...
        '    G_solar = 850 * max(0, luz);\n', ...
        '    I_par   = 1000 * max(0, luz);\n', ...
        'else\n', ...
        '    G_solar = 0.0;\n', ...
        '    I_par   = 0.0;\n', ...
        'end\n', ...
        '%% Temperatura ambiente: oscila entre 25°C (noche) y 34°C (mediodía)\n', ...
        'T_amb = 29.5 + 4.5 * sin(2*pi*(hora - 9)/24);\n']);
    
    set_matlab_fcn_code(fcn_env, code_env);
    
    add_line(sub_env, 'Clock/1', 'Generador_Perfiles/1');
    add_line(sub_env, 'Generador_Perfiles/1', 'G_solar/1');
    add_line(sub_env, 'Generador_Perfiles/2', 'I_par/1');
    add_line(sub_env, 'Generador_Perfiles/3', 'T_amb/1');

    %% =====================================================================
    %% 2. CONTROLADOR HÍBRIDO (Camisa + Peltier)
    %% =====================================================================
    sub_ctrl = [model_name '/Controlador_Hibrido'];
    add_block('simulink/Ports & Subsystems/Subsystem', sub_ctrl, 'Position', [320, 80, 480, 200]);
    
    delete_line(sub_ctrl, 'In1/1', 'Out1/1');
    delete_block([sub_ctrl '/In1']);
    delete_block([sub_ctrl '/Out1']);
    
    add_block('simulink/Ports & Subsystems/In1', [sub_ctrl '/T_medida'], 'Position', [30, 50, 60, 65]);
    add_block('simulink/Ports & Subsystems/In1', [sub_ctrl '/T_sp'],     'Position', [30, 85, 60, 100]);
    add_block('simulink/Ports & Subsystems/In1', [sub_ctrl '/T_amb'],    'Position', [30, 120, 60, 135]);
    
    fcn_ctrl = [sub_ctrl '/Logica_Hibrida'];
    add_block('simulink/User-Defined Functions/MATLAB Function', fcn_ctrl, 'Position', [120, 45, 260, 140]);
    
    add_block('simulink/Ports & Subsystems/Out1', [sub_ctrl '/s_camisa'], 'Position', [340, 65, 370, 80]);
    add_block('simulink/Ports & Subsystems/Out1', [sub_ctrl '/Ie_peltier'], 'Position', [340, 105, 370, 120]);
    
    code_ctrl = sprintf([...
        'function [s_camisa, Ie_peltier] = Logica_Hibrida(T_med, T_sp, T_amb)\n', ...
        '%% Lógica de control híbrido bio-inspirado del Frailejón\n', ...
        '%% Transición suave (sigmoide) para eliminar chattering\n', ...
        'e = T_med - T_sp;\n', ...
        '%% 1. Camisa: transición suave con sigmoide empinada\n', ...
        '%%    sigma ≈ 0 (cerrada/aislada) cuando T_med << T_sp+1\n', ...
        '%%    sigma ≈ 1 (abierta/disipa)  cuando T_med >> T_sp+1\n', ...
        'sigma = 1.0 / (1.0 + exp(-5.0 * (e - 1.0)));\n', ...
        '%% Solo abrir camisa si conviene (T_amb < T_med)\n', ...
        'if T_amb < T_med\n', ...
        '    s_camisa = 1.0 - sigma; %% sigma alto -> s=0 (abrir)\n', ...
        'else\n', ...
        '    s_camisa = 1.0; %% Siempre cerrada si afuera hace más calor\n', ...
        'end\n', ...
        '%% 2. Peltier proporcional suave con zona muerta\n', ...
        'if e > 0.5\n', ...
        '    Ie = 1.5 * (e - 0.5);\n', ...
        '    Ie_peltier = min(4.0, max(0.0, Ie));\n', ...
        'else\n', ...
        '    Ie_peltier = 0.0;\n', ...
        'end\n']);
    
    set_matlab_fcn_code(fcn_ctrl, code_ctrl);
    
    add_line(sub_ctrl, 'T_medida/1', 'Logica_Hibrida/1');
    add_line(sub_ctrl, 'T_sp/1',     'Logica_Hibrida/2');
    add_line(sub_ctrl, 'T_amb/1',    'Logica_Hibrida/3');
    add_line(sub_ctrl, 'Logica_Hibrida/1', 's_camisa/1');
    add_line(sub_ctrl, 'Logica_Hibrida/2', 'Ie_peltier/1');

    %% =====================================================================
    %% 3. PLANTA FÍSICA: FOTOBIORREACTOR (4 EDOs ACOPLADAS)
    %% =====================================================================
    sub_plant = [model_name '/Planta_Biorreactor_4EDOs'];
    add_block('simulink/Ports & Subsystems/Subsystem', sub_plant, 'Position', [580, 70, 780, 240]);
    
    delete_line(sub_plant, 'In1/1', 'Out1/1');
    delete_block([sub_plant '/In1']);
    delete_block([sub_plant '/Out1']);
    
    % Inports planta
    add_block('simulink/Ports & Subsystems/In1', [sub_plant '/s_camisa'],   'Position', [30, 40, 60, 55]);
    add_block('simulink/Ports & Subsystems/In1', [sub_plant '/Ie_peltier'], 'Position', [30, 75, 60, 90]);
    add_block('simulink/Ports & Subsystems/In1', [sub_plant '/G_solar'],    'Position', [30, 110, 60, 125]);
    add_block('simulink/Ports & Subsystems/In1', [sub_plant '/I_par'],      'Position', [30, 145, 60, 160]);
    add_block('simulink/Ports & Subsystems/In1', [sub_plant '/T_amb'],      'Position', [30, 180, 60, 195]);
    
    % MATLAB Function de Derivadas dX/dt, dS/dt, dQ/dt, dT/dt
    fcn_plant = [sub_plant '/Ecuaciones_Diferenciales'];
    add_block('simulink/User-Defined Functions/MATLAB Function', fcn_plant, 'Position', [140, 30, 320, 210]);
    
    % 4 Integradores Continuos con Saturación y Condiciones Iniciales
    add_block('simulink/Continuous/Integrator', [sub_plant '/Int_X'], 'Position', [400, 40, 430, 70], ...
        'InitialCondition', '0.5', 'LimitOutput', 'on', 'LowerSaturationLimit', '1e-6');
    add_block('simulink/Continuous/Integrator', [sub_plant '/Int_S'], 'Position', [400, 85, 430, 115], ...
        'InitialCondition', '5.0', 'LimitOutput', 'on', 'LowerSaturationLimit', '0.0');
    add_block('simulink/Continuous/Integrator', [sub_plant '/Int_Q'], 'Position', [400, 130, 430, 160], ...
        'InitialCondition', '5.0', 'LimitOutput', 'on', 'LowerSaturationLimit', '1.0');
    add_block('simulink/Continuous/Integrator', [sub_plant '/Int_T'], 'Position', [400, 175, 430, 205], ...
        'InitialCondition', '28.0', 'LimitOutput', 'on', 'LowerSaturationLimit', '5.0', 'UpperSaturationLimit', '50.0');
    
    % Outports planta
    add_block('simulink/Ports & Subsystems/Out1', [sub_plant '/X_biomasa'], 'Position', [500, 45, 530, 60]);
    add_block('simulink/Ports & Subsystems/Out1', [sub_plant '/S_sustrato'],'Position', [500, 90, 530, 105]);
    add_block('simulink/Ports & Subsystems/Out1', [sub_plant '/Q_cuota'],   'Position', [500, 135, 530, 150]);
    add_block('simulink/Ports & Subsystems/Out1', [sub_plant '/T_cultivo'], 'Position', [500, 180, 530, 195]);
    
    code_plant = sprintf([...
        'function [dXdt, dSdt, dQdt, dTdt] = Ecuaciones_Diferenciales(s, Ie, G, I, Tamb, X, S, Q, T)\n', ...
        '%% Parámetros biológicos base\n', ...
        'mu_max = 1.1; Qmin = 1.0; Iopt = 200.0; Tmin = 10.0; Topt = 28.0; Tmax = 35.0;\n', ...
        'rho_max = 2.0; KS = 0.5; kd = 0.005; D = 0.0; Sin = 5.0;\n', ...
        '%% 1. Factores de Crecimiento\n', ...
        'fI = (I / Iopt) * exp(1 - I / Iopt);\n', ...
        'if T > Tmin && T < Tmax\n', ...
        '    num = (T - Tmax) * (T - Tmin)^2;\n', ...
        '    den = (Topt - Tmin) * ((Topt - Tmin)*(T - Topt) - (Topt - Tmax)*(Topt + Tmin - 2*T));\n', ...
        '    fT = max(0.0, min(1.0, num / den));\n', ...
        'else\n', ...
        '    fT = 0.0;\n', ...
        'end\n', ...
        'mu = mu_max * (1 - Qmin / max(Q, 1.001)) * fI * fT;\n', ...
        'rho = rho_max * S / (KS + S);\n', ...
        '%% 2. Derivadas biológicas\n', ...
        'dXdt = (mu - D - kd) * X;\n', ...
        'dSdt = D * (Sin - S) - rho * X;\n', ...
        'dQdt = rho - mu * Q;\n', ...
        '%% 3. Balance térmico\n', ...
        'C_tot = 8870.0; %% [J/K] = rho*V*cp + Cmasa = 998*0.002*4186 + 500\n', ...
        'A_exp = 0.04; alpha_s = 0.30;\n', ...
        'Q_solar = alpha_s * A_exp * G;\n', ...
        'Q_led = 2.0;\n', ...
        'Q_met = 0.5 * X * 2.0; %% [W] = Qmet_coeff * X * V * 1000\n', ...
        '%% Coeficiente U segun estado de camisa (valores de parametros_modelo)\n', ...
        'U = (s == 0)*9.35 + (s == 1)*3.56;\n', ...
        'Q_pared = U * 0.04 * (T - Tamb);\n', ...
        '%% Evaporación (Dalton simplificada)\n', ...
        'psat_T = 610.78 * exp(17.27 * T / (T + 237.3));\n', ...
        'psat_A = 610.78 * exp(17.27 * Tamb / (Tamb + 237.3));\n', ...
        'dp = max(0.0, psat_T - 0.6 * psat_A);\n', ...
        'Q_evap = 1.5e-8 * 0.01 * dp * 2.26e6;\n', ...
        '%% Peltier TEC1-12706\n', ...
        'Q_peltier = 0.05 * (T + 273.15) * Ie - 0.5 * 2.0 * Ie^2 - 0.5 * (T - Tamb);\n', ...
        'Q_peltier = max(0.0, Q_peltier);\n', ...
        'dTdt = (Q_solar + Q_led + Q_met - Q_pared - Q_evap - Q_peltier) * 3600.0 / C_tot;\n']);
    
    set_matlab_fcn_code(fcn_plant, code_plant);
    
    % Conectar inports a la función
    add_line(sub_plant, 's_camisa/1',   'Ecuaciones_Diferenciales/1');
    add_line(sub_plant, 'Ie_peltier/1', 'Ecuaciones_Diferenciales/2');
    add_line(sub_plant, 'G_solar/1',    'Ecuaciones_Diferenciales/3');
    add_line(sub_plant, 'I_par/1',      'Ecuaciones_Diferenciales/4');
    add_line(sub_plant, 'T_amb/1',      'Ecuaciones_Diferenciales/5');
    
    % Conectar derivadas a integradores y retroalimentación de estados
    add_line(sub_plant, 'Ecuaciones_Diferenciales/1', 'Int_X/1');
    add_line(sub_plant, 'Ecuaciones_Diferenciales/2', 'Int_S/1');
    add_line(sub_plant, 'Ecuaciones_Diferenciales/3', 'Int_Q/1');
    add_line(sub_plant, 'Ecuaciones_Diferenciales/4', 'Int_T/1');
    
    add_line(sub_plant, 'Int_X/1', 'X_biomasa/1');
    add_line(sub_plant, 'Int_S/1', 'S_sustrato/1');
    add_line(sub_plant, 'Int_Q/1', 'Q_cuota/1');
    add_line(sub_plant, 'Int_T/1', 'T_cultivo/1');
    
    add_line(sub_plant, 'Int_X/1', 'Ecuaciones_Diferenciales/6');
    add_line(sub_plant, 'Int_S/1', 'Ecuaciones_Diferenciales/7');
    add_line(sub_plant, 'Int_Q/1', 'Ecuaciones_Diferenciales/8');
    add_line(sub_plant, 'Int_T/1', 'Ecuaciones_Diferenciales/9');

    %% =====================================================================
    %% 4. SUBSISTEMA DE SENSORES Y RUIDO
    %% =====================================================================
    sub_sens = [model_name '/Sensores_Con_Ruido'];
    add_block('simulink/Ports & Subsystems/Subsystem', sub_sens, 'Position', [580, 310, 780, 430]);
    
    delete_line(sub_sens, 'In1/1', 'Out1/1');
    delete_block([sub_sens '/In1']);
    delete_block([sub_sens '/Out1']);
    
    add_block('simulink/Sources/Clock', [sub_sens '/Clock'], 'Position', [30, 20, 60, 40]);
    add_block('simulink/Ports & Subsystems/In1', [sub_sens '/T_real'], 'Position', [30, 60, 60, 75]);
    add_block('simulink/Ports & Subsystems/In1', [sub_sens '/I_real'], 'Position', [30, 100, 60, 115]);
    
    fcn_sens = [sub_sens '/Generador_Ruido'];
    add_block('simulink/User-Defined Functions/MATLAB Function', fcn_sens, 'Position', [140, 30, 300, 130]);
    
    add_block('simulink/Ports & Subsystems/Out1', [sub_sens '/T_sensor'], 'Position', [370, 45, 400, 60]);
    add_block('simulink/Ports & Subsystems/Out1', [sub_sens '/pH_sensor'],'Position', [370, 80, 400, 95]);
    add_block('simulink/Ports & Subsystems/Out1', [sub_sens '/I_sensor'], 'Position', [370, 115, 400, 130]);
    
    code_sens = sprintf([...
        'function [T_noisy, pH_noisy, I_noisy] = Generador_Ruido(t_hours, T_in, I_in)\n', ...
        '%% Generación de perturbaciones y ruido físico sin variables persistentes\n', ...
        't_sec = t_hours * 3600.0;\n', ...
        '%% 1. Sensor DS18B20: Temperatura + Ruido Gaussiano + 50Hz\n', ...
        'T_noisy = T_in + 0.35 * sin(2*pi*13.7*t_sec) + 0.15 * sin(2*pi*50.0*t_sec);\n', ...
        '%% 2. Electrodo pH-4502C: Dinámica lenta + Outliers por paso de burbujas\n', ...
        'pH_base = 7.6 + 0.15 * sin(2*pi*t_sec/180.0);\n', ...
        'outlier = 0.0;\n', ...
        'if mod(t_sec, 30.0) < 0.3\n', ...
        '    outlier = 1.15; %% Pico espurio positivo\n', ...
        'elseif mod(t_sec, 47.0) < 0.3\n', ...
        '    outlier = -0.85; %% Pico espurio negativo\n', ...
        'end\n', ...
        'pH_noisy = pH_base + 0.04 * sin(2*pi*27.3*t_sec) + outlier;\n', ...
        '%% 3. Sensor de Radiación: Ruido + atenuación por nubes\n', ...
        'nube = 1.0;\n', ...
        'if (mod(t_sec, 100.0) > 40.0) && (mod(t_sec, 100.0) < 55.0)\n', ...
        '    nube = 0.5;\n', ...
        'end\n', ...
        'I_noisy = max(0.0, (I_in + 25.0 * sin(2*pi*5.3*t_sec)) * nube);\n']);
    
    set_matlab_fcn_code(fcn_sens, code_sens);
    
    add_line(sub_sens, 'Clock/1',    'Generador_Ruido/1');
    add_line(sub_sens, 'T_real/1',   'Generador_Ruido/2');
    add_line(sub_sens, 'I_real/1',   'Generador_Ruido/3');
    add_line(sub_sens, 'Generador_Ruido/1', 'T_sensor/1');
    add_line(sub_sens, 'Generador_Ruido/2', 'pH_sensor/1');
    add_line(sub_sens, 'Generador_Ruido/3', 'I_sensor/1');

    %% =====================================================================
    %% 5. SUBSISTEMA DE FILTROS DIGITALES (DSP)
    %% =====================================================================
    sub_dsp = [model_name '/Filtros_Digitales_DSP'];
    add_block('simulink/Ports & Subsystems/Subsystem', sub_dsp, 'Position', [320, 310, 480, 430]);
    
    delete_line(sub_dsp, 'In1/1', 'Out1/1');
    delete_block([sub_dsp '/In1']);
    delete_block([sub_dsp '/Out1']);
    
    add_block('simulink/Ports & Subsystems/In1', [sub_dsp '/T_sensor_in'], 'Position', [30, 45, 60, 60]);
    add_block('simulink/Ports & Subsystems/In1', [sub_dsp '/pH_sensor_in'],'Position', [30, 85, 60, 100]);
    add_block('simulink/Ports & Subsystems/In1', [sub_dsp '/I_sensor_in'], 'Position', [30, 125, 60, 140]);
    
    fcn_dsp = [sub_dsp '/Derivadas_Filtros'];
    add_block('simulink/User-Defined Functions/MATLAB Function', fcn_dsp, 'Position', [120, 35, 270, 150]);
    
    add_block('simulink/Continuous/Integrator', [sub_dsp '/Int_T_filt'], 'Position', [340, 45, 370, 75], ...
        'InitialCondition', '28.0');
    add_block('simulink/Continuous/Integrator', [sub_dsp '/Int_pH_filt'], 'Position', [340, 85, 370, 115], ...
        'InitialCondition', '7.6');
    add_block('simulink/Continuous/Integrator', [sub_dsp '/Int_I_filt'], 'Position', [340, 125, 370, 155], ...
        'InitialCondition', '0.0');
    
    add_block('simulink/Ports & Subsystems/Out1', [sub_dsp '/T_filtrada'],  'Position', [440, 50, 470, 65]);
    add_block('simulink/Ports & Subsystems/Out1', [sub_dsp '/pH_filtrada'], 'Position', [440, 90, 470, 105]);
    add_block('simulink/Ports & Subsystems/Out1', [sub_dsp '/I_filtrada'],  'Position', [440, 130, 470, 145]);
    
    code_dsp = sprintf([...
        'function [dT_f, dpH_f, dI_f] = Derivadas_Filtros(T_raw, pH_raw, I_raw, T_f, pH_f, I_f)\n', ...
        '%% Algoritmos continuos de filtrado DSP equivalentes\n', ...
        '%% 1. Filtro IIR (EMA, alpha=0.1 -> tau = 0.5 h)\n', ...
        'dT_f = (T_raw - T_f) / 0.5;\n', ...
        '%% 2. Filtro STM No Lineal (Rechazo de Outliers por tasa acotada)\n', ...
        'error_ph = pH_raw - pH_f;\n', ...
        'rate_lim = max(-0.4, min(0.4, error_ph / 0.05));\n', ...
        'dpH_f = rate_lim;\n', ...
        '%% 3. Filtro Promedio Movil MA (tau = 0.05 h)\n', ...
        'dI_f = (I_raw - I_f) / 0.05;\n']);
    
    set_matlab_fcn_code(fcn_dsp, code_dsp);
    
    add_line(sub_dsp, 'T_sensor_in/1', 'Derivadas_Filtros/1');
    add_line(sub_dsp, 'pH_sensor_in/1','Derivadas_Filtros/2');
    add_line(sub_dsp, 'I_sensor_in/1', 'Derivadas_Filtros/3');
    
    add_line(sub_dsp, 'Derivadas_Filtros/1', 'Int_T_filt/1');
    add_line(sub_dsp, 'Derivadas_Filtros/2', 'Int_pH_filt/1');
    add_line(sub_dsp, 'Derivadas_Filtros/3', 'Int_I_filt/1');
    
    add_line(sub_dsp, 'Int_T_filt/1', 'T_filtrada/1');
    add_line(sub_dsp, 'Int_pH_filt/1', 'pH_filtrada/1');
    add_line(sub_dsp, 'Int_I_filt/1', 'I_filtrada/1');
    
    add_line(sub_dsp, 'Int_T_filt/1', 'Derivadas_Filtros/4');
    add_line(sub_dsp, 'Int_pH_filt/1', 'Derivadas_Filtros/5');
    add_line(sub_dsp, 'Int_I_filt/1', 'Derivadas_Filtros/6');

    %% =====================================================================
    %% 6. SCOPES Y MONITOREO EN TIEMPO REAL
    %% =====================================================================
    % Scope Térmico
    add_block('simulink/Sinks/Scope', [model_name '/Scope_Termico'], ...
        'Position', [870, 60, 910, 100], 'NumInputPorts', '3');
    
    % Scope Biológico
    add_block('simulink/Sinks/Scope', [model_name '/Scope_Biologico'], ...
        'Position', [870, 120, 910, 160], 'NumInputPorts', '3');
        
    % Scope Sensores vs Filtros
    add_block('simulink/Sinks/Scope', [model_name '/Scope_Filtros_DSP'], ...
        'Position', [870, 330, 910, 370], 'NumInputPorts', '2');
        
    % Scope Actuadores
    add_block('simulink/Sinks/Scope', [model_name '/Scope_Actuadores'], ...
        'Position', [530, 20, 560, 55], 'NumInputPorts', '2');

    % Setpoint Constante Tsp = 26.5°C
    add_block('simulink/Sources/Constant', [model_name '/T_setpoint'], ...
        'Position', [230, 115, 270, 135], 'Value', '26.5');

    %% =====================================================================
    %% CONEXIONES DE NIVEL SUPERIOR (TOP-LEVEL WIRING)
    %% =====================================================================
    % Conectar Entorno -> Planta
    add_line(model_name, 'Entorno_Santa_Marta/1', 'Planta_Biorreactor_4EDOs/3'); % G_solar
    add_line(model_name, 'Entorno_Santa_Marta/2', 'Planta_Biorreactor_4EDOs/4'); % I_par
    add_line(model_name, 'Entorno_Santa_Marta/3', 'Planta_Biorreactor_4EDOs/5'); % T_amb
    
    % Conectar Entorno -> Controlador
    add_line(model_name, 'Entorno_Santa_Marta/3', 'Controlador_Hibrido/3'); % T_amb
    
    % Conectar Setpoint -> Controlador
    add_line(model_name, 'T_setpoint/1', 'Controlador_Hibrido/2');
    
    % Conectar Controlador -> Planta
    add_line(model_name, 'Controlador_Hibrido/1', 'Planta_Biorreactor_4EDOs/1'); % s_camisa
    add_line(model_name, 'Controlador_Hibrido/2', 'Planta_Biorreactor_4EDOs/2'); % Ie_peltier
    
    % Conectar Controlador -> Scope Actuadores
    add_line(model_name, 'Controlador_Hibrido/1', 'Scope_Actuadores/1');
    add_line(model_name, 'Controlador_Hibrido/2', 'Scope_Actuadores/2');
    
    % Conectar Planta -> Sensores
    add_line(model_name, 'Planta_Biorreactor_4EDOs/4', 'Sensores_Con_Ruido/1'); % T_cultivo
    add_line(model_name, 'Entorno_Santa_Marta/2',      'Sensores_Con_Ruido/2'); % I_par
    
    % Conectar Sensores -> Filtros DSP
    add_line(model_name, 'Sensores_Con_Ruido/1', 'Filtros_Digitales_DSP/1');
    add_line(model_name, 'Sensores_Con_Ruido/2', 'Filtros_Digitales_DSP/2');
    add_line(model_name, 'Sensores_Con_Ruido/3', 'Filtros_Digitales_DSP/3');
    
    % Conectar Filtros DSP -> Controlador (Cierre de lazo feedback)
    add_line(model_name, 'Filtros_Digitales_DSP/1', 'Controlador_Hibrido/1');
    
    % Conectar a Scopes
    add_line(model_name, 'Planta_Biorreactor_4EDOs/4', 'Scope_Termico/1'); % T real
    add_line(model_name, 'Entorno_Santa_Marta/3',      'Scope_Termico/2'); % T amb
    add_line(model_name, 'T_setpoint/1',               'Scope_Termico/3'); % T sp
    
    add_line(model_name, 'Planta_Biorreactor_4EDOs/1', 'Scope_Biologico/1'); % X biomasa
    add_line(model_name, 'Planta_Biorreactor_4EDOs/2', 'Scope_Biologico/2'); % S sustrato
    add_line(model_name, 'Planta_Biorreactor_4EDOs/3', 'Scope_Biologico/3'); % Q cuota
    
    add_line(model_name, 'Sensores_Con_Ruido/1',       'Scope_Filtros_DSP/1'); % T ruidosa
    add_line(model_name, 'Filtros_Digitales_DSP/1',    'Scope_Filtros_DSP/2'); % T filtrada

    % Guardar modelo
    save_system(model_name, fullfile(pwd, [model_name '.slx']));
    
    fprintf('\n✔ ¡Modelo Simulink "%s.slx" generado y guardado exitosamente!\n', model_name);
    fprintf('✔ Ubicación: %s\n\n', fullfile(pwd, [model_name '.slx']));
end

function set_matlab_fcn_code(block_path, code_str)
    % Helper para asignar script a un bloque MATLAB Function
    % Los bloques MATLAB Function son internamente Stateflow EMCharts.
    try
        sf = sfroot;
        chart = sf.find('Path', block_path, '-isa', 'Stateflow.EMChart');
        if ~isempty(chart)
            chart.Script = code_str;
        else
            warning('ALUNA:setCode', ...
                'No se encontró el EMChart en: %s\nEl código se deberá pegar manualmente.', block_path);
        end
    catch ME
        warning('ALUNA:setCode', ...
            'Error al asignar código a %s: %s\nEl código se deberá pegar manualmente.', ...
            block_path, ME.message);
    end
end
