import { motion } from 'framer-motion';
import { BlockMath, InlineMath } from 'react-katex';
import { useEffect } from 'react';
import anime from 'animejs';

export default function Slide06_ModeloMatematico() {
  useEffect(() => {
    anime({
      targets: '.eq-item',
      scale: [0.9, 1],
      opacity: [0, 1],
      delay: anime.stagger(150, {start: 300}),
      easing: 'easeOutBack'
    });
  }, []);

  return (
    <div className="w-full max-w-7xl h-full flex flex-col justify-center">
      <motion.h2 
        initial={{ opacity: 0, x: -50 }}
        animate={{ opacity: 1, x: 0 }}
        className="text-4xl md:text-5xl font-bold mb-8 border-l-4 border-electricBlue pl-6 text-slate-800"
      >
        Modelo dinámico
      </motion.h2>

      <div className="grid grid-cols-1 lg:grid-cols-5 gap-6 items-start">
        {/* Equations - Left (3 cols) */}
        <div className="lg:col-span-2 space-y-3">
          <div className="eq-item opacity-0 bg-white p-3 rounded-xl border border-slate-200 shadow-sm hover:border-electricBlue hover:shadow-md transition-all">
            <BlockMath math={String.raw`\frac{dE}{dt} = k_E H(t) - \delta_E E(t)`} />
          </div>
          <div className="eq-item opacity-0 bg-white p-3 rounded-xl border border-slate-200 shadow-sm hover:border-accentGreen hover:shadow-md transition-all">
            <BlockMath math={String.raw`\frac{dL}{dt} = k_L H(t) - \delta_L L(t)`} />
          </div>
          <div className="eq-item opacity-0 bg-white p-3 rounded-xl border border-slate-200 shadow-sm hover:border-accentPurple hover:shadow-md transition-all">
            <BlockMath math={String.raw`\frac{dA}{dt} = k_A I(t) - \delta_A A(t)`} />
          </div>

          <div className="eq-item opacity-0 mt-2 grid grid-cols-2 gap-4 text-sm text-slate-600 bg-slate-50 p-3 rounded-xl border border-slate-200">
            <div>
              <p><InlineMath math="H(t)" />: horas de práctica/trabajo.</p>
              <p><InlineMath math="I(t)" />: tiempo en IA y automatización.</p>
            </div>
            <div>
              <p><InlineMath math={String.raw`k_E, k_L, k_A`} />: tasas de aprendizaje.</p>
              <p><InlineMath math={String.raw`\delta_E, \delta_L, \delta_A`} />: degradación.</p>
            </div>
          </div>
        </div>

        {/* Main Equation - Right (3 cols) */}
        <motion.div 
          initial={{ opacity: 0, x: 50 }}
          animate={{ opacity: 1, x: 0 }}
          transition={{ delay: 0.8 }}
          className="lg:col-span-3 flex flex-col h-full justify-center"
        >
          <div className="bg-blue-50/80 p-6 rounded-2xl border-2 border-electricBlue/50 shadow-md relative">
            <div className="absolute top-0 right-0 w-32 h-32 bg-electricBlue/10 blur-[30px] -mr-16 -mt-16 rounded-full pointer-events-none"></div>
            
            <h3 className="text-lg font-bold text-slate-800 mb-4 text-center">
              Ecuación de Productividad Principal
            </h3>
            
            <div className="text-lg md:text-xl w-full">
              <BlockMath math={String.raw`P(t) = \frac{B \cdot (1+E(t)) \cdot (1+L(t)) \cdot (1+A(t))}{C(t)}`} />
            </div>

            <div className="space-y-2 text-slate-700 border-t border-blue-200 pt-4 mt-4">
              <p className="flex items-center gap-3">
                <span className="w-2 h-2 rounded-full bg-accentOrange"></span>
                <InlineMath math="B" /> = capacidad base inicial.
              </p>
              <p className="flex items-center gap-3">
                <span className="w-2 h-2 rounded-full bg-accentGreen"></span>
                <InlineMath math="C(t)" /> = complejidad del proyecto.
              </p>
            </div>
          </div>
        </motion.div>
      </div>
    </div>
  );
}
