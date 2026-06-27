import { useNavigate, useParams } from 'react-router-dom';
import { ArrowLeft, PlayCircle, FileText, Bot, MessageCircle, CheckCircle2, Play, Lock, ChevronRight } from 'lucide-react';
import { TOPICS } from '../data';
import { cn } from '../lib/utils';

export default function TopicDetail() {
  const navigate = useNavigate();
  const { id } = useParams();
  
  const topic = TOPICS.find(t => t.id === id) || TOPICS[0];

  return (
    <div className="pb-32 bg-background min-h-screen">
      {/* Header Image Area */}
      <div className="relative w-full h-80 rounded-b-[40px] overflow-hidden shadow-soft">
        <img src={topic.image} alt={topic.title} className="w-full h-full object-cover" />
        <div className="absolute inset-0 bg-black/30"></div>
        
        {/* Floating Actions */}
        <div className="absolute top-6 left-4 right-4 flex justify-between z-10">
          <button onClick={() => navigate(-1)} className="w-12 h-12 bg-white/20 backdrop-blur-md rounded-full flex items-center justify-center text-white border border-white/30 hover:bg-white/30 transition-all">
            <ArrowLeft className="w-6 h-6" />
          </button>
        </div>

        {/* Floating Play Button */}
        <div className="absolute inset-0 flex flex-col items-center justify-center z-10 mt-8">
          <button className="w-20 h-20 bg-white/20 backdrop-blur-md rounded-full flex items-center justify-center text-white border border-white/40 shadow-float hover:scale-105 transition-all active:scale-95 group">
            <Play className="w-8 h-8 ml-1 fill-white group-hover:fill-current" />
          </button>
          <span className="mt-3 bg-black/40 backdrop-blur-sm px-4 py-1.5 rounded-full text-white text-[11px] font-bold tracking-widest uppercase shadow-sm">
            Utangulizi
          </span>
        </div>
      </div>

      <main className="pt-6 px-4 max-w-lg mx-auto space-y-6">
        <section className="bg-white rounded-[32px] p-6 shadow-soft -mt-16 relative z-20">
          <div className="flex justify-between items-start mb-2">
            <span className="text-secondary font-bold text-[11px] uppercase tracking-wider">{topic.badge}</span>
          </div>
          <h1 className="font-bold text-2xl text-slate-800 mb-2 leading-tight">{topic.title}</h1>
          <p className="text-slate-600 text-[15px] leading-relaxed font-medium mb-6">
            Jifunze mbinu bora za kilimo na kuongeza mapato yako kupitia kozi hii.
          </p>

          <h2 className="text-sm font-bold text-slate-800 mb-3 px-1">Malengo ya Somo:</h2>
          {topic.outcomes ? (
            <ul className="space-y-3">
              {topic.outcomes.map((outcome, i) => (
                <li key={i} className="flex gap-3 text-slate-600 text-[13px] font-medium bg-slate-50 p-3 rounded-2xl">
                  <CheckCircle2 className="w-5 h-5 text-primary shrink-0" />
                  <span>{outcome}</span>
                </li>
              ))}
            </ul>
          ) : (
             <p className="text-slate-600 text-sm">Masomo kamili yanakuja hivi karibuni.</p>
          )}
        </section>

        <h3 className="font-bold text-lg text-slate-800 mb-4 px-2 mt-8">Masomo</h3>

        <div className="space-y-4">
          {/* Lesson 1 Video */}
          <div className="bg-white p-4 rounded-[24px] border border-slate-100 shadow-soft flex items-center gap-4 cursor-pointer active:scale-[0.98] transition-transform">
            <div className="w-16 h-16 rounded-[16px] bg-accent-peach flex items-center justify-center shrink-0 border border-slate-100 text-secondary">
              <PlayCircle className="w-6 h-6" />
            </div>
            <div className="flex-1">
              <div className="flex justify-between items-center mb-1">
                <span className="text-[10px] font-bold text-slate-400 uppercase tracking-widest">VIDEO • DKK 5</span>
              </div>
              <h3 className="font-bold text-[15px] leading-snug text-slate-800">Maandalizi ya shamba</h3>
            </div>
            <div className="w-8 h-8 rounded-full bg-slate-50 flex items-center justify-center text-slate-400 shrink-0">
               <ChevronRight className="w-4 h-4" />
            </div>
          </div>

          {/* Lesson 2 PDF */}
          <div className="bg-white p-4 rounded-[24px] border border-slate-100 shadow-soft flex items-center gap-4 cursor-pointer active:scale-[0.98] transition-transform">
            <div className="w-16 h-16 rounded-[16px] bg-accent-blue flex items-center justify-center shrink-0 border border-slate-100 text-blue-600">
              <FileText className="w-6 h-6" />
            </div>
            <div className="flex-1">
              <div className="flex justify-between items-center mb-1">
                <span className="text-[10px] font-bold text-slate-400 uppercase tracking-widest">PDF • 2 MB</span>
              </div>
              <h3 className="font-bold text-[15px] leading-snug text-slate-800">Mwongozo wa Somo</h3>
            </div>
            <div className="w-8 h-8 rounded-full bg-slate-50 flex items-center justify-center text-slate-400 shrink-0">
               <ChevronRight className="w-4 h-4" />
            </div>
          </div>
          
          {/* Locked Lesson Context */}
          <div onClick={() => navigate('/paywall')} className="bg-white p-4 rounded-[24px] border border-slate-100 shadow-sm flex items-center gap-4 cursor-pointer opacity-90 active:scale-[0.98] transition-transform">
            <div className="w-16 h-16 rounded-[16px] bg-slate-50 flex items-center justify-center shrink-0 border border-slate-100">
               <Lock className="w-6 h-6 text-slate-300" />
            </div>
            <div className="flex-1">
              <div className="flex justify-between items-center mb-1">
                <span className="text-[10px] font-bold text-slate-400 uppercase tracking-widest">PREMIUM</span>
              </div>
              <h4 className="font-bold text-sm leading-snug text-slate-600">Masomo yaliyosalia yapo Premium</h4>
            </div>
            <div className="w-8 h-8 rounded-full bg-slate-50 flex items-center justify-center text-slate-400 shrink-0">
              <Lock className="w-4 h-4" />
            </div>
          </div>
        </div>

        <section className="bg-accent-mint rounded-[32px] p-6 mt-8 shadow-soft flex flex-col gap-4 relative overflow-hidden">
          <div className="absolute -right-4 -top-4 w-32 h-32 bg-white/40 rounded-full flex items-center justify-center backdrop-blur-md">
            <Bot className="w-12 h-12 text-primary/20" />
          </div>
          <div className="relative z-10">
            <h4 className="font-bold text-slate-800 text-lg mb-1">Una swali gani?</h4>
            <p className="text-sm font-medium text-slate-600 mb-4">Mwalimu AI yuko tayari kujibu maswali kuhusu {topic.title}</p>
            <button 
              onClick={() => navigate('/ai-chat?topic=' + topic.title)}
              className="w-full bg-primary text-white py-4 rounded-full font-bold flex items-center justify-center gap-2 shadow-button active:scale-95 transition-transform"
            >
              <Bot className="w-5 h-5" />
              Uliza AI Sasa
            </button>
          </div>
        </section>

        <section className="bg-white border border-slate-100 rounded-[32px] p-6 shadow-soft flex flex-col items-center justify-center text-center gap-2">
            <div className="w-14 h-14 bg-green-50 text-green-600 rounded-full flex items-center justify-center mb-2">
               <MessageCircle className="w-6 h-6" />
            </div>
            <h4 className="font-bold text-slate-800 text-lg">Ongea na Mtaalamu</h4>
            <p className="text-sm font-medium text-slate-600 mb-4">Pata ushauri binafsi kupitia WhatsApp yetu.</p>
            <button 
              onClick={() => navigate('/whatsapp')}
              className="w-full bg-[#25D366] text-white py-4 rounded-full font-bold flex items-center justify-center gap-2 shadow-[0_8px_20px_-6px_rgba(37,211,102,0.4)] active:scale-95 transition-transform"
            >
              Tuma Ujumbe WhatsApp
            </button>
        </section>

      </main>
    </div>
  );
}
