import { useNavigate } from 'react-router-dom';
import { Eye, MessageCircle, Star, Rocket, Sparkles, ArrowLeft, Headphones } from 'lucide-react';
import { TOPICS } from '../data';
import { cn } from '../lib/utils';

export default function Topics() {
  const navigate = useNavigate();

  return (
    <div className="pt-24 px-4 max-w-lg mx-auto pb-32 space-y-6 bg-background min-h-screen">
      <header className="flex items-center gap-3 px-4 h-20 bg-background/80 backdrop-blur-xl border-b border-white/20 fixed top-0 w-full z-40">
        <button onClick={() => navigate(-1)} className="w-12 h-12 bg-white rounded-full flex items-center justify-center shadow-sm text-slate-600 hover:text-slate-900 -ml-2">
          <ArrowLeft className="w-6 h-6" />
        </button>
        <h1 className="font-bold text-xl text-slate-800">Mafunzo</h1>
      </header>

      <div className="mb-8 px-2 mt-4">
        <h2 className="text-3xl font-bold text-slate-800 mb-3 leading-tight">Chagua Mada. <br/><span className="text-primary">Jifunze Kilimo.</span></h2>
        <p className="text-slate-500 text-sm font-medium">Chagua kozi hapa chini ili kuongeza tija kwenye shamba lako leo.</p>
      </div>

      <div className="space-y-8">
        {TOPICS.map((topic, i) => (
          <div key={topic.id} className={cn("rounded-[32px] overflow-hidden shadow-soft", i === 1 ? "bg-accent-mint" : i === 2 ? "bg-accent-peach" : "bg-white")}>
            <div className="h-56 w-full relative p-4 pb-0">
              <div className="w-full h-full rounded-t-[24px] overflow-hidden relative">
                <img src={topic.image} alt={topic.title} className="w-full h-full object-cover" />
                <div className="absolute inset-0 bg-black/10"></div>
              </div>
              <div className="absolute top-8 left-8 bg-white/90 backdrop-blur-sm text-slate-800 px-4 py-2 rounded-full text-[11px] font-bold flex items-center gap-1.5 shadow-sm uppercase tracking-wider">
                {i === 0 ? <Star className="w-3.5 h-3.5 text-yellow-500 fill-yellow-500" /> : i === 1 ? <Rocket className="w-3.5 h-3.5 text-secondary" /> : <Sparkles className="w-3.5 h-3.5 text-blue-500" />}
                {topic.badge}
              </div>
            </div>
            
            <div className="p-6 flex flex-col">
              <h3 className="font-bold text-2xl text-slate-800 mb-3">{topic.title}</h3>
              <p className="text-slate-600 text-sm mb-6 leading-relaxed font-medium">{topic.description}</p>
              
              <div className="flex flex-col gap-3">
                <button 
                  onClick={() => navigate(`/topics/${topic.id}`)}
                  className="w-full bg-slate-900 text-white h-14 rounded-full font-bold flex justify-center items-center gap-2 hover:bg-slate-800 shadow-float transition-all active:scale-[0.98]"
                >
                  <Eye className="w-5 h-5" />
                  Anza Kujifunza
                </button>
                <div className="grid grid-cols-2 gap-3">
                  <button onClick={() => navigate('/ai-chat?topic=' + topic.title)} className="bg-white border-none text-slate-800 py-3 rounded-full font-bold text-[13px] flex justify-center items-center gap-2 shadow-sm hover:bg-slate-50 transition-colors">
                    <span className="w-6 h-6 rounded-full bg-primary/10 flex items-center justify-center">🤖</span>
                    Uliza AI
                  </button>
                  <button onClick={() => navigate('/whatsapp')} className="bg-white border border-slate-100 text-slate-800 py-3 rounded-full font-bold text-[13px] flex justify-center items-center gap-2 shadow-sm hover:bg-slate-50 transition-colors">
                    <span className="w-6 h-6 rounded-full bg-green-500/10 text-green-600 flex items-center justify-center">
                      <Headphones className="w-3.5 h-3.5" />
                    </span>
                    Mtaalamu
                  </button>
                </div>
              </div>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
