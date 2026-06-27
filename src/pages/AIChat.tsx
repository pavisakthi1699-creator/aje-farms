import { useState, useRef, useEffect } from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import { Send, Bot, FileText, ChevronRight, User, PlusCircle, ArrowLeft, Sparkles } from 'lucide-react';
import ReactMarkdown from 'react-markdown';
import { chatWithMwalimu } from '../lib/gemini';
import { cn } from '../lib/utils';

export default function AIChat() {
  const navigate = useNavigate();
  const location = useLocation();
  const [messages, setMessages] = useState<{role: 'user'|'model', text: string}[]>([
    { role: 'model', text: 'Habari! Mimi ni Mwalimu AI. Nawezaje kukusaidia kuhusu kilimo leo?' }
  ]);
  const [input, setInput] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const messagesEndRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    // Check if we came from problem screen with a topic
    const searchParams = new URLSearchParams(location.search);
    const topic = searchParams.get('topic');
    if (topic && messages.length === 1) {
      handleSend(`Nina shida kuhusu ${topic}. Naweza kupata ushauri?`);
    }
  }, [location]);

  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages]);

  const handleSend = async (text: string) => {
    if (!text.trim()) return;
    
    const newMsg = { role: 'user' as const, text };
    setMessages(prev => [...prev, newMsg]);
    setInput('');
    setIsLoading(true);

    const history = messages.map(m => ({
      role: m.role,
      parts: [{ text: m.text }]
    }));

    const responseText = await chatWithMwalimu(text, history);
    
    setMessages(prev => [...prev, { role: 'model', text: responseText || '' }]);
    setIsLoading(false);
  };

  const SUGGESTIONS = [
    'Dawa gani kwa ukungu?',
    'Mbolea ya DAP',
    'Matatizo ya Nyanya',
  ];

  return (
    <div className="flex flex-col h-screen bg-background relative overflow-hidden max-w-lg mx-auto">
      {/* Decorative bg */}
      <div className="absolute top-[-10%] right-[-10%] w-[300px] h-[300px] bg-accent-mint rounded-full blur-[100px] opacity-60 z-0"></div>

      {/* Header */}
      <header className="flex items-center justify-between px-4 h-20 bg-white/80 backdrop-blur-xl border-b border-slate-100 z-10 shrink-0">
        <div className="flex items-center gap-3">
          <button onClick={() => navigate(-1)} className="w-10 h-10 bg-slate-50 border border-slate-100 rounded-full flex items-center justify-center text-slate-600 hover:bg-slate-100 transition-colors">
            <ArrowLeft className="w-5 h-5" />
          </button>
          <div className="flex flex-col">
            <div className="flex items-center gap-1.5">
              <Sparkles className="w-3.5 h-3.5 text-primary" />
              <h1 className="font-bold text-slate-800 text-[15px]">Mwalimu AI</h1>
            </div>
            <span className="text-[10px] font-bold text-green-600 uppercase tracking-widest mt-0.5 w-full flex items-center gap-1.5">
               <div className="w-2 h-2 rounded-full bg-green-500 animate-pulse"></div>
               Online
            </span>
          </div>
        </div>
        <div className="w-10 h-10 rounded-[14px] bg-accent-blue flex items-center justify-center border border-blue-100 text-blue-600 shadow-sm">
          <Bot className="w-6 h-6" />
        </div>
      </header>

      {/* Chat Area */}
      <div className="flex-1 overflow-y-auto p-4 space-y-6 z-10 text-[15px] font-medium leading-relaxed">
        {messages.map((msg, i) => (
          <div key={i} className={cn("flex flex-col max-w-[85%]", msg.role === 'user' ? "items-end self-end ml-auto" : "items-start self-start")}>
            {msg.role === 'model' && i !== 0 && (
              <div className="flex items-center gap-2 mb-2 ml-2">
                <span className="text-[10px] font-bold text-slate-400 uppercase tracking-widest">Mwalimu AI</span>
              </div>
            )}
            <div className={cn(
              "p-5 rounded-[24px] shadow-soft",
              msg.role === 'user' 
                ? "bg-slate-900 text-white rounded-br-sm" 
                : "bg-white border border-slate-100 text-slate-800 rounded-tl-sm"
            )}>
              <div className="markdown-body text-[14.5px]">
                <ReactMarkdown>{msg.text}</ReactMarkdown>
              </div>
              
              {/* Show source card for Model responses if they contain "Chanzo:" */}
              {msg.role === 'model' && msg.text.includes('Chanzo:') && (
                <div 
                  onClick={() => navigate('/topics')}
                  className="mt-4 p-4 bg-accent-blue/30 rounded-[20px] border border-blue-100/50 flex items-center gap-3 cursor-pointer hover:bg-accent-blue/60 transition-colors"
                >
                  <div className="w-10 h-10 bg-white rounded-full flex items-center justify-center shadow-sm text-blue-600">
                    <FileText className="w-5 h-5" />
                  </div>
                  <div className="flex-1">
                    <span className="text-[9px] uppercase font-bold text-slate-400 tracking-wider">Rejea Mafunzo</span>
                    <p className="text-[13px] font-bold text-slate-700">Ona Kwenye Mafunzo</p>
                  </div>
                  <ChevronRight className="w-4 h-4 text-slate-400" />
                </div>
              )}
            </div>
          </div>
        ))}
        {isLoading && (
          <div className="flex items-start self-start max-w-[85%]">
             <div className="bg-white border border-slate-100 p-5 rounded-[24px] rounded-tl-sm shadow-soft flex gap-2 items-center">
               <div className="w-2.5 h-2.5 bg-primary/40 rounded-full animate-bounce" style={{ animationDelay: '0ms' }}></div>
               <div className="w-2.5 h-2.5 bg-primary/40 rounded-full animate-bounce" style={{ animationDelay: '150ms' }}></div>
               <div className="w-2.5 h-2.5 bg-primary/40 rounded-full animate-bounce" style={{ animationDelay: '300ms' }}></div>
             </div>
          </div>
        )}
        <div ref={messagesEndRef} className="h-4" />
      </div>

      {messages.length === 1 && (
        <div className="px-4 pb-2 z-10 w-full overflow-hidden">
          <div className="flex gap-2 overflow-x-auto pb-4 no-scrollbar">
            {SUGGESTIONS.map((s, i) => (
              <button 
                key={i} 
                onClick={() => handleSend(s)}
                className="shrink-0 bg-white border border-slate-100 text-slate-700 text-[13px] font-bold py-3 px-5 rounded-full shadow-sm hover:bg-slate-50 transition-colors"
              >
                {s}
              </button>
            ))}
          </div>
        </div>
      )}

      {/* Input Area */}
      <div className="p-4 bg-white/90 backdrop-blur-xl border-t border-slate-100 z-10 shrink-0 pb-safe pb-24">
        <div className="flex gap-2 items-center">
          <input 
            type="text" 
            value={input}
            onChange={(e) => setInput(e.target.value)}
            onKeyDown={(e) => e.key === 'Enter' && handleSend(input)}
            placeholder="Uliza ushauri kuhusu kilimo..."
            className="flex-1 bg-slate-100 border-none rounded-full px-5 py-4 h-14 outline-none focus:ring-2 focus:ring-primary/20 text-[15px] font-medium"
          />
          <button 
            onClick={() => handleSend(input)}
            disabled={!input.trim() || isLoading}
            className="w-14 h-14 bg-primary text-white rounded-full flex items-center justify-center shrink-0 disabled:opacity-50 disabled:bg-slate-300 shadow-button active:scale-95 transition-transform"
          >
            <Send className="w-5 h-5 ml-1" />
          </button>
        </div>
      </div>
    </div>
  );
}
