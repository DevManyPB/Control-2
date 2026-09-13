function G = perfil_irradiancia(t_h, G_max)
% PERFIL_IRRADIANCIA  Perfil diurno de irradiancia solar sinusoidal.
%
%   G = perfil_irradiancia(t_h, G_max)
%
%   Simula un ciclo día/noche con 12 h de luz y 12 h de oscuridad.
%   Se asume que el día comienza a las 6:00 (t = 6 h desde medianoche).
%
%   Entradas:
%     t_h   — Tiempo en horas (escalar o vector)
%     G_max — Irradiancia máxima [W/m²]
%
%   Salida:
%     G     — Irradiancia [W/m²]

    % Hora del día (módulo 24)
    hora = mod(t_h, 24);
    
    % Día: 6:00 a 18:00 (12 horas de luz)
    G = zeros(size(t_h));
    idx_dia = (hora >= 6) & (hora <= 18);
    
    if any(idx_dia)
        % Perfil sinusoidal con pico al mediodía (hora 12)
        G(idx_dia) = G_max * sin(pi * (hora(idx_dia) - 6) / 12);
    end
    
    G = max(G, 0);
end
