import { useEffect, useState } from 'react';
import { useNavigate, useSearchParams } from 'react-router-dom';
import { supabaseAdmin as supabase } from '../lib/supabase';
import { Users, Search, ChevronLeft, ChevronRight, Download, Loader2, Filter, X, Zap, Package } from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';
import toast from 'react-hot-toast';
import type { Profile } from '../types';
import { Skeleton } from '../components/Skeleton';

export function UsersList() {
  const navigate = useNavigate();
  const [searchParams, setSearchParams] = useSearchParams();
  const [users, setUsers] = useState<Profile[]>([]);
  const [loading, setLoading] = useState(true);
  const [exporting, setExporting] = useState(false);
  
  const page = parseInt(searchParams.get('page') || '0');
  const searchTerm = searchParams.get('q') || '';
  const filterDept = searchParams.get('dept') || '';
  const filterProg = searchParams.get('prog') || '';
  const filterSem = searchParams.get('sem') || '';
  const pageSize = 20;

  const [availablePrograms, setAvailablePrograms] = useState<any[]>([]);
  const [departments, setDepartments] = useState<string[]>([]);
  const [programs, setPrograms] = useState<string[]>([]);
  const [semesters, setSemesters] = useState<{code: string, title: string}[]>([]);

  useEffect(() => {
    fetchFilterOptions();
  }, []);

  async function fetchFilterOptions() {
    try {
      const { data: pData } = await supabase.from('programs').select('program_code, name, department_name');
      if (pData) {
        setAvailablePrograms(pData);
        setDepartments([...new Set(pData.map(p => p.department_name).filter(Boolean))].sort() as string[]);
        setPrograms([...new Set(pData.map(p => p.program_code).filter(Boolean))].sort() as string[]);
      }
      
      const { data: sData } = await supabase.from('semesters').select('code, title').order('created_at', { ascending: false });
      if (sData) {
        const uniqueSems = new Map<string, string>();
        const semList: {code: string, title: string}[] = [];
        sData.forEach(s => {
          if (!uniqueSems.has(s.code)) {
            uniqueSems.set(s.code, s.title);
            semList.push({ code: s.code, title: s.title });
          }
        });
        setSemesters(semList);
      }
    } catch (e) {
      console.error('Failed to fetch filters:', e);
    }
  }

  const setFilter = (key: string, val: string) => {
    setSearchParams(prev => {
      if (val) prev.set(key, val);
      else prev.delete(key);
      prev.set('page', '0');
      return prev;
    });
  };

  const setPage = (p: number | ((prev: number) => number)) => {
    const newPage = typeof p === 'function' ? p(page) : p;
    setSearchParams(prev => {
      prev.set('page', String(newPage));
      return prev;
    });
  };

  const setSearchTerm = (val: string) => {
    setSearchParams(prev => {
      if (val) prev.set('q', val);
      else prev.delete('q');
      prev.set('page', '0');
      return prev;
    });
  };

  useEffect(() => {
    fetchUsers();
  }, [page, searchTerm, filterDept, filterProg, filterSem]);

  async function fetchUsers() {
    setLoading(true);
    
    let query = supabase
      .from('profiles')
      .select('*', { count: 'exact' })
      .order('created_at', { ascending: false })
      .range(page * pageSize, (page + 1) * pageSize - 1);

    if (searchTerm) {
      query = query.or(`full_name.ilike.%${searchTerm}%,student_id.ilike.%${searchTerm}%`);
    }

    if (filterDept) {
      const deptPrograms = availablePrograms
        .filter(p => p.department_name === filterDept)
        .map(p => p.program_code);
      
      if (deptPrograms.length > 0) {
        query = query.in('program_code', deptPrograms);
      }
    }

    if (filterProg) {
      query = query.eq('program_code', filterProg);
    }

    if (filterSem) {
      query = query.eq('admitted_semester', filterSem);
    }

    const { data, error } = await query;

    if (!error && data) {
      setUsers(data as any as Profile[]);
    }
    setLoading(false);
  }

  const handleExportCSV = async () => {
    setExporting(true);
    const toastId = toast.loading('Exporting database records...');
    
    try {
      let allUsers: Profile[] = [];
      let from = 0;
      const batchSize = 1000;
      
      while (true) {
        let query = supabase
          .from('profiles')
          .select('full_name, student_id, program_code, department_name, cgpa, total_credits_earned, onboarding_status, created_at')
          .order('created_at', { ascending: false })
          .range(from, from + batchSize - 1);
        
        if (searchTerm) {
          query = query.or(`full_name.ilike.%${searchTerm}%,student_id.ilike.%${searchTerm}%`);
        }

        const { data, error } = await query;
        if (error) throw error;
        if (!data || data.length === 0) break;
        
        allUsers = [...allUsers, ...(data as Profile[])];
        if (data.length < batchSize) break;
        from += batchSize;
      }

      const headers = ['Full Name', 'Student ID', 'Program', 'Department', 'CGPA', 'Credits Earned', 'Status', 'Joined'];
      const rows = allUsers.map(u => [
        u.full_name || '',
        u.student_id || '',
        u.program_code || '',
        u.department_name || '',
        u.cgpa?.toString() || '0',
        u.total_credits_earned?.toString() || '0',
        u.onboarding_status || '',
        u.created_at ? new Date(u.created_at).toLocaleDateString() : ''
      ]);

      const csvContent = [headers, ...rows]
        .map(row => row.map(cell => `"${cell.replace(/"/g, '""')}"`).join(','))
        .join('\n');

      const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
      const url = URL.createObjectURL(blob);
      const link = document.createElement('a');
      link.href = url;
      link.download = `ewumate_export_${new Date().toISOString().split('T')[0]}.csv`;
      link.click();
      URL.revokeObjectURL(url);

      toast.success(`Exported ${allUsers.length} records successfully`, { id: toastId });
    } catch (err: unknown) {
      const message = err instanceof Error ? err.message : 'Export failed';
      toast.error(message, { id: toastId });
    } finally {
      setExporting(false);
    }
  };

  return (
    <div className="space-y-8 animate-in fade-in duration-700">
      <div className="flex flex-col md:flex-row items-start md:items-center justify-between gap-6">
        <div>
          <h2 className="text-3xl font-black text-slate-900 dark:text-white tracking-tight flex items-center gap-4">
             <div className="p-3 bg-indigo-600 rounded-2xl text-white shadow-lg shadow-indigo-100 dark:shadow-indigo-900/20">
               <Users className="w-6 h-6" />
             </div>
             User Directory
          </h2>
          <p className="text-slate-400 dark:text-slate-500 text-xs font-black uppercase tracking-[0.2em] mt-2 ml-1">Managing EWUmate Student Ecosystem</p>
        </div>

        <button
          onClick={handleExportCSV}
          disabled={exporting}
          className="w-full md:w-auto flex items-center justify-center gap-3 px-6 py-3.5 bg-slate-900 dark:bg-indigo-600 text-white rounded-2xl hover:bg-slate-800 dark:hover:bg-indigo-700 disabled:opacity-50 transition-all text-xs font-black uppercase tracking-widest shadow-xl shadow-slate-200 dark:shadow-none"
        >
          {exporting ? <Loader2 className="w-4 h-4 animate-spin" /> : <Download className="w-4 h-4" />}
          {exporting ? 'Preparing File...' : 'Export Intelligence'}
        </button>
      </div>

      {/* Modern Filter Bar */}
      <div className="bg-white/70 dark:bg-slate-800/70 backdrop-blur-xl p-4 sm:p-6 rounded-[1.5rem] sm:rounded-[2.5rem] border border-slate-200/60 dark:border-white/5 shadow-sm space-y-6 transition-colors duration-300">
        <div className="flex items-center gap-3 text-slate-900 dark:text-white mb-2">
           <Filter className="w-4 h-4" />
           <span className="text-[10px] font-black uppercase tracking-widest">Advanced Search & Filtering</span>
        </div>
        
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
          <div className="relative group">
            <div className="absolute inset-y-0 left-4 flex items-center pointer-events-none transition-transform group-focus-within:scale-110">
              <Search className="h-4 w-4 text-slate-400 group-focus-within:text-indigo-500" />
            </div>
            <input
              type="text"
              defaultValue={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="block w-full pl-12 pr-4 py-3.5 bg-slate-50 dark:bg-slate-900 border border-slate-100 dark:border-white/10 rounded-2xl text-sm font-bold text-slate-900 dark:text-white placeholder:text-slate-300 dark:placeholder:text-slate-600 focus:bg-white dark:focus:bg-slate-800 focus:ring-4 focus:ring-indigo-500/10 dark:focus:ring-indigo-500/5 focus:border-indigo-500 transition-all outline-none"
              placeholder="Search name or ID..."
            />
          </div>

          <div className="relative">
            <select
              value={filterDept}
              onChange={(e) => setFilter('dept', e.target.value)}
              className="block w-full px-4 py-3.5 bg-slate-50 dark:bg-slate-900 border border-slate-100 dark:border-white/10 rounded-2xl text-sm font-bold text-slate-900 dark:text-white appearance-none focus:bg-white dark:focus:bg-slate-800 focus:ring-4 focus:ring-indigo-500/10 dark:focus:ring-indigo-500/5 focus:border-indigo-500 transition-all outline-none"
            >
              <option value="">Departments</option>
              {departments.map(d => <option key={d} value={d} className="dark:bg-slate-800">{d}</option>)}
            </select>
            <div className="absolute inset-y-0 right-4 flex items-center pointer-events-none text-slate-400">
               <ChevronRight className="w-4 h-4 rotate-90" />
            </div>
          </div>

          <div className="relative">
            <select
              value={filterProg}
              onChange={(e) => setFilter('prog', e.target.value)}
              className="block w-full px-4 py-3.5 bg-slate-50 dark:bg-slate-900 border border-slate-100 dark:border-white/10 rounded-2xl text-sm font-bold text-slate-900 dark:text-white appearance-none focus:bg-white dark:focus:bg-slate-800 focus:ring-4 focus:ring-indigo-500/10 dark:focus:ring-indigo-500/5 focus:border-indigo-500 transition-all outline-none"
            >
              <option value="">Programs</option>
              {programs.map(p => <option key={p} value={p} className="dark:bg-slate-800">{p}</option>)}
            </select>
            <div className="absolute inset-y-0 right-4 flex items-center pointer-events-none text-slate-400">
               <ChevronRight className="w-4 h-4 rotate-90" />
            </div>
          </div>

          <div className="relative">
            <select
              value={filterSem}
              onChange={(e) => setFilter('sem', e.target.value)}
              className="block w-full px-4 py-3.5 bg-slate-50 dark:bg-slate-900 border border-slate-100 dark:border-white/10 rounded-2xl text-sm font-bold text-slate-900 dark:text-white appearance-none focus:bg-white dark:focus:bg-slate-800 focus:ring-4 focus:ring-indigo-500/10 dark:focus:ring-indigo-500/5 focus:border-indigo-500 transition-all outline-none"
            >
              <option value="">Admission Batch</option>
              {semesters.map(s => <option key={s.code} value={s.code} className="dark:bg-slate-800">{s.title}</option>)}
            </select>
            <div className="absolute inset-y-0 right-4 flex items-center pointer-events-none text-slate-400">
               <ChevronRight className="w-4 h-4 rotate-90" />
            </div>
          </div>
        </div>

        <AnimatePresence>
          {(searchTerm || filterDept || filterProg || filterSem) && (
            <motion.div 
              initial={{ opacity: 0, height: 0 }}
              animate={{ opacity: 1, height: 'auto' }}
              exit={{ opacity: 0, height: 0 }}
              className="flex justify-end border-t border-slate-100 pt-4"
            >
              <button 
                onClick={() => setSearchParams({})}
                className="flex items-center gap-2 text-[10px] font-black text-indigo-600 dark:text-indigo-400 uppercase tracking-widest hover:text-indigo-800 transition-colors"
              >
                <X className="w-3 h-3" /> Reset Intelligent Filters
              </button>
            </motion.div>
          )}
        </AnimatePresence>
      </div>

      {/* Users Table */}
      <div className="bg-white dark:bg-slate-800 rounded-[1.5rem] sm:rounded-[2.5rem] border border-slate-200/60 dark:border-white/5 shadow-sm overflow-hidden flex flex-col transition-colors duration-300">
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead className="bg-slate-50/50 dark:bg-slate-900/50 border-b border-slate-100 dark:border-white/5">
              <tr>
                <th className="px-6 sm:px-8 py-5 text-left text-[10px] font-black text-slate-400 uppercase tracking-widest">Student Profile</th>
                <th className="hidden lg:table-cell px-8 py-5 text-left text-[10px] font-black text-slate-400 uppercase tracking-widest">Departmental Hub</th>
                <th className="hidden sm:table-cell px-8 py-5 text-left text-[10px] font-black text-slate-400 uppercase tracking-widest">Vitals</th>
                <th className="hidden xl:table-cell px-8 py-5 text-center text-[10px] font-black text-slate-400 uppercase tracking-widest">Version</th>
                <th className="hidden xl:table-cell px-8 py-5 text-center text-[10px] font-black text-slate-400 uppercase tracking-widest">Activity</th>
                <th className="px-6 sm:px-8 py-5 text-right text-[10px] font-black text-slate-400 uppercase tracking-widest">Last Access</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-50 dark:divide-white/5">
              {loading ? (
                Array.from({ length: 5 }).map((_, i) => (
                  <tr key={i}>
                    <td className="px-8 py-6"><Skeleton className="w-48 h-8 rounded-xl" /></td>
                    <td className="px-8 py-6"><Skeleton className="w-32 h-8 rounded-xl" /></td>
                    <td className="px-8 py-6"><Skeleton className="w-24 h-8 rounded-xl" /></td>
                    <td className="px-8 py-6 text-center"><Skeleton className="w-12 h-12 rounded-full mx-auto" /></td>
                    <td className="px-8 py-6"><Skeleton className="w-32 h-8 rounded-xl ml-auto" /></td>
                  </tr>
                ))
              ) : users.length === 0 ? (
                <tr>
                  <td colSpan={5} className="px-8 py-24 text-center">
                    <div className="w-20 h-20 bg-slate-50 dark:bg-white/5 rounded-3xl flex items-center justify-center mx-auto mb-6">
                       <Search className="w-10 h-10 text-slate-200 dark:text-slate-700" />
                    </div>
                    <h3 className="text-lg font-black text-slate-900 dark:text-white">No Intelligence Found</h3>
                    <p className="text-slate-400 dark:text-slate-500 text-sm font-medium mt-2">Adjust your filters to scan different quadrants of the ecosystem.</p>
                  </td>
                </tr>
              ) : (
                users.map((user, i) => (
                  <motion.tr 
                    key={user.id} 
                    initial={{ opacity: 0, y: 10 }}
                    animate={{ opacity: 1, y: 0 }}
                    transition={{ delay: i * 0.03 }}
                    className="hover:bg-slate-50/50 dark:hover:bg-white/5 cursor-pointer transition-all group" 
                    onClick={() => navigate(`/users/${user.id}`)}
                  >
                    <td className="px-6 sm:px-8 py-6">
                      <div className="flex items-center gap-4">
                        <div className="w-10 h-10 sm:w-12 sm:h-12 rounded-xl sm:rounded-2xl bg-indigo-50 dark:bg-indigo-500/10 border border-indigo-100 dark:border-indigo-500/20 flex items-center justify-center font-black text-indigo-500 shadow-sm transition-transform group-hover:scale-110 shrink-0">
                           {user.full_name?.substring(0, 1) || 'U'}
                        </div>
                        <div className="min-w-0">
                          <div className="text-sm font-black text-slate-900 dark:text-white tracking-tight group-hover:text-indigo-600 transition-colors truncate">{user.full_name || 'Anonymous User'}</div>
                          <div className="text-[10px] font-black text-slate-400 dark:text-slate-500 uppercase tracking-widest mt-0.5 truncate">{user.student_id || 'Identity Pending'}</div>
                        </div>
                      </div>
                    </td>
                    <td className="hidden lg:table-cell px-8 py-6">
                      <div className="text-sm font-black text-slate-900 dark:text-white">{user.program_code || 'N/A'}</div>
                      <div className="text-[9px] font-bold text-slate-400 dark:text-slate-500 uppercase tracking-tight mt-0.5">{user.department_name || 'Unassigned'}</div>
                    </td>
                    <td className="hidden sm:table-cell px-8 py-6">
                      <div className="flex items-center gap-2">
                        <div className="flex flex-col">
                           <span className="text-[10px] font-black text-slate-400 dark:text-slate-500 uppercase tracking-widest">CGPA</span>
                           <span className="text-sm font-black text-indigo-600 dark:text-indigo-400">{user.cgpa?.toFixed(2) || '0.00'}</span>
                        </div>
                        <div className="h-8 w-px bg-slate-100 dark:bg-white/5 mx-2" />
                        <div className="flex flex-col">
                           <span className="text-[10px] font-black text-slate-400 dark:text-slate-500 uppercase tracking-widest">CREDITS</span>
                           <span className="text-sm font-black text-slate-900 dark:text-white">{user.total_credits_earned || '0'}</span>
                        </div>
                      </div>
                    </td>
                    <td className="hidden xl:table-cell px-8 py-6 text-center">
                      {(user as any).app_version ? (
                        <div className="inline-flex items-center gap-2 px-3 py-1.5 rounded-2xl bg-emerald-50 dark:bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 border border-emerald-100 dark:border-emerald-500/20 shadow-sm">
                           <Package className="w-3 h-3" />
                           <span className="text-[10px] font-black uppercase tracking-widest">{/^\d/.test((user as any).app_version) ? `v${(user as any).app_version}` : (user as any).app_version}</span>
                        </div>
                      ) : (
                        <span className="text-[10px] font-black text-slate-300 dark:text-slate-700 uppercase tracking-widest">Legacy</span>
                      )}
                    </td>
                    <td className="hidden xl:table-cell px-8 py-6 text-center">
                      <div className="inline-flex items-center gap-2 px-3 py-1.5 rounded-2xl bg-indigo-50 dark:bg-indigo-500/10 text-indigo-600 dark:text-indigo-400 border border-indigo-100 dark:border-indigo-500/20 shadow-sm">
                         <Zap className="w-3 h-3" />
                         <span className="text-[10px] font-black uppercase tracking-widest">{user.app_open_count || 0}</span>
                      </div>
                    </td>
                    <td className="px-6 sm:px-8 py-6 text-right">
                      {user.last_active_at ? (
                        <div className="flex flex-col items-end">
                          <div className="text-xs font-black text-slate-900 dark:text-white tracking-tight whitespace-nowrap">{new Date(user.last_active_at).toLocaleDateString([], { month: 'short', day: 'numeric' })}</div>
                          <div className="text-[10px] font-bold text-slate-400 dark:text-slate-500 uppercase tracking-widest mt-0.5 whitespace-nowrap">{new Date(user.last_active_at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', timeZoneName: 'short' })}</div>
                        </div>
                      ) : (
                        <span className="text-[10px] font-black text-slate-200 dark:text-slate-800 uppercase tracking-widest">No Log History</span>
                      )}
                    </td>
                  </motion.tr>
                ))
              )}
            </tbody>
          </table>
        </div>

        {!loading && (
          <div className="px-8 py-6 bg-slate-50/50 dark:bg-slate-900/50 border-t border-slate-100 dark:border-white/5 flex flex-col md:flex-row items-center justify-between gap-6">
            <div className="text-[10px] font-black text-slate-400 dark:text-slate-500 uppercase tracking-widest">
              Scanning Phase <span className="text-slate-900 dark:text-white">{page + 1}</span> of Global User Database
            </div>
            
            <div className="flex items-center gap-3">
              <button
                onClick={() => setPage(p => Math.max(0, p - 1))}
                disabled={page === 0}
                className="p-3 bg-white dark:bg-slate-900 border border-slate-200 dark:border-white/10 rounded-2xl text-slate-600 dark:text-slate-400 hover:bg-slate-50 dark:hover:bg-white/5 hover:shadow-md disabled:opacity-30 transition-all"
              >
                <ChevronLeft className="h-5 w-5" />
              </button>
              
              <div className="px-6 py-3 bg-white dark:bg-slate-900 border border-slate-200 dark:border-white/10 rounded-2xl text-xs font-black text-slate-900 dark:text-white shadow-sm">
                {page + 1}
              </div>

              <button
                onClick={() => setPage(p => p + 1)}
                disabled={users.length < pageSize}
                className="p-3 bg-white dark:bg-slate-900 border border-slate-200 dark:border-white/10 rounded-2xl text-slate-600 dark:text-slate-400 hover:bg-slate-50 dark:hover:bg-white/5 hover:shadow-md disabled:opacity-30 transition-all"
              >
                <ChevronRight className="h-5 w-5" />
              </button>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
