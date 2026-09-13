function dashboard_biorreactor()
% DASHBOARD_BIORREACTOR  Dashboard interactivo de simulación.
%
%   dashboard_biorreactor()
%
%   Panel de control con:
%     - 3 checkboxes: refinamientos (Qmet, dV/dt, puente térmico)
%     - 4 sliders: Gmax, φ, Tsp, Ie_max
%     - Botón SIMULAR
%     - Métricas en tiempo real
%
%   6 gráficas:
%     - Temperatura vs setpoint y límite letal
%     - Biomasa (X) y Sustrato (S)
%     - Volumen del reactor (si dV/dt activo)
%     - Desglose de flujos de calor
%     - Corriente del Peltier
%     - Estado de la camisa
%
%   Requiere: parametros_modelo.m, simular_refinado.m,
%             perfil_irradiancia.m, f_temperatura.m,
%             f_luz_steele.m, psat_agua.m
%
%   Compatible con MATLAB R2014b+

    %% ================================================================
    %  CARGAR PARÁMETROS BASE
    % =================================================================
    p = parametros_modelo();   % Imprime resumen en consola (normal)

    %% ================================================================
    %  CREAR FIGURA
    % =================================================================
    scr = get(0, 'ScreenSize');
    fig_w = min(1620, scr(3) - 40);
    fig_h = min(920, scr(4) - 80);
    fig_x = max(20, round((scr(3) - fig_w) / 2));
    fig_y = max(40, round((scr(4) - fig_h) / 2));

    fig = figure('Name', 'Dashboard Biorreactor — Frailejon Artificial', ...
        'NumberTitle', 'off', 'MenuBar', 'none', 'ToolBar', 'figure', ...
        'Position', [fig_x, fig_y, fig_w, fig_h], ...
        'Color', [0.94 0.94 0.97], ...
        'Resize', 'on');

    %% ================================================================
    %  PANEL DE CONTROLES (izquierda)
    % =================================================================
    pnl_w = 260;
    pnl = uipanel(fig, 'Title', '', 'Units', 'pixels', ...
        'Position', [8, 8, pnl_w, fig_h - 16], ...
        'BackgroundColor', [0.90 0.90 0.95], ...
        'BorderType', 'line');

    % Posiciones verticales dentro del panel
    pw = pnl_w - 20;   % Ancho útil
    cx = 10;            % Margen izquierdo
    y  = fig_h - 56;    % Cursor vertical (de arriba a abajo)
    lh = 22;            % Altura de línea

    % ═══════════════════════════════════════════════════════════════
    %  TÍTULO
    % ═══════════════════════════════════════════════════════════════
    uicontrol(pnl, 'Style', 'text', ...
        'String', 'DASHBOARD DE CONTROL', ...
        'Position', [cx, y, pw, lh+4], ...
        'FontSize', 11, 'FontWeight', 'bold', ...
        'ForegroundColor', [0.15 0.15 0.40], ...
        'BackgroundColor', [0.90 0.90 0.95], ...
        'HorizontalAlignment', 'center');
    y = y - lh - 12;

    % ═══════════════════════════════════════════════════════════════
    %  SECCIÓN: REFINAMIENTOS
    % ═══════════════════════════════════════════════════════════════
    uicontrol(pnl, 'Style', 'text', ...
        'String', '  REFINAMIENTOS', ...
        'Position', [cx, y, pw, lh], ...
        'FontSize', 9, 'FontWeight', 'bold', ...
        'ForegroundColor', [0.2 0.4 0.7], ...
        'BackgroundColor', [0.85 0.85 0.92], ...
        'HorizontalAlignment', 'left');
    y = y - lh - 4;

    h.chk_Qmet = uicontrol(pnl, 'Style', 'checkbox', ...
        'String', ' Qmet refinado (mu*X + kd*X)', ...
        'Position', [cx+4, y, pw-4, lh], ...
        'BackgroundColor', [0.90 0.90 0.95], ...
        'FontSize', 8, 'Value', 0, ...
        'Callback', @cb_simular);
    y = y - lh - 2;

    h.chk_dVdt = uicontrol(pnl, 'Style', 'checkbox', ...
        'String', ' dV/dt por evaporacion', ...
        'Position', [cx+4, y, pw-4, lh], ...
        'BackgroundColor', [0.90 0.90 0.95], ...
        'FontSize', 8, 'Value', 0, ...
        'Callback', @cb_simular);
    y = y - lh - 2;

    h.chk_puente = uicontrol(pnl, 'Style', 'checkbox', ...
        'String', ' Puente termico Peltier (KTE)', ...
        'Position', [cx+4, y, pw-4, lh], ...
        'BackgroundColor', [0.90 0.90 0.95], ...
        'FontSize', 8, 'Value', 0, ...
        'Callback', @cb_simular);
    y = y - lh - 16;

    % ═══════════════════════════════════════════════════════════════
    %  SECCIÓN: AMBIENTE
    % ═══════════════════════════════════════════════════════════════
    uicontrol(pnl, 'Style', 'text', ...
        'String', '  AMBIENTE', ...
        'Position', [cx, y, pw, lh], ...
        'FontSize', 9, 'FontWeight', 'bold', ...
        'ForegroundColor', [0.2 0.4 0.7], ...
        'BackgroundColor', [0.85 0.85 0.92], ...
        'HorizontalAlignment', 'left');
    y = y - lh - 4;

    % --- Gmax ---
    h.lbl_Gmax = uicontrol(pnl, 'Style', 'text', ...
        'String', sprintf('Gmax = %d W/m2', p.G_max), ...
        'Position', [cx, y, pw, lh-2], ...
        'FontSize', 8, 'HorizontalAlignment', 'left', ...
        'BackgroundColor', [0.90 0.90 0.95]);
    y = y - 20;

    h.sld_Gmax = uicontrol(pnl, 'Style', 'slider', ...
        'Min', 100, 'Max', 1400, 'Value', p.G_max, ...
        'Position', [cx+2, y, pw-4, 18], ...
        'Callback', @cb_simular);
    y = y - lh - 8;

    % --- phi ---
    h.lbl_phi = uicontrol(pnl, 'Style', 'text', ...
        'String', sprintf('Humedad phi = %.2f', p.phi), ...
        'Position', [cx, y, pw, lh-2], ...
        'FontSize', 8, 'HorizontalAlignment', 'left', ...
        'BackgroundColor', [0.90 0.90 0.95]);
    y = y - 20;

    h.sld_phi = uicontrol(pnl, 'Style', 'slider', ...
        'Min', 0.20, 'Max', 0.95, 'Value', p.phi, ...
        'Position', [cx+2, y, pw-4, 18], ...
        'Callback', @cb_simular);
    y = y - lh - 12;

    % ═══════════════════════════════════════════════════════════════
    %  SECCIÓN: CONTROL
    % ═══════════════════════════════════════════════════════════════
    uicontrol(pnl, 'Style', 'text', ...
        'String', '  CONTROL', ...
        'Position', [cx, y, pw, lh], ...
        'FontSize', 9, 'FontWeight', 'bold', ...
        'ForegroundColor', [0.2 0.4 0.7], ...
        'BackgroundColor', [0.85 0.85 0.92], ...
        'HorizontalAlignment', 'left');
    y = y - lh - 4;

    % --- Tsp ---
    h.lbl_Tsp = uicontrol(pnl, 'Style', 'text', ...
        'String', sprintf('Tsp = %.1f C', p.Tsp), ...
        'Position', [cx, y, pw, lh-2], ...
        'FontSize', 8, 'HorizontalAlignment', 'left', ...
        'BackgroundColor', [0.90 0.90 0.95]);
    y = y - 20;

    h.sld_Tsp = uicontrol(pnl, 'Style', 'slider', ...
        'Min', 18, 'Max', 34, 'Value', p.Tsp, ...
        'Position', [cx+2, y, pw-4, 18], ...
        'Callback', @cb_simular);
    y = y - lh - 8;

    % --- Ie_max ---
    h.lbl_Ie = uicontrol(pnl, 'Style', 'text', ...
        'String', sprintf('Ie_max = %.1f A', p.Ie_max), ...
        'Position', [cx, y, pw, lh-2], ...
        'FontSize', 8, 'HorizontalAlignment', 'left', ...
        'BackgroundColor', [0.90 0.90 0.95]);
    y = y - 20;

    h.sld_Ie = uicontrol(pnl, 'Style', 'slider', ...
        'Min', 0.5, 'Max', 8.0, 'Value', p.Ie_max, ...
        'Position', [cx+2, y, pw-4, 18], ...
        'Callback', @cb_simular);
    y = y - lh - 16;

    % ═══════════════════════════════════════════════════════════════
    %  BOTÓN SIMULAR
    % ═══════════════════════════════════════════════════════════════
    h.btn_sim = uicontrol(pnl, 'Style', 'pushbutton', ...
        'String', 'SIMULAR', ...
        'Position', [cx+10, y, pw-20, 36], ...
        'FontSize', 11, 'FontWeight', 'bold', ...
        'BackgroundColor', [0.20 0.55 0.30], ...
        'ForegroundColor', [1 1 1], ...
        'Callback', @cb_simular);
    y = y - 16;

    % ═══════════════════════════════════════════════════════════════
    %  INDICADOR DE ESTADO
    % ═══════════════════════════════════════════════════════════════
    h.lbl_estado = uicontrol(pnl, 'Style', 'text', ...
        'String', '', ...
        'Position', [cx, y - 14, pw, 16], ...
        'FontSize', 8, 'FontAngle', 'italic', ...
        'ForegroundColor', [0.3 0.3 0.5], ...
        'BackgroundColor', [0.90 0.90 0.95], ...
        'HorizontalAlignment', 'center');
    y = y - 32;

    % ═══════════════════════════════════════════════════════════════
    %  MÉTRICAS
    % ═══════════════════════════════════════════════════════════════
    uicontrol(pnl, 'Style', 'text', ...
        'String', '  METRICAS', ...
        'Position', [cx, y, pw, lh], ...
        'FontSize', 9, 'FontWeight', 'bold', ...
        'ForegroundColor', [0.2 0.4 0.7], ...
        'BackgroundColor', [0.85 0.85 0.92], ...
        'HorizontalAlignment', 'left');
    y = y - lh - 4;

    h.lbl_metrics = uicontrol(pnl, 'Style', 'text', ...
        'String', 'Ejecutando simulacion inicial...', ...
        'Position', [cx, max(10, y - 160), pw, 165], ...
        'FontSize', 8, 'FontName', 'Consolas', ...
        'HorizontalAlignment', 'left', ...
        'BackgroundColor', [0.96 0.96 1.0], ...
        'Max', 2);  % Permitir multi-línea

    %% ================================================================
    %  CREAR EJES DE GRÁFICAS (derecha, grilla 3×2)
    % =================================================================
    % Márgenes de la zona de gráficas
    ax_left_margin  = (pnl_w + 30) / fig_w;    % Normalizado
    ax_right_margin = 0.02;
    ax_top_margin   = 0.06;
    ax_bot_margin   = 0.07;
    ax_hgap = 0.06;      % Gap horizontal entre columnas
    ax_vgap = 0.09;      % Gap vertical entre filas

    ax_total_w = 1 - ax_left_margin - ax_right_margin - ax_hgap;
    ax_total_h = 1 - ax_top_margin - ax_bot_margin - 2 * ax_vgap;
    ax_w = ax_total_w / 2;
    ax_h = ax_total_h / 3;

    col_x = [ax_left_margin, ax_left_margin + ax_w + ax_hgap];
    row_y = [ax_bot_margin + 2*(ax_h + ax_vgap), ...
             ax_bot_margin + (ax_h + ax_vgap), ...
             ax_bot_margin];

    ax_names = {'Temperatura', 'Biomasa y Sustrato'; ...
                'Volumen',     'Flujos de Calor'; ...
                'Corriente Peltier', 'Estado Camisa'};

    h.ax = gobjects(3, 2);
    for r = 1:3
        for c = 1:2
            h.ax(r,c) = axes(fig, 'Units', 'normalized', ...
                'Position', [col_x(c), row_y(r), ax_w, ax_h], ...
                'FontSize', 8, 'Box', 'on');
            grid(h.ax(r,c), 'on');
            title(h.ax(r,c), ax_names{r,c}, 'FontSize', 9);
            hold(h.ax(r,c), 'on');
        end
    end

    %% ================================================================
    %  ALMACENAR HANDLES Y EJECUTAR SIMULACIÓN INICIAL
    % =================================================================
    h.p = p;
    guidata(fig, h);

    cb_simular([], []);

    %% ================================================================
    %  CALLBACK PRINCIPAL — ejecuta simulación y actualiza gráficas
    % =================================================================
    function cb_simular(~, ~)
        h = guidata(fig);
        p_sim = h.p;

        % --- Leer controles ---
        opts.Qmet_refinado  = logical(get(h.chk_Qmet,   'Value'));
        opts.dVdt_activo    = logical(get(h.chk_dVdt,    'Value'));
        opts.puente_termico = logical(get(h.chk_puente,  'Value'));

        p_sim.G_max  = round(get(h.sld_Gmax, 'Value'));
        p_sim.phi    = round(get(h.sld_phi,   'Value'), 2);
        p_sim.Tsp    = round(get(h.sld_Tsp,   'Value'), 1);
        p_sim.Ie_max = round(get(h.sld_Ie,    'Value'), 1);

        % Recalcular Ie_opt con el nuevo Tsp
        Tc_ref = p_sim.Tsp + 273.15;
        p_sim.Ie_opt = p_sim.alpha_TE * Tc_ref / p_sim.RTE;

        % --- Actualizar labels de sliders ---
        set(h.lbl_Gmax, 'String', sprintf('Gmax = %d W/m2', p_sim.G_max));
        set(h.lbl_phi,  'String', sprintf('Humedad phi = %.2f', p_sim.phi));
        set(h.lbl_Tsp,  'String', sprintf('Tsp = %.1f C', p_sim.Tsp));
        set(h.lbl_Ie,   'String', sprintf('Ie_max = %.1f A', p_sim.Ie_max));

        % --- Indicador de estado ---
        set(h.lbl_estado, 'String', 'Simulando...', ...
            'ForegroundColor', [0.8 0.4 0.0]);
        drawnow;

        % --- Preparar condiciones iniciales ---
        x0 = [p_sim.X0; p_sim.S0; p_sim.Q0; p_sim.T0];
        if opts.dVdt_activo
            x0 = [x0; p_sim.V];
        end

        t_span = 0:0.02:72;   % dt=0.02h (72s) — buen balance velocidad/precisión
        N = length(t_span);

        % --- EJECUTAR SIMULACIÓN ---
        tic;
        [t, x, logs] = simular_refinado(t_span, x0, p_sim, opts);
        t_sim = toc;

        set(h.lbl_estado, 'String', ...
            sprintf('Completado en %.2f s', t_sim), ...
            'ForegroundColor', [0.1 0.5 0.1]);

        % --- Extraer datos ---
        T_data = x(:, 4);
        X_data = x(:, 1);
        S_data = x(:, 2);

        if opts.dVdt_activo
            V_mL = x(:, 5) * 1e6;  % m³ → mL
        else
            V_mL = ones(N, 1) * p_sim.V * 1e6;
        end

        % ═══════════════════════════════════════════════════════════
        %  GRÁFICA 1: TEMPERATURA
        % ═══════════════════════════════════════════════════════════
        cla(h.ax(1,1));
        % Banda de confort ±2°C
        fill(h.ax(1,1), [t(1) t(end) t(end) t(1)], ...
            [p_sim.Tsp-2, p_sim.Tsp-2, p_sim.Tsp+2, p_sim.Tsp+2], ...
            [0.7 1.0 0.7], 'FaceAlpha', 0.20, 'EdgeColor', 'none');
        plot(h.ax(1,1), t, T_data, 'Color', [0.0 0.45 0.0], 'LineWidth', 1.5);
        yline(h.ax(1,1), p_sim.Tsp,  'k--', 'T_{sp}', ...
            'LineWidth', 1, 'FontSize', 7, 'LabelHorizontalAlignment', 'left');
        yline(h.ax(1,1), p_sim.Tmax, 'r--', 'T_{max} LETAL', ...
            'LineWidth', 1.2, 'FontSize', 7, 'Color', [0.8 0 0], ...
            'LabelHorizontalAlignment', 'left');
        xlabel(h.ax(1,1), 'Tiempo [h]');
        ylabel(h.ax(1,1), 'T [C]');
        title(h.ax(1,1), 'Temperatura del Cultivo', 'FontSize', 9);
        xlim(h.ax(1,1), [0 72]);

        % ═══════════════════════════════════════════════════════════
        %  GRÁFICA 2: BIOMASA Y SUSTRATO
        % ═══════════════════════════════════════════════════════════
        cla(h.ax(1,2));
        yyaxis(h.ax(1,2), 'left');
        cla(h.ax(1,2));
        plot(h.ax(1,2), t, X_data, 'Color', [0.0 0.4 0.8], 'LineWidth', 1.5);
        ylabel(h.ax(1,2), 'Biomasa X [g/L]');
        set(h.ax(1,2), 'YColor', [0.0 0.4 0.8]);
        yyaxis(h.ax(1,2), 'right');
        plot(h.ax(1,2), t, S_data, 'Color', [0.85 0.2 0.0], 'LineWidth', 1.5);
        ylabel(h.ax(1,2), 'Sustrato S [mmol/L]');
        set(h.ax(1,2), 'YColor', [0.85 0.2 0.0]);
        xlabel(h.ax(1,2), 'Tiempo [h]');
        title(h.ax(1,2), 'Biomasa y Sustrato', 'FontSize', 9);
        xlim(h.ax(1,2), [0 72]);

        % ═══════════════════════════════════════════════════════════
        %  GRÁFICA 3: VOLUMEN
        % ═══════════════════════════════════════════════════════════
        cla(h.ax(2,1));
        if opts.dVdt_activo
            dV_total = V_mL(1) - V_mL(end);
            dV_pct   = dV_total / V_mL(1) * 100;
            plot(h.ax(2,1), t, V_mL, 'Color', [0.5 0.0 0.75], 'LineWidth', 1.5);
            title(h.ax(2,1), ...
                sprintf('Volumen (DV = %.1f mL, %.1f%%)', dV_total, dV_pct), ...
                'FontSize', 9);
        else
            plot(h.ax(2,1), t, V_mL, '--', 'Color', [0.5 0.5 0.5], 'LineWidth', 1.2);
            title(h.ax(2,1), 'Volumen (dV/dt DESACTIVADO)', ...
                'FontSize', 9, 'Color', [0.5 0.5 0.5]);
        end
        xlabel(h.ax(2,1), 'Tiempo [h]');
        ylabel(h.ax(2,1), 'V [mL]');
        xlim(h.ax(2,1), [0 72]);

        % ═══════════════════════════════════════════════════════════
        %  GRÁFICA 4: FLUJOS DE CALOR
        % ═══════════════════════════════════════════════════════════
        cla(h.ax(2,2));
        % Convención: positivo = calienta el cultivo, negativo = enfría
        plot(h.ax(2,2), t, logs.Q_solar_log, 'LineWidth', 1.2, ...
            'Color', [1.0 0.6 0.0]);               % Solar (ganancia)
        plot(h.ax(2,2), t, logs.Q_met_log, 'LineWidth', 1.2, ...
            'Color', [0.6 0.0 0.6]);                % Metabólico (ganancia)
        plot(h.ax(2,2), t, -logs.Q_pared_log, 'LineWidth', 1.2, ...
            'Color', [0.0 0.5 0.8]);                % Pared (pérdida)
        plot(h.ax(2,2), t, -logs.Q_evap_log, 'LineWidth', 1.2, ...
            'Color', [0.0 0.7 0.7]);                % Evaporación (pérdida)
        plot(h.ax(2,2), t, -logs.Q_pelt_log, 'LineWidth', 1.2, ...
            'Color', [0.8 0.0 0.2]);                % Peltier (pérdida)
        xlabel(h.ax(2,2), 'Tiempo [h]');
        ylabel(h.ax(2,2), 'Q [W]');
        title(h.ax(2,2), 'Flujos de Calor (+calienta / -enfria)', 'FontSize', 9);
        legend(h.ax(2,2), 'Q_{sol}', 'Q_{met}', '-Q_{par}', '-Q_{evap}', '-Q_{pelt}', ...
            'Location', 'best', 'FontSize', 7);
        xlim(h.ax(2,2), [0 72]);

        % ═══════════════════════════════════════════════════════════
        %  GRÁFICA 5: CORRIENTE PELTIER
        % ═══════════════════════════════════════════════════════════
        cla(h.ax(3,1));
        area(h.ax(3,1), t, logs.Ie_log, ...
            'FaceColor', [0.2 0.5 0.9], 'FaceAlpha', 0.3, 'EdgeColor', [0.1 0.3 0.7]);
        yline(h.ax(3,1), p_sim.Ie_max, 'r--', 'I_{e,max}', ...
            'LineWidth', 1, 'FontSize', 7);
        yline(h.ax(3,1), min(p_sim.Ie_opt, p_sim.Ie_max), 'm:', 'I_{e,opt}', ...
            'LineWidth', 1, 'FontSize', 7);
        xlabel(h.ax(3,1), 'Tiempo [h]');
        ylabel(h.ax(3,1), 'I_e [A]');
        title(h.ax(3,1), 'Corriente del Peltier', 'FontSize', 9);
        xlim(h.ax(3,1), [0 72]);

        % ═══════════════════════════════════════════════════════════
        %  GRÁFICA 6: ESTADO DE CAMISA
        % ═══════════════════════════════════════════════════════════
        cla(h.ax(3,2));
        % Sombrear noche
        for dia = 0:2
            fill(h.ax(3,2), [18+24*dia, 30+24*dia, 30+24*dia, 18+24*dia], ...
                [-0.15, -0.15, 1.15, 1.15], ...
                [0.85 0.85 0.95], 'EdgeColor', 'none', 'FaceAlpha', 0.5);
        end
        stairs(h.ax(3,2), t, logs.s_log, 'Color', [0.80 0.20 0.0], 'LineWidth', 2);
        xlabel(h.ax(3,2), 'Tiempo [h]');
        ylabel(h.ax(3,2), 's');
        title(h.ax(3,2), 'Estado Camisa (sombreado=noche)', 'FontSize', 9);
        ylim(h.ax(3,2), [-0.15 1.15]);
        set(h.ax(3,2), 'YTick', [0 1], 'YTickLabel', {'Abierta', 'Cerrada'});
        xlim(h.ax(3,2), [0 72]);

        % ═══════════════════════════════════════════════════════════
        %  ACTUALIZAR MÉTRICAS
        % ═══════════════════════════════════════════════════════════
        err_rms     = sqrt(mean((T_data - p_sim.Tsp).^2));
        T_max_val   = max(T_data);
        T_min_val   = min(T_data);
        tiempo_zona = sum(abs(T_data - p_sim.Tsp) <= 2.0) / N * 100;
        conmut      = sum(abs(diff(logs.s_log)));

        % Refinamientos activos
        ref_str = '';
        if opts.Qmet_refinado,  ref_str = [ref_str, 'Qmet ']; end
        if opts.dVdt_activo,    ref_str = [ref_str, 'dV/dt ']; end
        if opts.puente_termico, ref_str = [ref_str, 'KTE ']; end
        if isempty(ref_str), ref_str = 'Ninguno'; end

        if opts.dVdt_activo
            dV_str = sprintf('DV = %.1f mL (%.1f%%)', ...
                V_mL(1) - V_mL(end), (V_mL(1) - V_mL(end)) / V_mL(1) * 100);
        else
            dV_str = 'DV = N/A';
        end

        metrics_text = sprintf([...
            'Error RMS: %.3f C\n', ...
            'T max:     %.2f C\n', ...
            'T min:     %.2f C\n', ...
            'En zona:   %.1f%%\n', ...
            'Conmut:    %d\n', ...
            '%s\n', ...
            'X final:   %.3f g/L\n', ...
            'S final:   %.3f mmol/L\n', ...
            '---\n', ...
            'Refin: %s\n', ...
            't_sim: %.2f s'], ...
            err_rms, T_max_val, T_min_val, tiempo_zona, ...
            conmut, dV_str, x(end,1), x(end,2), ref_str, t_sim);

        set(h.lbl_metrics, 'String', metrics_text);

        % Restaurar grids
        for r2 = 1:3
            for c2 = 1:2
                grid(h.ax(r2,c2), 'on');
            end
        end

        guidata(fig, h);
    end
end
