import { motion } from 'framer-motion';
import { Target, Lightbulb, Heart, Wrench, Users, Info, Quote, BrainCircuit, Code2, Cpu } from 'lucide-react';
import { useEffect, useRef } from 'react';
import anime from 'animejs';

export default function Slide03_MyWorldMap() {
  const mapRef = useRef(null);

  useEffect(() => {
    const tl = anime.timeline({
      easing: 'easeOutElastic(1, .8)',
    });

    tl.add({
      targets: '.center-node',
      scale: [0, 1],
      opacity: [0, 1],
      duration: 800,
    })
    .add({
      targets: '.map-node',
      translateY: [20, 0],
      opacity: [0, 1],
      duration: 600,
      delay: anime.stagger(100)
    }, '-=400');
  }, []);

  return (
    <div className="w-full max-w-7xl h-full flex flex-col justify-center items-center py-4" ref={mapRef}>
      <motion.h2 
        initial={{ opacity: 0, y: -20 }}
        animate={{ opacity: 1, y: 0 }}
        className="text-3xl md:text-4xl font-bold mb-6 tracking-wider text-center text-slate-800 flex items-center justify-center gap-4"
      >
        <span className="text-electricBlue">-</span> MY WORLD MAP <span className="text-electricBlue">-</span>
      </motion.h2>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-4 w-full h-[75vh] overflow-y-auto pr-2 pb-12 custom-scrollbar">
        
        {/* Left Column */}
        <div className="flex flex-col gap-4">
          {/* Mis Fortalezas */}
          <div className="map-node opacity-0 bg-white border-2 border-accentPurple/50 rounded-2xl p-4 shadow-sm relative overflow-hidden">
            <div className="absolute top-0 left-0 w-1 h-full bg-accentPurple"></div>
            <div className="flex items-center gap-2 mb-3">
              <Lightbulb className="text-accentPurple" size={20} />
              <h3 className="font-bold text-accentPurple">Mis Fortalezas</h3>
            </div>
            <ul className="text-sm text-slate-600 space-y-2">
              <li className="flex items-start gap-2"><div className="mt-1"><BrainCircuit size={14} className="text-accentPurple"/></div> Resolución de problemas y lógica</li>
              <li className="flex items-start gap-2"><div className="mt-1"><Zap size={14} className="text-accentPurple"/></div> Aprendizaje rápido y perseverancia</li>
              <li className="flex items-start gap-2"><div className="mt-1"><Code2 size={14} className="text-accentPurple"/></div> Creatividad y Programación</li>
            </ul>
          </div>

          {/* Lo que más me importa */}
          <div className="map-node opacity-0 bg-white border-2 border-red-400/50 rounded-2xl p-4 shadow-sm relative overflow-hidden">
            <div className="absolute top-0 left-0 w-1 h-full bg-red-400"></div>
            <div className="flex items-center gap-2 mb-3">
              <Heart className="text-red-400" size={20} />
              <h3 className="font-bold text-red-500">Lo que más me importa</h3>
            </div>
            <ul className="text-sm text-slate-600 space-y-2">
              <li>• Mi familia</li>
              <li>• Mi crecimiento personal y profesional</li>
              <li>• Terminar mi carrera universitaria</li>
              <li>• Crear proyectos de calidad y con impacto</li>
              <li>• Vivir de lo que me apasiona</li>
            </ul>
          </div>

          {/* Mis Herramientas */}
          <div className="map-node opacity-0 bg-white border-2 border-electricBlue/50 rounded-2xl p-4 shadow-sm relative overflow-hidden">
            <div className="absolute top-0 left-0 w-1 h-full bg-electricBlue"></div>
            <div className="flex items-center gap-2 mb-3">
              <Wrench className="text-electricBlue" size={20} />
              <h3 className="font-bold text-electricBlue">Mis Herramientas & Lenguajes</h3>
            </div>
            <div className="grid grid-cols-2 gap-4 text-sm text-slate-600">
              <div>
                <strong className="text-slate-800 text-xs uppercase tracking-wider block mb-1 border-b border-slate-100 pb-1">Lenguajes</strong>
                <ul className="space-y-1">
                  <li>• Python</li>
                  <li>• JavaScript</li>
                  <li>• Luau</li>
                  <li>• C++ (Básico)</li>
                </ul>
              </div>
              <div>
                <strong className="text-slate-800 text-xs uppercase tracking-wider block mb-1 border-b border-slate-100 pb-1">Tecnologías</strong>
                <ul className="space-y-1">
                  <li>• VS Code & Linux</li>
                  <li>• GitHub & Obsidian</li>
                  <li>• MATLAB & Proteus</li>
                  <li>• Antigravity & OpenCode</li>
                </ul>
              </div>
            </div>
          </div>
        </div>

        {/* Center Column */}
        <div className="flex flex-col gap-4">
          {/* Mis Metas */}
          <div className="map-node opacity-0 bg-white border-2 border-accentGreen/50 rounded-2xl p-4 shadow-sm relative overflow-hidden">
            <div className="absolute top-0 left-0 w-1 h-full bg-accentGreen"></div>
            <div className="flex items-center gap-2 mb-3 justify-center">
              <Target className="text-accentGreen" size={20} />
              <h3 className="font-bold text-accentGreen">Mis Metas</h3>
            </div>
            <div className="grid grid-cols-2 gap-4 text-sm">
              <div className="bg-slate-50 p-2 rounded border border-slate-100">
                <strong className="text-slate-700 block mb-2 text-center text-xs uppercase">Corto Plazo</strong>
                <ul className="text-slate-600 space-y-2 text-xs">
                  <li>✅ Graduarme como Ing. Electrónico (~1 año)</li>
                  <li>✅ Profundizar en automatización con IA</li>
                </ul>
              </div>
              <div className="bg-slate-50 p-2 rounded border border-slate-100">
                <strong className="text-slate-700 block mb-2 text-center text-xs uppercase">Largo Plazo</strong>
                <ul className="text-slate-600 space-y-2 text-xs">
                  <li>✅ Tener desarrollo profesional exitoso</li>
                  <li>✅ Automatizar procesos y herramientas con agentes IA</li>
                </ul>
              </div>
            </div>
          </div>

          {/* Center Avatar */}
          <div className="center-node opacity-0 flex-1 min-h-[200px] flex flex-col items-center justify-center bg-slate-50 rounded-3xl border-4 border-slate-200 shadow-inner p-6 relative overflow-hidden">
            <div className="absolute -top-10 -right-10 w-32 h-32 bg-electricBlue/5 rounded-full blur-2xl"></div>
            <div className="absolute -bottom-10 -left-10 w-32 h-32 bg-accentPurple/5 rounded-full blur-2xl"></div>
            
            <div className="w-28 h-28 rounded-full overflow-hidden border-4 border-electricBlue shadow-sm mb-4 z-10 bg-white">
              <img src="/perfil.png" alt="Jhon Cárdenas" className="w-full h-full object-cover bg-slate-50" onError={(e) => e.target.style.display = 'none'} />
            </div>
            
            <h2 className="text-2xl font-bold text-slate-800 mb-1 z-10 text-center">Jhon Cárdenas</h2>
            <span className="text-electricBlue font-medium text-sm z-10 text-center">Estudiante de Ing. Electrónica</span>
          </div>

          {/* Quote */}
          <div className="map-node opacity-0 bg-[#fff9c4] border border-[#fbc02d] rounded-sm p-4 shadow-sm text-center relative rotate-1">
             <div className="absolute top-[-10px] left-1/2 transform -translate-x-1/2 w-8 h-4 bg-slate-300/50 backdrop-blur-sm"></div>
             <Quote className="text-slate-400 mx-auto mb-2 opacity-50" size={16} />
             <p className="text-slate-700 font-medium text-sm italic">
               "La tecnología no solo es el futuro, es la herramienta para crear un mundo mejor."
             </p>
          </div>
        </div>

        {/* Right Column */}
        <div className="flex flex-col gap-4">
          {/* Mis Intereses */}
          <div className="map-node opacity-0 bg-white border-2 border-cyan-500/50 rounded-2xl p-4 shadow-sm relative overflow-hidden">
            <div className="absolute top-0 left-0 w-1 h-full bg-cyan-500"></div>
            <div className="flex items-center gap-2 mb-3">
              <Cpu className="text-cyan-600" size={20} />
              <h3 className="font-bold text-cyan-700">Mis Intereses</h3>
            </div>
            <ul className="text-sm text-slate-600 space-y-2 grid grid-cols-2 gap-x-2">
              <li className="col-span-2">• Programación y Tecnología</li>
              <li className="col-span-2">• IA y Automatización</li>
              <li>• Linux</li>
              <li>• Roblox Studio</li>
              <li>• Matemáticas</li>
              <li>• Ingeniería</li>
            </ul>
          </div>

          {/* Trabajo en equipo */}
          <div className="map-node opacity-0 bg-white border-2 border-slate-400/50 rounded-2xl p-4 shadow-sm relative overflow-hidden">
            <div className="absolute top-0 left-0 w-1 h-full bg-slate-400"></div>
            <div className="flex items-center gap-2 mb-3">
              <Users className="text-slate-600" size={20} />
              <h3 className="font-bold text-slate-700">Cómo prefiero trabajar en equipo</h3>
            </div>
            <ul className="text-sm text-slate-600 space-y-2">
              <li>• Con personas responsables</li>
              <li>• Comunicación clara</li>
              <li>• Cada integrante con un rol definido</li>
              <li>• Compartir ideas y recibir retroalimentación</li>
              <li>• Ambiente de respeto y confianza</li>
            </ul>
          </div>

          {/* Lo que quiero que otros sepan */}
          <div className="map-node opacity-0 bg-white border-2 border-accentOrange/50 rounded-2xl p-4 shadow-sm relative overflow-hidden">
            <div className="absolute top-0 left-0 w-1 h-full bg-accentOrange"></div>
            <div className="flex items-center gap-2 mb-3">
              <Info className="text-accentOrange" size={20} />
              <h3 className="font-bold text-accentOrange">Lo que quiero que sepan de mí</h3>
            </div>
            <ul className="text-sm text-slate-600 space-y-2">
              <li>• Me esfuerzo por hacer las cosas bien.</li>
              <li>• No me rindo fácilmente.</li>
              <li>• Siempre estoy buscando aprender.</li>
              <li>• Me gusta crear proyectos que sean útiles.</li>
            </ul>
          </div>
        </div>

      </div>
    </div>
  );
}

const Zap = ({size, className}) => (
  <svg xmlns="http://www.w3.org/2000/svg" width={size} height={size} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className={className}><polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2"></polygon></svg>
)
