import { motion } from 'framer-motion';
import { InlineMath } from 'react-katex';
import { useEffect } from 'react';
import anime from 'animejs';

export default function Slide07_Simulink() {
  useEffect(() => {
    const tl = anime.timeline({
      easing: 'easeOutExpo',
    });

    tl.add({
      targets: '.sl-row-1',
      opacity: [0, 1],
      translateX: [-50, 0],
      duration: 800,
    })
    .add({
      targets: '.sl-row-2',
      opacity: [0, 1],
      translateX: [-50, 0],
      duration: 800,
    }, '-=400')
    .add({
      targets: '.sl-row-3',
      opacity: [0, 1],
      translateX: [-50, 0],
      duration: 800,
    }, '-=400')
    .add({
      targets: '.sl-combiner',
      opacity: [0, 1],
      scale: [0.9, 1],
      duration: 800,
    }, '-=200');

  }, []);

  const SmallArrow = () => (
    <svg width="24" height="12" viewBox="0 0 24 12" className="shrink-0">
      <line x1="0" y1="6" x2="20" y2="6" stroke="#94a3b8" strokeWidth="2"/>
      <polygon points="18,2 24,6 18,10" fill="#94a3b8"/>
    </svg>
  );

  const GainBlock = ({label}) => (
    <div className="bg-white border-2 border-slate-300 px-3 py-1 flex flex-col items-center min-w-[60px] shadow-sm">
      <span className="text-[10px] text-slate-400">Gain</span>
      <InlineMath math={label} />
    </div>
  );

  const IntegratorBlock = () => (
    <div className="bg-blue-50 border-2 border-electricBlue px-3 py-1 flex flex-col items-center min-w-[70px] shadow-sm">
      <span className="text-[10px] text-slate-400">Integrator</span>
      <span className="font-mono text-sm">1/s</span>
    </div>
  );

  const SumCircle = () => (
    <div className="w-7 h-7 rounded-full border-2 border-slate-400 flex items-center justify-center bg-white shrink-0 shadow-sm">
      <span className="text-slate-600 text-sm font-bold">+</span>
    </div>
  );

  const drawRow = (inputLabel, gainLabel, outputLabel, feedbackLabel, rowClass) => (
    <div className={`flex items-center gap-1 relative opacity-0 ${rowClass}`}>
      {/* Input */}
      <div className="text-sm font-bold text-slate-700 w-10 text-center shrink-0"><InlineMath math={inputLabel} /></div>
      <SmallArrow />
      <GainBlock label={gainLabel} />
      <SmallArrow />
      <SumCircle />
      <SmallArrow />
      <IntegratorBlock />
      <SmallArrow />
      {/* Output */}
      <div className="text-sm font-bold text-electricBlue w-10 text-center shrink-0"><InlineMath math={outputLabel} /></div>
      
      {/* Feedback label below */}
      <div className="absolute -bottom-5 left-[50%] transform -translate-x-1/2 text-[11px] text-slate-400 whitespace-nowrap">
        <InlineMath math={feedbackLabel} />
      </div>
    </div>
  );

  return (
    <div className="w-full max-w-6xl h-full flex flex-col justify-center">
      <motion.h2 
        initial={{ opacity: 0, x: -50 }}
        animate={{ opacity: 1, x: 0 }}
        className="text-4xl md:text-5xl font-bold mb-10 border-l-4 border-electricBlue pl-6 text-slate-800"
      >
        Modelo en Simulink
      </motion.h2>

      <div className="flex items-center justify-between gap-8 w-full">
        {/* Left side: Three parallel paths */}
        <div className="flex flex-col gap-10">
          {drawRow("H(t)", "k_E", "E(t)", String.raw`-\delta_E`, "sl-row-1")}
          {drawRow("H(t)", "k_L", "L(t)", String.raw`-\delta_L`, "sl-row-2")}
          {drawRow("I(t)", "k_A", "A(t)", String.raw`-\delta_A`, "sl-row-3")}
        </div>

        {/* Right side: Combiner block */}
        <div className="sl-combiner opacity-0 flex items-center gap-2 shrink-0">
          {/* Converging arrows */}
          <svg width="60" height="120" viewBox="0 0 60 120" className="shrink-0">
            {/* Top arrow */}
            <line x1="0" y1="15" x2="50" y2="55" stroke="#0088cc" strokeWidth="2"/>
            <polygon points="48,50 56,56 48,60" fill="#0088cc"/>
            {/* Middle arrow */}
            <line x1="0" y1="60" x2="50" y2="60" stroke="#0088cc" strokeWidth="2"/>
            <polygon points="48,56 56,60 48,64" fill="#0088cc"/>
            {/* Bottom arrow */}
            <line x1="0" y1="105" x2="50" y2="65" stroke="#0088cc" strokeWidth="2"/>
            <polygon points="48,60 56,64 48,68" fill="#0088cc"/>
          </svg>
          
          {/* Math Function Block */}
          <div className="bg-white shadow-sm border-2 border-accentPurple p-4 rounded-lg text-center">
            <span className="text-xs text-slate-400 block mb-1">Math Function</span>
            <span className="font-bold text-accentPurple text-sm"><InlineMath math="P(t) = f(E,L,A)" /></span>
          </div>
          
          {/* Output arrow */}
          <svg width="40" height="20" viewBox="0 0 40 20" className="shrink-0">
            <line x1="0" y1="10" x2="32" y2="10" stroke="#0088cc" strokeWidth="2"/>
            <polygon points="30,6 38,10 30,14" fill="#0088cc"/>
          </svg>
          
          {/* P(t) output */}
          <div className="font-bold text-xl text-slate-800 bg-blue-50 px-4 py-2 border-2 border-electricBlue rounded shadow-sm">
            <InlineMath math="P(t)" />
          </div>
        </div>
      </div>
    </div>
  );
}
