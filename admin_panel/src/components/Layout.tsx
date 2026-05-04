import { Outlet, Link, useNavigate, useLocation } from 'react-router-dom';
import { LayoutDashboard, LogOut, Users, BellRing, BookOpen, Settings, Database, FileUp, Mail, CalendarDays, ShieldCheck, Globe } from 'lucide-react';
import { supabase } from '../lib/supabase';

export function Layout() {
  const navigate = useNavigate();
  const location = useLocation();

  const handleLogout = async () => {
    await supabase.auth.signOut();
    navigate('/login');
  };

  const getLinkClass = (path: string) => {
    const isActive = location.pathname === path;
    return `flex items-center gap-3 px-4 py-3 rounded-xl transition-all duration-200 ${
      isActive 
      ? 'bg-white/10 font-bold text-white shadow-inner shadow-black/10' 
      : 'text-indigo-100 hover:bg-white/5 hover:text-white'
    }`;
  };

  return (
    <div className="flex h-screen bg-slate-50 font-sans">
      <aside className="w-72 bg-gradient-to-b from-indigo-800 to-indigo-900 text-white flex flex-col shadow-2xl relative z-10">
        <div className="p-6 font-extrabold text-2xl border-b border-white/10 flex items-center justify-center gap-2 mb-4">
          <div className="w-8 h-8 rounded-lg bg-gradient-to-tr from-blue-400 to-indigo-500 shadow-md flex items-center justify-center">
            <span className="text-white text-lg">E</span>
          </div>
          <span>EWUmate <span className="text-blue-300">Admin</span></span>
        </div>
        <nav className="flex-1 px-4 space-y-1.5 overflow-y-auto custom-scrollbar">
          <Link to="/" className={getLinkClass('/')}>
            <LayoutDashboard className="w-5 h-5 opacity-90" />
            Overview
          </Link>
          <div className="pt-4 pb-2 px-4">
            <p className="text-xs font-semibold text-indigo-300/80 uppercase tracking-wider">Database</p>
          </div>
          <Link to="/academic-data" className={getLinkClass('/academic-data')}>
            <Database className="w-5 h-5 opacity-90" />
             Global Data
          </Link>
          <Link to="/calendar-editor" className={getLinkClass('/calendar-editor')}>
            <CalendarDays className="w-5 h-5 opacity-90" />
            Calendar Manager
          </Link>
          <Link to="/users" className={getLinkClass('/users')}>
            <Users className="w-5 h-5 opacity-90" />
            Users & Profiles
          </Link>
          <Link to="/courses" className={getLinkClass('/courses')}>
            <BookOpen className="w-5 h-5 opacity-90" />
            Courses Catalog
          </Link>
          <Link to="/data-quality" className={getLinkClass('/data-quality')}>
            <ShieldCheck className="w-5 h-5 opacity-90" />
            Data Quality
          </Link>
          <div className="pt-4 pb-2 px-4">
            <p className="text-xs font-semibold text-indigo-300/80 uppercase tracking-wider">Operations</p>
          </div>
          
          <Link to="/notifications" className={getLinkClass('/notifications')}>
            <BellRing className="w-5 h-5 opacity-90" />
            Notifications
          </Link>
          <div className="pt-4 pb-2 px-4">
            <p className="text-xs font-semibold text-indigo-300/80 uppercase tracking-wider">System</p>
          </div>
          <Link to="/feedbacks" className={getLinkClass('/feedbacks')}>
            <Mail className="w-5 h-5 opacity-90" />
            User Feedbacks
          </Link>
          <Link to="/parser" className={getLinkClass('/parser')}>
            <FileUp className="w-5 h-5 opacity-90" />
            File Parser
          </Link>
          <Link to="/scraper" className={getLinkClass('/scraper')}>
            <Globe className="w-5 h-5 opacity-90" />
            Portal Scraper
          </Link>

          <Link to="/settings" className={getLinkClass('/settings')}>
            <Settings className="w-5 h-5 opacity-90" />
            App Config (CMS)
          </Link>
        </nav>
        <div className="p-5 border-t border-white/10 mt-auto bg-black/10">
          <button 
            onClick={handleLogout}
            className="flex items-center justify-center gap-2 w-full p-3 rounded-lg bg-rose-500/10 text-rose-300 font-semibold hover:bg-rose-500 hover:text-white hover:shadow-md transition-all"
          >
            <LogOut className="w-5 h-5" />
            Sign Out Session
          </button>
        </div>
      </aside>
      
      <main className="flex-1 overflow-auto bg-slate-50/50 relative">
        <header className="bg-white/80 backdrop-blur-md sticky top-0 z-20 border-b border-gray-200/80 px-8 py-5">
          <h1 className="text-2xl font-extrabold text-gray-800 tracking-tight">Admin Console</h1>
        </header>
        <div className="p-8 max-w-7xl mx-auto relative z-10">
          <Outlet />
        </div>
      </main>
    </div>
  );
}
