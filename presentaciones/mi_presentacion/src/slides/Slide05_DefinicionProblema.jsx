import { motion } from 'framer-motion';
import { BlockMath, InlineMath } from 'react-katex';
import { useEffect } from 'react';
import anime from 'animejs';

export default function Slide05_DefinicionProblema() {
  useEffect(() => {
    anime({
      targets: '.math-block',
      translateY: [20, 0],
      opacity: [0, 1],
      delay: anime.stagger(200, {start: 300}),
      easing: 'easeOutQuad'
    });
  }, []);

  return (
    <div className="w-full max-w-6xl h-full flex flex-col justify-center">
      <motion.h2 
        initial={{ opacity: 0, x: -50 }}
        animate={{ opacity: 1, x: 0 }}
        className="text-4xl md:text-5xl font-bold mb-10 border-l-4 border-electricBlue pl-6 text-slate-800"
      >
        Del problema al modelo
      </motion.h2>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
        {/* Left Column: Output and Error */}
        <div className="space-y-6">
          <div className="math-block opacity-0 bg-white p-6 rounded-xl shadow-sm border border-slate-200">
            <h3 className="text-xl font-bold text-electricBlue mb-4">Variable de salida</h3>
            <BlockMath math="y(k) = P(k)" />
            <p className="text-slate-600 mt-2">
              donde <InlineMath math="P(k)" /> = productividad durante el periodo <InlineMath math="k" />.
            </p>
          </div>

          <div className="math-block opacity-0 bg-white p-6 rounded-xl shadow-sm border border-slate-200">
            <h3 className="text-xl font-bold text-accentGreen mb-4">Referencia y Error</h3>
            <p className="text-slate-600 mb-2">Referencia:</p>
            <BlockMath math={String.raw`r(k) = P_{\text{objetivo}}`} />
            
            <p className="text-slate-600 mt-4 mb-2">Error del sistema:</p>
            <BlockMath math={String.raw`e(k) = r(k) - y(k)`} />
          </div>
        </div>

        {/* Right Column: State Variables and Block Diagram */}
        <div className="space-y-6">
          <div className="math-block opacity-0 bg-purple-50/50 p-6 rounded-xl shadow-sm border border-accentPurple/30">
            <h3 className="text-xl font-bold text-accentPurple mb-4">Variables de estado</h3>
            <BlockMath math={String.raw`x(k) = \begin{bmatrix} E(k) \\ L(k) \\ A(k) \end{bmatrix}`} />
            
            <ul className="text-slate-600 mt-4 space-y-3">
              <li>
                <InlineMath math="E(k)" /> = experiencia acumulada.
              </li>
              <li>
                <InlineMath math="L(k)" /> = nivel de aprendizaje/conocimiento.
              </li>
              <li>
                <InlineMath math="A(k)" /> = nivel de automatización mediante IA.
              </li>
            </ul>
          </div>
        </div>
      </div>
      
      {/* Abstract Block Diagram at the bottom */}
      <motion.div 
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ delay: 0.8 }}
        className="mt-12 flex justify-center items-center space-x-4 opacity-90"
      >
         <div className="text-accentGreen font-semibold"><InlineMath math="r(k)" /></div>
         <div className="h-0.5 w-12 bg-accentGreen relative"><div className="absolute right-0 -top-1 w-2 h-2 bg-accentGreen rotate-45 transform origin-center border-t border-r"></div></div>
         
         <div className="w-12 h-12 rounded-full border-2 border-slate-400 bg-white flex items-center justify-center relative shadow-sm">
           <span className="absolute left-2 text-slate-600 font-bold">+</span>
           <span className="absolute bottom-1 text-slate-600 font-bold">-</span>
         </div>
         
         <div className="h-0.5 w-12 bg-slate-400 relative">
            <div className="absolute bottom-2 left-2 text-slate-600 font-medium"><InlineMath math={String.raw`e(k)`} /></div>
            <div className="absolute right-0 -top-1 w-2 h-2 bg-slate-400 rotate-45 transform origin-center border-t border-r"></div>
         </div>
         
         <div className="bg-white border-2 border-accentPurple shadow-sm p-4 text-center rounded-md text-slate-700">
           <span className="font-semibold block mb-1">Sistema de Productividad</span>
           <InlineMath math={String.raw`x(k+1) = \Phi x(k) + \Gamma u(k)`} />
         </div>
         
         <div className="h-0.5 w-16 bg-electricBlue relative">
           <div className="absolute right-0 -top-1 w-2 h-2 bg-electricBlue rotate-45 transform origin-center border-t border-r"></div>
         </div>
         <div className="text-electricBlue font-bold"><InlineMath math="y(k)" /></div>
      </motion.div>
    </div>
  );
}
