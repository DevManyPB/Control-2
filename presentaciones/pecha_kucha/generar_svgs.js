// Script para generar SVGs de alta definición para Pecha Kucha
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const imgDir = path.join(__dirname, 'img');
if (!fs.existsSync(imgDir)) fs.mkdirSync(imgDir, { recursive: true });

// Paleta de colores
const C = {
  bg: '#0a0e20',
  axes: '#0e142a',
  grid: '#222845',
  text: '#f2f6fc',
  muted: '#8b9bb4',
  cyan: '#00d4ff',
  green: '#00ff88',
  purple: '#8b4dff',
  orange: '#ff6b35',
  red: '#ff4757',
  yellow: '#ffd700'
};

function createSvgHeader(w, h, title) {
  return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${w} ${h}" width="100%" height="100%" style="background:${C.bg}; border-radius:10px; font-family:'Inter',system-ui,sans-serif;">
  <defs>
    <linearGradient id="cyanGrad" x1="0" y1="0" x2="1" y2="0"><stop offset="0%" stop-color="${C.cyan}"/><stop offset="100%" stop-color="${C.purple}"/></linearGradient>
    <linearGradient id="greenGrad" x1="0" y1="0" x2="0" y2="1"><stop offset="0%" stop-color="${C.green}" stop-opacity="0.35"/><stop offset="100%" stop-color="${C.green}" stop-opacity="0.0"/></linearGradient>
    <linearGradient id="biomassGrad" x1="0" y1="0" x2="0" y2="1"><stop offset="0%" stop-color="${C.cyan}" stop-opacity="0.4"/><stop offset="100%" stop-color="${C.cyan}" stop-opacity="0.0"/></linearGradient>
    <filter id="glow" x="-20%" y="-20%" width="140%" height="140%"><feGaussianBlur stdDeviation="3" result="blur"/><feMerge><feMergeNode in="blur"/><feMergeNode in="SourceGraphic"/></feMerge></filter>
  </defs>
  <!-- Background & Axes Card -->
  <rect x="0" y="0" width="${w}" height="${h}" rx="10" fill="${C.bg}"/>
  <rect x="50" y="45" width="${w-80}" height="${h-90}" rx="6" fill="${C.axes}" stroke="${C.grid}" stroke-width="1.2"/>
  <!-- Title -->
  <text x="${w/2}" y="28" fill="${C.text}" font-size="14" font-weight="700" text-anchor="middle" letter-spacing="0.5">${title}</text>`;
}

// 1. CTMI f(T)
function generateCTMI() {
  const w = 700, h = 420;
  let svg = createSvgHeader(w, h, 'Modelo Cardinal CTMI de Rosso: f(T) vs Temperatura');
  
  const xMin = 5, xMax = 40, yMin = 0, yMax = 1.15;
  const mapX = (t) => 50 + ((t - xMin) / (xMax - xMin)) * (w - 80);
  const mapY = (f) => (h - 45) - ((f - yMin) / (yMax - yMin)) * (h - 90);

  // Grids
  for (let t = 10; t <= 35; t += 5) {
    svg += `<line x1="${mapX(t)}" y1="45" x2="${mapX(t)}" y2="${h-45}" stroke="${C.grid}" stroke-dasharray="3,3" stroke-width="1"/>`;
    svg += `<text x="${mapX(t)}" y="${h-25}" fill="${C.muted}" font-size="11" text-anchor="middle">${t}°C</text>`;
  }
  for (let f = 0.2; f <= 1.0; f += 0.2) {
    svg += `<line x1="50" y1="${mapY(f)}" x2="${w-30}" y2="${mapY(f)}" stroke="${C.grid}" stroke-dasharray="3,3" stroke-width="1"/>`;
    svg += `<text x="42" y="${mapY(f)+4}" fill="${C.muted}" font-size="10" text-anchor="end">${f.toFixed(1)}</text>`;
  }

  // Santa Marta zone
  const smLeft = mapX(27), smRight = mapX(40);
  svg += `<rect x="${smLeft}" y="45" width="${smRight-smLeft}" height="${h-90}" fill="${C.red}" fill-opacity="0.13"/>`;
  svg += `<text x="${(smLeft+smRight)/2}" y="70" fill="${C.red}" font-size="11" font-weight="bold" text-anchor="middle">Zona Santa Marta (27°C–40°C)</text>`;

  // Curve points
  let pathD = '';
  const Tmin = 10, Topt = 28, Tmax = 35;
  for (let T = 5; T <= 40; T += 0.2) {
    let fT = 0;
    if (T > Tmin && T < Tmax) {
      const num = (T - Tmax) * Math.pow(T - Tmin, 2);
      const den = (Topt - Tmin) * ((Topt - Tmin) * (T - Topt) - (Topt - Tmax) * (Topt + Tmin - 2 * T));
      fT = Math.max(0, Math.min(1, num / den));
    }
    const x = mapX(T), y = mapY(fT);
    pathD += (pathD === '' ? `M ${x} ${y}` : ` L ${x} ${y}`);
  }

  svg += `<path d="${pathD}" fill="none" stroke="${C.red}" stroke-width="3.5" filter="url(#glow)"/>`;

  // Key points
  svg += `<line x1="${mapX(Topt)}" y1="${mapY(1)}" x2="${mapX(Topt)}" y2="${h-45}" stroke="${C.cyan}" stroke-dasharray="4,4" stroke-width="1.5"/>`;
  svg += `<circle cx="${mapX(Topt)}" cy="${mapY(1)}" r="6" fill="${C.cyan}" stroke="#fff" stroke-width="2"/>`;
  svg += `<text x="${mapX(Topt)-8}" y="${mapY(1)-12}" fill="${C.cyan}" font-size="12" font-weight="bold">Topt = 28°C (f=1.0)</text>`;
  
  svg += `<circle cx="${mapX(Tmin)}" cy="${mapY(0)}" r="5" fill="${C.muted}"/>`;
  svg += `<text x="${mapX(Tmin)}" y="${mapY(0)-10}" fill="${C.muted}" font-size="10" text-anchor="middle">Tmin = 10°C</text>`;
  
  svg += `<circle cx="${mapX(Tmax)}" cy="${mapY(0)}" r="5" fill="${C.red}"/>`;
  svg += `<text x="${mapX(Tmax)}" y="${mapY(0)-10}" fill="${C.red}" font-size="10" text-anchor="middle">Tmax = 35°C (Letal)</text>`;

  svg += `</svg>`;
  fs.writeFileSync(path.join(imgDir, 'plot_ctmi.svg'), svg);
}

// 2. Steele f(I)
function generateSteele() {
  const w = 700, h = 420;
  let svg = createSvgHeader(w, h, 'Modelo de Steele: f(I) vs Irradiancia (Fotoinhibición)');
  
  const xMin = 0, xMax = 1000, yMin = 0, yMax = 1.15;
  const mapX = (I) => 50 + ((I - xMin) / (xMax - xMin)) * (w - 80);
  const mapY = (f) => (h - 45) - ((f - yMin) / (yMax - yMin)) * (h - 90);

  for (let I = 200; I <= 1000; I += 200) {
    svg += `<line x1="${mapX(I)}" y1="45" x2="${mapX(I)}" y2="${h-45}" stroke="${C.grid}" stroke-dasharray="3,3" stroke-width="1"/>`;
    svg += `<text x="${mapX(I)}" y="${h-25}" fill="${C.muted}" font-size="11" text-anchor="middle">${I} µmol</text>`;
  }
  for (let f = 0.2; f <= 1.0; f += 0.2) {
    svg += `<line x1="50" y1="${mapY(f)}" x2="${w-30}" y2="${mapY(f)}" stroke="${C.grid}" stroke-dasharray="3,3" stroke-width="1"/>`;
    svg += `<text x="42" y="${mapY(f)+4}" fill="${C.muted}" font-size="10" text-anchor="end">${f.toFixed(1)}</text>`;
  }

  const Iopt = 200;
  const optX = mapX(Iopt);
  svg += `<rect x="50" y="45" width="${optX-50}" height="${h-90}" fill="${C.green}" fill-opacity="0.08"/>`;
  svg += `<rect x="${optX}" y="45" width="${w-30-optX}" height="${h-90}" fill="${C.orange}" fill-opacity="0.08"/>`;
  svg += `<text x="${(50+optX)/2}" y="70" fill="${C.green}" font-size="11" text-anchor="middle">Fotosaturación</text>`;
  svg += `<text x="${(optX+w-30)/2}" y="70" fill="${C.orange}" font-size="11" font-weight="bold" text-anchor="middle">Zona de Fotoinhibición (Estrés D1)</text>`;

  let pathD = '';
  for (let I = 0; I <= 1000; I += 5) {
    const fI = (I / Iopt) * Math.exp(1 - I / Iopt);
    const x = mapX(I), y = mapY(fI);
    pathD += (pathD === '' ? `M ${x} ${y}` : ` L ${x} ${y}`);
  }

  svg += `<path d="${pathD}" fill="none" stroke="${C.orange}" stroke-width="3.5" filter="url(#glow)"/>`;
  svg += `<line x1="${optX}" y1="${mapY(1)}" x2="${optX}" y2="${h-45}" stroke="${C.yellow}" stroke-dasharray="4,4" stroke-width="1.5"/>`;
  svg += `<circle cx="${optX}" cy="${mapY(1)}" r="6" fill="${C.yellow}" stroke="#fff" stroke-width="2"/>`;
  svg += `<text x="${optX+8}" y="${mapY(1)-12}" fill="${C.yellow}" font-size="12" font-weight="bold">Iopt = 200 µmol (f=1.0)</text>`;

  svg += `</svg>`;
  fs.writeFileSync(path.join(imgDir, 'plot_steele.svg'), svg);
}

// 3. Simulación Térmica 72h
function generateSimTemp() {
  const w = 800, h = 440;
  let svg = createSvgHeader(w, h, 'Evolución Térmica del Biorreactor en 72h (Control Camisa + Peltier)');
  
  const xMin = 0, xMax = 72, yMin = 22, yMax = 38;
  const mapX = (t) => 50 + (t / 72) * (w - 80);
  const mapY = (T) => (h - 45) - ((T - yMin) / (yMax - yMin)) * (h - 90);

  for (let t = 12; t <= 72; t += 12) {
    svg += `<line x1="${mapX(t)}" y1="45" x2="${mapX(t)}" y2="${h-45}" stroke="${C.grid}" stroke-dasharray="3,3" stroke-width="1"/>`;
    svg += `<text x="${mapX(t)}" y="${h-25}" fill="${C.muted}" font-size="11" text-anchor="middle">${t}h</text>`;
  }
  for (let T = 24; T <= 36; T += 2) {
    svg += `<line x1="50" y1="${mapY(T)}" x2="${w-30}" y2="${mapY(T)}" stroke="${C.grid}" stroke-dasharray="3,3" stroke-width="1"/>`;
    svg += `<text x="42" y="${mapY(T)+4}" fill="${C.muted}" font-size="10" text-anchor="end">${T}°C</text>`;
  }

  const Tsp = 26.5;
  // Banda ±1°C
  svg += `<rect x="50" y="${mapY(Tsp+1)}" width="${w-80}" height="${mapY(Tsp-1)-mapY(Tsp+1)}" fill="${C.green}" fill-opacity="0.12"/>`;
  svg += `<text x="${w-40}" y="${mapY(Tsp)+4}" fill="${C.green}" font-size="10" text-anchor="end">Banda Óptima ±1.0°C</text>`;

  // Línea Tmax letal
  svg += `<line x1="50" y1="${mapY(35)}" x2="${w-30}" y2="${mapY(35)}" stroke="${C.red}" stroke-dasharray="6,3" stroke-width="1.5"/>`;
  svg += `<text x="60" y="${mapY(35)-8}" fill="${C.red}" font-size="10" font-weight="bold">Límite Letal Tmax = 35°C</text>`;

  // Setpoint
  svg += `<line x1="50" y1="${mapY(Tsp)}" x2="${w-30}" y2="${mapY(Tsp)}" stroke="${C.yellow}" stroke-dasharray="4,4" stroke-width="1.8"/>`;

  // Lazo abierto (sin control)
  let dOpen = '';
  for (let t = 0; t <= 72; t += 0.2) {
    const amb = 29 + 6 * Math.sin(2 * Math.PI * (t - 9) / 24);
    const Top = amb + 4 * Math.max(0, Math.sin(2 * Math.PI * (t - 6) / 24));
    dOpen += (dOpen === '' ? `M ${mapX(t)} ${mapY(Top)}` : ` L ${mapX(t)} ${mapY(Top)}`);
  }
  svg += `<path d="${dOpen}" fill="none" stroke="${C.red}" stroke-opacity="0.5" stroke-width="1.8" stroke-dasharray="5,4"/>`;

  // Lazo cerrado (con control camisa + Peltier)
  let dClosed = '';
  for (let t = 0; t <= 72; t += 0.2) {
    const Tcl = Tsp + 1.2 * Math.sin(2 * Math.PI * (t - 9) / 24) * Math.exp(-t / 40);
    dClosed += (dClosed === '' ? `M ${mapX(t)} ${mapY(Tcl)}` : ` L ${mapX(t)} ${mapY(Tcl)}`);
  }
  svg += `<path d="${dClosed}" fill="none" stroke="${C.green}" stroke-width="3" filter="url(#glow)"/>`;

  // Leyenda
  svg += `<g transform="translate(60, ${h-80})">
    <rect width="360" height="26" rx="4" fill="${C.axes}" stroke="${C.grid}" stroke-width="1"/>
    <line x1="12" y1="13" x2="35" y2="13" stroke="${C.green}" stroke-width="3"/>
    <text x="42" y="17" fill="${C.text}" font-size="10">Control Activo Híbrido</text>
    <line x1="170" y1="13" x2="195" y2="13" stroke="${C.yellow}" stroke-width="2" stroke-dasharray="3,3"/>
    <text x="202" y="17" fill="${C.yellow}" font-size="10">Setpoint 26.5°C</text>
    <line x1="285" y1="13" x2="310" y2="13" stroke="${C.red}" stroke-width="1.8" stroke-dasharray="3,3"/>
    <text x="315" y="17" fill="${C.red}" font-size="10">Sin Control</text>
  </g>`;

  svg += `</svg>`;
  fs.writeFileSync(path.join(imgDir, 'plot_sim_temp.svg'), svg);
}

// 4. Simulación Biomasa 72h
function generateSimBiomass() {
  const w = 800, h = 440;
  let svg = createSvgHeader(w, h, 'Cinética de Crecimiento de Biomasa Chlorella vulgaris (72h)');
  
  const mapX = (t) => 50 + (t / 72) * (w - 80);
  const mapY = (X) => (h - 45) - (X / 7.0) * (h - 90);

  for (let t = 12; t <= 72; t += 12) {
    svg += `<line x1="${mapX(t)}" y1="45" x2="${mapX(t)}" y2="${h-45}" stroke="${C.grid}" stroke-dasharray="3,3" stroke-width="1"/>`;
    svg += `<text x="${mapX(t)}" y="${h-25}" fill="${C.muted}" font-size="11" text-anchor="middle">${t}h</text>`;
  }
  for (let X = 1; X <= 6; X += 1) {
    svg += `<line x1="50" y1="${mapY(X)}" x2="${w-30}" y2="${mapY(X)}" stroke="${C.grid}" stroke-dasharray="3,3" stroke-width="1"/>`;
    svg += `<text x="42" y="${mapY(X)+4}" fill="${C.muted}" font-size="10" text-anchor="end">${X} g/L</text>`;
  }

  let X_val = 0.5;
  let dPath = `M ${mapX(0)} ${mapY(X_val)}`;
  let dArea = `M ${mapX(0)} ${mapY(0)} L ${mapX(0)} ${mapY(X_val)}`;

  for (let t = 0.2; t <= 72; t += 0.2) {
    const hora = t % 24;
    const luz = Math.max(0, Math.sin(Math.PI * (hora - 6) / 12));
    const fI = (luz * 800 / 200) * Math.exp(1 - luz * 800 / 200);
    const mu = 0.08 * fI * (1 - X_val / 6.8);
    X_val += mu * X_val * 0.2;
    dPath += ` L ${mapX(t)} ${mapY(X_val)}`;
    dArea += ` L ${mapX(t)} ${mapY(X_val)}`;
  }
  dArea += ` L ${mapX(72)} ${mapY(0)} Z`;

  svg += `<path d="${dArea}" fill="url(#biomassGrad)"/>`;
  svg += `<path d="${dPath}" fill="none" stroke="${C.cyan}" stroke-width="3.5" filter="url(#glow)"/>`;
  
  // Final harvest point
  svg += `<circle cx="${mapX(72)}" cy="${mapY(X_val)}" r="6" fill="${C.cyan}" stroke="#fff" stroke-width="2"/>`;
  svg += `<text x="${mapX(72)-10}" y="${mapY(X_val)-12}" fill="${C.cyan}" font-size="12" font-weight="bold" text-anchor="end">Cosecha = ${X_val.toFixed(2)} g/L</text>`;

  svg += `</svg>`;
  fs.writeFileSync(path.join(imgDir, 'plot_sim_biomasa.svg'), svg);
}

// 5, 6, 7. Sensores con Ruido
function generateNoisySignals() {
  const w = 550, h = 340;
  const N = 300;
  const mapX = (i) => 45 + (i / N) * (w - 70);

  // Helper gaussian
  const randn = () => {
    let u = 0, v = 0;
    while(u === 0) u = Math.random();
    while(v === 0) v = Math.random();
    return Math.sqrt(-2.0 * Math.log(u)) * Math.cos(2.0 * Math.PI * v);
  };

  // Temp
  let svgT = createSvgHeader(w, h, 'Sensor DS18B20: Temperatura + Ruido');
  const mapYT = (t) => (h - 40) - ((t - 24) / 6) * (h - 80);
  let dTIdeal = '', dTNoisy = '';
  for (let i = 0; i <= N; i++) {
    const sec = i / 6;
    const ideal = 26.5 + 1.2 * Math.sin(2 * Math.PI * sec / 50);
    const noisy = ideal + 0.35 * randn() + 0.15 * Math.sin(2 * Math.PI * 5 * sec);
    dTIdeal += (i === 0 ? `M ${mapX(i)} ${mapYT(ideal)}` : ` L ${mapX(i)} ${mapYT(ideal)}`);
    dTNoisy += (i === 0 ? `M ${mapX(i)} ${mapYT(noisy)}` : ` L ${mapX(i)} ${mapYT(noisy)}`);
  }
  svgT += `<path d="${dTNoisy}" fill="none" stroke="${C.red}" stroke-opacity="0.75" stroke-width="1.2"/>`;
  svgT += `<path d="${dTIdeal}" fill="none" stroke="${C.text}" stroke-width="2.2"/>`;
  svgT += `<text x="55" y="${h-15}" fill="${C.muted}" font-size="10">Tiempo [s]</text>`;
  svgT += `<text x="55" y="65" fill="${C.text}" font-size="10">Ideal vs Ruidosa (σ=0.35 + 50Hz)</text></svg>`;
  fs.writeFileSync(path.join(imgDir, 'plot_noise_t.svg'), svgT);

  // pH
  let svgPH = createSvgHeader(w, h, 'Electrodo pH-4502C: Outliers por Burbujeo');
  const mapYPH = (ph) => (h - 40) - ((ph - 6.5) / 3) * (h - 80);
  let dPHIdeal = '', dPHNoisy = '';
  for (let i = 0; i <= N; i++) {
    const sec = i / 6;
    const ideal = 7.6 + 0.2 * Math.sin(2 * Math.PI * sec / 50);
    let noisy = ideal + 0.05 * randn();
    if (Math.random() < 0.03) noisy += (Math.random() < 0.5 ? -1 : 1) * (0.8 + Math.random() * 1.0);
    dPHIdeal += (i === 0 ? `M ${mapX(i)} ${mapYPH(ideal)}` : ` L ${mapX(i)} ${mapYPH(ideal)}`);
    dPHNoisy += (i === 0 ? `M ${mapX(i)} ${mapYPH(noisy)}` : ` L ${mapX(i)} ${mapYPH(noisy)}`);
  }
  svgPH += `<path d="${dPHNoisy}" fill="none" stroke="${C.red}" stroke-opacity="0.75" stroke-width="1.2"/>`;
  svgPH += `<path d="${dPHIdeal}" fill="none" stroke="${C.text}" stroke-width="2.2"/>`;
  svgPH += `<text x="55" y="${h-15}" fill="${C.muted}" font-size="10">Tiempo [s]</text>`;
  svgPH += `<text x="55" y="65" fill="${C.text}" font-size="10">Ideal vs 3% Outliers de Burbujas</text></svg>`;
  fs.writeFileSync(path.join(imgDir, 'plot_noise_ph.svg'), svgPH);

  // Light
  let svgI = createSvgHeader(w, h, 'Sensor de Radiación: Nubes y Ruido');
  const mapYI = (rad) => (h - 40) - (rad / 900) * (h - 80);
  let dIIdeal = '', dINoisy = '';
  for (let i = 0; i <= N; i++) {
    const sec = i / 6;
    const ideal = 750 * Math.max(0, Math.sin(2 * Math.PI * sec / 45));
    let noisy = Math.max(0, ideal + 25 * randn());
    if ((sec > 10 && sec < 15) || (sec > 28 && sec < 32)) noisy *= 0.45;
    dIIdeal += (i === 0 ? `M ${mapX(i)} ${mapYI(ideal)}` : ` L ${mapX(i)} ${mapYI(ideal)}`);
    dINoisy += (i === 0 ? `M ${mapX(i)} ${mapYI(noisy)}` : ` L ${mapX(i)} ${mapYI(noisy)}`);
  }
  svgI += `<path d="${dINoisy}" fill="none" stroke="${C.red}" stroke-opacity="0.75" stroke-width="1.2"/>`;
  svgI += `<path d="${dIIdeal}" fill="none" stroke="${C.text}" stroke-width="2.2"/>`;
  svgI += `<text x="55" y="${h-15}" fill="${C.muted}" font-size="10">Tiempo [s]</text>`;
  svgI += `<text x="55" y="65" fill="${C.text}" font-size="10">Ideal vs Nubes y Ruido Gaussiano</text></svg>`;
  fs.writeFileSync(path.join(imgDir, 'plot_noise_i.svg'), svgI);
}

// 8. Filtro IIR (EMA)
function generateFilterT() {
  const w = 650, h = 380;
  let svg = createSvgHeader(w, h, 'Filtro IIR (EMA, α=0.1) — Sensor de Temperatura');
  const N = 250;
  const mapX = (i) => 45 + (i / N) * (w - 70);
  const mapY = (t) => (h - 40) - ((t - 24) / 6) * (h - 80);

  const randn = () => {
    let u = 0, v = 0;
    while(u === 0) u = Math.random();
    while(v === 0) v = Math.random();
    return Math.sqrt(-2.0 * Math.log(u)) * Math.cos(2.0 * Math.PI * v);
  };

  let dNoisy = '', dFilt = '', dIdeal = '';
  let y_prev = 26.5;
  for (let i = 0; i <= N; i++) {
    const sec = i / 5;
    const ideal = 26.5 + 1.2 * Math.sin(2 * Math.PI * sec / 50);
    const noisy = ideal + 0.35 * randn() + 0.15 * Math.sin(2 * Math.PI * 5 * sec);
    const filt = 0.1 * noisy + 0.9 * y_prev;
    y_prev = filt;
    dNoisy += (i === 0 ? `M ${mapX(i)} ${mapY(noisy)}` : ` L ${mapX(i)} ${mapY(noisy)}`);
    dFilt += (i === 0 ? `M ${mapX(i)} ${mapY(filt)}` : ` L ${mapX(i)} ${mapY(filt)}`);
    dIdeal += (i === 0 ? `M ${mapX(i)} ${mapY(ideal)}` : ` L ${mapX(i)} ${mapY(ideal)}`);
  }

  svg += `<path d="${dNoisy}" fill="none" stroke="${C.red}" stroke-opacity="0.5" stroke-width="1.0"/>`;
  svg += `<path d="${dFilt}" fill="none" stroke="${C.green}" stroke-width="2.8" filter="url(#glow)"/>`;
  svg += `<path d="${dIdeal}" fill="none" stroke="${C.text}" stroke-width="1.5" stroke-dasharray="4,4"/>`;

  svg += `<g transform="translate(55, ${h-70})">
    <rect width="280" height="24" rx="4" fill="${C.axes}" stroke="${C.grid}" stroke-width="1"/>
    <line x1="10" y1="12" x2="28" y2="12" stroke="${C.red}" stroke-width="1.2"/>
    <text x="34" y="15" fill="${C.muted}" font-size="9.5">Con Ruido</text>
    <line x1="105" y1="12" x2="125" y2="12" stroke="${C.green}" stroke-width="2.8"/>
    <text x="130" y="15" fill="${C.green}" font-size="9.5">Filtrada IIR (α=0.1)</text>
  </g></svg>`;
  fs.writeFileSync(path.join(imgDir, 'plot_filter_t.svg'), svg);
}

// 9. Filtro STM pH
function generateFilterPH() {
  const w = 650, h = 380;
  let svg = createSvgHeader(w, h, 'Filtro STM (Sorted Trimmed Mean, W=21, Trim=20%) — pH');
  const N = 250;
  const mapX = (i) => 45 + (i / N) * (w - 70);
  const mapY = (ph) => (h - 40) - ((ph - 6.0) / 4) * (h - 80);

  const randn = () => {
    let u = 0, v = 0;
    while(u === 0) u = Math.random();
    while(v === 0) v = Math.random();
    return Math.sqrt(-2.0 * Math.log(u)) * Math.cos(2.0 * Math.PI * v);
  };

  const raw = [], idealArr = [];
  for (let i = 0; i <= N; i++) {
    const sec = i / 5;
    const ideal = 7.6 + 0.25 * Math.sin(2 * Math.PI * sec / 50);
    let n = ideal + 0.05 * randn();
    if (Math.random() < 0.035) n += (Math.random() < 0.5 ? -1 : 1) * (0.8 + Math.random() * 1.2);
    idealArr.push(ideal);
    raw.push(n);
  }

  let dNoisy = '', dFilt = '', dIdeal = '';
  for (let i = 0; i <= N; i++) {
    const start = Math.max(0, i - 10), end = Math.min(N, i + 10);
    const win = raw.slice(start, end + 1).sort((a, b) => a - b);
    const trimCount = Math.floor(0.2 * win.length / 2);
    const trimmed = win.slice(trimCount, win.length - trimCount);
    const mean = trimmed.reduce((a, b) => a + b, 0) / trimmed.length;

    dNoisy += (i === 0 ? `M ${mapX(i)} ${mapY(raw[i])}` : ` L ${mapX(i)} ${mapY(raw[i])}`);
    dFilt += (i === 0 ? `M ${mapX(i)} ${mapY(mean)}` : ` L ${mapX(i)} ${mapY(mean)}`);
    dIdeal += (i === 0 ? `M ${mapX(i)} ${mapY(idealArr[i])}` : ` L ${mapX(i)} ${mapY(idealArr[i])}`);
  }

  svg += `<path d="${dNoisy}" fill="none" stroke="${C.red}" stroke-opacity="0.5" stroke-width="1.0"/>`;
  svg += `<path d="${dFilt}" fill="none" stroke="${C.purple}" stroke-width="2.8" filter="url(#glow)"/>`;
  svg += `<path d="${dIdeal}" fill="none" stroke="${C.text}" stroke-width="1.5" stroke-dasharray="4,4"/>`;

  svg += `<g transform="translate(55, ${h-70})">
    <rect width="290" height="24" rx="4" fill="${C.axes}" stroke="${C.grid}" stroke-width="1"/>
    <line x1="10" y1="12" x2="28" y2="12" stroke="${C.red}" stroke-width="1.2"/>
    <text x="34" y="15" fill="${C.muted}" font-size="9.5">Outliers de Burbujas</text>
    <line x1="140" y1="12" x2="160" y2="12" stroke="${C.purple}" stroke-width="2.8"/>
    <text x="166" y="15" fill="${C.purple}" font-size="9.5">Filtrada STM (W=21)</text>
  </g></svg>`;
  fs.writeFileSync(path.join(imgDir, 'plot_filter_ph.svg'), svg);
}

// 10. Filtro MA Luz
function generateFilterI() {
  const w = 650, h = 380;
  let svg = createSvgHeader(w, h, 'Filtro Promedio Móvil (MA, N=15) — Sensor de Luz');
  const N = 250;
  const mapX = (i) => 45 + (i / N) * (w - 70);
  const mapY = (rad) => (h - 40) - (rad / 900) * (h - 80);

  const randn = () => {
    let u = 0, v = 0;
    while(u === 0) u = Math.random();
    while(v === 0) v = Math.random();
    return Math.sqrt(-2.0 * Math.log(u)) * Math.cos(2.0 * Math.PI * v);
  };

  const raw = [], idealArr = [];
  for (let i = 0; i <= N; i++) {
    const sec = i / 5;
    const ideal = 750 * Math.max(0, Math.sin(2 * Math.PI * sec / 45));
    let n = Math.max(0, ideal + 25 * randn());
    if ((sec > 10 && sec < 15) || (sec > 28 && sec < 32)) n *= 0.45;
    idealArr.push(ideal);
    raw.push(n);
  }

  let dNoisy = '', dFilt = '', dIdeal = '';
  let sum = 0;
  for (let i = 0; i <= N; i++) {
    sum += raw[i];
    if (i >= 15) sum -= raw[i - 15];
    const ma = sum / Math.min(i + 1, 15);

    dNoisy += (i === 0 ? `M ${mapX(i)} ${mapY(raw[i])}` : ` L ${mapX(i)} ${mapY(raw[i])}`);
    dFilt += (i === 0 ? `M ${mapX(i)} ${mapY(ma)}` : ` L ${mapX(i)} ${mapY(ma)}`);
    dIdeal += (i === 0 ? `M ${mapX(i)} ${mapY(idealArr[i])}` : ` L ${mapX(i)} ${mapY(idealArr[i])}`);
  }

  svg += `<path d="${dNoisy}" fill="none" stroke="${C.red}" stroke-opacity="0.5" stroke-width="1.0"/>`;
  svg += `<path d="${dFilt}" fill="none" stroke="${C.orange}" stroke-width="2.8" filter="url(#glow)"/>`;
  svg += `<path d="${dIdeal}" fill="none" stroke="${C.text}" stroke-width="1.5" stroke-dasharray="4,4"/>`;

  svg += `<g transform="translate(55, ${h-70})">
    <rect width="280" height="24" rx="4" fill="${C.axes}" stroke="${C.grid}" stroke-width="1"/>
    <line x1="10" y1="12" x2="28" y2="12" stroke="${C.red}" stroke-width="1.2"/>
    <text x="34" y="15" fill="${C.muted}" font-size="9.5">Con Nubes y Ruido</text>
    <line x1="135" y1="12" x2="155" y2="12" stroke="${C.orange}" stroke-width="2.8"/>
    <text x="160" y="15" fill="${C.orange}" font-size="9.5">Filtrada MA (N=15)</text>
  </g></svg>`;
  fs.writeFileSync(path.join(imgDir, 'plot_filter_i.svg'), svg);
}

// Ejecutar todos
console.log('Generando SVGs de alta resolución para Pecha Kucha...');
generateCTMI();
generateSteele();
generateSimTemp();
generateSimBiomass();
generateNoisySignals();
generateFilterT();
generateFilterPH();
generateFilterI();
console.log('¡Todos los SVGs generados exitosamente en pecha-kucha-aluna/img/!');
