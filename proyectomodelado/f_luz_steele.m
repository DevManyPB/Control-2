function fI = f_luz_steele(I, Iopt)
% F_LUZ_STEELE  Factor de luz (Steele, §8.4 de la guía).
%
%   fI = f_luz_steele(I, Iopt)
%
%   Modelo de fotoinhibición de Steele:
%     f(I) = (I / Iopt) · exp(1 − I / Iopt)
%
%   Propiedades:
%     - f(0)    = 0    (sin luz, sin crecimiento)
%     - f(Iopt) = 1    (pico normalizado)
%     - f → 0 para I → ∞ (fotoinhibición a altas irradiancias)
%     - Iopt se lee directo de la curva P-I experimental
%
%   Entradas:
%     I    — Irradiancia [µmol fotón m⁻² s⁻¹] (escalar o vector)
%     Iopt — Irradiancia óptima [µmol fotón m⁻² s⁻¹]
%
%   Salida:
%     fI   — Factor adimensional ∈ [0, 1]

    fI = zeros(size(I));
    idx = I > 0;
    
    if any(idx)
        ratio = I(idx) / Iopt;
        fI(idx) = ratio .* exp(1 - ratio);
    end
    
    fI = max(0, min(1, fI));
end
