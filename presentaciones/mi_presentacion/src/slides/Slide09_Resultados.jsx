import { motion } from 'framer-motion';
import { InlineMath, BlockMath } from 'react-katex';
import { HelpCircle } from 'lucide-react';
import { useEffect } from 'react';
import anime from 'animejs';

export default function Slide09_Resultados() {
  useEffect(() => {
    const tl = anime.timeline({
      easing: 'easeOutExpo',
    });

    tl.add({
      targets: '.chart-line-1',
      strokeDashoffset: [anime.setDashoffset, 0],
      duration: 1500,
      delay: 500
    })
    .add({
      targets: '.chart-line-2',
      strokeDashoffset: [anime.setDashoffset, 0],
      duration: 1500,
    }, '-=1000')
    .add({
      targets: '.chart-line-3',
      strokeDashoffset: [anime.setDashoffset, 0],
      duration: 1500,
    }, '-=1000');
  }, []);

  return (
    <div className="w-full max-w-6xl h-full flex flex-col justify-center">
      <motion.h2 
        initial={{ opacity: 0, x: -50 }}
        animate={{ opacity: 1, x: 0 }}
        className="text-4xl md:text-5xl font-bold mb-8 border-l-4 border-electricBlue pl-6 text-slate-800"
      >
        ¿Qué quiero comprobar?
      </motion.h2>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-12">
        {/* Left Col: Graph (Conceptual) */}
        <motion.div 
          initial={{ opacity: 0, scale: 0.9 }}
          animate={{ opacity: 1, scale: 1 }}
          transition={{ delay: 0.2 }}
          className="bg-white p-6 rounded-xl border border-slate-200 shadow-sm relative flex flex-col"
        >
          <div className="absolute top-2 right-4 text-xs font-bold text-white uppercase tracking-widest bg-slate-800 px-2 py-1 rounded shadow-sm">
            Resultado esperado / Hipótesis
          </div>
          
          <h3 className="text-xl font-bold text-slate-800 mb-6">Proyección Teórica</h3>
          
          {/* Simple CSS-based Chart */}
          <div className="relative h-64 border-l-2 border-b-2 border-slate-300 flex items-end ml-4 pb-2">
            <span className="absolute -left-10 top-1/2 -rotate-90 text-sm text-slate-500 font-medium whitespace-nowrap">
              Productividad <InlineMath math="P(k)" />
            </span>
            <span className="absolute -bottom-8 left-1/2 -translate-x-1/2 text-sm text-slate-500 font-medium">
              Tiempo / semanas
            </span>

            {/* Line 1: Tradicional */}
            <svg className="absolute inset-0 w-full h-full overflow-visible" preserveAspectRatio="none">
              <path className="chart-line-1" d="M 0,250 Q 150,220 300,200 T 500,180" fill="transparent" stroke="#ea580c" strokeWidth="3" strokeDasharray="5,5" />
            </svg>
            
            {/* Line 2: IA */}
            <svg className="absolute inset-0 w-full h-full overflow-visible" preserveAspectRatio="none">
              <path className="chart-line-2" d="M 0,250 Q 150,180 300,120 T 500,80" fill="transparent" stroke="#0088cc" strokeWidth="3" />
            </svg>

            {/* Line 3: IA + Agentes */}
            <svg className="absolute inset-0 w-full h-full overflow-visible" preserveAspectRatio="none">
              <path className="chart-line-3" d="M 0,250 Q 150,150 300,50 T 500,20" fill="transparent" stroke="#9333ea" strokeWidth="4" />
            </svg>
          </div>

          {/* Legend */}
          <div className="mt-8 flex justify-around text-sm font-medium text-slate-600">
            <div className="flex items-center gap-2"><div className="w-4 h-1 bg-accentOrange border-b-2 border-dashed border-accentOrange"></div> Tradicional</div>
            <div className="flex items-center gap-2"><div className="w-4 h-1 bg-electricBlue"></div> IA</div>
            <div className="flex items-center gap-2"><div className="w-4 h-2 bg-accentPurple shadow-sm"></div> IA + Agentes</div>
          </div>
        </motion.div>

        {/* Right Col: Hypothesis and Questions */}
        <motion.div 
          initial={{ opacity: 0, x: 50 }}
          animate={{ opacity: 1, x: 0 }}
          transition={{ delay: 0.4 }}
          className="space-y-8"
        >
          <div className="bg-blue-50 p-6 rounded-xl border border-electricBlue shadow-[0_4px_14px_0_rgba(0,136,204,0.15)]">
            <h3 className="text-xl font-bold text-electricBlue mb-4">Hipótesis Principal</h3>
            <div className="text-xl flex justify-center text-slate-800">
              <BlockMath math={String.raw`P_{\text{IA+Agentes}} > P_{\text{IA}} > P_{\text{Tradicional}}`} />
            </div>
            <p className="text-center text-sm text-slate-500 mt-4 italic">
              * Esta relación debe comprobarse experimentalmente con datos reales.
            </p>
          </div>

          <div className="bg-white p-6 rounded-xl border border-slate-200 shadow-sm">
             <div className="flex items-center gap-2 mb-4">
               <HelpCircle className="text-slate-700" />
               <h3 className="text-lg font-bold text-slate-800">Preguntas Clave</h3>
             </div>
             <ul className="text-slate-600 space-y-3 font-medium">
               <li className="flex items-start gap-2">
                 <span className="text-electricBlue mt-1">▶</span>
                 <span>¿La IA realmente aumenta mi productividad a largo plazo?</span>
               </li>
               <li className="flex items-start gap-2">
                 <span className="text-electricBlue mt-1">▶</span>
                 <span>¿En qué tipo de tareas tiene mayor impacto?</span>
               </li>
               <li className="flex items-start gap-2">
                 <span className="text-electricBlue mt-1">▶</span>
                 <span>¿Cuánto tiempo neto puedo ahorrar?</span>
               </li>
               <li className="flex items-start gap-2">
                 <span className="text-electricBlue mt-1">▶</span>
                 <span>¿Qué tareas de desarrollo son mejores candidatas para automatización total?</span>
               </li>
             </ul>
          </div>
        </motion.div>
      </div>
    </div>
  );
}
