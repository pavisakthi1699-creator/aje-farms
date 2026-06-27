import { useNavigate } from 'react-router-dom';
import { Clock, Search, Bot, Star, Users, Droplets, Bug, Sprout, TrendingUp } from 'lucide-react';
import { TOPICS } from '../data';

export default function Home() {
  const navigate = useNavigate();

  return (
    <div className="pt-24 px-5 max-w-lg mx-auto space-y-8 pb-32">
      <header className="flex justify-between items-center w-full px-5 h-20 fixed top-0 left-0 right-0 z-40 bg-background/80 backdrop-blur-xl border-b border-white/20">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 bg-white rounded-full flex items-center justify-center shadow-sm">
            <Sprout className="text-primary w-5 h-5" />
          </div>
          <h1 className="font-bold text-lg text-slate-800">AJE Farms</h1>
        </div>
      </header>

      {/* Greeting & Trial */}
      <section className="flex justify-between items-center mb-2 px-2">
        <div>
          <h2 className="text-xl font-bold text-slate-800">Karibu, Mkulima</h2>
          <p className="text-sm text-slate-500 font-medium">Endeleza shamba lako leo</p>
        </div>
      </section>

      <div className="grid grid-cols-1 gap-6">
        {/* Primary Action Card - Soft Blue Accent */}
        <section 
          onClick={() => navigate('/problem')}
          className="bg-accent-blue rounded-[32px] p-6 shadow-soft flex flex-col relative overflow-hidden group cursor-pointer active:scale-[0.98] transition-transform"
        >
          <div className="flex justify-between items-start mb-4 relative z-10">
            <div className="bg-white/60 backdrop-blur-md text-primary rounded-full px-4 py-2 flex items-center gap-2 font-bold text-[11px] uppercase tracking-wide border border-white">
              <Clock className="w-4 h-4" />
              <span>24h Jaribio Lako</span>
            </div>
          </div>
          <div className="relative z-10 w-full mb-6">
            <h3 className="text-2xl font-bold mb-2 text-slate-800 pr-12 leading-tight">Una changamoto gani leo?</h3>
            <p className="text-sm text-slate-600 font-medium leading-relaxed pr-8">
              Pata ushauri wa kitaalamu papo hapo kwa msaada wa AI.
            </p>
          </div>
          <button className="self-start bg-slate-900 text-white px-8 py-4 rounded-full font-bold text-sm flex items-center gap-3 hover:bg-slate-800 transition-all shadow-float relative z-10">
            <Search className="w-4 h-4" />
            Eleza Tatizo
          </button>
          
          <div className="absolute -right-4 -top-4 w-32 h-32 bg-white/40 rounded-full flex items-center justify-center backdrop-blur-md">
            <Sprout className="w-12 h-12 text-blue-500/50" />
          </div>
        </section>

        <div className="grid grid-cols-2 gap-4">
          {/* AI Access - Soft Mint Accent */}
          <section 
            onClick={() => navigate('/ai-chat')}
            className="bg-accent-mint rounded-[28px] p-6 flex flex-col items-center justify-center text-center cursor-pointer shadow-soft active:scale-[0.98] transition-all"
          >
            <div className="w-16 h-16 bg-white rounded-full flex items-center justify-center text-primary shadow-sm mb-4">
              <Bot className="w-8 h-8" />
            </div>
            <h4 className="font-bold text-slate-800 text-[15px] mb-1">Uliza AI</h4>
            <p className="text-[11px] text-slate-500 font-bold uppercase tracking-wider">Majibu ya Papo</p>
          </section>

          {/* Premium Teaser - Dark Accent */}
          <section 
            onClick={() => navigate('/paywall')}
            className="bg-accent-dark text-white rounded-[28px] p-6 flex flex-col items-center justify-center text-center relative overflow-hidden cursor-pointer shadow-float active:scale-[0.98] transition-all"
          >
            <div className="absolute inset-0 opacity-20 bg-[radial-gradient(ellipse_at_top,_var(--tw-gradient-stops))] from-white via-transparent to-transparent"></div>
            <div className="z-10 w-16 h-16 bg-white/10 rounded-full flex items-center justify-center mb-4 backdrop-blur-md border border-white/20">
              <Star className="w-7 h-7 text-yellow-400 fill-yellow-400" />
            </div>
            <h4 className="font-bold text-[15px] mb-1 z-10 text-white">Premium</h4>
            <p className="text-[11px] text-white/60 font-bold uppercase tracking-wider z-10">Fungua Soko</p>
          </section>
        </div>

        {/* Continue Learning - Soft Peach Area */}
        <section className="bg-accent-peach rounded-[32px] p-6 shadow-soft">
          <div className="flex justify-between items-center mb-5">
            <h4 className="font-bold text-slate-800 text-lg">Masomo Yangu</h4>
            <button onClick={() => navigate('/topics')} className="w-10 h-10 bg-white rounded-full flex items-center justify-center shadow-sm text-secondary hover:scale-105 transition-transform">
              <span className="text-xl font-bold leading-none -mt-1">+</span>
            </button>
          </div>
          
          <div 
            onClick={() => navigate('/topics/pasheni')}
            className="flex flex-col sm:flex-row gap-4 p-4 bg-white rounded-[24px] shadow-sm cursor-pointer active:scale-[0.98] transition-transform border border-white/60"
          >
            <div className="w-full sm:w-24 h-32 sm:h-24 rounded-[16px] overflow-hidden shrink-0">
              <img src={TOPICS[0].image} alt={TOPICS[0].title} className="w-full h-full object-cover" />
            </div>
            <div className="flex-1 flex flex-col justify-center">
              <h5 className="font-bold text-slate-800 text-base mb-3">{TOPICS[0].title}</h5>
              <div className="flex justify-between text-[11px] font-bold text-slate-500 mb-2">
                <span>SEHEMU YA 4/6</span>
                <span className="text-primary">{TOPICS[0].progress}%</span>
              </div>
              <div className="w-full bg-slate-100 rounded-full h-3 overflow-hidden">
                <div className="bg-primary h-full rounded-full" style={{ width: `${TOPICS[0].progress}%` }}></div>
              </div>
            </div>
          </div>
        </section>

        {/* Popular Topics Mini */}
        <section>
          <div className="flex justify-between items-center px-2 mb-4">
            <h4 className="font-bold text-slate-800 text-lg">Mada Zinazovuma</h4>
          </div>
          <div className="flex gap-4 overflow-x-auto pb-4 no-scrollbar -mx-5 px-5">
            {[
              { icon: Droplets, label: 'Maji', color: 'text-blue-500' },
              { icon: Bug, label: 'Wadudu', color: 'text-red-500' },
              { icon: Sprout, label: 'Mbolea', color: 'text-primary' },
              { icon: TrendingUp, label: 'Soko', color: 'text-secondary' },
            ].map((item, i) => (
              <div key={i} className="shrink-0 w-[100px] h-[100px] bg-white rounded-[24px] shadow-sm flex flex-col items-center justify-center gap-3 cursor-pointer active:scale-95 transition-transform">
                <div className={`w-12 h-12 bg-slate-50 rounded-full flex items-center justify-center ${item.color}`}>
                  <item.icon className="w-6 h-6" />
                </div>
                <span className="text-[12px] font-bold text-slate-700">{item.label}</span>
              </div>
            ))}
          </div>
        </section>
        
        {/* Community Teaser */}
        <section 
          onClick={() => navigate('/community')}
          className="bg-white rounded-[28px] p-2 flex justify-between items-center cursor-pointer shadow-soft border border-slate-100"
        >
          <div className="flex items-center gap-4">
            <div className="w-14 h-14 bg-accent-blue rounded-[20px] flex items-center justify-center text-blue-600 ml-2">
              <Users className="w-6 h-6" />
            </div>
            <div>
              <h4 className="font-bold text-slate-800">Jiunge na Jamii</h4>
              <p className="text-[12px] text-slate-500 font-medium">Wakulima 1,200+</p>
            </div>
          </div>
          <div className="w-12 h-12 rounded-full border border-slate-100 flex items-center justify-center mr-2 text-slate-400">
            <svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
              <path d="M9 18L15 12L9 6" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
            </svg>
          </div>
        </section>

      </div>
    </div>
  );
}
