import { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { supabase } from '../lib/supabase';
import { Users, BookOpen, Activity, GraduationCap, Clock, CalendarClock, Mail } from 'lucide-react';
import type { Profile, DashboardStats, SemesterTrackStats } from '../types';

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
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function fetchDashboardData() {
      try {
        setLoading(true);

        const yesterday = new Date();
        yesterday.setHours(yesterday.getHours() - 24);
        const yesterdayIso = yesterday.toISOString();

        const { count: usersCount } = await supabase.from('profiles').select('*', { count: 'exact', head: true });
        // Use last_active_at for better accuracy of 'active users'
        const { count: activeUsersCount } = await supabase.from('profiles').select('*', { count: 'exact', head: true }).gte('last_active_at', yesterdayIso);
        const { count: programsCount } = await supabase.from('programs').select('*', { count: 'exact', head: true });
        const { count: noticesCount } = await supabase.from('notifications').select('*', { count: 'exact', head: true });
        const { count: pendingFeedbackCount } = await supabase.from('feedbacks').select('*', { count: 'exact', head: true }).eq('status', 'pending');

        const { data: recent } = await supabase
          .from('profiles')
          .select('id, full_name, student_id, program_code, department_name, created_at, last_active_at, app_open_count')
          .order('created_at', { ascending: false })
          .limit(5);

        const { data: activeNow } = await supabase
          .from('profiles')
          .select('id, full_name, student_id, last_active_at, app_open_count')
          .order('last_active_at', { ascending: false })
          .limit(5);

        const { data: activeSemesters } = await supabase.from('active_semester').select('*');
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

            // 1. Fetch Current Semester Counts
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

            // 2. Fetch Next Semester Counts
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
      }
    }

    fetchDashboardData();
  }, []);

  if (loading) return <div>Loading statistics...</div>;

  return (
    <div className="space-y-6">
      <div className="flex justify-between flex-wrap gap-4 items-center mb-8">
        <div>
          <h2 className="text-3xl font-extrabold text-gray-900 tracking-tight">Platform Overview</h2>
          <p className="text-gray-500 mt-1 text-sm">Welcome back to the EWUmate command center.</p>
        </div>
      </div>
      
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">    
        <div className="bg-white rounded-xl shadow-sm border border-gray-100 p-6 flex items-center hover:shadow-md transition-shadow">
          <div className="p-4 rounded-xl bg-blue-50 text-blue-600 mr-5 shadow-inner">
            <Users className="w-8 h-8" />
          </div>
          <div>
            <p className="text-sm font-semibold text-gray-500 uppercase tracking-wide">Total Users</p>
            <p className="text-3xl font-bold text-gray-900 mt-1">{stats.users.toLocaleString()}</p>
          </div>
        </div>

        <div className="bg-gradient-to-r from-indigo-500 to-indigo-600 rounded-xl shadow-md border-transparent p-6 flex items-center hover:shadow-lg transition-shadow text-white">
          <div className="p-4 rounded-xl bg-white/20 mr-5 shadow-inner backdrop-blur-sm">
            <Clock className="w-8 h-8 text-white" />
          </div>
          <div>
            <p className="text-sm font-semibold text-indigo-100 uppercase tracking-wide">Active (24h)</p>
            <p className="text-3xl font-bold text-white mt-1">{stats.activeUsers24h.toLocaleString()}</p>
          </div>
        </div>

        <div className="bg-white rounded-xl shadow-sm border border-gray-100 p-6 flex items-center hover:shadow-md transition-shadow">
          <div className="p-4 rounded-xl bg-emerald-50 text-emerald-600 mr-5 shadow-inner">
            <BookOpen className="w-8 h-8" />
          </div>
          <div>
            <p className="text-sm font-semibold text-gray-500 uppercase tracking-wide">Programs</p>
            <p className="text-3xl font-bold text-gray-900 mt-1">{stats.programs}</p>
          </div>
        </div>

        <div className="bg-white rounded-xl shadow-sm border border-gray-100 p-6 flex items-center hover:shadow-md transition-shadow">
          <div className="p-4 rounded-xl bg-amber-50 text-amber-600 mr-5 shadow-inner">
            <GraduationCap className="w-8 h-8" />
          </div>
          <div>
            <p className="text-sm font-semibold text-gray-500 uppercase tracking-wide">Courses</p>
            <p className="text-3xl font-bold text-gray-900 mt-1">{stats.courses.toLocaleString()}</p>
          </div>
        </div>

        <div 
          className="bg-white rounded-xl shadow-sm border border-gray-100 p-6 flex items-center hover:shadow-md transition-shadow cursor-pointer"
          onClick={() => navigate('/feedbacks')}
        >
          <div className="p-4 rounded-xl bg-red-50 text-red-600 mr-5 shadow-inner">
            <Mail className="w-8 h-8" />
          </div>
          <div>
            <p className="text-sm font-semibold text-gray-500 uppercase tracking-wide">Pending Issues</p>
            <p className="text-3xl font-bold text-gray-900 mt-1">{stats.pendingFeedbacks}</p>
          </div>
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mt-2">
        {Object.entries(semesterStats).map(([track, data]) => (
          <div key={track} className="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden hover:shadow-md transition-shadow">
            <div className="px-6 py-4 border-b border-gray-100 flex items-center gap-3 bg-gray-50/80">
              <CalendarClock className="w-5 h-5 text-indigo-600" />
              <h3 className="text-lg font-bold text-gray-800 capitalize tracking-tight">{track.replace('_', ' ')}</h3>
            </div>
            <div className="flex divide-x divide-gray-100">
               <div className="flex-1 p-6 flex flex-col justify-center text-center">
                 <p className="text-xs font-bold text-gray-400 uppercase tracking-wider mb-2">Current Semester</p>
                 <p className="text-xl font-extrabold text-indigo-700 mb-3">{data.current || 'N/A'}</p>
                 <div className="flex justify-center gap-4 text-sm">
                   <div className="bg-gray-50 px-3 py-1.5 rounded-lg border border-gray-100">
                     <span className="font-bold text-gray-700">{data.current_courses}</span> <span className="text-gray-500">Courses</span>
                   </div>
                   <div className="bg-gray-50 px-3 py-1.5 rounded-lg border border-gray-100">
                     <span className="font-bold text-gray-700">{data.current_sections}</span> <span className="text-gray-500">Sections</span>
                   </div>
                 </div>
               </div>
               
               <div className="flex-1 p-6 flex flex-col justify-center text-center bg-gray-50/30">
                 <p className="text-xs font-bold text-gray-400 uppercase tracking-wider mb-2">Upcoming Semester</p>
                 <p className="text-xl font-extrabold text-emerald-600 mb-3">{data.next || 'N/A'}</p>
                 <div className="flex justify-center gap-4 text-sm">
                   <div className="bg-white px-3 py-1.5 rounded-lg border border-gray-100">
                     <span className="font-bold text-gray-700">{data.next_courses}</span> <span className="text-gray-500">Courses</span>
                   </div>
                   <div className="bg-white px-3 py-1.5 rounded-lg border border-gray-100">
                     <span className="font-bold text-gray-700">{data.next_sections}</span> <span className="text-gray-500">Sections</span>
                   </div>
                 </div>
               </div>
            </div>
          </div>
        ))}
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-8 mt-8">
        {/* Recent Registrations */}
        <div className="bg-white rounded-xl shadow-sm border border-gray-100 overflow-hidden">
          <div className="px-6 py-5 border-b border-gray-100 flex items-center justify-between bg-gray-50/50">
            <h3 className="text-lg font-semibold text-gray-900 flex items-center gap-2">
              <Users className="w-5 h-5 text-indigo-600" />
              New Students
            </h3>
          </div>
          <div className="overflow-x-auto">
            <table className="min-w-full divide-y divide-gray-100">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-semibold text-gray-500 uppercase">Student</th>
                  <th className="px-6 py-3 text-left text-xs font-semibold text-gray-500 uppercase">Joined</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-100">
                {recentUsers.map((user) => (
                  <tr key={user.id} className="hover:bg-gray-50 cursor-pointer" onClick={() => navigate(`/users/${user.id}`)}>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="text-sm font-bold text-gray-900">{user.full_name || 'Unknown'}</div>
                      <div className="text-xs text-indigo-600">{user.student_id || '-'}</div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                      {new Date(user.created_at).toLocaleDateString()}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>

        {/* Recent Activity */}
        <div className="bg-white rounded-xl shadow-sm border border-gray-100 overflow-hidden">
          <div className="px-6 py-5 border-b border-gray-100 flex items-center justify-between bg-gray-50/50">
            <h3 className="text-lg font-semibold text-gray-900 flex items-center gap-2">
              <Activity className="w-5 h-5 text-emerald-600" />
              Recent Activity
            </h3>
          </div>
          <div className="overflow-x-auto">
            <table className="min-w-full divide-y divide-gray-100">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-semibold text-gray-500 uppercase">Student</th>
                  <th className="px-6 py-3 text-left text-xs font-semibold text-gray-500 uppercase text-center">App Opens</th>
                  <th className="px-6 py-3 text-left text-xs font-semibold text-gray-500 uppercase">Last Active</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-100">
                {activeUsers.map((user) => (
                  <tr key={user.id} className="hover:bg-gray-50 cursor-pointer" onClick={() => navigate(`/users/${user.id}`)}>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="text-sm font-bold text-gray-900">{user.full_name || 'Unknown'}</div>
                      <div className="text-xs text-indigo-600">{user.student_id || '-'}</div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm font-bold text-gray-900 text-center">
                      <span className="bg-gray-100 px-2 py-1 rounded-md">{user.app_open_count || 0}</span>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                      {user.last_active_at ? new Date(user.last_active_at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }) : 'Never'}
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
