function fT = f_temperatura(T, Tmin, Topt, Tmax)
% F_TEMPERATURA  Factor de temperatura para la tasa de crecimiento.
%
%   fT = f_temperatura(T, Tmin, Topt, Tmax)
%
%   Modelo cardinal tipo Rosso/CTMI (Cardinal Temperature Model with
%   Inflection), estándar en literatura de fitoplancton.
%
%   ➤ VACÍO DECLARADO: f(T) NO está definida en ningún documento del
%   curso (ni en la guía §8.3-8.5, ni en Tebbani, ni en Abu-Reesh, ni
%   en Kumar et al.). La elección de la forma funcional y sus tres
%   parámetros cardinales es decisión propia del estudiante.
%
%   Propiedades del modelo:
%     - f(T) = 0  si  T ≤ Tmin  o  T ≥ Tmax
%     - f(T) = 1  en  T = Topt  (pico normalizado)
%     - Función suave, diferenciable en todo el dominio
%     - Solo 3 parámetros con significado biológico directo
%
%   Forma explícita (CTMI):
%                     (T - Tmax)(T - Tmin)²
%     f(T) = ——————————————————————————————————————————————
%            (Topt - Tmin)[(Topt - Tmin)(T - Topt) - (Topt - Tmax)(Topt + Tmin - 2T)]
%
%   Referencia:
%     Rosso, L., Lobry, J.R., Flandrois, J.P. (1993)
%     "An unexpected correlation between cardinal temperatures of
%     microbial growth highlighted by a new model."
%     J. Theor. Biol. 162(4):447-463.
%
%   Justificación de los valores cardinales elegidos:
%     Tmin = 10 °C — supuesto conservador (ver parametros_modelo.m)
%     Topt = 28 °C — Chlorella-específico (ver parametros_modelo.m)
%     Tmax = 35 °C — restricción dura de la guía §8.8
%
%   Entradas:
%     T     — Temperatura [°C] (escalar o vector)
%     Tmin  — Temperatura mínima cardinal [°C]
%     Topt  — Temperatura óptima cardinal [°C]
%     Tmax  — Temperatura máxima cardinal [°C]
%
%   Salida:
%     fT    — Factor adimensional ∈ [0, 1]

    % Preallocar salida (soporta entradas vectoriales)
    fT = zeros(size(T));
    
    % Solo evaluar en el rango viable (Tmin < T < Tmax)
    idx = (T > Tmin) & (T < Tmax);
    
    if any(idx)
        Tv = T(idx);
        
        % Numerador: (T − Tmax)(T − Tmin)²
        num = (Tv - Tmax) .* (Tv - Tmin).^2;
        
        % Denominador: (Topt − Tmin) × [(Topt − Tmin)(T − Topt)
        %              − (Topt − Tmax)(Topt + Tmin − 2T)]
        a = Topt - Tmin;
        b = Topt - Tmax;
        den = a .* (a .* (Tv - Topt) - b .* (Topt + Tmin - 2*Tv));
        
        fT(idx) = num ./ den;
    end
    
    % Clamp numérico (por seguridad ante errores de redondeo)
    fT = max(0, min(1, fT));
end
