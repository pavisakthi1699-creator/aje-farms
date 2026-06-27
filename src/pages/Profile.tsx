import { Crown, CheckCircle2, ChevronRight, BookOpen, Clock, FileText, Settings, HelpCircle, LogOut } from 'lucide-react';
import { useNavigate } from 'react-router-dom';

export default function Profile() {
  const navigate = useNavigate();

  return (
    <div className="pt-16 px-5 max-w-lg mx-auto pb-24 bg-background min-h-screen">
      <header className="flex items-center w-full px-5 h-16 fixed top-0 left-0 right-0 z-40 bg-white/80 backdrop-blur border-b border-slate-200">
        <h1 className="font-bold text-lg text-slate-800 mx-auto">Akaunti Yangu</h1>
      </header>

      <div className="mt-8 mb-6 flex flex-col items-center">
        <div className="w-24 h-24 bg-primary/10 rounded-full flex items-center justify-center text-primary mb-3">
          <span className="text-3xl font-bold">+255</span>
        </div>
        <h2 className="text-xl font-bold text-slate-800">+255 7XX XXX XXX</h2>
        <p className="text-sm text-slate-500 font-medium">Mkulima Mwanachama</p>
      </div>

      <div className="bg-white p-5 rounded-2xl border border-slate-200 mb-6 shadow-sm">
        <div className="flex justify-between items-start mb-4">
          <div>
            <h3 className="font-bold text-slate-800">Hali ya Akaunti</h3>
            <p className="text-sm text-secondary font-bold">Majaribio (Trial)</p>
          </div>
          <Clock className="text-secondary w-6 h-6" />
        </div>
        
        <div className="bg-secondary/10 p-3 rounded-xl mb-4 border-l-4 border-secondary">
          <p className="text-xs text-secondary/80 font-medium leading-relaxed">
            Muda wako wa majaribio unakwisha baada ya <span className="font-bold">saa 2</span>. Jiunge sasa ili uendelee kupata ushauri.
          </p>
        </div>
        
        <button 
          onClick={() => navigate('/paywall')}
          className="w-full bg-primary text-white py-3 rounded-full font-bold text-sm flex items-center justify-center gap-2 shadow-sm"
        >
          <Crown className="w-4 h-4 fill-current" />
          Lipia Kifurushi Sasa
        </button>
      </div>

      <div className="space-y-1">
        <h4 className="text-[10px] font-bold text-slate-400 uppercase tracking-wider px-2 py-2">Shughuli Zangu</h4>
        
        <div className="bg-white rounded-2xl border border-slate-200 overflow-hidden shadow-sm">
          <div className="flex items-center justify-between p-4 border-b border-slate-100 cursor-pointer hover:bg-slate-50">
            <div className="flex items-center gap-4">
              <div className="bg-primary/10 p-2 rounded-lg text-primary">
                <BookOpen className="w-5 h-5" />
              </div>
              <span className="text-sm font-bold text-slate-700">Mafunzo yangu</span>
            </div>
            <ChevronRight className="w-4 h-4 text-slate-400" />
          </div>
          
          <div className="flex items-center justify-between p-4 border-b border-slate-100 cursor-pointer hover:bg-slate-50">
            <div className="flex items-center gap-4">
              <div className="bg-primary/10 p-2 rounded-lg text-primary">
                <FileText className="w-5 h-5" />
              </div>
              <span className="text-sm font-bold text-slate-700">Nyaraka zilizohifadhiwa</span>
            </div>
            <ChevronRight className="w-4 h-4 text-slate-400" />
          </div>
          
          <div className="flex items-center justify-between p-4 border-b border-slate-100 cursor-pointer hover:bg-slate-50">
            <div className="flex items-center gap-4">
              <div className="bg-primary/10 p-2 rounded-lg text-primary">
                <Settings className="w-5 h-5" />
              </div>
              <span className="text-sm font-bold text-slate-700">Mipangilio</span>
            </div>
            <ChevronRight className="w-4 h-4 text-slate-400" />
          </div>
          
          <div onClick={() => navigate('/whatsapp')} className="flex items-center justify-between p-4 cursor-pointer hover:bg-slate-50">
            <div className="flex items-center gap-4">
              <div className="bg-green-100 p-2 rounded-lg text-green-600">
                <HelpCircle className="w-5 h-5" />
              </div>
              <div className="flex flex-col">
                <span className="text-sm font-bold text-slate-700">Msaada / WhatsApp</span>
                <span className="text-[10px] text-slate-500 font-medium">Tupo kwa ajili yako 24/7</span>
              </div>
            </div>
            <ChevronRight className="w-4 h-4 text-slate-400" />
          </div>
        </div>
      </div>

      <button className="w-full mt-6 text-red-500 font-bold text-sm py-4 rounded-full flex items-center justify-center gap-2 hover:bg-red-50 transition-colors">
        <LogOut className="w-4 h-4" />
        Ondoka kwenye Akaunti
      </button>

      <p className="text-center text-[10px] text-slate-400 mt-4">Toleo la App 2.4.0</p>
    </div>
  );
}
