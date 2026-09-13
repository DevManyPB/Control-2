import { motion } from 'framer-motion';
import { Terminal, Cpu, Network, Bot } from 'lucide-react';
import { useEffect, useRef } from 'react';
import anime from 'animejs';

export default function Slide01_Portada() {
  const titleRef = useRef(null);

  useEffect(() => {
    anime({
      targets: titleRef.current,
      translateY: [-20, 0],
      opacity: [0, 1],
      duration: 1200,
      easing: 'easeOutExpo',
      delay: 300
    });
  }, []);

  return (
    <div className="flex flex-col items-center justify-center h-full w-full max-w-5xl text-center">
      <motion.div 
        initial={{ scale: 0.95, opacity: 0 }}
        animate={{ scale: 1, opacity: 1 }}
        transition={{ duration: 0.8, ease: "easeOut" }}
        className="relative mb-12 w-full"
      >
        {/* Abstract Tech Graphic */}
        <div className="absolute inset-0 flex items-center justify-center opacity-10 pointer-events-none">
           <Cpu size={300} className="text-electricBlue absolute animate-pulse" style={{ animationDuration: '4s' }} />
           <Network size={400} className="text-accentPurple absolute rotate-45" />
        </div>
        
        <h1 ref={titleRef} className="text-5xl md:text-7xl font-bold mb-6 tracking-tight text-slate-800 relative z-10 drop-shadow-sm">
          MI<br/>
          <span className="text-electricBlue">PRESENTACIÓN</span>
        </h1>
        
        <motion.div 
          initial={{ y: 20, opacity: 0 }}
          animate={{ y: 0, opacity: 1 }}
          transition={{ delay: 0.5, duration: 0.5 }}
          className="relative z-10 bg-white/80 shadow-[0_8px_30px_rgb(0,0,0,0.04)] border border-slate-200 p-6 rounded-xl backdrop-blur-sm max-w-3xl mx-auto"
        >
          <h2 className="text-xl md:text-2xl font-medium text-slate-600">
            Bienvenidos a mi espacio, donde la creatividad y la tecnología se unen para crear proyectos increíbles
          </h2>
        </motion.div>
      </motion.div>

      <motion.div 
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ delay: 1, duration: 0.8 }}
        className="flex space-x-12 mt-8 z-10"
      >
        <div className="flex flex-col items-center">
          <Terminal className="text-accentGreen mb-2" size={32} />
          <span className="text-lg font-semibold tracking-wider text-slate-700">Jhon Cárdenas</span>
        </div>
        <div className="flex flex-col items-center">
          <Cpu className="text-accentPurple mb-2" size={32} />
          <span className="text-lg font-semibold tracking-wider text-slate-700">Ingeniería Electrónica</span>
        </div>
        <div className="flex flex-col items-center">
          <Bot className="text-accentOrange mb-2" size={32} />
          <span className="text-lg font-bold tracking-wider text-accentOrange">DevManyPB</span>
        </div>
      </motion.div>
    </div>
  );
}
