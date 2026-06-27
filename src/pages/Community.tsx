import { MapPin, MessageCircle, Bot, PhoneCall, MoreVertical, Plus } from 'lucide-react';
import { COMMUNITY_POSTS } from '../data';
import { useNavigate } from 'react-router-dom';

export default function Community() {
  const navigate = useNavigate();

  return (
    <div className="pt-20 px-5 max-w-lg mx-auto pb-24 bg-background min-h-screen">
      <header className="flex justify-between items-center w-full px-5 h-16 fixed top-0 left-0 right-0 z-40 bg-white/80 backdrop-blur border-b border-slate-200">
        <h1 className="font-bold text-xl text-primary mx-auto">Jamii ya Wakulima</h1>
      </header>

      <div className="flex gap-2 overflow-x-auto pb-2 no-scrollbar mb-6 -mx-5 px-5">
        <button className="bg-primary text-white px-5 py-1.5 rounded-full text-xs font-bold whitespace-nowrap shadow-sm">Zote</button>
        <button className="bg-white text-slate-500 border border-slate-200 px-5 py-1.5 rounded-full text-xs font-bold whitespace-nowrap">Mimea</button>
        <button className="bg-white text-slate-500 border border-slate-200 px-5 py-1.5 rounded-full text-xs font-bold whitespace-nowrap">Mifugo</button>
        <button className="bg-white text-slate-500 border border-slate-200 px-5 py-1.5 rounded-full text-xs font-bold whitespace-nowrap">Masoko</button>
      </div>

      <div className="space-y-6">
        {COMMUNITY_POSTS.map((post) => (
          <article key={post.id} className="bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden active:scale-[0.98] transition-transform">
            <div className="p-4 flex items-center justify-between">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-full flex items-center justify-center font-bold bg-slate-100 overflow-hidden">
                  <img src={post.authorImage} alt={post.author} className="w-full h-full object-cover" />
                </div>
                <div>
                  <p className="font-bold text-slate-800 text-sm">{post.author}</p>
                  <p className="text-[10px] text-slate-500 font-medium flex items-center gap-1">
                    <MapPin className="w-3 h-3" />
                    {post.location} • {post.time}
                  </p>
                </div>
              </div>
              <button className="text-slate-400 hover:text-slate-600">
                <MoreVertical className="w-5 h-5" />
              </button>
            </div>
            
            <div className="px-4 pb-4 space-y-4">
              <p className="text-slate-800 text-sm leading-relaxed">{post.content}</p>
              
              {post.image && (
                <div className="rounded-xl overflow-hidden aspect-[16/10] bg-slate-100">
                  <img src={post.image} alt="Post inline image" className="w-full h-full object-cover" />
                </div>
              )}
              
              {post.relatedTopic && (
                <div className="bg-slate-50 p-3 rounded-xl border border-slate-200 flex items-center gap-3 cursor-pointer">
                  <div className="bg-primary/10 text-primary w-10 h-10 rounded-lg flex items-center justify-center">
                    <MessageCircle className="w-5 h-5" />
                  </div>
                  <div>
                    <p className="text-[9px] uppercase font-bold text-primary mb-0.5 tracking-wider">Somo Linahusiana</p>
                    <p className="text-xs font-bold text-slate-700">{post.relatedTopic}</p>
                  </div>
                </div>
              )}

              <div className="flex items-center gap-2 pt-2 border-t border-slate-100">
                <button className="flex-1 flex justify-center items-center gap-2 py-2 border border-slate-200 rounded-full text-xs font-bold text-slate-700">
                  <MessageCircle className="w-4 h-4" />
                  Jibu
                </button>
                <button 
                  onClick={() => navigate('/ai-chat?topic=' + post.content)}
                  className="flex-1 flex justify-center items-center gap-2 py-2 bg-primary/10 text-primary rounded-full text-xs font-bold"
                >
                  <Bot className="w-4 h-4" />
                  Uliza AI
                </button>
                <button 
                  onClick={() => navigate('/whatsapp')}
                  className="w-10 h-10 border border-secondary/20 bg-secondary/5 text-secondary rounded-full flex items-center justify-center shrink-0"
                >
                  <PhoneCall className="w-4 h-4" />
                </button>
              </div>
            </div>
          </article>
        ))}
      </div>

      <button className="fixed bottom-24 right-5 w-14 h-14 bg-primary text-white rounded-2xl shadow-xl flex items-center justify-center hover:scale-105 active:scale-95 transition-all z-40">
        <Plus className="w-7 h-7" />
      </button>
    </div>
  );
}
