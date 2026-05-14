import { Outlet, Link, useNavigate, useLocation } from 'react-router-dom';
import { LayoutDashboard, LogOut, Users, BellRing, BookOpen, Settings, Database, FileUp, Mail, CalendarDays, ShieldCheck, Globe, Menu, X, TrendingUp } from 'lucide-react';
import { supabase } from '../lib/supabase';
import { motion, AnimatePresence } from 'framer-motion';
import { useState, useEffect } from 'react';
import { cn } from '../lib/utils';
import { CommandPalette } from './CommandPalette';

export function Layout() {
  const navigate = useNavigate();
  const location = useLocation();
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false);

  const [userProfile, setUserProfile] = useState<{ name: string; role: string } | null>(null);

  useEffect(() => {
    async function fetchProfile() {
      const { data: { user } } = await supabase.auth.getUser();
      if (user) {
        const { data: profile } = await supabase
          .from('profiles')
          .select('full_name')
          .eq('id', user.id)
          .single();
        
        // Check if admin
        const { data: admin } = await supabase
          .from('admin_users')
          .select('id')
          .eq('user_id', user.id)
          .maybeSingle();

        setUserProfile({
          name: profile?.full_name || user.email?.split('@')[0] || 'Administrator',
          role: admin ? 'System Architect' : 'Staff Member'
        });
      }
    }
    fetchProfile();
  }, []);

  const handleLogout = async () => {
    await supabase.auth.signOut();
    navigate('/login');
  };

  const getLinkClass = (path: string) => {
    const isActive = location.pathname === path;
    return cn(
      "flex items-center gap-3 px-4 py-3 rounded-xl transition-all duration-300 group relative overflow-hidden",
      isActive 
      ? 'bg-white/15 font-bold text-white shadow-[inset_0_1px_1px_rgba(255,255,255,0.1)]' 
      : 'text-indigo-100/70 hover:bg-white/10 hover:text-white'
    );
  };

  return (
    <div className="flex h-screen bg-[#F8FAFC] font-sans overflow-hidden relative">
      <CommandPalette />
      {/* Glassmorphic Sidebar */}
      <aside className={cn(
        "fixed inset-y-0 left-0 z-50 w-72 bg-[#1E1B4B] text-white flex flex-col shadow-2xl transition-transform duration-300 lg:relative lg:translate-x-0",
        !isMobileMenuOpen && "-translate-x-full"
      )}>
        <div className="p-8 font-black text-2xl border-b border-white/5 flex items-center justify-center gap-3 mb-4">
          <motion.div 
            initial={{ rotate: -10, scale: 0.9 }}
            animate={{ rotate: 0, scale: 1 }}
            className="w-10 h-10 rounded-xl bg-gradient-to-tr from-indigo-500 to-blue-400 shadow-lg flex items-center justify-center"
          >
            <span className="text-white text-xl">E</span>
          </motion.div>
          <span className="tracking-tighter">EWUmate <span className="text-indigo-400">Admin</span></span>
        </div>

        <nav className="flex-1 px-4 space-y-1 overflow-y-auto custom-scrollbar py-4">
          <Link to="/" className={getLinkClass('/')} onClick={() => setIsMobileMenuOpen(false)}>
            <LayoutDashboard className="w-5 h-5" />
            <span>Overview</span>
            {location.pathname === '/' && (
              <motion.div layoutId="activeNav" className="absolute left-0 w-1 h-6 bg-blue-400 rounded-r-full" />
            )}
          </Link>

          <Link to="/analytics" className={getLinkClass('/analytics')} onClick={() => setIsMobileMenuOpen(false)}>
            <TrendingUp className="w-5 h-5" />
            <span>Advanced Analytics</span>
            {location.pathname === '/analytics' && (
              <motion.div layoutId="activeNav" className="absolute left-0 w-1 h-6 bg-blue-400 rounded-r-full" />
            )}
          </Link>

          <div className="pt-6 pb-2 px-4">
            <p className="text-[10px] font-black text-indigo-400/50 uppercase tracking-[0.2em]">Core Database</p>
          </div>
          
          <Link to="/academic-data" className={getLinkClass('/academic-data')} onClick={() => setIsMobileMenuOpen(false)}>
            <Database className="w-5 h-5" />
            <span>Global Data</span>
            {location.pathname === '/academic-data' && (
              <motion.div layoutId="activeNav" className="absolute left-0 w-1 h-6 bg-blue-400 rounded-r-full" />
            )}
          </Link>

          <Link to="/calendar-editor" className={getLinkClass('/calendar-editor')} onClick={() => setIsMobileMenuOpen(false)}>
            <CalendarDays className="w-5 h-5" />
            <span>Academic Calendar</span>
            {location.pathname === '/calendar-editor' && (
              <motion.div layoutId="activeNav" className="absolute left-0 w-1 h-6 bg-blue-400 rounded-r-full" />
            )}
          </Link>

          <Link to="/users" className={getLinkClass('/users')} onClick={() => setIsMobileMenuOpen(false)}>
            <Users className="w-5 h-5" />
            <span>Students & Profiles</span>
            {location.pathname === '/users' && (
              <motion.div layoutId="activeNav" className="absolute left-0 w-1 h-6 bg-blue-400 rounded-r-full" />
            )}
          </Link>

          <Link to="/courses" className={getLinkClass('/courses')} onClick={() => setIsMobileMenuOpen(false)}>
            <BookOpen className="w-5 h-5" />
            <span>Course Catalog</span>
            {location.pathname === '/courses' && (
              <motion.div layoutId="activeNav" className="absolute left-0 w-1 h-6 bg-blue-400 rounded-r-full" />
            )}
          </Link>

          <Link to="/faculty" className={getLinkClass('/faculty')} onClick={() => setIsMobileMenuOpen(false)}>
            <Users className="w-5 h-5" />
            <span>Faculty Master</span>
            {location.pathname === '/faculty' && (
              <motion.div layoutId="activeNav" className="absolute left-0 w-1 h-6 bg-blue-400 rounded-r-full" />
            )}
          </Link>

          <Link to="/data-quality" className={getLinkClass('/data-quality')} onClick={() => setIsMobileMenuOpen(false)}>
            <ShieldCheck className="w-5 h-5" />
            <span>Data Integrity</span>
            {location.pathname === '/data-quality' && (
              <motion.div layoutId="activeNav" className="absolute left-0 w-1 h-6 bg-blue-400 rounded-r-full" />
            )}
          </Link>

          <div className="pt-6 pb-2 px-4">
            <p className="text-[10px] font-black text-indigo-400/50 uppercase tracking-[0.2em]">Automations</p>
          </div>
          
          <Link to="/scraper" className={getLinkClass('/scraper')} onClick={() => setIsMobileMenuOpen(false)}>
            <Globe className="w-5 h-5" />
            <span>Portal Scraper</span>
            {location.pathname === '/scraper' && (
              <motion.div layoutId="activeNav" className="absolute left-0 w-1 h-6 bg-blue-400 rounded-r-full" />
            )}
          </Link>

          <Link to="/notifications" className={getLinkClass('/notifications')} onClick={() => setIsMobileMenuOpen(false)}>
            <BellRing className="w-5 h-5" />
            <span>Broadcaster</span>
            {location.pathname === '/notifications' && (
              <motion.div layoutId="activeNav" className="absolute left-0 w-1 h-6 bg-blue-400 rounded-r-full" />
            )}
          </Link>

          <div className="pt-6 pb-2 px-4">
            <p className="text-[10px] font-black text-indigo-400/50 uppercase tracking-[0.2em]">Management</p>
          </div>

          <Link to="/feedbacks" className={getLinkClass('/feedbacks')} onClick={() => setIsMobileMenuOpen(false)}>
            <Mail className="w-5 h-5" />
            <span>Feedback Inbox</span>
            {location.pathname === '/feedbacks' && (
              <motion.div layoutId="activeNav" className="absolute left-0 w-1 h-6 bg-blue-400 rounded-r-full" />
            )}
          </Link>

          <Link to="/parser" className={getLinkClass('/parser')} onClick={() => setIsMobileMenuOpen(false)}>
            <FileUp className="w-5 h-5" />
            <span>File Sync</span>
            {location.pathname === '/parser' && (
              <motion.div layoutId="activeNav" className="absolute left-0 w-1 h-6 bg-blue-400 rounded-r-full" />
            )}
          </Link>

          <Link to="/settings" className={getLinkClass('/settings')} onClick={() => setIsMobileMenuOpen(false)}>
            <Settings className="w-5 h-5" />
            <span>App Config</span>
            {location.pathname === '/settings' && (
              <motion.div layoutId="activeNav" className="absolute left-0 w-1 h-6 bg-blue-400 rounded-r-full" />
            )}
          </Link>
        </nav>

        <div className="p-6 border-t border-white/5 mt-auto bg-black/20 backdrop-blur-md">
          <button 
            onClick={handleLogout}
            className="flex items-center justify-center gap-3 w-full p-4 rounded-2xl bg-rose-500/10 text-rose-400 font-bold text-xs uppercase tracking-widest hover:bg-rose-500 hover:text-white transition-all shadow-lg shadow-rose-500/5 group"
          >
            <LogOut className="w-4 h-4 group-hover:-translate-x-1 transition-transform" />
            Logout
          </button>
        </div>
      </aside>
      
      {/* Main Content */}
      <main className="flex-1 overflow-auto relative custom-scrollbar flex flex-col">
        {/* Header with Glassmorphism */}
        <header className="bg-white/80 backdrop-blur-xl sticky top-0 z-40 border-b border-slate-200/60 px-4 sm:px-8 py-4 flex items-center justify-between">
          <div className="flex items-center gap-4">
            <button 
              className="lg:hidden p-2 text-slate-600 hover:bg-slate-100 rounded-xl transition-colors"
              onClick={() => setIsMobileMenuOpen(!isMobileMenuOpen)}
            >
              {isMobileMenuOpen ? <X /> : <Menu />}
            </button>
            <div>
              <h1 className="text-xl font-black text-slate-900 tracking-tight">Admin Console</h1>
              <p className="text-[10px] font-bold text-slate-400 uppercase tracking-widest">Management Terminal</p>
            </div>
          </div>
          
          <div className="flex items-center gap-4">
             <div className="hidden sm:flex flex-col items-end mr-2">
               <span className="text-xs font-black text-slate-900">{userProfile?.name || 'Loading...'}</span>
               <span className="text-[9px] font-bold text-indigo-500 uppercase">{userProfile?.role || 'Staff'}</span>
             </div>
             <div className="w-10 h-10 rounded-2xl bg-indigo-100 border border-indigo-200 flex items-center justify-center overflow-hidden shadow-sm shrink-0">
                <div className="w-full h-full bg-gradient-to-br from-indigo-500 to-blue-400 opacity-80 flex items-center justify-center text-white font-black">
                  {userProfile?.name?.charAt(0) || 'A'}
                </div>
             </div>
          </div>
        </header>

        {/* Content Wrapper with Animations */}
        <div className="p-4 sm:p-6 lg:p-8 w-full max-w-screen-2xl mx-auto flex-1">
          <AnimatePresence mode="wait">
            <motion.div
              key={location.pathname}
              initial={{ opacity: 0, y: 10 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -10 }}
              transition={{ duration: 0.3, ease: [0.22, 1, 0.36, 1] }}
            >
              <Outlet />
            </motion.div>
          </AnimatePresence>
        </div>
      </main>

      {/* Mobile Overlay */}
      {isMobileMenuOpen && (
        <div 
          className="fixed inset-0 bg-slate-900/60 backdrop-blur-sm z-40 lg:hidden"
          onClick={() => setIsMobileMenuOpen(false)}
        />
      )}
    </div>
  );
}

