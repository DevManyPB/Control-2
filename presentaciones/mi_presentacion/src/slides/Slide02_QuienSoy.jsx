import { motion } from 'framer-motion';
import { User, Code2, Gamepad2, BrainCircuit, Cog } from 'lucide-react';
import { useEffect, useRef } from 'react';
import anime from 'animejs';

export default function Slide02_QuienSoy() {
  const iconsRef = useRef(null);

  useEffect(() => {
    anime({
      targets: '.stagger-icon',
      scale: [0.8, 1],
      opacity: [0, 1],
      delay: anime.stagger(150, {start: 500}),
      easing: 'easeOutElastic(1, .8)'
    });
  }, []);

  return (
    <div className="w-full max-w-6xl h-full flex flex-col justify-center">
      <motion.h2 
        initial={{ opacity: 0, x: -50 }}
        animate={{ opacity: 1, x: 0 }}
        className="text-4xl md:text-5xl font-bold mb-12 border-l-4 border-electricBlue pl-6 text-slate-800"
      >
        ¿Quién soy?
      </motion.h2>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-12 items-center">
        <motion.div 
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ delay: 0.3 }}
          className="text-xl md:text-2xl font-light leading-relaxed text-slate-700 bg-white p-10 rounded-2xl shadow-[0_8px_30px_rgb(0,0,0,0.04)] border border-slate-200 flex flex-col items-center text-center"
        >
          <div className="w-40 h-40 rounded-full overflow-hidden border-4 border-electricBlue shadow-md mb-8">
            <img src="/perfil.png" alt="Jhon Cárdenas" className="w-full h-full object-cover bg-slate-50" onError={(e) => e.target.style.display = 'none'} />
          </div>

          <p>
            "Soy estudiante de <strong className="text-electricBlue font-semibold">Ingeniería Electrónica</strong> y desarrollador, con profundo interés en <strong className="text-accentGreen font-semibold">programación</strong>, tecnología e <strong className="text-accentPurple font-semibold">Inteligencia Artificial</strong>."
          </p>
        </motion.div>

        <div ref={iconsRef} className="grid grid-cols-2 gap-6">
          <div className="stagger-icon opacity-0 flex flex-col items-center justify-center p-6 bg-white shadow-sm border border-slate-200 rounded-xl hover:border-electricBlue hover:shadow-md transition-all">
            <User size={48} className="text-electricBlue mb-4" />
            <span className="text-center font-medium text-slate-600">Ingeniería<br/>Electrónica</span>
          </div>
          
          <div className="stagger-icon opacity-0 flex flex-col items-center justify-center p-6 bg-white shadow-sm border border-slate-200 rounded-xl hover:border-accentGreen hover:shadow-md transition-all">
            <Code2 size={48} className="text-accentGreen mb-4" />
            <span className="text-center font-medium text-slate-600">Programación</span>
          </div>
          
          <div className="stagger-icon opacity-0 flex flex-col items-center justify-center p-6 bg-white shadow-sm border border-slate-200 rounded-xl hover:border-accentOrange hover:shadow-md transition-all">
            <Gamepad2 size={48} className="text-accentOrange mb-4" />
            <span className="text-center font-medium text-slate-600">Roblox Studio</span>
          </div>
          
          <div className="stagger-icon opacity-0 flex flex-col items-center justify-center p-6 bg-white shadow-sm border border-slate-200 rounded-xl hover:border-accentPurple hover:shadow-md transition-all">
            <BrainCircuit size={48} className="text-accentPurple mb-4" />
            <span className="text-center font-medium text-slate-600">Inteligencia<br/>Artificial</span>
          </div>

          <div className="stagger-icon opacity-0 col-span-2 flex flex-col items-center justify-center p-6 bg-white shadow-sm border border-slate-200 rounded-xl hover:border-slate-400 hover:shadow-md transition-all">
            <Cog size={48} className="text-slate-400 mb-4 animate-spin-slow" style={{ animationDuration: '4s' }} />
            <span className="text-center font-medium text-slate-600">Automatización</span>
          </div>
        </div>
      </div>
    </div>
  );
}
