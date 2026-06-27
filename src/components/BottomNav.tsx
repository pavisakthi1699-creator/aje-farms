import { Link, useLocation } from 'react-router-dom';
import { cn } from '../lib/utils';
import { Home, BookOpen, Bot, Users, User } from 'lucide-react';

export default function BottomNav() {
  const location = useLocation();

  const navItems = [
    { path: '/home', icon: Home, label: 'Nyumbani' },
    { path: '/topics', icon: BookOpen, label: 'Mafunzo' },
    { path: '/ai-chat', icon: Bot, label: 'Uliza AI' },
    { path: '/community', icon: Users, label: 'Jamii' },
    { path: '/profile', icon: User, label: 'Akaunti' },
  ];

  return (
    <nav className="fixed bottom-0 left-0 w-full z-50 flex justify-around items-center px-4 py-4 bg-white/90 backdrop-blur-xl border-t border-slate-100 shadow-float rounded-t-[32px]">
      {navItems.map((item) => {
        const isActive = location.pathname.startsWith(item.path);
        const Icon = item.icon;
        
        return (
          <Link
            key={item.path}
            to={item.path}
            className={cn(
              "flex flex-col items-center justify-center p-2 rounded-[20px] transition-all duration-300",
              isActive 
                ? "bg-primary text-white shadow-button px-5 py-2 -translate-y-1" 
                : "text-slate-400 hover:text-slate-600 hover:bg-slate-50"
            )}
          >
            <Icon className={cn("w-6 h-6", isActive && "fill-current opacity-90")} strokeWidth={isActive ? 2.5 : 2} />
            {isActive && (
              <span className="text-[10px] mt-1 font-bold tracking-wide">
                {item.label}
              </span>
            )}
          </Link>
        );
      })}
    </nav>
  );
}
