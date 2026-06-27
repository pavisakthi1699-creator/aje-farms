import { useNavigate } from 'react-router-dom';
import { Bug, Droplets, Sprout, TrendingUp, HandCoins, HelpCircle, ChevronRight, Leaf } from 'lucide-react';

export default function Problem() {
  const navigate = useNavigate();

  const handleSelect = (category: string) => {
    navigate('/ai-chat?topic=' + encodeURIComponent(category));
  };

  return (
    <div className="pt-20 px-5 max-w-lg mx-auto pb-24 space-y-8 bg-background">
      {/* Header */}
      <header className="flex items-center w-full px-5 h-16 fixed top-0 left-0 right-0 z-40 bg-background/90 backdrop-blur border-b border-slate-200/50">
        <h1 className="font-bold text-lg text-slate-800 mx-auto">Tueleze Changamoto</h1>
      </header>

      <section>
        <h2 className="text-2xl font-bold text-slate-800 mb-1">Eleza Tatizo</h2>
        <p className="text-slate-500">Una changamoto gani leo kwenye shamba lako?</p>
      </section>

      <div className="grid grid-cols-2 gap-4">
        <button onClick={() => handleSelect('Magonjwa ya mimea')} className="p-4 bg-white border border-slate-200 rounded-2xl text-left hover:bg-slate-50 transition-colors">
          <div className="w-10 h-10 rounded-full bg-red-50 text-red-600 flex items-center justify-center mb-3">
            <Leaf className="w-5 h-5" />
          </div>
          <span className="font-bold text-sm text-slate-800">Magonjwa ya mimea</span>
        </button>
        
        <button onClick={() => handleSelect('Wadudu')} className="p-4 bg-white border border-slate-200 rounded-2xl text-left hover:bg-slate-50 transition-colors">
          <div className="w-10 h-10 rounded-full bg-orange-50 text-orange-600 flex items-center justify-center mb-3">
            <Bug className="w-5 h-5" />
          </div>
          <span className="font-bold text-sm text-slate-800">Wadudu na Visumbufu</span>
        </button>
        
        <button onClick={() => handleSelect('Mbolea')} className="p-4 bg-white border border-slate-200 rounded-2xl text-left hover:bg-slate-50 transition-colors">
          <div className="w-10 h-10 rounded-full bg-emerald-50 text-emerald-600 flex items-center justify-center mb-3">
            <Sprout className="w-5 h-5" />
          </div>
          <span className="font-bold text-sm text-slate-800">Mbolea na Udongo</span>
        </button>
        
        <button onClick={() => handleSelect('Maji na Umwagiliaji')} className="p-4 bg-white border border-slate-200 rounded-2xl text-left hover:bg-slate-50 transition-colors">
          <div className="w-10 h-10 rounded-full bg-blue-50 text-blue-600 flex items-center justify-center mb-3">
            <Droplets className="w-5 h-5" />
          </div>
          <span className="font-bold text-sm text-slate-800">Maji / Umwagiliaji</span>
        </button>
        
        <button onClick={() => handleSelect('Soko')} className="p-4 bg-white border border-slate-200 rounded-2xl text-left hover:bg-slate-50 transition-colors">
          <div className="w-10 h-10 rounded-full bg-amber-50 text-amber-600 flex items-center justify-center mb-3">
            <TrendingUp className="w-5 h-5" />
          </div>
          <span className="font-bold text-sm text-slate-800">Soko na Bei</span>
        </button>
        
        <button onClick={() => handleSelect('Ufugaji')} className="p-4 bg-white border border-slate-200 rounded-2xl text-left hover:bg-slate-50 transition-colors">
          <div className="w-10 h-10 rounded-full bg-secondary/10 text-secondary flex items-center justify-center mb-3">
            <HandCoins className="w-5 h-5" />
          </div>
          <span className="font-bold text-sm text-slate-800">Ufugaji</span>
        </button>
        
        <button onClick={() => handleSelect('Sijui')} className="col-span-2 flex items-center gap-4 p-4 bg-slate-100 border border-slate-200 rounded-2xl text-left hover:bg-slate-200 transition-colors">
          <div className="w-10 h-10 rounded-full bg-white text-slate-600 flex items-center justify-center shadow-sm">
            <HelpCircle className="w-5 h-5" />
          </div>
          <div>
            <span className="font-bold text-sm text-slate-800 block">Sijui tatizo</span>
            <span className="text-xs text-slate-500">Mwalimu AI itakusaidia kutambua</span>
          </div>
        </button>
      </div>

      <section className="space-y-3">
        <h3 className="font-bold text-slate-800 px-1">Mada Pengekezi</h3>
        <div className="bg-white rounded-xl p-3 border border-slate-200 flex items-center gap-3">
          <div className="w-14 h-14 rounded-lg bg-slate-100 overflow-hidden shrink-0">
            <img src="https://lh3.googleusercontent.com/aida-public/AB6AXuCjlgAXn9XWyJDMdlGwNWu_disje1mrTOz91yawEa_ikXpmayxJaLNGo1LV8xRznrPzXtakoTYTiM3LCD5I5aw3Z20IUezZgYk5yNOg696nLzbx66ClGC7L1OteVwuWfS5NoS9wDhrh2FJcDOWHCwibhcoi7FTYnlq4rvOGRol4jK_ILwBguiBVKqe5-mcAHRceVKBpZBN59lJh8Bi9AH4eZc4x3GEVEiIeswZmhB3aKLb1p82bp6gZGXEC7qcEAiy6WHc-7FWeY4ox" className="w-full h-full object-cover" />
          </div>
          <div className="flex-1">
            <h4 className="font-bold text-sm text-slate-800">Kuzuia Ukungu kwenye Nyanya</h4>
            <span className="text-[10px] text-slate-500 font-medium">Dakika 3 kusoma</span>
          </div>
          <ChevronRight className="w-5 h-5 text-slate-400" />
        </div>
      </section>

    </div>
  );
}
