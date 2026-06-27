import { useNavigate } from 'react-router-dom';
import { ShieldCheck, Calendar, Star, BookOpen, Smartphone } from 'lucide-react';
import { useState } from 'react';

export default function Paywall() {
  const navigate = useNavigate();
  const [isProcessing, setIsProcessing] = useState(false);
  const [isSuccess, setIsSuccess] = useState(false);

  const handlePayment = () => {
    setIsProcessing(true);
    setTimeout(() => {
      setIsProcessing(false);
      setIsSuccess(true);
      setTimeout(() => {
        navigate('/home');
      }, 2000);
    }, 2000);
  };

  if (isProcessing) {
    return (
      <div className="min-h-screen bg-background flex flex-col items-center justify-center p-6 text-center">
        <div className="w-16 h-16 border-4 border-primary border-t-transparent rounded-full animate-spin mb-6 shadow-sm"></div>
        <h2 className="text-xl font-bold text-slate-800 mb-2">Inasubiri uthibitisho...</h2>
        <p className="text-slate-500 text-[15px] font-medium">Tafadhali ingiza namba ya siri kwenye simu yako kuthibitisha malipo.</p>
      </div>
    );
  }

  if (isSuccess) {
    return (
      <div className="min-h-screen bg-background flex flex-col items-center justify-center p-6 text-center">
        <div className="w-24 h-24 bg-green-100 rounded-full flex items-center justify-center mb-6 shadow-soft">
          <ShieldCheck className="w-12 h-12 text-green-600" />
        </div>
        <h2 className="text-2xl font-bold text-slate-800 mb-2">Malipo Yamefanikiwa!</h2>
        <p className="text-slate-500 text-[15px] font-medium">Akaunti yako imefunguliwa kwa siku 30. Asante kwa kujiunga nasi.</p>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-background pt-12 px-5 max-w-lg mx-auto pb-8 flex flex-col">
      <header className="flex justify-between items-center w-full mb-8">
        <h1 className="font-bold text-xl text-primary">AJE Farms</h1>
        <button onClick={() => navigate(-1)} className="text-sm font-bold text-slate-400 hover:text-slate-600 bg-white px-4 py-2 rounded-full shadow-sm">Baadaye</button>
      </header>

      <section className="mb-8">
        <div className="relative w-full h-48 rounded-[32px] overflow-hidden mb-6 shadow-soft">
          <img src="https://lh3.googleusercontent.com/aida-public/AB6AXuAnBRFfIhxW-ippscLNsCD75ZI1D9o_mDUDpegY33Og6WWUqOu3UPWX1Q1fZxmWqSbw2Cw5836ZYvfULwGCH1xnqtuC_LDBbDzCDih5gzBAGxc7bjaxLU9ua9iKjPh1XQo7Ys3dTJw-RPKGxI6DDM9ZII346revATFe6qbzEl762kmWSAytzthVvxvrYufaetPjSsN7r-4L45A-ojkSovNyzoGCYuGUxb6I9laVJ97Gc3JxKIxwjIaBnt_8AykszcIqk3qG-0sRwJUQ" className="w-full h-full object-cover" />
          <div className="absolute inset-0 bg-gradient-to-t from-black/80 to-transparent"></div>
          <div className="absolute bottom-6 left-6 right-6 text-white">
            <span className="bg-secondary px-3 py-1.5 rounded-full text-[10px] font-bold tracking-wider mb-2 inline-block uppercase shadow-sm">Kifurushi Kimeisha</span>
            <h2 className="text-2xl font-bold leading-tight">Muda wa jaribio umeisha</h2>
          </div>
        </div>
        <p className="text-slate-600 text-[15px] font-medium px-2 text-center">
          Lipa kuendelea kupata mafunzo, vitabu na msaada wa AI kwenye kilimo chako.
        </p>
      </section>

      <section className="space-y-4 mb-10">
        <div className="bg-white rounded-[24px] p-5 flex items-center justify-between cursor-pointer active:scale-[0.98] transition-transform shadow-soft border border-slate-100">
          <div className="flex items-center gap-4">
            <div className="bg-slate-50 p-4 rounded-[16px] border border-slate-100">
              <Calendar className="w-6 h-6 text-slate-600" />
            </div>
            <div>
              <h3 className="font-bold text-slate-800 text-[15px]">Wiki 1</h3>
              <p className="text-[12px] text-slate-500 font-medium mt-0.5">Ufikiaji wa haraka</p>
            </div>
          </div>
          <div className="text-right">
            <span className="font-bold text-lg text-primary">TZS 3,000</span>
          </div>
        </div>

        <div className="relative bg-accent-mint border-2 border-primary-container rounded-[24px] p-5 flex items-center justify-between cursor-pointer shadow-soft">
          <div className="absolute -top-3 left-1/2 -translate-x-1/2 bg-slate-900 text-white text-[10px] font-bold px-4 py-1.5 rounded-full uppercase tracking-widest shadow-sm">
            Inapendekezwa
          </div>
          <div className="flex items-center gap-4">
            <div className="bg-primary text-white p-4 rounded-[16px] shadow-sm">
              <Star className="w-6 h-6 fill-current" />
            </div>
            <div>
              <h3 className="font-bold text-slate-800 text-[15px]">Mwezi 1</h3>
              <p className="text-[12px] text-primary font-bold mt-0.5">Thamani bora zaidi</p>
            </div>
          </div>
          <div className="text-right">
            <span className="font-bold text-2xl text-primary">TZS 10,000</span>
          </div>
        </div>

        <div className="bg-white rounded-[24px] p-5 flex items-center justify-between cursor-pointer active:scale-[0.98] transition-transform shadow-soft border border-slate-100">
          <div className="flex items-center gap-4">
            <div className="bg-slate-50 p-4 rounded-[16px] border border-slate-100">
              <BookOpen className="w-6 h-6 text-slate-600" />
            </div>
            <div>
              <h3 className="font-bold text-slate-800 text-[15px]">Kozi Maalum</h3>
              <p className="text-[12px] text-slate-500 font-medium mt-0.5">Utaalamu wa kina</p>
            </div>
          </div>
          <div className="text-right">
            <span className="font-bold text-lg text-primary">TZS 50,000</span>
          </div>
        </div>
      </section>

      <section className="bg-white rounded-[32px] p-6 shadow-soft mt-auto">
        <h4 className="text-center text-[11px] font-bold text-slate-400 mb-5 uppercase tracking-widest">Njia za Kulipa</h4>
        <div className="flex justify-center items-center gap-3 mb-6">
          <div className="px-4 py-2 bg-slate-50 rounded-full text-[13px] font-bold text-red-600 border border-slate-100">M-Pesa</div>
          <div className="px-4 py-2 bg-slate-50 rounded-full text-[13px] font-bold text-blue-600 border border-slate-100">Tigo</div>
          <div className="px-4 py-2 bg-slate-50 rounded-full text-[13px] font-bold text-red-500 border border-slate-100">Airtel</div>
        </div>
        
        <button 
          onClick={handlePayment}
          className="w-full bg-slate-900 text-white py-4 h-[64px] rounded-full font-bold shadow-float flex items-center justify-center gap-2 hover:bg-slate-800 transition-all active:scale-[0.98] text-[15px]"
        >
          <Smartphone className="w-5 h-5" />
          Lipa kwa Mobile Money
        </button>
        
        <div className="mt-5 flex items-center justify-center gap-2">
          <ShieldCheck className="w-5 h-5 text-green-500" />
          <p className="text-[11px] text-slate-500 font-medium">
            Malipo yako ni salama. Tunalinda taarifa zako zote.
          </p>
        </div>
      </section>
    </div>
  );
}
