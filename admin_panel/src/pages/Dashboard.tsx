import { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { supabase } from '../lib/supabase';
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
import { CardSkeleton, Skeleton } from '../components/Skeleton';
import { cn } from '../lib/utils';

export function Dashboard() {
  const navigate = useNavigate();
  const [stats, setStats] = useState<DashboardStats>({
    users: 0,
    activeUsers24h: 0,
    programs: 0,
    courses: 0,
    notifications: 0,
    pendingFeedbacks: 0,
  });
  const [recentUsers, setRecentUsers] = useState<Profile[]>([]);
  const [activeUsers, setActiveUsers] = useState<Profile[]>([]);
  const [semesterStats, setSemesterStats] = useState<Record<string, SemesterTrackStats>>({});
  const [registrationTrend, setRegistrationTrend] = useState<any[]>([]);
  const [activityTrend, setActivityTrend] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [isRefreshing, setIsRefreshing] = useState(false);
  
  // Search state
  const [searchTerm, setSearchTerm] = useState('');
  const [searchResults, setSearchResults] = useState<Profile[]>([]);

  const fetchDashboardData = async (silent = false) => {
    try {
      if (!silent) setLoading(true);
      else setIsRefreshing(true);

      const yesterday = new Date();
      yesterday.setHours(yesterday.getHours() - 24);
      const yesterdayIso = yesterday.toISOString();

      const last7Days = new Date();
      last7Days.setDate(last7Days.getDate() - 7);
      const last7DaysIso = last7Days.toISOString();

      // Parallel data fetching
      const [
        { count: usersCount },
        { count: activeUsersCount },
        { count: programsCount },
        { count: noticesCount },
        { count: pendingFeedbackCount },
        { data: recent },
        { data: activeNow },
        { data: activeSemesters },
        { data: rawTrendData },
        { data: activityData }
      ] = await Promise.all([
        supabase.from('profiles').select('*', { count: 'exact', head: true }),
        supabase.from('profiles').select('*', { count: 'exact', head: true }).gte('last_active_at', yesterdayIso),
        supabase.from('programs').select('*', { count: 'exact', head: true }),
        supabase.from('notifications').select('*', { count: 'exact', head: true }),
        supabase.from('feedbacks').select('*', { count: 'exact', head: true }).eq('status', 'pending'),
        supabase.from('profiles').select('id, full_name, student_id, program_code, department_name, created_at, last_active_at, app_open_count').order('created_at', { ascending: false }).limit(5),
        supabase.from('profiles').select('id, full_name, student_id, last_active_at, app_open_count').order('last_active_at', { ascending: false }).limit(5),
        supabase.from('active_semester').select('*'),
        supabase.from('profiles').select('created_at').order('created_at', { ascending: true }),
        supabase.from('profiles').select('last_active_at').gte('last_active_at', last7DaysIso)
      ]);

      // Process Registration Trend Data
      if (rawTrendData) {
        const groups: Record<string, number> = {};
        rawTrendData.forEach(p => {
          const date = new Date(p.created_at).toLocaleDateString([], { month: 'short', day: 'numeric' });
          groups[date] = (groups[date] || 0) + 1;
        });
        
        let cumulative = 0;
        const trend = Object.entries(groups).map(([date, count]) => {
          cumulative += count;
          return { date, count, total: cumulative };
        }).slice(-14); // Last 14 days
        setRegistrationTrend(trend);
      }

      // Process Activity Trend Data (Last 7 Days)
      if (activityData) {
        const activityGroups: Record<string, number> = {};
        // Initialize last 7 days with 0
        for (let i = 6; i >= 0; i--) {
          const d = new Date();
          d.setDate(d.getDate() - i);
          const dateKey = d.toLocaleDateString([], { month: 'short', day: 'numeric' });
          activityGroups[dateKey] = 0;
        }

        activityData.forEach(p => {
          if (p.last_active_at) {
            const date = new Date(p.last_active_at).toLocaleDateString([], { month: 'short', day: 'numeric' });
            if (activityGroups[date] !== undefined) {
              activityGroups[date]++;
            }
          }
        });

        const actTrend = Object.entries(activityGroups).map(([date, active]) => ({
          date,
          active
        }));
        setActivityTrend(actTrend);
      }

      const semStats: Record<string, SemesterTrackStats> = {};
      let totalActiveCourses = 0;

      async function fetchAllCourseCodes(tableName: string) {
        let allCodes: { course_code: string }[] = [];
        let from = 0;
        let to = 999;
        while (true) {
          const { data, error } = await supabase.from(tableName).select('course_code').range(from, to);
          if (error || !data || data.length === 0) break;
          allCodes = [...allCodes, ...data];
          if (data.length < 1000) break;
          from += 1000;
          to += 1000;
        }
        return allCodes;
      }

      if (activeSemesters) {
        for (const sem of activeSemesters) {
          semStats[sem.track] = {
            current: sem.current_semester_code,
            next: sem.next_semester_code,
            current_courses: 0,
            current_sections: 0,
            next_courses: 0,
            next_sections: 0
          };

          if (sem.current_semester_code) {
             const tableBase = sem.current_semester_code.toLowerCase().replace(/[\s_]+/g, '');
             const cData = await fetchAllCourseCodes(`courses_${tableBase}`);       
             if (cData && Array.isArray(cData)) {
               semStats[sem.track].current_sections = cData.length;
               const uniqueCourses = new Set(cData.map(c => c.course_code)).size;
               semStats[sem.track].current_courses = uniqueCourses;
               totalActiveCourses += uniqueCourses;
             }
          }

          if (sem.next_semester_code) {
             const tableBase = sem.next_semester_code.toLowerCase().replace(/[\s_]+/g, '');
             const nData = await fetchAllCourseCodes(`courses_${tableBase}`);
             if (nData && Array.isArray(nData)) {
               semStats[sem.track].next_sections = nData.length;
               const uniqueNextCourses = new Set(nData.map(c => c.course_code)).size;
               semStats[sem.track].next_courses = uniqueNextCourses;
             }
          }
        }
      }

      setStats({
        users: usersCount || 0,
        activeUsers24h: activeUsersCount || 0,
        programs: programsCount || 0,
        courses: totalActiveCourses,
        notifications: noticesCount || 0,
        pendingFeedbacks: pendingFeedbackCount || 0,
      });
      
      setSemesterStats(semStats);
      setRecentUsers((recent as Profile[]) || []);
      setActiveUsers((activeNow as Profile[]) || []);
    } catch (err) {
      console.error('Failed to fetch dashboard data:', err);
    } finally {
      setLoading(false);
      setIsRefreshing(false);
    }
  };

  useEffect(() => {
    fetchDashboardData();
  }, []);

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
          <h2 className="text-2xl sm:text-3xl font-black text-slate-900 tracking-tight flex items-center gap-3">
            Platform Insights
            {isRefreshing && <RefreshCcw className="w-5 h-5 text-indigo-500 animate-spin" />}
          </h2>
          <p className="text-slate-400 font-bold text-[10px] uppercase tracking-widest mt-1">Live Statistics & Global Overview</p>
        </div>

        <div className="flex items-center gap-3 w-full md:w-auto">
          <div className="relative flex-1 md:w-80">
            <Search className="absolute left-4 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400" />
            <input
              type="text"
              className="w-full pl-11 pr-4 py-3 bg-white border border-slate-200 rounded-2xl text-sm font-bold text-slate-900 focus:ring-2 focus:ring-indigo-100 outline-none transition-all placeholder:text-slate-400 shadow-sm"
              placeholder="Search students..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
            />
            {searchResults.length > 0 && (
              <motion.div 
                initial={{ opacity: 0, y: 10 }}
                animate={{ opacity: 1, y: 0 }}
                className="absolute z-50 mt-2 w-full bg-white rounded-2xl shadow-2xl border border-slate-100 overflow-hidden"
              >
                {searchResults.map((user) => (
                  <button
                    key={user.id}
                    className="w-full text-left p-4 hover:bg-slate-50 border-b border-slate-50 last:border-0 transition-colors"
                    onClick={() => navigate(`/users/${user.id}`)}
                  >
                    <div className="font-black text-slate-900">{user.full_name}</div>
                    <div className="text-[10px] text-indigo-500 font-black uppercase tracking-wider">{user.student_id} • {user.program_code}</div>
                  </button>
                ))}
              </motion.div>
            )}
          </div>
          <button 
            onClick={() => fetchDashboardData(true)}
            className="p-3 bg-white border border-slate-200 rounded-2xl text-slate-600 hover:bg-slate-50 transition-all shadow-sm"
          >
            <RefreshCcw className={cn("w-5 h-5", isRefreshing && "animate-spin")} />
          </button>
        </div>
      </div>
      
      {/* Top Stats Grid */}
      <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-4 sm:gap-6">    
        <motion.div whileHover={{ y: -4 }} className="bg-white rounded-3xl p-6 shadow-sm border border-slate-100 flex items-center gap-5 transition-all">
          <div className="p-4 rounded-2xl bg-indigo-50 text-indigo-600 shadow-inner">
            <Users className="w-8 h-8" />
          </div>
          <div>
            <p className="text-[10px] font-black text-slate-400 uppercase tracking-widest">Total Users</p>
            <p className="text-2xl font-black text-slate-900">{stats.users.toLocaleString()}</p>
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

        <motion.div whileHover={{ y: -4 }} className="bg-white rounded-3xl p-6 shadow-sm border border-slate-100 flex items-center gap-5 transition-all">
          <div className="p-4 rounded-2xl bg-emerald-50 text-emerald-600 shadow-inner">
            <BookOpen className="w-8 h-8" />
          </div>
          <div>
            <p className="text-[10px] font-black text-slate-400 uppercase tracking-widest">Programs</p>
            <p className="text-2xl font-black text-slate-900">{stats.programs}</p>
          </div>
        </motion.div>

        <motion.div whileHover={{ y: -4 }} className="bg-white rounded-3xl p-6 shadow-sm border border-slate-100 flex items-center gap-5 transition-all">
          <div className="p-4 rounded-2xl bg-amber-50 text-amber-600 shadow-inner">
            <GraduationCap className="w-8 h-8" />
          </div>
          <div>
            <p className="text-[10px] font-black text-slate-400 uppercase tracking-widest">Live Courses</p>
            <p className="text-2xl font-black text-slate-900">{stats.courses.toLocaleString()}</p>
          </div>
        </motion.div>
      </div>

      {/* Main Analytics Row */}
      <div className="grid grid-cols-1 lg:grid-cols-4 gap-8">
        {/* Registration Chart */}
        <div className="lg:col-span-2 bg-white rounded-[1.5rem] sm:rounded-[2rem] p-4 sm:p-8 shadow-sm border border-slate-100 flex flex-col overflow-hidden">
          <div className="flex items-center justify-between mb-8">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-indigo-50 rounded-xl">
                <TrendingUp className="w-5 h-5 text-indigo-600" />
              </div>
              <div>
                <h3 className="text-lg font-black text-slate-900 tracking-tight">Growth Trend</h3>
                <p className="text-[10px] font-bold text-slate-400 uppercase tracking-widest">New users per day (Last 14 days)</p>
              </div>
            </div>
            <div className="flex items-center gap-2 px-3 py-1 bg-emerald-50 text-emerald-600 rounded-full text-[10px] font-black uppercase">
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
                <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#f1f5f9" />
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
        <div className="lg:col-span-2 bg-white rounded-[1.5rem] sm:rounded-[2rem] p-4 sm:p-8 shadow-sm border border-slate-100 flex flex-col overflow-hidden">
          <div className="flex items-center justify-between mb-8">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-emerald-50 rounded-xl">
                <Activity className="w-5 h-5 text-emerald-600" />
              </div>
              <div>
                <h3 className="text-lg font-black text-slate-900 tracking-tight">Activity Heatmap</h3>
                <p className="text-[10px] font-bold text-slate-400 uppercase tracking-widest">Active users per day (Last 7 days)</p>
              </div>
            </div>
            <div className="flex items-center gap-2 px-3 py-1 bg-indigo-50 text-indigo-600 rounded-full text-[10px] font-black uppercase">
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
                <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#f1f5f9" />
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
           <div className="md:col-span-3 bg-white rounded-[1.5rem] sm:rounded-[2rem] p-6 sm:p-8 shadow-sm border border-slate-100 flex flex-col">
              <div className="flex items-center justify-between mb-8">
                 <h3 className="text-lg font-black text-slate-900 tracking-tight">System Infrastructure</h3>
                 <span className="text-[10px] font-black px-3 py-1 bg-slate-100 text-slate-400 rounded-full uppercase">Operational</span>
              </div>
              <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
                {[
                  { label: 'Portal Scraper', status: 'Healthy', icon: Zap, color: 'bg-amber-500' },
                  { label: 'Azure Core', status: 'Live', icon: ShieldCheck, color: 'bg-emerald-500' },
                  { label: 'Cloud DB', status: 'Optimized', icon: Clock, color: 'bg-indigo-500' },
                  { label: 'Broadcaster', status: 'Idle', icon: Mail, color: 'bg-slate-400' }
                ].map((sys, i) => (
                  <div key={i} className="p-4 bg-slate-50 rounded-2xl border border-slate-100 flex items-center justify-between group hover:bg-white hover:border-indigo-100 transition-all">
                    <div className="flex items-center gap-4">
                      <div className={cn("p-2 rounded-xl bg-white shadow-sm group-hover:scale-110 transition-transform")}>
                        <sys.icon className="w-5 h-5 text-slate-900" />
                      </div>
                      <div>
                        <h4 className="text-xs font-black text-slate-900">{sys.label}</h4>
                        <p className="text-[9px] font-bold text-slate-400 uppercase tracking-widest">{sys.status}</p>
                      </div>
                    </div>
                    <div className={cn("w-2 h-2 rounded-full", sys.color)} />
                  </div>
                ))}
              </div>
           </div>
           
           <div className="bg-white rounded-[1.5rem] sm:rounded-[2rem] p-6 sm:p-8 shadow-sm border border-slate-100 flex flex-col justify-center">
              <button 
                className="w-full py-6 bg-indigo-600 rounded-2xl text-white font-black text-xs uppercase tracking-widest shadow-lg shadow-indigo-100 hover:bg-indigo-700 transition-all flex items-center justify-center gap-2 group"
                onClick={() => navigate('/scraper')}
              >
                <span>Launch Scraper</span>
                <ArrowUpRight className="w-4 h-4 group-hover:translate-x-1 group-hover:-translate-y-1 transition-transform" />
              </button>
           </div>
        </div>
      </div>

      {/* Semester Tracks */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
        {Object.entries(semesterStats).map(([track, data]) => (
          <motion.div 
            key={track} 
            whileHover={{ y: -4 }}
            className="bg-white rounded-[1.5rem] sm:rounded-[2rem] shadow-sm border border-slate-100 overflow-hidden flex flex-col"
          >
            <div className="px-8 py-6 border-b border-slate-50 flex items-center justify-between bg-slate-50/50">
              <div className="flex items-center gap-3">
                <CalendarClock className="w-5 h-5 text-indigo-600" />
                <h3 className="text-lg font-black text-slate-900 capitalize tracking-tight">{track.replace('_', ' ')}</h3>
              </div>
              <div className="px-3 py-1 bg-white rounded-full border border-slate-200 text-[9px] font-black text-slate-400 uppercase tracking-widest">Active Track</div>
            </div>
            
            <div className="grid grid-cols-2 divide-x divide-slate-50 flex-1">
              <div className="p-8 text-center">
                <p className="text-[10px] font-black text-slate-400 uppercase tracking-widest mb-2">Current</p>
                <h4 className="text-xl font-black text-indigo-600 mb-4">{data.current || 'N/A'}</h4>
                <div className="flex justify-center gap-3">
                  <div className="px-3 py-2 bg-slate-50 rounded-xl border border-slate-100 flex flex-col">
                    <span className="text-sm font-black text-slate-900">{data.current_courses}</span>
                    <span className="text-[8px] font-bold text-slate-400 uppercase">Courses</span>
                  </div>
                  <div className="px-3 py-2 bg-slate-50 rounded-xl border border-slate-100 flex flex-col">
                    <span className="text-sm font-black text-slate-900">{data.current_sections}</span>
                    <span className="text-[8px] font-bold text-slate-400 uppercase">Sec</span>
                  </div>
                </div>
              </div>
              
              <div className="p-8 text-center bg-slate-50/30">
                <p className="text-[10px] font-black text-slate-400 uppercase tracking-widest mb-2">Upcoming</p>
                <h4 className="text-xl font-black text-emerald-500 mb-4">{data.next || 'N/A'}</h4>
                <div className="flex justify-center gap-3">
                  <div className="px-3 py-2 bg-white rounded-xl border border-slate-100 flex flex-col shadow-sm">
                    <span className="text-sm font-black text-slate-900">{data.next_courses}</span>
                    <span className="text-[8px] font-bold text-slate-400 uppercase">Courses</span>
                  </div>
                  <div className="px-3 py-2 bg-white rounded-xl border border-slate-100 flex flex-col shadow-sm">
                    <span className="text-sm font-black text-slate-900">{data.next_sections}</span>
                    <span className="text-[8px] font-bold text-slate-400 uppercase">Sec</span>
                  </div>
                </div>
              </div>
            </div>
          </motion.div>
        ))}
      </div>

      {/* Tables Row */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
        {/* Recent Registrations */}
        <div className="bg-white rounded-[1.5rem] sm:rounded-[2rem] shadow-sm border border-slate-100 overflow-hidden">
          <div className="px-6 sm:px-8 py-5 sm:py-6 border-b border-slate-50 flex items-center justify-between">
            <h3 className="text-base sm:text-lg font-black text-slate-900 flex items-center gap-3 tracking-tight">
              <div className="w-2 h-2 rounded-full bg-indigo-500" />
              New Students
            </h3>
            <button className="text-[10px] font-black text-indigo-600 uppercase tracking-widest hover:underline" onClick={() => navigate('/users')}>View All</button>
          </div>
          <div className="overflow-x-auto custom-scrollbar">
            <table className="w-full min-w-[500px] sm:min-w-0">
              <thead className="bg-slate-50/50">
                <tr>
                  <th className="px-8 py-4 text-left text-[10px] font-black text-slate-400 uppercase tracking-widest">Student Info</th>
                  <th className="px-8 py-4 text-left text-[10px] font-black text-slate-400 uppercase tracking-widest">Join Date</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-50">
                {recentUsers.map((user) => (
                  <tr key={user.id} className="hover:bg-slate-50 cursor-pointer transition-colors group" onClick={() => navigate(`/users/${user.id}`)}>
                    <td className="px-8 py-5">
                      <div className="flex items-center gap-4">
                        <div className="w-10 h-10 rounded-xl bg-slate-100 flex items-center justify-center font-black text-slate-400 group-hover:bg-indigo-50 group-hover:text-indigo-500 transition-all uppercase text-xs">
                          {user.full_name?.substring(0, 2)}
                        </div>
                        <div>
                          <div className="text-sm font-black text-slate-900">{user.full_name || 'Unknown'}</div>
                          <div className="text-[10px] text-indigo-500 font-bold uppercase tracking-wider">{user.student_id || '-'}</div>
                        </div>
                      </div>
                    </td>
                    <td className="px-8 py-5">
                      <div className="text-xs font-bold text-slate-700">
                        {new Date(user.created_at).toLocaleDateString([], { month: 'short', day: 'numeric', year: 'numeric' })}
                      </div>
                      <div className="text-[9px] text-slate-400 font-bold">
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
        <div className="bg-white rounded-[2rem] shadow-sm border border-slate-100 overflow-hidden">
          <div className="px-8 py-6 border-b border-slate-50 flex items-center justify-between">
            <h3 className="text-lg font-black text-slate-900 flex items-center gap-3 tracking-tight">
              <div className="w-2 h-2 rounded-full bg-emerald-500" />
              Recent Activity
            </h3>
            <button className="text-[10px] font-black text-indigo-600 uppercase tracking-widest hover:underline" onClick={() => navigate('/users')}>View Trends</button>
          </div>
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead className="bg-slate-50/50">
                <tr>
                  <th className="px-8 py-4 text-left text-[10px] font-black text-slate-400 uppercase tracking-widest">User</th>
                  <th className="px-8 py-4 text-center text-[10px] font-black text-slate-400 uppercase tracking-widest">Sessions</th>
                  <th className="px-8 py-4 text-left text-[10px] font-black text-slate-400 uppercase tracking-widest">Last Active</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-50">
                {activeUsers.map((user) => (
                  <tr key={user.id} className="hover:bg-slate-50 cursor-pointer transition-colors group" onClick={() => navigate(`/users/${user.id}`)}>
                    <td className="px-8 py-5">
                      <div className="text-sm font-black text-slate-900 truncate max-w-[150px]">{user.full_name || 'Unknown'}</div>
                      <div className="text-[10px] text-indigo-500 font-bold uppercase tracking-wider">{user.student_id || '-'}</div>
                    </td>
                    <td className="px-8 py-5 text-center">
                      <span className="px-3 py-1 bg-slate-100 rounded-lg text-xs font-black text-slate-700 border border-slate-200">
                        {user.app_open_count || 0}
                      </span>
                    </td>
                    <td className="px-8 py-5">
                      <div className="text-xs font-bold text-slate-700">
                        {user.last_active_at ? new Date(user.last_active_at).toLocaleDateString([], { month: 'short', day: 'numeric' }) : 'Never'}
                      </div>
                      <div className="text-[9px] text-slate-400 font-bold">
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

