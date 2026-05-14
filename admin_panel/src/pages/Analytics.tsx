import { useEffect, useState } from 'react';
import { supabase } from '../lib/supabase';
import { 
  TrendingUp, Activity, 
  RefreshCcw, Users, 
  ArrowUpRight, Clock
} from 'lucide-react';
import { 
  XAxis, YAxis, CartesianGrid, 
  Tooltip, ResponsiveContainer, AreaChart, Area,
  BarChart, Bar
} from 'recharts';
import { motion } from 'framer-motion';
import { cn } from '../lib/utils';

type TimeRange = '15D' | '1M' | '3M' | '6M';

export function Analytics() {
  const [timeRange, setTimeRange] = useState<TimeRange>('1M');
  const [, setLoading] = useState(true);
  const [isRefreshing, setIsRefreshing] = useState(false);
  const [growthData, setGrowthData] = useState<any[]>([]);
  const [activityData, setActivityData] = useState<any[]>([]);
  const [stats, setStats] = useState({
    totalUsers: 0,
    activeUsers: 0,
    growthRate: 0,
    peakActivity: 0
  });

  const timeWindows = {
    '15D': 15,
    '1M': 30,
    '3M': 90,
    '6M': 180
  };

  const fetchAnalytics = async (silent = false) => {
    try {
      if (!silent) setLoading(true);
      else setIsRefreshing(true);

      const days = timeWindows[timeRange];
      const startDate = new Date();
      startDate.setDate(startDate.getDate() - days);

      // Fetch all profiles for growth (we need creation dates)
      // For large datasets, this should be an RPC or edge function
      const { data: allProfiles, error: profileError } = await supabase
        .from('profiles')
        .select('created_at, last_active_at')
        .order('created_at', { ascending: true });

      if (profileError) throw profileError;

      // 1. Process Growth Data
      const growthMap: Record<string, number> = {};
      // Initialize the range with 0s
      for (let i = days; i >= 0; i--) {
        const d = new Date();
        d.setDate(d.getDate() - i);
        const key = d.toLocaleDateString([], { month: 'short', day: 'numeric' });
        growthMap[key] = 0;
      }

      let totalBeforeRange = 0;
      allProfiles.forEach(p => {
        const pDate = new Date(p.created_at);
        const key = pDate.toLocaleDateString([], { month: 'short', day: 'numeric' });
        if (growthMap[key] !== undefined) {
          growthMap[key]++;
        } else if (pDate < startDate) {
          totalBeforeRange++;
        }
      });

      let cumulative = totalBeforeRange;
      const growthTrend = Object.entries(growthMap).map(([date, count]) => {
        cumulative += count;
        return { date, count, total: cumulative };
      });

      // 2. Process Activity Data
      const activityMap: Record<string, number> = {};
      for (let i = days; i >= 0; i--) {
        const d = new Date();
        d.setDate(d.getDate() - i);
        const key = d.toLocaleDateString([], { month: 'short', day: 'numeric' });
        activityMap[key] = 0;
      }

      allProfiles.forEach(p => {
        if (p.last_active_at) {
          const aDate = new Date(p.last_active_at);
          const key = aDate.toLocaleDateString([], { month: 'short', day: 'numeric' });
          if (activityMap[key] !== undefined) {
            activityMap[key]++;
          }
        }
      });

      const activityTrend = Object.entries(activityMap).map(([date, active]) => ({
        date,
        active
      }));

      // 3. Calculate Stats
      const currentActive = allProfiles.filter(p => {
        if (!p.last_active_at) return false;
        const lastActive = new Date(p.last_active_at);
        const twentyFourHoursAgo = new Date();
        twentyFourHoursAgo.setHours(twentyFourHoursAgo.getHours() - 24);
        return lastActive >= twentyFourHoursAgo;
      }).length;

      const peak = Math.max(...activityTrend.map(d => d.active));
      const totalInRange = allProfiles.filter(p => new Date(p.created_at) >= startDate).length;
      const rate = ((totalInRange / allProfiles.length) * 100).toFixed(1);

      setGrowthData(growthTrend);
      setActivityData(activityTrend);
      setStats({
        totalUsers: allProfiles.length,
        activeUsers: currentActive,
        growthRate: parseFloat(rate),
        peakActivity: peak
      });

    } catch (err) {
      console.error('Failed to fetch analytics:', err);
    } finally {
      setLoading(false);
      setIsRefreshing(false);
    }
  };

  useEffect(() => {
    fetchAnalytics();
  }, [timeRange]);

  return (
    <div className="space-y-8 animate-in fade-in duration-700">
      {/* Header & Controls */}
      <div className="flex flex-col md:flex-row justify-between gap-6 items-start md:items-center">
        <div>
          <h2 className="text-3xl font-black text-slate-900 tracking-tight flex items-center gap-3">
            Advanced Analytics
            {isRefreshing && <RefreshCcw className="w-5 h-5 text-indigo-500 animate-spin" />}
          </h2>
          <p className="text-slate-400 font-bold text-[10px] uppercase tracking-widest mt-1">Surgical Data Analysis & Trends</p>
        </div>

        <div className="flex items-center gap-2 bg-white p-1.5 rounded-2xl border border-slate-200 shadow-sm">
          {(['15D', '1M', '3M', '6M'] as TimeRange[]).map((range) => (
            <button
              key={range}
              onClick={() => setTimeRange(range)}
              className={cn(
                "px-5 py-2.5 rounded-xl text-xs font-black transition-all",
                timeRange === range 
                ? "bg-slate-900 text-white shadow-lg shadow-slate-200" 
                : "text-slate-400 hover:text-slate-900 hover:bg-slate-50"
              )}
            >
              {range}
            </button>
          ))}
          <div className="w-px h-4 bg-slate-200 mx-1" />
          <button 
            onClick={() => fetchAnalytics(true)}
            className="p-2.5 text-slate-400 hover:text-indigo-600 transition-colors"
          >
            <RefreshCcw className={cn("w-4 h-4", isRefreshing && "animate-spin")} />
          </button>
        </div>
      </div>

      {/* Top Insights Grid */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
        {[
          { label: 'Growth Delta', value: `+${stats.growthRate}%`, icon: TrendingUp, sub: 'Total Base Growth', color: 'text-indigo-600', bg: 'bg-indigo-50' },
          { label: 'Active (24h)', value: stats.activeUsers, icon: Activity, sub: 'Current Engagement', color: 'text-emerald-600', bg: 'bg-emerald-50' },
          { label: 'Peak Activity', value: stats.peakActivity, icon: Clock, sub: 'Highest Daily Count', color: 'text-amber-600', bg: 'bg-amber-50' },
          { label: 'Total Ecosystem', value: stats.totalUsers, icon: Users, sub: 'Cumulative Profiles', color: 'text-slate-600', bg: 'bg-slate-100' }
        ].map((item, i) => (
          <motion.div 
            key={i}
            whileHover={{ y: -4 }}
            className="bg-white p-6 rounded-[2rem] border border-slate-100 shadow-sm flex items-center gap-5 transition-all"
          >
            <div className={cn("p-4 rounded-2xl shadow-inner", item.bg, item.color)}>
              <item.icon className="w-6 h-6" />
            </div>
            <div>
              <p className="text-[10px] font-black text-slate-400 uppercase tracking-widest">{item.label}</p>
              <p className="text-2xl font-black text-slate-900">{item.value}</p>
              <p className="text-[9px] font-bold text-slate-400 uppercase mt-0.5">{item.sub}</p>
            </div>
          </motion.div>
        ))}
      </div>

      {/* Growth Trend Section */}
      <div className="bg-white rounded-[2.5rem] p-6 sm:p-10 border border-slate-100 shadow-sm">
        <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between mb-10 gap-4">
          <div>
            <div className="flex items-center gap-3 mb-2">
              <div className="p-2 bg-indigo-50 rounded-xl">
                <TrendingUp className="w-5 h-5 text-indigo-600" />
              </div>
              <h3 className="text-xl font-black text-slate-900 tracking-tight">Ecosystem Growth Engine</h3>
            </div>
            <p className="text-xs font-bold text-slate-400 uppercase tracking-widest">Cumulative User Adoption Trend ({timeRange})</p>
          </div>
          
          <div className="flex items-center gap-4">
             <div className="text-right">
                <p className="text-[10px] font-black text-slate-400 uppercase tracking-widest">Total Growth</p>
                <p className="text-lg font-black text-indigo-600">+{growthData[growthData.length - 1]?.total - (growthData[0]?.total || 0)} Students</p>
             </div>
             <div className="w-px h-8 bg-slate-100" />
             <div className="flex items-center gap-2 px-3 py-1.5 bg-emerald-50 text-emerald-600 rounded-full text-[10px] font-black uppercase">
                <ArrowUpRight className="w-4 h-4" />
                Expanding
             </div>
          </div>
        </div>

        <div className="h-[400px] w-full">
          <ResponsiveContainer width="100%" height="100%">
            <AreaChart data={growthData}>
              <defs>
                <linearGradient id="growthGradient" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="5%" stopColor="#6366f1" stopOpacity={0.15}/>
                  <stop offset="95%" stopColor="#6366f1" stopOpacity={0}/>
                </linearGradient>
              </defs>
              <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#f1f5f9" />
              <XAxis 
                dataKey="date" 
                axisLine={false} 
                tickLine={false} 
                tick={{ fontSize: 10, fontWeight: 'bold', fill: '#94a3b8' }} 
                dy={15}
                minTickGap={30}
              />
              <YAxis 
                axisLine={false} 
                tickLine={false} 
                tick={{ fontSize: 10, fontWeight: 'bold', fill: '#94a3b8' }} 
              />
              <Tooltip 
                contentStyle={{ 
                  borderRadius: '20px', 
                  border: 'none', 
                  boxShadow: '0 25px 50px -12px rgb(0 0 0 / 0.15)',
                  padding: '16px'
                }}
                itemStyle={{ fontWeight: 'black', fontSize: '14px' }}
                labelStyle={{ fontWeight: 'bold', color: '#94a3b8', marginBottom: '4px', fontSize: '10px', textTransform: 'uppercase' }}
              />
              <Area 
                type="monotone" 
                dataKey="total" 
                name="Total Students"
                stroke="#6366f1" 
                strokeWidth={5} 
                fillOpacity={1} 
                fill="url(#growthGradient)" 
                animationDuration={1500}
              />
            </AreaChart>
          </ResponsiveContainer>
        </div>
      </div>

      {/* Activity Bar Chart Section */}
      <div className="bg-white rounded-[2.5rem] p-6 sm:p-10 border border-slate-100 shadow-sm">
        <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between mb-10 gap-4">
          <div>
            <div className="flex items-center gap-3 mb-2">
              <div className="p-2 bg-emerald-50 rounded-xl">
                <Activity className="w-5 h-5 text-emerald-600" />
              </div>
              <h3 className="text-xl font-black text-slate-900 tracking-tight">Activity Heatmap</h3>
            </div>
            <p className="text-xs font-bold text-slate-400 uppercase tracking-widest">Daily Active Users Engagement ({timeRange})</p>
          </div>
          
          <div className="flex items-center gap-4">
             <div className="text-right">
                <p className="text-[10px] font-black text-slate-400 uppercase tracking-widest">Avg Daily</p>
                <p className="text-lg font-black text-emerald-600">
                  {Math.round(activityData.reduce((acc, curr) => acc + curr.active, 0) / (activityData.length || 1))} DAU
                </p>
             </div>
             <div className="w-px h-8 bg-slate-100" />
             <div className="flex items-center gap-2 px-3 py-1.5 bg-indigo-50 text-indigo-600 rounded-full text-[10px] font-black uppercase">
                Active Pulse
             </div>
          </div>
        </div>

        <div className="h-[300px] w-full">
          <ResponsiveContainer width="100%" height="100%">
            <BarChart data={activityData}>
              <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#f1f5f9" />
              <XAxis 
                dataKey="date" 
                axisLine={false} 
                tickLine={false} 
                tick={{ fontSize: 10, fontWeight: 'bold', fill: '#94a3b8' }} 
                dy={15}
                minTickGap={30}
              />
              <YAxis 
                axisLine={false} 
                tickLine={false} 
                tick={{ fontSize: 10, fontWeight: 'bold', fill: '#94a3b8' }} 
              />
              <Tooltip 
                cursor={{ fill: '#f8fafc', radius: 10 }}
                contentStyle={{ 
                  borderRadius: '20px', 
                  border: 'none', 
                  boxShadow: '0 25px 50px -12px rgb(0 0 0 / 0.15)',
                  padding: '16px'
                }}
              />
              <Bar 
                dataKey="active" 
                name="Active Students"
                fill="#10b981" 
                radius={[6, 6, 0, 0]} 
                barSize={timeRange === '6M' ? 4 : timeRange === '3M' ? 10 : 20}
              />
            </BarChart>
          </ResponsiveContainer>
        </div>
      </div>
    </div>
  );
}
