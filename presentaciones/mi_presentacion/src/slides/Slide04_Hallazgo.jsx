import { motion } from 'framer-motion';
import { Clock, ArrowDown, CheckSquare, Code, Bot, TrendingUp } from 'lucide-react';
import { useEffect } from 'react';
import anime from 'animejs';

export default function Slide04_Hallazgo() {
  useEffect(() => {
    anime({
      targets: '.chain-node',
      scale: [0.8, 1],
      opacity: [0, 1],
      delay: anime.stagger(150, {start: 800}),
      easing: 'easeOutElastic(1, .8)'
    });
  }, []);

  return (
    <div className="w-full max-w-6xl h-full flex flex-col justify-center">
      <motion.h2 
        initial={{ opacity: 0, x: -50 }}
        animate={{ opacity: 1, x: 0 }}
        className="text-4xl md:text-5xl font-bold mb-8 border-l-4 border-electricBlue pl-6 text-slate-800"
      >
        El hallazgo
      </motion.h2>

      <div className="grid grid-cols-1 md:grid-cols-5 gap-8 items-center">
        
        {/* Left Side: Observation & Question */}
        <div className="md:col-span-3 space-y-6">
          <motion.div 
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.2 }}
            className="bg-white p-6 rounded-xl shadow-sm border border-slate-200"
          >
            <p className="text-lg text-slate-600 font-light leading-relaxed">
              "Mi capacidad para desarrollar proyectos está limitada no solamente por mis conocimientos, sino también por el <strong className="text-electricBlue font-semibold">tiempo necesario para ejecutar</strong> todas las tareas que componen un proyecto."
            </p>
          </motion.div>

          <motion.div 
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.6 }}
            className="bg-blue-50 p-6 rounded-xl border border-electricBlue shadow-[0_4px_14px_0_rgba(0,136,204,0.15)]"
          >
            <h3 className="text-xl font-bold text-slate-800 mb-2">Pregunta central:</h3>
            <p className="text-lg text-electricBlue font-medium">
              "¿Puede la automatización mediante agentes de IA aumentar mi productividad sin aumentar proporcionalmente el tiempo de trabajo?"
            </p>
          </motion.div>
        </div>

        {/* Right Side: The Chain - compact horizontal layout */}
        <div className="md:col-span-2 flex flex-col items-center gap-1 py-4 bg-slate-50/50 rounded-2xl border border-slate-100">
          {[
            { icon: Clock, label: "TIEMPO", color: "text-slate-400", border: "border-slate-200" },
            { icon: CheckSquare, label: "TAREAS", color: "text-accentOrange", border: "border-accentOrange" },
            { icon: Code, label: "DESARROLLO", color: "text-accentGreen", border: "border-accentGreen" },
            { icon: Bot, label: "AUTOMATIZACIÓN", color: "text-accentPurple", border: "border-accentPurple" },
            { icon: TrendingUp, label: "PRODUCTIVIDAD", color: "text-electricBlue", border: "border-electricBlue", highlight: true },
          ].map((item, idx, arr) => (
            <div key={idx} className="chain-node opacity-0 flex flex-col items-center">
              <div className={`bg-white p-3 rounded-full shadow-sm border ${item.border} ${item.highlight ? 'shadow-[0_4px_14px_0_rgba(0,136,204,0.15)] bg-blue-50' : ''}`}>
                <item.icon size={24} className={item.color} />
              </div>
              <span className={`font-bold tracking-widest ${item.color} text-xs mt-1`}>{item.label}</span>
              {idx < arr.length - 1 && (
                <ArrowDown size={16} className="text-slate-300 my-0.5" />
              )}
            </div>
          ))}
        </div>

      </div>
    </div>
  );
}
