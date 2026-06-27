import { useNavigate } from 'react-router-dom';
import { ArrowLeft, MessageCircle, Info, Send } from 'lucide-react';

export default function WhatsAppEscalation() {
  const navigate = useNavigate();

  const handleOpenWhatsApp = () => {
    window.open('https://wa.me/255700000000?text=Habari%20Mwalimu%2C%20nahitaji%20msaada%20kuhusu%20kilimo.%20Nimetokea%20kwenye%20app%20ya%20Mwalimu%20wa%20Kilimo.', '_blank');
  };

  return (
    <div className="min-h-screen bg-background">
      <header className="flex items-center gap-3 px-4 h-16 bg-white/80 backdrop-blur-md border-b border-slate-200">
        <button onClick={() => navigate(-1)} className="p-2 -ml-2 text-slate-500 hover:text-slate-800">
          <ArrowLeft className="w-6 h-6" />
        </button>
        <div className="flex items-center gap-2">
          <h1 className="font-bold text-slate-800 w-full text-center">Ongea na Mtaalamu</h1>
        </div>
      </header>

      <main className="px-5 pt-8 max-w-lg mx-auto flex flex-col items-center">
        <div className="w-20 h-20 bg-primary/10 rounded-full flex items-center justify-center mb-6">
          <MessageCircle className="w-10 h-10 text-primary" />
        </div>
        
        <h2 className="text-2xl font-bold text-primary mb-2">Msaada wa Moja kwa Moja</h2>
        <p className="text-slate-500 text-center mb-10 w-full px-4">
          Tutafungua WhatsApp na ujumbe uliotayarishwa ili upate msaada wa haraka kutoka kwa wataalamu wetu.
        </p>

        <div className="w-full bg-white rounded-2xl p-5 border border-slate-200 shadow-sm mb-8 relative overflow-hidden">
          <div className="flex items-center gap-2 mb-4">
            <div className="w-2 h-2 rounded-full bg-primary"></div>
            <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider">Preview ya Ujumbe</span>
          </div>

          <div className="bg-[#E5DDD5] rounded-xl p-4 relative">
            <div className="bg-[#DCF8C6] text-[#303030] p-4 rounded-xl rounded-tl-sm shadow-sm relative w-[90%]">
              <p className="text-sm leading-relaxed">
                Habari Mwalimu, nahitaji msaada kuhusu kilimo. Nimetokea kwenye app ya AJE Farms.
              </p>
              <div className="text-[9px] text-slate-500 text-right mt-1">12:45 PM</div>
            </div>
          </div>

          <div className="mt-5 flex items-start gap-3 bg-slate-50 p-3 rounded-xl border-l-4 border-primary">
            <Info className="w-5 h-5 text-primary shrink-0" />
            <p className="text-xs text-slate-600 leading-relaxed font-medium">
              Mtaalamu wetu atajibu ndani ya dakika chache baada ya kutuma ujumbe huu.
            </p>
          </div>
        </div>

        <div className="w-full space-y-3">
          <button 
            onClick={handleOpenWhatsApp}
            className="w-full bg-[#25D366] text-white py-4 rounded-full font-bold flex items-center justify-center gap-2 shadow-lg hover:opacity-90 active:scale-95 transition-all"
          >
            <Send className="w-5 h-5" />
            Fungua WhatsApp sasa
          </button>
          <button 
            onClick={() => navigate(-1)}
            className="w-full bg-transparent text-slate-500 border border-slate-300 py-4 rounded-full font-bold hover:bg-slate-50 active:scale-95 transition-all"
          >
            Rudi nyuma
          </button>
        </div>
      </main>
    </div>
  );
}
