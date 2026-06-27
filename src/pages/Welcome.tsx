import { useNavigate } from 'react-router-dom';
import { Play, AlertTriangle, BookOpen, Bot, ChevronRight, Sprout } from 'lucide-react';

export default function Welcome() {
  const navigate = useNavigate();

  return (
    <div className="flex flex-col min-h-screen pt-12 pb-12 px-5 max-w-lg mx-auto bg-background">
      {/* Header */}
      <header className="flex justify-between items-center w-full mb-6 relative z-10">
        <div className="w-12 h-12 bg-white rounded-full flex items-center justify-center shadow-sm">
          <Sprout className="text-primary w-6 h-6" />
        </div>
        <div className="px-4 py-2 rounded-full bg-white text-slate-700 text-xs font-bold shadow-sm flex items-center gap-2">
          <div className="w-2 h-2 rounded-full bg-secondary animate-pulse"></div>
          JARIBIO
        </div>
      </header>

      {/* Hero */}
      <section className="relative mb-6">
        <div className="w-full aspect-[4/5] rounded-[32px] overflow-hidden relative shadow-soft">
          <img 
            src="https://lh3.googleusercontent.com/aida-public/AB6AXuCIzoFRxZOBx_mreEUNyCCPyunkGSRHE_NSs8or8b08yIa8DMQaNmSbJ4I_JDvQG6WDCkZyobjG4U7ecMNEOrBBCmL8yc9DMYSNRaulCzwJMw3TbOoNv1sXKDXsFGF2MQWE_tLy7AsDFZqq815kitqf3iKZXYlK0Mt-HZzrL2LlpO5056keMUv-_EV-aYfjBxM0QpOK0TD1hOibQZ1XC8NZfQCwYjTmqYv4jzItzCeZ0x1HZOIlzcufdnvhfqDQBholjHTEp1eRHr25" 
            alt="Tanzanian Farmer" 
            className="w-full h-full object-cover"
          />
          <div className="absolute inset-0 bg-black/20"></div>
          
          <div className="absolute inset-0 flex flex-col justify-center items-center">
            <button className="w-16 h-16 bg-white/20 backdrop-blur-md border border-white/40 rounded-full flex items-center justify-center text-white shadow-float mb-4 active:scale-95 transition-all">
              <Play className="w-6 h-6 ml-1 fill-white" />
            </button>
            <span className="text-white text-[10px] uppercase tracking-widest font-bold bg-black/20 px-3 py-1 rounded-full backdrop-blur-sm">Tazama Utangulizi</span>
          </div>

          <div className="absolute bottom-0 left-0 right-0 p-8 bg-gradient-to-t from-black/80 to-transparent pt-20">
            <h1 className="text-3xl font-bold text-white mb-2 leading-tight">Kilimo na Ujasiliamali</h1>
            <p className="text-white/90 text-sm leading-relaxed font-medium">
              Jifunze kilimo kwa vitendo, uliza AI, na ongea na mtaalamu unapohitaji.
            </p>
          </div>
        </div>
      </section>

      {/* Actions */}
      <section className="flex flex-col gap-4">
        <button 
          onClick={() => navigate('/home')}
          className="w-full h-[64px] bg-primary text-white rounded-full flex items-center justify-center gap-2 shadow-button active:scale-[0.98] transition-all font-bold text-lg"
        >
          Anza Jaribio Sasa
        </button>

        <div className="grid grid-cols-2 gap-4">
          <button 
            onClick={() => navigate('/problem')}
            className="flex flex-col items-center justify-center p-6 bg-accent-peach border-none rounded-[28px] text-slate-800 shadow-soft active:scale-95 transition-transform"
          >
            <div className="w-14 h-14 rounded-full bg-secondary/10 flex items-center justify-center mb-4 text-secondary">
              <AlertTriangle className="w-7 h-7" />
            </div>
            <span className="text-[13px] font-bold text-center leading-tight">Nina Tatizo Shambani</span>
          </button>
          
          <button 
            onClick={() => navigate('/topics')}
            className="flex flex-col items-center justify-center p-6 bg-accent-blue border-none rounded-[28px] text-slate-800 shadow-soft active:scale-95 transition-transform"
          >
            <div className="w-14 h-14 rounded-full bg-blue-500/10 flex items-center justify-center mb-4 text-blue-700">
              <BookOpen className="w-7 h-7" />
            </div>
            <span className="text-[13px] font-bold text-center leading-tight">Angalia Mafunzo</span>
          </button>
        </div>

        {/* AI Teaser */}
        <button 
          onClick={() => navigate('/ai-chat')}
          className="p-5 bg-accent-dark border border-slate-800 rounded-[28px] flex items-center justify-between shadow-float text-left active:scale-[0.98] transition-transform"
        >
          <div className="flex items-center gap-4">
            <div className="w-14 h-14 bg-white/10 rounded-full flex items-center justify-center text-white shrink-0">
              <Bot className="w-7 h-7" />
            </div>
            <div>
              <h3 className="font-bold text-white mb-0.5 text-lg">Ushauri wa AI 24/7</h3>
              <p className="text-[13px] text-slate-400 font-medium leading-snug">Pata majibu ya papo hapo.</p>
            </div>
          </div>
          <div className="w-10 h-10 bg-white/10 rounded-full flex items-center justify-center text-white">
            <ChevronRight className="w-5 h-5" />
          </div>
        </button>
      </section>

      <footer className="mt-8 pb-4 text-center">
        <p className="text-[10px] text-slate-400 font-bold tracking-widest uppercase">Kilimo Bora • Maisha Bora</p>
      </footer>
    </div>
  );
}
