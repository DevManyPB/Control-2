import { motion } from 'framer-motion';
import { BlockMath, InlineMath } from 'react-katex';
import { AlertTriangle, Database, FileSpreadsheet } from 'lucide-react';
import { useEffect } from 'react';
import anime from 'animejs';

export default function Slide08_Experimento() {
  const tableData = [
    { sem: 1, horas: "--", tareas: "--", t_prom: "--", uso_ia: "--", err: "--" },
    { sem: 2, horas: "--", tareas: "--", t_prom: "--", uso_ia: "--", err: "--" },
    { sem: 3, horas: "--", tareas: "--", t_prom: "--", uso_ia: "--", err: "--" },
  ];

  useEffect(() => {
    anime({
      targets: 'tbody tr',
      translateX: [-20, 0],
      opacity: [0, 1],
      delay: anime.stagger(100, {start: 600}),
      easing: 'easeOutQuad'
    });
  }, []);

  return (
    <div className="w-full max-w-6xl h-full flex flex-col justify-center">
      <motion.h2 
        initial={{ opacity: 0, x: -50 }}
        animate={{ opacity: 1, x: 0 }}
        className="text-4xl md:text-5xl font-bold mb-8 border-l-4 border-electricBlue pl-6 text-slate-800"
      >
        El experimento
      </motion.h2>

      <p className="text-xl text-slate-600 font-light mb-8 max-w-3xl">
        El modelo teórico será contrastado con <strong className="text-electricBlue font-semibold">datos reales</strong> obtenidos de mi propia actividad.
      </p>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
        
        {/* Left Col: Formula & Vars */}
        <motion.div 
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.2 }}
          className="lg:col-span-1 space-y-6"
        >
          <div className="bg-white p-6 rounded-xl border border-electricBlue shadow-[0_4px_14px_0_rgba(0,136,204,0.15)]">
            <h3 className="text-lg font-bold text-slate-800 mb-4">Métrica Principal</h3>
            <BlockMath math={String.raw`P(k) = \frac{N_{\text{tareas}}(k)}{H_{\text{trabajo}}(k)}`} />
          </div>

          <div className="bg-orange-50 p-6 rounded-xl border border-accentOrange/30 shadow-sm">
             <div className="flex items-center gap-2 mb-4">
               <AlertTriangle className="text-accentOrange" size={20} />
               <h3 className="text-lg font-bold text-accentOrange">Perturbaciones <InlineMath math="d(k)" /></h3>
             </div>
             <ul className="text-sm text-slate-700 space-y-2">
               <li>• Universidad y Exámenes</li>
               <li>• Proyectos simultáneos</li>
               <li>• Bugs inesperados</li>
               <li>• Cambios de requisitos</li>
               <li>• Falta de tiempo</li>
             </ul>
          </div>
        </motion.div>

        {/* Right Col: Experimental Data Table */}
        <motion.div 
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.4 }}
          className="lg:col-span-2"
        >
          <div className="bg-white p-6 rounded-xl border border-dashed border-slate-300 h-full shadow-sm">
            <div className="flex items-center justify-between mb-6">
              <div className="flex items-center gap-3">
                <FileSpreadsheet className="text-accentGreen" />
                <h3 className="text-xl font-bold text-accentGreen">Variables a registrar</h3>
              </div>
              <span className="bg-red-50 text-red-600 text-xs px-2 py-1 rounded border border-red-200 uppercase tracking-widest font-bold animate-pulse">
                Datos por recolectar
              </span>
            </div>

            <div className="overflow-x-auto">
              <table className="w-full text-sm text-left">
                <thead className="text-xs text-slate-500 uppercase bg-slate-50 border-b border-slate-200">
                  <tr>
                    <th className="px-4 py-3">Semana (k)</th>
                    <th className="px-4 py-3">Hrs Trabajo</th>
                    <th className="px-4 py-3">N° Tareas</th>
                    <th className="px-4 py-3">Tiempo/Tarea</th>
                    <th className="px-4 py-3">% Uso IA</th>
                    <th className="px-4 py-3">Errores</th>
                  </tr>
                </thead>
                <tbody>
                  {tableData.map((row, idx) => (
                    <tr key={idx} className="border-b border-slate-100 text-slate-600 font-mono opacity-0">
                      <td className="px-4 py-3 font-semibold">Semana {row.sem}</td>
                      <td className="px-4 py-3">{row.horas}</td>
                      <td className="px-4 py-3">{row.tareas}</td>
                      <td className="px-4 py-3">{row.t_prom}</td>
                      <td className="px-4 py-3">{row.uso_ia}</td>
                      <td className="px-4 py-3">{row.err}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>

            <div className="mt-6 flex items-center justify-center gap-2 text-slate-500 text-sm bg-slate-50 py-2 rounded-md border border-slate-100">
              <Database size={16} />
              <span>Pendiente de recolección en base de datos.</span>
            </div>
          </div>
        </motion.div>
      </div>
    </div>
  );
}
