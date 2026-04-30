import { useEffect, useState } from 'react';
import { useNavigate, useSearchParams } from 'react-router-dom';
import { supabaseAdmin as supabase } from '../lib/supabase';
import { Users, Search, ChevronLeft, ChevronRight, Download, Loader2 } from 'lucide-react';
import toast from 'react-hot-toast';
import type { Profile } from '../types';

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
    const toastId = toast.loading('Exporting users...');
    
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

      // Build CSV
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
      link.download = `ewumate_users_${new Date().toISOString().split('T')[0]}.csv`;
      link.click();
      URL.revokeObjectURL(url);

      toast.success(`Exported ${allUsers.length} users`, { id: toastId });
    } catch (err: unknown) {
      const message = err instanceof Error ? err.message : 'Export failed';
      toast.error(message, { id: toastId });
    } finally {
      setExporting(false);
    }
  };

  return (
    <div className="bg-white rounded-lg shadow overflow-hidden flex flex-col h-full">
      <div className="p-6 border-b border-gray-200">
        <div className="flex items-center justify-between mb-4">
          <h2 className="text-2xl font-bold flex items-center gap-2 text-gray-800">
            <Users className="w-6 h-6 text-indigo-600" />
            User Management
          </h2>
          <button
            onClick={handleExportCSV}
            disabled={exporting}
            className="flex items-center gap-2 px-4 py-2 bg-emerald-600 text-white rounded-lg hover:bg-emerald-700 disabled:opacity-50 transition-colors text-sm font-medium shadow-sm"
          >
            {exporting ? <Loader2 className="w-4 h-4 animate-spin" /> : <Download className="w-4 h-4" />}
            {exporting ? 'Exporting...' : 'Export CSV'}
          </button>
        </div>
        
        <div className="flex flex-wrap gap-3 items-end">
          <div className="flex-1 min-w-[200px]">
            <label className="block text-xs font-bold text-gray-400 uppercase mb-1">Search</label>
            <div className="relative">
              <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                <Search className="h-4 w-4 text-gray-400" />
              </div>
              <input
                type="text"
                defaultValue={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="block w-full pl-9 pr-3 py-2 border border-gray-200 rounded-lg bg-gray-50 focus:bg-white focus:ring-2 focus:ring-indigo-500 transition-all sm:text-sm"
                placeholder="Name or ID..."
              />
            </div>
          </div>

          <div className="w-48">
            <label className="block text-xs font-bold text-gray-400 uppercase mb-1">Department</label>
            <select
              value={filterDept}
              onChange={(e) => setFilter('dept', e.target.value)}
              className="block w-full px-3 py-2 border border-gray-200 rounded-lg bg-gray-50 focus:bg-white focus:ring-2 focus:ring-indigo-500 transition-all sm:text-sm"
            >
              <option value="">All Departments</option>
              {departments.map(d => <option key={d} value={d}>{d}</option>)}
            </select>
          </div>

          <div className="w-32">
            <label className="block text-xs font-bold text-gray-400 uppercase mb-1">Program</label>
            <select
              value={filterProg}
              onChange={(e) => setFilter('prog', e.target.value)}
              className="block w-full px-3 py-2 border border-gray-200 rounded-lg bg-gray-50 focus:bg-white focus:ring-2 focus:ring-indigo-500 transition-all sm:text-sm"
            >
              <option value="">All Programs</option>
              {programs.map(p => <option key={p} value={p}>{p}</option>)}
            </select>
          </div>

          <div className="w-40">
            <label className="block text-xs font-bold text-gray-400 uppercase mb-1">Batch/Admission</label>
            <select
              value={filterSem}
              onChange={(e) => setFilter('sem', e.target.value)}
              className="block w-full px-3 py-2 border border-gray-200 rounded-lg bg-gray-50 focus:bg-white focus:ring-2 focus:ring-indigo-500 transition-all sm:text-sm"
            >
              <option value="">All Batches</option>
              {semesters.map(s => <option key={s.code} value={s.code}>{s.title}</option>)}
            </select>
          </div>

          {(searchTerm || filterDept || filterProg || filterSem) && (
            <button 
              onClick={() => setSearchParams({})}
              className="px-3 py-2 text-sm font-medium text-indigo-600 hover:text-indigo-800 transition-colors"
            >
              Clear Filters
            </button>
          )}
        </div>
      </div>
      
      <div className="overflow-x-auto flex-1">
        <table className="min-w-full divide-y divide-gray-200">
          <thead className="bg-gray-50 border-b border-gray-200">
            <tr>
              <th className="px-6 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Name / ID</th>
              <th className="px-6 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Department</th>
              <th className="px-6 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Academic Info</th>
              <th className="px-6 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider text-center">App Opens</th>
              <th className="px-6 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Last Active</th>
              <th className="px-6 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Joined</th>
            </tr>
          </thead>
          <tbody className="bg-white divide-y divide-gray-200">
            {loading ? (
              <tr>
                 <td colSpan={6} className="px-6 py-4 text-center text-sm text-gray-500">Loading users...</td>
              </tr>
            ) : users.length === 0 ? (
              <tr>
                <td colSpan={6} className="px-6 py-4 text-center text-sm text-gray-500">
                  No users found.
                </td>
              </tr>
            ) : (
              users.map((user) => (
                  <tr key={user.id} className="hover:bg-gray-50 cursor-pointer transition-colors" onClick={() => navigate(`/users/${user.id}`)}>
                  <td className="px-6 py-4">
                    <div className="text-sm font-bold text-gray-900">{user.full_name || user.nickname || 'Unknown'}</div>
                    <div className="text-sm text-indigo-600 font-medium font-mono">{user.student_id ? `${user.student_id}` : 'No ID'}</div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="text-sm font-medium text-gray-900">{user.program_code || 'N/A'}</div>
                    <div className="text-xs text-gray-500">{user.department_name || ''}</div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="text-xs text-gray-600">CGPA: <span className="font-medium text-gray-900">{user.cgpa || '0.00'}</span></div>
                    <div className="text-xs text-gray-600 mt-1">Credits: <span className="font-medium text-gray-900">{user.total_credits_earned || '0'}</span></div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-center">
                    <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-bold bg-indigo-100 text-indigo-800">
                      {user.app_open_count || 0}
                    </span>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                    {user.last_active_at ? (
                      <div>
                        <div className="font-medium text-gray-900">{new Date(user.last_active_at).toLocaleDateString()}</div>
                        <div className="text-xs text-gray-500">{new Date(user.last_active_at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}</div>
                      </div>
                    ) : (
                      <span className="text-gray-300">Never</span>
                    )}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                    <div className="font-medium text-gray-800">
                      {new Date(user.created_at || Date.now()).toLocaleDateString(undefined, { year: 'numeric', month: 'short', day: 'numeric' })}
                    </div>
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>

      {!loading && (
        <div className="bg-white px-4 py-3 border-t border-gray-200 flex items-center justify-between sm:px-6">
          <div className="flex-1 flex justify-between sm:hidden">
            <button
              onClick={() => setPage(p => Math.max(0, p - 1))}
              disabled={page === 0}
              className="relative inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50"
            >
              Previous
            </button>
            <button
              onClick={() => setPage(p => p + 1)}
              disabled={users.length < pageSize}
              className="ml-3 relative inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50"
            >
              Next
            </button>
          </div>
          <div className="hidden sm:flex-1 sm:flex sm:items-center sm:justify-between">
            <div>
              <p className="text-sm text-gray-700">
                Showing top results for page <span className="font-medium">{page + 1}</span>
              </p>
            </div>
            <div>
              <nav className="relative z-0 inline-flex rounded-md shadow-sm -space-x-px" aria-label="Pagination">
                <button
                  onClick={() => setPage(p => Math.max(0, p - 1))}
                  disabled={page === 0}
                  className={`relative inline-flex items-center px-2 py-2 rounded-l-md border border-gray-300 bg-white text-sm font-medium ${page === 0 ? 'text-gray-300' : 'text-gray-500 hover:bg-gray-50'}`}
                >
                  <span className="sr-only">Previous</span>
                  <ChevronLeft className="h-5 w-5" aria-hidden="true" />
                </button>
                <button
                  onClick={() => setPage(p => p + 1)}
                  disabled={users.length < pageSize}
                  className={`relative inline-flex items-center px-2 py-2 rounded-r-md border border-gray-300 bg-white text-sm font-medium ${users.length < pageSize ? 'text-gray-300' : 'text-gray-500 hover:bg-gray-50'}`}
                >
                  <span className="sr-only">Next</span>
                  <ChevronRight className="h-5 w-5" aria-hidden="true" />
                </button>
              </nav>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
