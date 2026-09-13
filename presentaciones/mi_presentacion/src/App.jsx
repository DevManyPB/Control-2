import { useState, useEffect } from 'react';
import { AnimatePresence } from 'framer-motion';
import { ChevronLeft, ChevronRight } from 'lucide-react';
import SlideWrapper from './components/SlideWrapper';

// Slides imports
import Slide01 from './slides/Slide01_Portada';
import Slide02 from './slides/Slide02_QuienSoy';
import Slide03 from './slides/Slide03_MyWorldMap';
import Slide04 from './slides/Slide04_Hallazgo';
import Slide05 from './slides/Slide05_DefinicionProblema';
import Slide06 from './slides/Slide06_ModeloMatematico';
import Slide07 from './slides/Slide07_Simulink';
import Slide08 from './slides/Slide08_Experimento';
import Slide09 from './slides/Slide09_Resultados';
import Slide10 from './slides/Slide10_Cierre';

const slides = [
  <Slide01 key="s1" />,
  <Slide02 key="s2" />,
  <Slide03 key="s3" />,
  <Slide04 key="s4" />,
  <Slide05 key="s5" />,
  <Slide06 key="s6" />,
  <Slide07 key="s7" />,
  <Slide08 key="s8" />,
  <Slide09 key="s9" />,
  <Slide10 key="s10" />
];

export default function App() {
  const [[page, direction], setPage] = useState([0, 0]);

  const paginate = (newDirection) => {
    const newPage = page + newDirection;
    if (newPage >= 0 && newPage < slides.length) {
      setPage([newPage, newDirection]);
    }
  };

  useEffect(() => {
    const handleKeyDown = (e) => {
      if (e.key === 'ArrowRight') {
        paginate(1);
      } else if (e.key === 'ArrowLeft') {
        paginate(-1);
      }
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [page]);

  const progress = ((page + 1) / slides.length) * 100;

  return (
    <div className="relative w-screen h-screen bg-darkBg text-slate-900 overflow-hidden tech-grid font-sans">
      
      {/* Background glow effects - lighter for light theme */}
      <div className="absolute top-[-10%] left-[-10%] w-[40%] h-[40%] rounded-full bg-electricBlue/10 blur-[120px] pointer-events-none"></div>
      <div className="absolute bottom-[-10%] right-[-10%] w-[40%] h-[40%] rounded-full bg-accentPurple/10 blur-[120px] pointer-events-none"></div>

      {/* Main Content Area */}
      <div className="relative w-full h-full overflow-hidden">
        <AnimatePresence initial={false} custom={direction}>
          <SlideWrapper key={page} direction={direction}>
            {slides[page]}
          </SlideWrapper>
        </AnimatePresence>
      </div>

      {/* Navigation Controls */}
      <div className="absolute bottom-8 left-0 right-0 flex justify-between items-center px-12 pointer-events-none z-50">
        
        {/* Progress indicator */}
        <div className="flex flex-col gap-2 w-48 pointer-events-auto">
          <div className="text-sm font-mono text-slate-500 font-medium">
            {String(page + 1).padStart(2, '0')} / {slides.length}
          </div>
          <div className="w-full h-2 bg-slate-200 rounded-full overflow-hidden shadow-inner">
            <div 
              className="h-full bg-electricBlue transition-all duration-300 ease-out"
              style={{ width: `${progress}%` }}
            ></div>
          </div>
        </div>

        {/* Buttons */}
        <div className="flex gap-4 pointer-events-auto">
          <button 
            onClick={() => paginate(-1)}
            disabled={page === 0}
            className={`p-3 rounded-full border border-slate-300 transition-colors shadow-sm ${page === 0 ? 'opacity-50 cursor-not-allowed text-slate-400' : 'hover:border-electricBlue hover:text-electricBlue bg-white text-slate-700'}`}
          >
            <ChevronLeft size={24} />
          </button>
          
          <button 
            onClick={() => paginate(1)}
            disabled={page === slides.length - 1}
            className={`p-3 rounded-full border border-slate-300 transition-colors shadow-sm ${page === slides.length - 1 ? 'opacity-50 cursor-not-allowed text-slate-400' : 'hover:border-electricBlue hover:text-electricBlue bg-white text-slate-700'}`}
          >
            <ChevronRight size={24} />
          </button>
        </div>
      </div>
    </div>
  );
}
