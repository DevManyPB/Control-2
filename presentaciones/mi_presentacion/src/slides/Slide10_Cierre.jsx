import { motion } from 'framer-motion';
import { Search, BarChart2, Zap, Terminal } from 'lucide-react';
import { useEffect } from 'react';
import anime from 'animejs';

export default function Slide10_Cierre() {
  useEffect(() => {
    anime({
      targets: '.final-item',
      translateY: [20, 0],
      opacity: [0, 1],
      delay: anime.stagger(200, {start: 500}),
      easing: 'easeOutQuad'
    });
  }, []);

  return (
    <div className="w-full max-w-6xl h-full flex flex-col justify-center items-center text-center">
      <motion.h2 
        initial={{ opacity: 0, y: -20 }}
        animate={{ opacity: 1, y: 0 }}
        className="text-4xl md:text-5xl font-bold mb-8 text-slate-800"
      >
        ¿Qué espero aprender sobre mí?
      </motion.h2>

      <motion.p 
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ delay: 0.2 }}
        className="text-xl text-slate-600 font-medium mb-12 max-w-4xl mx-auto"
      >
        "Quiero descubrir cómo cambia mi productividad cuando incorporo Inteligencia Artificial y automatización a mi proceso de desarrollo."
      </motion.p>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-8 w-full mb-16">
        <div className="final-item opacity-0 bg-white border border-slate-200 shadow-sm p-8 rounded-xl hover:border-electricBlue hover:shadow-md transition-all group">
          <div className="flex justify-center mb-6">
            <div className="bg-blue-50 p-4 rounded-full group-hover:scale-110 transition-transform">
              <Search className="text-electricBlue" size={32} />
            </div>
          </div>
          <p className="text-slate-700 font-medium">
            "Identificar qué actividades puedo automatizar."
          </p>
        </div>

        <div className="final-item opacity-0 bg-white border border-slate-200 shadow-sm p-8 rounded-xl hover:border-accentGreen hover:shadow-md transition-all group">
          <div className="flex justify-center mb-6">
            <div className="bg-green-50 p-4 rounded-full group-hover:scale-110 transition-transform">
              <BarChart2 className="text-accentGreen" size={32} />
            </div>
          </div>
          <p className="text-slate-700 font-medium">
            "Medir cuantitativamente el impacto de la IA sobre mi productividad."
          </p>
        </div>

        <div className="final-item opacity-0 bg-white border border-slate-200 shadow-sm p-8 rounded-xl hover:border-accentPurple hover:shadow-md transition-all group">
          <div className="flex justify-center mb-6">
            <div className="bg-purple-50 p-4 rounded-full group-hover:scale-110 transition-transform">
              <Zap className="text-accentPurple" size={32} />
            </div>
          </div>
          <p className="text-slate-700 font-medium">
            "Entender cómo puedo utilizar la IA como una extensión de mis capacidades."
          </p>
        </div>
      </div>

      <motion.div 
        initial={{ opacity: 0, scale: 0.9 }}
        animate={{ opacity: 1, scale: 1 }}
        transition={{ delay: 1.2, duration: 0.8 }}
        className="relative py-8 px-12 bg-white rounded-2xl border border-slate-200 shadow-md overflow-hidden"
      >
        <div className="absolute inset-0 bg-gradient-to-r from-blue-50 via-transparent to-purple-50"></div>
        <h3 className="text-2xl md:text-3xl font-bold text-slate-800 relative z-10 leading-tight">
          "No busco reemplazar mi trabajo con IA, <br/>
          <span className="text-electricBlue drop-shadow-sm">sino ampliar lo que soy capaz de construir con ella.</span>"
        </h3>
      </motion.div>

      <motion.div 
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ delay: 1.8 }}
        className="mt-16 text-center space-y-1"
      >
        <div className="text-xl font-bold tracking-widest text-slate-800">Jhon Cárdenas</div>
        <div className="text-sm text-slate-500 font-medium">Ingeniería Electrónica</div>
        <div className="text-sm font-bold text-accentOrange">DevManyPB</div>
      </motion.div>
    </div>
  );
}
