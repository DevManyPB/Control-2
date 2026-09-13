function ps = psat_agua(T_C)
% PSAT_AGUA  Presión de saturación de vapor de agua (Antoine).
%
%   ps = psat_agua(T_C)
%
%   Ecuación de Antoine para agua (válida ~1–100 °C):
%     log10(ps [mmHg]) = A − B / (C + T [°C])
%     → convertida a Pa (1 mmHg = 133.322 Pa)
%
%   Entrada:
%     T_C — Temperatura [°C] (escalar o vector)
%
%   Salida:
%     ps  — Presión de saturación [Pa]

    A = 8.07131;
    B = 1730.63;
    C = 233.426;
    
    ps = 133.322 * 10.^(A - B ./ (C + T_C));
end
