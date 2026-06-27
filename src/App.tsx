import { Routes, Route, BrowserRouter, useLocation } from 'react-router-dom';
import Welcome from './pages/Welcome';
import Home from './pages/Home';
import Topics from './pages/Topics';
import TopicDetail from './pages/TopicDetail';
import Problem from './pages/Problem';
import AIChat from './pages/AIChat';
import Community from './pages/Community';
import Profile from './pages/Profile';
import Paywall from './pages/Paywall';
import WhatsAppEscalation from './pages/WhatsAppEscalation';
import BottomNav from './components/BottomNav';

function AppContent() {
  const location = useLocation();
  const showBottomNav = !['/', '/welcome', '/whatsapp'].includes(location.pathname);

  return (
    <div className="min-h-screen bg-background text-on-surface font-sans flex flex-col">
      <div className="flex-1 pb-20">
        <Routes>
          <Route path="/" element={<Welcome />} />
          <Route path="/home" element={<Home />} />
          <Route path="/problem" element={<Problem />} />
          <Route path="/topics" element={<Topics />} />
          <Route path="/topics/:id" element={<TopicDetail />} />
          <Route path="/ai-chat" element={<AIChat />} />
          <Route path="/community" element={<Community />} />
          <Route path="/profile" element={<Profile />} />
          <Route path="/paywall" element={<Paywall />} />
          <Route path="/whatsapp" element={<WhatsAppEscalation />} />
        </Routes>
      </div>
      {showBottomNav && <BottomNav />}
    </div>
  );
}

export default function App() {
  return (
    <BrowserRouter>
      <AppContent />
    </BrowserRouter>
  );
}
