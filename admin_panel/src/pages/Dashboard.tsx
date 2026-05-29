import { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import toast from 'react-hot-toast';
import { supabaseAdmin as supabase } from '../lib/supabase';
import { 
  Users, BookOpen, Activity, GraduationCap, Clock, 
  CalendarClock, Mail, Search, Zap, ShieldCheck, 
  TrendingUp, ArrowUpRight, RefreshCcw
} from 'lucide-react';
import { 
  XAxis, YAxis, CartesianGrid, 
  Tooltip, ResponsiveContainer, AreaChart, Area 
} from 'recharts';
import { motion } from 'framer-motion';
import type { Profile, DashboardStats, SemesterTrackStats } from '../types';
import { useTheme } from '../components/ThemeContext';
import { CardSkeleton, Skeleton } from '../components/Skeleton';
import { cn } from '../lib/utils';

export function Dashboard() {
  const navigate = useNavigate();
  const { theme } = useTheme();
  const [stats, setStats] = useState<DashboardStats>({
    users: 0,
    activeUsers24h: 0,
    programs: 0,
    courses: 0,
    notifications: 0,
    pendingFeedbacks: 0,
    inProgressFeedbacks: 0,
    resolvedFeedbacks: 0,
    ignoredFeedbacks: 0,
  });
  const [recentUsers, setRecentUsers] = useState<Profile[]>([]);
  const [activeUsers, setActiveUsers] = useState<Profile[]>([]);
  const [semesterStats, setSemesterStats] = useState<Record<string, SemesterTrackStats>>({});
  const [registrationTrend, setRegistrationTrend] = useState<any[]>([]);
  const [activityTrend, setActivityTrend] = useState<any[]>([]);
  const [vaultStats, setVaultStats] = useState({
    pending: 0,
    removalRequested: 0,
    approved: 0,
    rejected: 0,
    total: 0
  });
  const [loading, setLoading] = useState(true);
  const [isRefreshing, setIsRefreshing] = useState(false);
  
  // Search state
  const [searchTerm, setSearchTerm] = useState('');
  const [searchResults, setSearchResults] = useState<Profile[]>([]);

  // Real-time System Infrastructure Health Check State
  const [isCheckingHealth, setIsCheckingHealth] = useState(false);
  const [infraStatus, setInfraStatus] = useState({
    scraper: 'Pending Diagnostics',
    azure: 'Pending Diagnostics',
    db: 'Pending Diagnostics',
    broadcaster: 'Pending Diagnostics'
  });
  const [infraColors, setInfraColors] = useState({
    scraper: 'bg-slate-300 dark:bg-white/10 text-slate-400',
    azure: 'bg-slate-300 dark:bg-white/10 text-slate-400',
    db: 'bg-slate-300 dark:bg-white/10 text-slate-400',
    broadcaster: 'bg-slate-300 dark:bg-white/10 text-slate-400'
  });

  const checkInfrastructureHealth = async () => {
    setIsCheckingHealth(true);
    const toastId = toast.loading('Running system diagnostics...');
    
    // 1. Check DB Edge Latency
    const startDb = performance.now();
    try {
      const { error } = await supabase.from('profiles').select('id').limit(1).maybeSingle();
      const endDb = performance.now();
      const latency = endDb - startDb;
      
      let status = 'Optimized';
      let color = 'bg-indigo-500 text-white';
      if (error) {
        status = 'Error';
        color = 'bg-rose-500 text-white';
      } else if (latency > 1000) {
        status = 'Lagging';
        color = 'bg-amber-500 text-white';
      } else if (latency > 300) {
        status = 'Operational';
        color = 'bg-emerald-500 text-white';
      }
      
      setInfraStatus(prev => ({ ...prev, db: status }));
      setInfraColors(prev => ({ ...prev, db: color }));
    } catch {
      setInfraStatus(prev => ({ ...prev, db: 'Offline' }));
      setInfraColors(prev => ({ ...prev, db: 'bg-rose-500 text-white' }));
    }

    // 2. Check Azure Function Connectivity (Securely via azure-admin-proxy)
    try {
      const res = await supabase.functions.invoke('azure-admin-proxy', {
        body: {
          action: 'portal_sync',
          semester: 'PING',
          preview: true
        }
      });
      if (!res.error) {
        setInfraStatus(prev => ({ ...prev, scraper: 'Healthy', azure: 'Live' }));
        setInfraColors(prev => ({ ...prev, scraper: 'bg-amber-500 text-white', azure: 'bg-emerald-500 text-white' }));
      } else {
        setInfraStatus(prev => ({ ...prev, scraper: 'Issues', azure: 'Down' }));
        setInfraColors(prev => ({ ...prev, scraper: 'bg-rose-500 text-white', azure: 'bg-rose-500 text-white' }));
      }
    } catch {
      setInfraStatus(prev => ({ ...prev, scraper: 'Offline', azure: 'Offline' }));
      setInfraColors(prev => ({ ...prev, scraper: 'bg-rose-500 text-white', azure: 'bg-rose-500 text-white' }));
    }

    // 3. Check Broadcaster (Ping securely under admin session token)
    try {
      const { error } = await supabase.functions.invoke('broadcast', {
        body: { ping: true }
      });
      if (!error) {
        setInfraStatus(prev => ({ ...prev, broadcaster: 'Idle' }));
        setInfraColors(prev => ({ ...prev, broadcaster: 'bg-slate-400 text-white' }));
      } else {
        setInfraStatus(prev => ({ ...prev, broadcaster: 'Issues' }));
        setInfraColors(prev => ({ ...prev, broadcaster: 'bg-rose-500 text-white' }));
      }
    } catch {
      setInfraStatus(prev => ({ ...prev, broadcaster: 'Offline' }));
      setInfraColors(prev => ({ ...prev, broadcaster: 'bg-rose-500 text-white' }));
    }

    setIsCheckingHealth(false);
    toast.success('Diagnostics completed successfully!', { id: toastId });
  };

  const fetchDashboardData = async (silent = false) => {
    try {
      if (!silent) setLoading(true);
      else setIsRefreshing(true);

      const { data, error } = await supabase.rpc('get_admin_dashboard_stats');
      if (error) throw error;

      if (data) {
        setStats({
          users: data.stats.users || 0,
          activeUsers24h: data.stats.activeUsers24h || 0,
          programs: data.stats.programs || 0,
          courses: data.stats.courses || 0,
          notifications: data.stats.notifications || 0,
          pendingFeedbacks: data.stats.pendingFeedbacks || 0,
          inProgressFeedbacks: data.stats.inProgressFeedbacks || 0,
          resolvedFeedbacks: data.stats.resolvedFeedbacks || 0,
          ignoredFeedbacks: data.stats.ignoredFeedbacks || 0,
        });

        setVaultStats({
          pending: data.vaultStats.pending || 0,
          removalRequested: data.vaultStats.removalRequested || 0,
          approved: data.vaultStats.approved || 0,
          rejected: data.vaultStats.rejected || 0,
          total: data.vaultStats.total || 0
        });

        setRecentUsers((data.recentUsers as Profile[]) || []);
        setActiveUsers((data.activeUsers as Profile[]) || []);
        setSemesterStats(data.semesterStats || {});
        setRegistrationTrend(data.registrationTrend || []);
        setActivityTrend(data.activityTrend || []);
      }
    } catch (err) {
      console.error('Failed to fetch dashboard data:', err);
      toast.error('Failed to load real-time dashboard analytics');
    } finally {
      setLoading(false);
      setIsRefreshing(false);
    }
  };

  useEffect(() => {
    fetchDashboardData();
  }, []);

  const toggleTrackState = async (track: string, field: 'is_advising_open' | 'is_next_semester_open', currentValue: boolean) => {
    const newValue = !currentValue;
    
    // Optimistic state update
    setSemesterStats(prev => {
      if (!prev[track]) return prev;
      return {
        ...prev,
        [track]: {
          ...prev[track],
          [field]: newValue
        }
      };
    });

    const { error } = await supabase
      .from('active_semester')
      .update({ [field]: newValue })
      .eq('track', track);

    if (error) {
      toast.error(`Failed to update ${track}: ${error.message}`);
      fetchDashboardData(true);
    } else {
      toast.success(`${track.replace('_', ' ')} ${field === 'is_advising_open' ? 'Advising' : 'Next Semester'} set to ${newValue ? 'ON' : 'OFF'}`);
    }
  };

  // Handle Search
  useEffect(() => {
    const delayDebounceFn = setTimeout(async () => {
      if (searchTerm.trim().length < 2) {
        setSearchResults([]);
        return;
      }


      try {
        const { data } = await supabase
          .from('profiles')
          .select('id, full_name, student_id, program_code')
          .or(`full_name.ilike.%${searchTerm}%,student_id.ilike.%${searchTerm}%`)
          .limit(5);
        
        setSearchResults((data as Profile[]) || []);
      } catch (err) {
        console.error('Search failed:', err);
      } finally {

      }
    }, 300);

    return () => clearTimeout(delayDebounceFn);
  }, [searchTerm]);

  if (loading) {
    return (
      <div className="space-y-8 animate-in fade-in duration-500">
        <div className="flex justify-between items-center">
          <Skeleton className="w-64 h-10" />
          <Skeleton className="w-48 h-10 rounded-xl" />
        </div>
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
          <CardSkeleton />
          <CardSkeleton />
          <CardSkeleton />
          <CardSkeleton />
        </div>
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
           <Skeleton className="lg:col-span-2 h-[400px] rounded-3xl" />
           <Skeleton className="h-[400px] rounded-3xl" />
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-8 animate-in fade-in duration-700">
      {/* Header Section */}
      <div className="flex flex-col md:flex-row justify-between gap-6 items-start md:items-center">
        <div>
          <h2 className="text-2xl sm:text-3xl font-black text-slate-900 dark:text-white tracking-tight flex items-center gap-3">
            Platform Insights
            {isRefreshing && <RefreshCcw className="w-5 h-5 text-indigo-500 animate-spin" />}
          </h2>
          <p className="text-slate-400 dark:text-slate-500 font-bold text-[10px] uppercase tracking-widest mt-1">Live Statistics & Global Overview</p>
        </div>

        <div className="flex items-center gap-3 w-full md:w-auto">
          <div className="relative flex-1 md:w-80">
            <Search className="absolute left-4 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400" />
            <input
              type="text"
              className="w-full pl-11 pr-4 py-3 bg-white dark:bg-slate-900 border border-slate-200 dark:border-white/10 rounded-2xl text-sm font-bold text-slate-900 dark:text-white focus:ring-2 focus:ring-indigo-100 dark:focus:ring-indigo-500/20 outline-none transition-all placeholder:text-slate-400 dark:placeholder:text-slate-500 shadow-sm"
              placeholder="Search students..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
            />
            {searchResults.length > 0 && (
              <motion.div 
                initial={{ opacity: 0, y: 10 }}
                animate={{ opacity: 1, y: 0 }}
                className="absolute z-50 mt-2 w-full bg-white dark:bg-slate-800 rounded-2xl shadow-2xl border border-slate-100 dark:border-white/5 overflow-hidden"
              >
                {searchResults.map((user) => (
                  <button
                    key={user.id}
                    className="w-full text-left p-4 hover:bg-slate-50 dark:hover:bg-white/5 border-b border-slate-50 dark:border-white/5 last:border-0 transition-colors"
                    onClick={() => navigate(`/users/${user.id}`)}
                  >
                    <div className="font-black text-slate-900 dark:text-white">{user.full_name}</div>
                    <div className="text-[10px] text-indigo-500 font-black uppercase tracking-wider">{user.student_id} • {user.program_code}</div>
                  </button>
                ))}
              </motion.div>
            )}
          </div>
          <button 
            onClick={() => fetchDashboardData(true)}
            className="p-3 bg-white dark:bg-slate-900 border border-slate-200 dark:border-white/10 rounded-2xl text-slate-600 dark:text-slate-400 hover:bg-slate-50 dark:hover:bg-white/5 transition-all shadow-sm"
          >
            <RefreshCcw className={cn("w-5 h-5", isRefreshing && "animate-spin")} />
          </button>
        </div>
      </div>
      
      {/* Top Stats Grid */}
      <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-4 sm:gap-6">    
        <motion.div whileHover={{ y: -4 }} className="bg-white dark:bg-slate-800 rounded-3xl p-6 shadow-sm border border-slate-100 dark:border-white/5 flex items-center gap-5 transition-all">
          <div className="p-4 rounded-2xl bg-indigo-50 dark:bg-indigo-500/10 text-indigo-600 dark:text-indigo-400 shadow-inner">
            <Users className="w-8 h-8" />
          </div>
          <div>
            <p className="text-[10px] font-black text-slate-400 dark:text-slate-500 uppercase tracking-widest">Total Users</p>
            <p className="text-2xl font-black text-slate-900 dark:text-white">{stats.users.toLocaleString()}</p>
          </div>
        </motion.div>

        <motion.div whileHover={{ y: -4 }} className="bg-slate-900 rounded-3xl p-6 shadow-xl border border-slate-800 flex items-center gap-5 transition-all text-white">
          <div className="p-4 rounded-2xl bg-white/10 text-white shadow-inner backdrop-blur-sm">
            <Activity className="w-8 h-8" />
          </div>
          <div>
            <p className="text-[10px] font-black text-slate-400 uppercase tracking-widest">Active (24h)</p>
            <p className="text-2xl font-black text-white">{stats.activeUsers24h.toLocaleString()}</p>
          </div>
        </motion.div>

        <motion.div whileHover={{ y: -4 }} className="bg-white dark:bg-slate-800 rounded-3xl p-6 shadow-sm border border-slate-100 dark:border-white/5 flex items-center gap-5 transition-all">
          <div className="p-4 rounded-2xl bg-emerald-50 dark:bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 shadow-inner">
            <BookOpen className="w-8 h-8" />
          </div>
          <div>
            <p className="text-[10px] font-black text-slate-400 dark:text-slate-500 uppercase tracking-widest">Programs</p>
            <p className="text-2xl font-black text-slate-900 dark:text-white">{stats.programs}</p>
          </div>
        </motion.div>

        <motion.div whileHover={{ y: -4 }} className="bg-white dark:bg-slate-800 rounded-3xl p-6 shadow-sm border border-slate-100 dark:border-white/5 flex items-center gap-5 transition-all">
          <div className="p-4 rounded-2xl bg-amber-50 dark:bg-amber-500/10 text-amber-600 dark:text-amber-400 shadow-inner">
            <GraduationCap className="w-8 h-8" />
          </div>
          <div>
            <p className="text-[10px] font-black text-slate-400 dark:text-slate-500 uppercase tracking-widest">Live Courses</p>
            <p className="text-2xl font-black text-slate-900 dark:text-white">{stats.courses.toLocaleString()}</p>
          </div>
        </motion.div>
      </div>

      {/* Main Analytics Row */}
      <div className="grid grid-cols-1 lg:grid-cols-4 gap-8">
        {/* Registration Chart */}
        <div className="lg:col-span-2 bg-white dark:bg-slate-800 rounded-[1.5rem] sm:rounded-[2rem] p-4 sm:p-8 shadow-sm border border-slate-100 dark:border-white/5 flex flex-col overflow-hidden">
          <div className="flex items-center justify-between mb-8">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-indigo-50 dark:bg-indigo-500/10 rounded-xl">
                <TrendingUp className="w-5 h-5 text-indigo-600 dark:text-indigo-400" />
              </div>
              <div>
                <h3 className="text-lg font-black text-slate-900 dark:text-white tracking-tight">Growth Trend</h3>
                <p className="text-[10px] font-bold text-slate-400 dark:text-slate-500 uppercase tracking-widest">New users per day (Last 14 days)</p>
              </div>
            </div>
            <div className="flex items-center gap-2 px-3 py-1 bg-emerald-50 dark:bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 rounded-full text-[10px] font-black uppercase">
              <ArrowUpRight className="w-3 h-3" />
              Rising
            </div>
          </div>
          
          <div className="flex-1 h-[280px] w-full">
            <ResponsiveContainer width="100%" height={280}>
              <AreaChart data={registrationTrend}>
                <defs>
                  <linearGradient id="colorTotal" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="#6366f1" stopOpacity={0.3}/>
                    <stop offset="95%" stopColor="#6366f1" stopOpacity={0}/>
                  </linearGradient>
                </defs>
                <CartesianGrid strokeDasharray="3 3" vertical={false} stroke={theme === 'dark' ? '#334155' : '#f1f5f9'} />
                <XAxis 
                  dataKey="date" 
                  axisLine={false} 
                  tickLine={false} 
                  tick={{ fontSize: 10, fontWeight: 'bold', fill: '#94a3b8' }} 
                  dy={10}
                />
                <YAxis 
                  axisLine={false} 
                  tickLine={false} 
                  tick={{ fontSize: 10, fontWeight: 'bold', fill: '#94a3b8' }} 
                />
                <Tooltip 
                  contentStyle={{ 
                    borderRadius: '16px', 
                    border: 'none', 
                    boxShadow: '0 20px 25px -5px rgb(0 0 0 / 0.1)',
                    fontSize: '12px',
                    fontWeight: 'bold'
                  }}
                />
                <Area 
                  type="monotone" 
                  dataKey="count" 
                  stroke="#6366f1" 
                  strokeWidth={4} 
                  fillOpacity={1} 
                  fill="url(#colorTotal)" 
                />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        </div>

        {/* Activity Trend Chart */}
        <div className="lg:col-span-2 bg-white dark:bg-slate-800 rounded-[1.5rem] sm:rounded-[2rem] p-4 sm:p-8 shadow-sm border border-slate-100 dark:border-white/5 flex flex-col overflow-hidden">
          <div className="flex items-center justify-between mb-8">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-emerald-50 dark:bg-emerald-500/10 rounded-xl">
                <Activity className="w-5 h-5 text-emerald-600 dark:text-emerald-400" />
              </div>
              <div>
                <h3 className="text-lg font-black text-slate-900 dark:text-white tracking-tight">Activity Heatmap</h3>
                <p className="text-[10px] font-bold text-slate-400 dark:text-slate-500 uppercase tracking-widest">Active users per day (Last 7 days)</p>
              </div>
            </div>
            <div className="flex items-center gap-2 px-3 py-1 bg-indigo-50 dark:bg-indigo-500/10 text-indigo-600 dark:text-indigo-400 rounded-full text-[10px] font-black uppercase">
              7D Window
            </div>
          </div>
          
          <div className="flex-1 h-[280px] w-full">
            <ResponsiveContainer width="100%" height={280}>
              <AreaChart data={activityTrend}>
                <defs>
                  <linearGradient id="colorActive" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="#10b981" stopOpacity={0.3}/>
                    <stop offset="95%" stopColor="#10b981" stopOpacity={0}/>
                  </linearGradient>
                </defs>
                <CartesianGrid strokeDasharray="3 3" vertical={false} stroke={theme === 'dark' ? '#334155' : '#f1f5f9'} />
                <XAxis 
                  dataKey="date" 
                  axisLine={false} 
                  tickLine={false} 
                  tick={{ fontSize: 10, fontWeight: 'bold', fill: '#94a3b8' }} 
                  dy={10}
                />
                <YAxis 
                  axisLine={false} 
                  tickLine={false} 
                  tick={{ fontSize: 10, fontWeight: 'bold', fill: '#94a3b8' }} 
                />
                <Tooltip 
                  contentStyle={{ 
                    borderRadius: '16px', 
                    border: 'none', 
                    boxShadow: '0 20px 25px -5px rgb(0 0 0 / 0.1)',
                    fontSize: '12px',
                    fontWeight: 'bold'
                  }}
                />
                <Area 
                  type="monotone" 
                  dataKey="active" 
                  stroke="#10b981" 
                  strokeWidth={4} 
                  fillOpacity={1} 
                  fill="url(#colorActive)" 
                />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        </div>

        {/* System Health / Status */}
        <div className="lg:col-span-4 grid grid-cols-1 md:grid-cols-4 gap-8">
           <div className="md:col-span-3 bg-white dark:bg-slate-800 rounded-[1.5rem] sm:rounded-[2rem] p-6 sm:p-8 shadow-sm border border-slate-100 dark:border-white/5 flex flex-col">
              <div className="flex flex-col sm:flex-row justify-between gap-4 items-start sm:items-center mb-8">
                 <div>
                    <h3 className="text-lg font-black text-slate-900 dark:text-white tracking-tight">System Infrastructure</h3>
                    <p className="text-[9px] font-bold text-slate-400 dark:text-slate-500 uppercase tracking-widest mt-0.5">Diagnostics & Cloud Telemetry</p>
                 </div>
                 <button 
                   onClick={checkInfrastructureHealth}
                   disabled={isCheckingHealth}
                   className={cn(
                     "text-[10px] font-black px-4 py-2.5 rounded-xl transition-all uppercase tracking-wider flex items-center gap-2 border",
                     isCheckingHealth 
                       ? "bg-slate-100 dark:bg-white/5 text-slate-400 dark:text-slate-500 border-slate-200 dark:border-white/5 cursor-not-allowed"
                       : "bg-indigo-50 dark:bg-indigo-500/10 hover:bg-indigo-100 dark:hover:bg-indigo-500/20 text-indigo-600 dark:text-indigo-400 border-indigo-100/50 dark:border-indigo-500/20 shadow-sm"
                   )}
                 >
                   {isCheckingHealth ? (
                     <>
                       <RefreshCcw className="w-3.5 h-3.5 animate-spin" />
                       Running...
                     </>
                   ) : (
                     'Run Diagnostics'
                   )}
                 </button>
              </div>
              <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
                {[
                  { label: 'Portal Scraper', status: infraStatus.scraper, icon: Zap, color: infraColors.scraper },
                  { label: 'Azure Core', status: infraStatus.azure, icon: ShieldCheck, color: infraColors.azure },
                  { label: 'Cloud DB', status: infraStatus.db, icon: Clock, color: infraColors.db },
                  { label: 'Broadcaster', status: infraStatus.broadcaster, icon: Mail, color: infraColors.broadcaster }
                ].map((sys, i) => (
                  <div key={i} className="p-4 bg-slate-50 dark:bg-white/5 rounded-2xl border border-slate-100 dark:border-white/5 flex items-center justify-between group hover:bg-white dark:hover:bg-slate-700 hover:border-indigo-100 dark:hover:border-indigo-500/20 transition-all">
                    <div className="flex items-center gap-4">
                      <div className={cn("p-2 rounded-xl bg-white dark:bg-slate-800 shadow-sm group-hover:scale-110 transition-transform")}>
                        <sys.icon className="w-5 h-5 text-slate-900 dark:text-white" />
                      </div>
                      <div>
                        <h4 className="text-xs font-black text-slate-900 dark:text-white">{sys.label}</h4>
                        <p className="text-[9px] font-bold text-slate-400 dark:text-slate-500 uppercase tracking-widest">{sys.status}</p>
                      </div>
                    </div>
                    <div className={cn("w-2 h-2 rounded-full", sys.color)} />
                  </div>
                ))}
              </div>

              {/* Feedback Breakdown */}
              <div className="mt-8 pt-8 border-t border-slate-50 dark:border-white/5">
                <div className="flex items-center justify-between mb-6">
                  <h3 className="text-sm font-black text-slate-900 dark:text-white tracking-tight uppercase tracking-[0.2em]">Feedback Resolution</h3>
                  <button onClick={() => navigate('/feedbacks')} className="text-[10px] font-black text-indigo-500 hover:underline">Manage Feedbacks</button>
                </div>
                <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                  {[
                    { label: 'Pending', count: stats.pendingFeedbacks, color: 'text-amber-500', bg: 'bg-amber-500/10' },
                    { label: 'In Progress', count: stats.inProgressFeedbacks, color: 'text-blue-500', bg: 'bg-blue-500/10' },
                    { label: 'Resolved', count: stats.resolvedFeedbacks, color: 'text-emerald-500', bg: 'bg-emerald-500/10' },
                    { label: 'Ignored', count: stats.ignoredFeedbacks, color: 'text-slate-400', bg: 'bg-slate-400/10' }
                  ].map((stat, i) => (
                    <div key={i} className="p-4 rounded-2xl bg-slate-50 dark:bg-white/5 border border-slate-100 dark:border-white/5">
                      <p className="text-[9px] font-black text-slate-400 dark:text-slate-500 uppercase tracking-widest mb-1">{stat.label}</p>
                      <p className={cn("text-xl font-black", stat.color)}>{stat.count}</p>
                    </div>
                  ))}
                </div>
              </div>

              {/* Study Vault Breakdown */}
              <div className="mt-8 pt-8 border-t border-slate-50 dark:border-white/5">
                <div className="flex items-center justify-between mb-6">
                  <h3 className="text-sm font-black text-slate-900 dark:text-white tracking-tight uppercase tracking-[0.2em]">Vault Moderation</h3>
                  <button onClick={() => navigate('/study-vault')} className="text-[10px] font-black text-indigo-500 hover:underline">Manage Vault</button>
                </div>
                <div className="grid grid-cols-2 md:grid-cols-5 gap-4">
                  {[
                    { label: 'Pending', count: vaultStats.pending, color: 'text-amber-500 dark:text-amber-400', bg: 'bg-amber-500/10 dark:bg-amber-500/15' },
                    { label: 'Removal Req.', count: vaultStats.removalRequested, color: 'text-rose-500 dark:text-rose-400', bg: 'bg-rose-500/10 dark:bg-rose-500/15' },
                    { label: 'Approved', count: vaultStats.approved, color: 'text-emerald-500 dark:text-emerald-400', bg: 'bg-emerald-500/10 dark:bg-emerald-500/15' },
                    { label: 'Rejected', count: vaultStats.rejected, color: 'text-slate-500 dark:text-slate-400', bg: 'bg-slate-100 dark:bg-white/5' },
                    { label: 'Total Items', count: vaultStats.total, color: 'text-indigo-500 dark:text-indigo-400', bg: 'bg-indigo-500/5 dark:bg-indigo-500/10', isTotal: true }
                  ].map((stat, i) => (
                    <div key={i} className={cn("p-4 rounded-2xl bg-slate-50 dark:bg-white/5 border border-slate-100 dark:border-white/5", stat.isTotal && "border-indigo-500/20")}>
                      <p className="text-[9px] font-black text-slate-400 dark:text-slate-500 uppercase tracking-widest mb-1">{stat.label}</p>
                      <p className={cn("text-xl font-black", stat.color)}>{stat.count}</p>
                    </div>
                  ))}
                </div>
              </div>

           </div>
            
            <div className="bg-white dark:bg-slate-800 rounded-[1.5rem] sm:rounded-[2rem] p-6 sm:p-8 shadow-sm border border-slate-100 dark:border-white/5 flex flex-col justify-between">
              <div>
                <div className="flex items-center gap-3 mb-8">
                  <div className="p-2.5 rounded-xl bg-indigo-500/10 text-indigo-500 dark:bg-indigo-500/20 dark:text-indigo-400">
                    <Zap className="w-5 h-5 animate-pulse" />
                  </div>
                  <div>
                    <h3 className="text-sm font-black text-slate-900 dark:text-white tracking-tight uppercase tracking-[0.2em]">Quick Actions</h3>
                    <p className="text-[10px] font-bold text-slate-400 dark:text-slate-500 uppercase tracking-widest mt-0.5">Control Shortcuts</p>
                  </div>
                </div>

                <div className="flex flex-col gap-4">
                  {/* Feedback Action */}
                  <button 
                    className="w-full p-4 bg-slate-50 hover:bg-slate-100 dark:bg-white/5 dark:hover:bg-white/10 rounded-2xl text-slate-900 dark:text-white font-black text-xs uppercase tracking-widest border border-slate-100 dark:border-white/5 hover:-translate-y-0.5 active:translate-y-0 transition-all flex items-center justify-between group"
                    onClick={() => navigate('/feedbacks')}
                  >
                    <div className="flex items-center gap-3">
                      <div className="p-2 rounded-lg bg-indigo-500/10 text-indigo-500 dark:bg-indigo-500/20 dark:text-indigo-400">
                        <Mail className="w-4 h-4" />
                      </div>
                      <span>Feedback Panel</span>
                    </div>
                    <ArrowUpRight className="w-4 h-4 text-slate-400 group-hover:translate-x-0.5 group-hover:-translate-y-0.5 transition-transform" />
                  </button>

                  {/* Study Vault Action */}
                  <button 
                    className="w-full p-4 bg-indigo-600 dark:bg-indigo-500 hover:bg-indigo-700 dark:hover:bg-indigo-600 text-white font-black text-xs uppercase tracking-widest rounded-2xl shadow-lg shadow-indigo-100 dark:shadow-indigo-950/20 hover:-translate-y-0.5 active:translate-y-0 transition-all flex items-center justify-between group"
                    onClick={() => navigate('/study-vault')}
                  >
                    <div className="flex items-center gap-3">
                      <div className="p-2 rounded-lg bg-white/20 text-white">
                        <BookOpen className="w-4 h-4" />
                      </div>
                      <span>Study Vault</span>
                    </div>
                    <ArrowUpRight className="w-4 h-4 text-white/80 group-hover:translate-x-0.5 group-hover:-translate-y-0.5 transition-transform" />
                  </button>

                  {/* Scraper Action */}
                  <button 
                    className="w-full p-4 bg-slate-50 hover:bg-slate-100 dark:bg-white/5 dark:hover:bg-white/10 rounded-2xl text-slate-900 dark:text-white font-black text-xs uppercase tracking-widest border border-slate-100 dark:border-white/5 hover:-translate-y-0.5 active:translate-y-0 transition-all flex items-center justify-between group"
                    onClick={() => navigate('/scraper')}
                  >
                    <div className="flex items-center gap-3">
                      <div className="p-2 rounded-lg bg-amber-500/10 text-amber-500 dark:bg-amber-500/20 dark:text-amber-400">
                        <Zap className="w-4 h-4" />
                      </div>
                      <span>Launch Scraper</span>
                    </div>
                    <ArrowUpRight className="w-4 h-4 text-slate-400 group-hover:translate-x-0.5 group-hover:-translate-y-0.5 transition-transform" />
                  </button>
                </div>
              </div>
              
              <div className="mt-8 p-4 bg-slate-50 dark:bg-slate-900/50 rounded-2xl border border-slate-100 dark:border-white/5 text-[9px] font-medium text-slate-400 dark:text-slate-500 text-center leading-relaxed">
                EWUmate Administrative Shortcuts console. Select any action above to manage respective systems.
              </div>
            </div>
        </div>
      </div>

      {/* Semester Tracks */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
        {Object.entries(semesterStats).map(([track, data]) => (
          <motion.div 
            key={track} 
            whileHover={{ y: -4 }}
            className="bg-white dark:bg-slate-800 rounded-[1.5rem] sm:rounded-[2rem] shadow-sm border border-slate-100 dark:border-white/5 overflow-hidden flex flex-col"
          >
            <div className="px-8 py-6 border-b border-slate-50 dark:border-white/5 flex items-center justify-between bg-slate-50/50 dark:bg-white/5">
              <div className="flex items-center gap-3">
                <CalendarClock className="w-5 h-5 text-indigo-600 dark:text-indigo-400" />
                <h3 className="text-lg font-black text-slate-900 dark:text-white capitalize tracking-tight">{track.replace('_', ' ')}</h3>
              </div>
              <div className="px-3 py-1 bg-white dark:bg-slate-900 rounded-full border border-slate-200 dark:border-white/10 text-[9px] font-black text-slate-400 dark:text-slate-500 uppercase tracking-widest">Active Track</div>
            </div>
            
            <div className="grid grid-cols-2 divide-x divide-slate-50 dark:divide-white/5 flex-1">
              <div className="p-8 text-center">
                <p className="text-[10px] font-black text-slate-400 dark:text-slate-500 uppercase tracking-widest mb-2">Current</p>
                <h4 className="text-xl font-black text-indigo-600 dark:text-indigo-400 mb-4">{data.current || 'N/A'}</h4>
                <div className="flex justify-center gap-3">
                  <div className="px-3 py-2 bg-slate-50 dark:bg-white/5 rounded-xl border border-slate-100 dark:border-white/5 flex flex-col">
                    <span className="text-sm font-black text-slate-900 dark:text-white">{data.current_courses}</span>
                    <span className="text-[8px] font-bold text-slate-400 dark:text-slate-500 uppercase">Courses</span>
                  </div>
                  <div className="px-3 py-2 bg-slate-50 dark:bg-white/5 rounded-xl border border-slate-100 dark:border-white/5 flex flex-col">
                    <span className="text-sm font-black text-slate-900 dark:text-white">{data.current_sections}</span>
                    <span className="text-[8px] font-bold text-slate-400 dark:text-slate-500 uppercase">Sec</span>
                  </div>
                </div>
              </div>
              
              <div className="p-8 text-center bg-slate-50/30 dark:bg-black/10">
                <p className="text-[10px] font-black text-slate-400 dark:text-slate-500 uppercase tracking-widest mb-2">Upcoming</p>
                <h4 className="text-xl font-black text-emerald-500 dark:text-emerald-400 mb-4">{data.next || 'N/A'}</h4>
                <div className="flex justify-center gap-3">
                  <div className="px-3 py-2 bg-white dark:bg-slate-900 rounded-xl border border-slate-100 dark:border-white/5 flex flex-col shadow-sm">
                    <span className="text-sm font-black text-slate-900 dark:text-white">{data.next_courses}</span>
                    <span className="text-[8px] font-bold text-slate-400 dark:text-slate-500 uppercase">Courses</span>
                  </div>
                  <div className="px-3 py-2 bg-white dark:bg-slate-900 rounded-xl border border-slate-100 dark:border-white/5 flex flex-col shadow-sm">
                    <span className="text-sm font-black text-slate-900 dark:text-white">{data.next_sections}</span>
                    <span className="text-[8px] font-bold text-slate-400 dark:text-slate-500 uppercase">Sec</span>
                  </div>
                </div>
              </div>
            </div>

            {/* Quick Status Toggles */}
            <div className="p-6 bg-slate-50/50 dark:bg-slate-900/30 border-t border-slate-50 dark:border-white/5 grid grid-cols-2 gap-4">
              {/* Advising Toggle */}
              <div 
                onClick={() => toggleTrackState(track, 'is_advising_open', data.is_advising_open)}
                className={`p-3.5 rounded-xl border transition-all cursor-pointer flex items-center justify-between group/toggle ${
                  data.is_advising_open 
                    ? 'bg-emerald-50/50 dark:bg-emerald-500/10 border-emerald-100/50 dark:border-emerald-500/20 shadow-sm' 
                    : 'bg-white dark:bg-slate-900 border-slate-100 dark:border-white/5 hover:border-slate-200 dark:hover:border-white/10'
                }`}
              >
                <div>
                  <p className={`text-[8px] font-black uppercase tracking-widest mb-0.5 ${
                    data.is_advising_open ? 'text-emerald-600 dark:text-emerald-400' : 'text-slate-400 dark:text-slate-500'
                  }`}>Advising System</p>
                  <p className="text-xs font-black text-slate-800 dark:text-white">
                    {data.is_advising_open ? 'OPEN' : 'CLOSED'}
                  </p>
                </div>
                <div className={`w-9 h-5 rounded-full relative transition-colors ${
                  data.is_advising_open ? 'bg-emerald-500' : 'bg-slate-200 dark:bg-slate-700'
                }`}>
                  <div className={`absolute top-1 w-3 h-3 bg-white rounded-full transition-all ${
                    data.is_advising_open ? 'left-5' : 'left-1'
                  }`} />
                </div>
              </div>

              {/* Next Semester Toggle */}
              <div 
                onClick={() => toggleTrackState(track, 'is_next_semester_open', data.is_next_semester_open)}
                className={`p-3.5 rounded-xl border transition-all cursor-pointer flex items-center justify-between group/toggle ${
                  data.is_next_semester_open 
                    ? 'bg-blue-50/50 dark:bg-blue-500/10 border-blue-100/50 dark:border-blue-500/20 shadow-sm' 
                    : 'bg-white dark:bg-slate-900 border-slate-100 dark:border-white/5 hover:border-slate-200 dark:hover:border-white/10'
                }`}
              >
                <div>
                  <p className={`text-[8px] font-black uppercase tracking-widest mb-0.5 ${
                    data.is_next_semester_open ? 'text-blue-600 dark:text-blue-400' : 'text-slate-400 dark:text-slate-500'
                  }`}>Next Sem Screen</p>
                  <p className="text-xs font-black text-slate-800 dark:text-white">
                    {data.is_next_semester_open ? 'VISIBLE' : 'HIDDEN'}
                  </p>
                </div>
                <div className={`w-9 h-5 rounded-full relative transition-colors ${
                  data.is_next_semester_open ? 'bg-blue-500' : 'bg-slate-200 dark:bg-slate-700'
                }`}>
                  <div className={`absolute top-1 w-3 h-3 bg-white rounded-full transition-all ${
                    data.is_next_semester_open ? 'left-5' : 'left-1'
                  }`} />
                </div>
              </div>
            </div>
          </motion.div>
        ))}
      </div>

      {/* Tables Row */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
        {/* Recent Registrations */}
        <div className="bg-white dark:bg-slate-800 rounded-[1.5rem] sm:rounded-[2rem] shadow-sm border border-slate-100 dark:border-white/5 overflow-hidden">
          <div className="px-6 sm:px-8 py-5 sm:py-6 border-b border-slate-50 dark:border-white/5 flex items-center justify-between">
            <h3 className="text-base sm:text-lg font-black text-slate-900 dark:text-white flex items-center gap-3 tracking-tight">
              <div className="w-2 h-2 rounded-full bg-indigo-500" />
              New Students
            </h3>
            <button className="text-[10px] font-black text-indigo-600 dark:text-indigo-400 uppercase tracking-widest hover:underline" onClick={() => navigate('/users')}>View All</button>
          </div>
          <div className="overflow-x-auto custom-scrollbar">
            <table className="w-full min-w-[500px] sm:min-w-0">
              <thead className="bg-slate-50/50 dark:bg-white/5">
                <tr>
                  <th className="px-8 py-4 text-left text-[10px] font-black text-slate-400 dark:text-slate-500 uppercase tracking-widest">Student Info</th>
                  <th className="px-8 py-4 text-left text-[10px] font-black text-slate-400 dark:text-slate-500 uppercase tracking-widest">Join Date</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-50 dark:divide-white/5">
                {recentUsers.map((user) => (
                  <tr key={user.id} className="hover:bg-slate-50 dark:hover:bg-white/5 cursor-pointer transition-colors group" onClick={() => navigate(`/users/${user.id}`)}>
                    <td className="px-8 py-5">
                      <div className="flex items-center gap-4">
                        <div className="w-10 h-10 rounded-xl bg-slate-100 dark:bg-slate-700 flex items-center justify-center font-black text-slate-400 dark:text-slate-500 group-hover:bg-indigo-50 dark:group-hover:bg-indigo-500/10 group-hover:text-indigo-500 transition-all uppercase text-xs">
                          {user.full_name?.substring(0, 2)}
                        </div>
                        <div>
                          <div className="text-sm font-black text-slate-900 dark:text-white">{user.full_name || 'Unknown'}</div>
                          <div className="text-[10px] text-indigo-500 font-bold uppercase tracking-wider">{user.student_id || '-'}</div>
                        </div>
                      </div>
                    </td>
                    <td className="px-8 py-5">
                      <div className="text-xs font-bold text-slate-700 dark:text-slate-300">
                        {new Date(user.created_at).toLocaleDateString([], { month: 'short', day: 'numeric', year: 'numeric' })}
                      </div>
                      <div className="text-[9px] text-slate-400 dark:text-slate-500 font-bold">
                        {new Date(user.created_at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', timeZoneName: 'short' })}
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>

        {/* Recent Activity */}
        <div className="bg-white dark:bg-slate-800 rounded-[2rem] shadow-sm border border-slate-100 dark:border-white/5 overflow-hidden">
          <div className="px-8 py-6 border-b border-slate-50 dark:border-white/5 flex items-center justify-between">
            <h3 className="text-lg font-black text-slate-900 dark:text-white flex items-center gap-3 tracking-tight">
              <div className="w-2 h-2 rounded-full bg-emerald-500" />
              Recent Activity
            </h3>
            <button className="text-[10px] font-black text-indigo-600 dark:text-indigo-400 uppercase tracking-widest hover:underline" onClick={() => navigate('/users')}>View Trends</button>
          </div>
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead className="bg-slate-50/50 dark:bg-white/5">
                <tr>
                  <th className="px-8 py-4 text-left text-[10px] font-black text-slate-400 dark:text-slate-500 uppercase tracking-widest">User</th>
                  <th className="px-8 py-4 text-center text-[10px] font-black text-slate-400 dark:text-slate-500 uppercase tracking-widest">Sessions</th>
                  <th className="px-8 py-4 text-left text-[10px] font-black text-slate-400 dark:text-slate-500 uppercase tracking-widest">Last Active</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-50 dark:divide-white/5">
                {activeUsers.map((user) => (
                  <tr key={user.id} className="hover:bg-slate-50 dark:hover:bg-white/5 cursor-pointer transition-colors group" onClick={() => navigate(`/users/${user.id}`)}>
                    <td className="px-8 py-5">
                      <div className="text-sm font-black text-slate-900 dark:text-white truncate max-w-[150px]">{user.full_name || 'Unknown'}</div>
                      <div className="text-[10px] text-indigo-500 font-bold uppercase tracking-wider">{user.student_id || '-'}</div>
                    </td>
                    <td className="px-8 py-5 text-center">
                      <span className="px-3 py-1 bg-slate-100 dark:bg-slate-900 rounded-lg text-xs font-black text-slate-700 dark:text-slate-300 border border-slate-200 dark:border-white/5">
                        {user.app_open_count || 0}
                      </span>
                    </td>
                    <td className="px-8 py-5">
                      <div className="text-xs font-bold text-slate-700 dark:text-slate-300">
                        {user.last_active_at ? new Date(user.last_active_at).toLocaleDateString([], { month: 'short', day: 'numeric' }) : 'Never'}
                      </div>
                      <div className="text-[9px] text-slate-400 dark:text-slate-500 font-bold">
                        {user.last_active_at ? new Date(user.last_active_at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', timeZoneName: 'short' }) : '-'}
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>
  );
}

