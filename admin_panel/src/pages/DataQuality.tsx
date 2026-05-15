import { useEffect, useState } from 'react';
import { supabase } from '../lib/supabase';
import { ShieldCheck, AlertTriangle, Copy, Search, RefreshCw } from 'lucide-react';
import toast from 'react-hot-toast';

interface QualityIssue {
  id: string;
  course_code: string;
  course_name: string | null;
  section_number: number | null;
  faculty_initials: string | null;
  credit_val: number | null;
  issues: string[];
}

interface DuplicateGroup {
  key: string;
  count: number;
  ids: string[];
}

interface QualityStats {
  totalSections: number;
  totalUniqueCourses: number;
  completePercent: number;
  missingFaculty: number;
  missingName: number;
  missingCredits: number;
  duplicates: number;
}

export function DataQuality() {
  const [activeSemester, setActiveSemester] = useState('');
  const [loading, setLoading] = useState(true);
  const [issues, setIssues] = useState<QualityIssue[]>([]);
  const [duplicates, setDuplicates] = useState<DuplicateGroup[]>([]);
  const [stats, setStats] = useState<QualityStats | null>(null);
  const [searchFilter, setSearchFilter] = useState('');

  useEffect(() => {
    fetchActiveSemester();
  }, []);

  useEffect(() => {
    if (activeSemester) runAudit();
  }, [activeSemester]);

  async function fetchActiveSemester() {
    const { data } = await supabase
      .from('active_semester')
      .select('current_semester_code')
      .eq('track', 'tri_semester')
      .maybeSingle();

    if (data?.current_semester_code) {
      setActiveSemester(data.current_semester_code);
    } else {
      setLoading(false);
    }
  }

  async function runAudit() {
    setLoading(true);
    const cleanSem = activeSemester.replace(/\s+/g, '').replace(/_/g, '').toLowerCase();
    const tableName = `courses_${cleanSem}`;

    try {
      // Fetch all courses from the semester table
      let allCourses: Record<string, unknown>[] = [];
      let from = 0;
      while (true) {
        const { data, error } = await supabase
          .from(tableName)
          .select('id, course_code, course_name, section_number, faculty_initials, credit_val')
          .range(from, from + 999);

        if (error) {
          toast.error(`Table "${tableName}" not found or error: ${error.message}`);
          setLoading(false);
          return;
        }
        if (!data || data.length === 0) break;
        allCourses = [...allCourses, ...data];
        if (data.length < 1000) break;
        from += 1000;
      }

      // Find issues
      const foundIssues: QualityIssue[] = [];
      let missingFaculty = 0;
      let missingName = 0;
      let missingCredits = 0;

      for (const course of allCourses) {
        const courseIssues: string[] = [];
        
        if (!course.faculty_initials || (course.faculty_initials as string).trim() === '' || course.faculty_initials === 'TBA') {
          courseIssues.push('Missing faculty');
          missingFaculty++;
        }
        if (!course.course_name || (course.course_name as string).trim() === '') {
          courseIssues.push('Missing course name');
          missingName++;
        }
        if (course.credit_val === null || course.credit_val === undefined) {
          courseIssues.push('Missing credits');
          missingCredits++;
        }

        if (courseIssues.length > 0) {
          foundIssues.push({
            id: course.id as string,
            course_code: course.course_code as string,
            course_name: course.course_name as string | null,
            section_number: course.section_number as number | null,
            faculty_initials: course.faculty_initials as string | null,
            credit_val: course.credit_val as number | null,
            issues: courseIssues
          });
        }
      }

      // Find duplicates (same course_code + section_number)
      const groupMap: Record<string, string[]> = {};
      for (const course of allCourses) {
        const key = `${course.course_code}-${course.section_number || '?'}`;
        if (!groupMap[key]) groupMap[key] = [];
        groupMap[key].push(course.id as string);
      }
      
      const foundDuplicates: DuplicateGroup[] = [];
      for (const [key, ids] of Object.entries(groupMap)) {
        if (ids.length > 1) {
          foundDuplicates.push({ key, count: ids.length, ids });
        }
      }

      // Calculate stats
      const uniqueCodes = new Set(allCourses.map(c => c.course_code));
      const completeCount = allCourses.length - foundIssues.length;

      setIssues(foundIssues);
      setDuplicates(foundDuplicates);
      setStats({
        totalSections: allCourses.length,
        totalUniqueCourses: uniqueCodes.size,
        completePercent: allCourses.length > 0 ? Math.round((completeCount / allCourses.length) * 100) : 100,
        missingFaculty,
        missingName,
        missingCredits,
        duplicates: foundDuplicates.length
      });

    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : 'Unknown error';
      toast.error('Audit failed: ' + msg);
    } finally {
      setLoading(false);
    }
  }

  const filtered = issues.filter(i =>
    !searchFilter ||
    i.course_code.toLowerCase().includes(searchFilter.toLowerCase()) ||
    (i.course_name || '').toLowerCase().includes(searchFilter.toLowerCase())
  );

  return (
    <div className="space-y-8 animate-in fade-in duration-700">
      <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-6">
        <div>
          <h1 className="text-3xl font-black text-slate-900 dark:text-white tracking-tight flex items-center gap-3">
            <ShieldCheck className="w-8 h-8 text-indigo-600 dark:text-indigo-400" />
            Data Integrity Guard
          </h1>
          <p className="text-slate-400 dark:text-slate-500 font-bold text-[10px] uppercase tracking-widest mt-1">
            Auditing <span className="text-indigo-600 dark:text-indigo-400">{activeSemester || '...'}</span> for structural anomalies
          </p>
        </div>
        <button
          onClick={runAudit}
          disabled={loading || !activeSemester}
          className="w-full md:w-auto flex items-center justify-center gap-2 px-6 py-3 bg-white dark:bg-slate-800 border border-slate-200 dark:border-white/5 rounded-2xl shadow-sm hover:bg-slate-50 dark:hover:bg-white/5 text-slate-700 dark:text-slate-300 font-black text-[10px] uppercase tracking-widest transition-all disabled:opacity-50"
        >
          <RefreshCw className={`w-4 h-4 ${loading ? 'animate-spin' : ''}`} />
          Execute Audit
        </button>
      </div>

      {/* Stats Cards */}
      {stats && (
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
          <div className="bg-white dark:bg-slate-800 rounded-3xl shadow-sm border border-slate-100 dark:border-white/5 p-6">
            <p className="text-[10px] font-black text-slate-400 dark:text-slate-500 uppercase tracking-widest">Total Sections</p>
            <p className="text-3xl font-black text-slate-900 dark:text-white mt-1">{stats.totalSections}</p>
            <p className="text-[10px] text-indigo-500 font-black uppercase tracking-wider mt-2">{stats.totalUniqueCourses} Unique Courses</p>
          </div>
          <div className={`rounded-3xl shadow-sm border p-6 ${stats.completePercent >= 95 ? 'bg-emerald-50 dark:bg-emerald-500/10 border-emerald-100 dark:border-emerald-500/20' : stats.completePercent >= 80 ? 'bg-amber-50 dark:bg-amber-500/10 border-amber-100 dark:border-amber-500/20' : 'bg-rose-50 dark:bg-rose-500/10 border-rose-100 dark:border-rose-500/20'}`}>
            <p className="text-[10px] font-black text-slate-400 dark:text-slate-500 uppercase tracking-widest">Completeness Score</p>
            <p className={`text-3xl font-black mt-1 ${stats.completePercent >= 95 ? 'text-emerald-600 dark:text-emerald-400' : stats.completePercent >= 80 ? 'text-amber-600 dark:text-amber-400' : 'text-rose-600 dark:text-rose-400'}`}>{stats.completePercent}%</p>
            <p className="text-[10px] font-black text-slate-400 dark:text-slate-500 uppercase tracking-wider mt-2">{issues.length} Flagged Sections</p>
          </div>
          <div className="bg-white dark:bg-slate-800 rounded-3xl shadow-sm border border-slate-100 dark:border-white/5 p-6">
            <p className="text-[10px] font-black text-slate-400 dark:text-slate-500 uppercase tracking-widest">Identity Gaps</p>
            <p className={`text-3xl font-black mt-1 ${stats.missingFaculty > 0 ? 'text-amber-500' : 'text-emerald-500'}`}>{stats.missingFaculty}</p>
            <p className="text-[10px] text-slate-400 dark:text-slate-500 font-black uppercase tracking-wider mt-2">Missing Faculty Initials</p>
          </div>
          <div className="bg-white dark:bg-slate-800 rounded-3xl shadow-sm border border-slate-100 dark:border-white/5 p-6">
            <p className="text-[10px] font-black text-slate-400 dark:text-slate-500 uppercase tracking-widest">Duplicates</p>
            <p className={`text-3xl font-black mt-1 ${stats.duplicates > 0 ? 'text-rose-500' : 'text-emerald-500'}`}>{stats.duplicates}</p>
            <p className="text-[10px] text-slate-400 dark:text-slate-500 font-black uppercase tracking-wider mt-2">Section Overlaps</p>
          </div>
        </div>
      )}

      {/* Duplicates */}
      {duplicates.length > 0 && (
        <div className="bg-rose-50 dark:bg-rose-500/10 rounded-3xl shadow-sm border border-rose-100 dark:border-rose-500/20 overflow-hidden animate-in slide-in-from-top-4">
          <div className="px-8 py-5 border-b border-rose-100 dark:border-rose-500/20 flex items-center gap-3">
            <Copy className="w-5 h-5 text-rose-500" />
            <h3 className="text-lg font-black text-rose-900 dark:text-white tracking-tight">Duplication Matrix ({duplicates.length})</h3>
          </div>
          <div className="p-8 grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
            {duplicates.map(d => (
              <div key={d.key} className="bg-white dark:bg-slate-800 p-4 rounded-2xl border border-rose-100 dark:border-white/5 flex justify-between items-center shadow-sm">
                <span className="font-black text-sm text-slate-900 dark:text-white tracking-tight">{d.key}</span>
                <span className="bg-rose-100 dark:bg-rose-500/20 text-rose-600 dark:text-rose-400 text-[10px] font-black px-2.5 py-1 rounded-lg uppercase">{d.count}x</span>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Issues Table */}
      <div className="bg-white dark:bg-slate-800 rounded-3xl shadow-sm border border-slate-100 dark:border-white/5 overflow-hidden">
        <div className="px-8 py-6 border-b border-slate-100 dark:border-white/5 flex flex-col md:flex-row items-center justify-between gap-4">
          <div className="flex items-center gap-3">
            <AlertTriangle className="w-5 h-5 text-amber-500" />
            <h3 className="text-xl font-black text-slate-900 dark:text-white tracking-tight">Audit Log ({filtered.length} Alerts)</h3>
          </div>
          <div className="relative w-full md:w-80">
            <Search className="w-4 h-4 absolute left-4 top-1/2 -translate-y-1/2 text-slate-400" />
            <input
              type="text"
              value={searchFilter}
              onChange={e => setSearchFilter(e.target.value)}
              placeholder="Search by code or name..."
              className="w-full pl-11 pr-4 py-3 bg-slate-50 dark:bg-slate-900 border border-slate-100 dark:border-white/10 rounded-2xl text-sm font-black text-slate-900 dark:text-white focus:ring-4 focus:ring-indigo-500/10 outline-none transition-all placeholder:text-slate-300 dark:placeholder:text-slate-600"
            />
          </div>
        </div>
        
        {loading ? (
          <div className="p-24 text-center">
            <RefreshCw className="w-12 h-12 text-indigo-500 animate-spin mx-auto mb-4" />
            <p className="text-slate-400 dark:text-slate-500 font-bold text-[10px] uppercase tracking-widest">Scanning academic matrix...</p>
          </div>
        ) : filtered.length === 0 ? (
          <div className="p-24 text-center">
            <ShieldCheck className="w-16 h-16 text-emerald-500 mx-auto mb-4" />
            <p className="text-xl font-black text-slate-900 dark:text-white tracking-tight">All Clear!</p>
            <p className="text-sm text-slate-400 dark:text-slate-500 font-medium mt-1">No data quality anomalies detected in this quadrant.</p>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left">
              <thead className="bg-slate-50/50 dark:bg-white/5 border-b border-slate-100 dark:border-white/5">
                <tr>
                  <th className="px-8 py-5 text-[10px] font-black text-slate-400 dark:text-slate-500 uppercase tracking-widest">Course Code</th>
                  <th className="px-8 py-5 text-[10px] font-black text-slate-400 dark:text-slate-500 uppercase tracking-widest">Identification</th>
                  <th className="px-8 py-5 text-center text-[10px] font-black text-slate-400 dark:text-slate-500 uppercase tracking-widest">Sec</th>
                  <th className="px-8 py-5 text-[10px] font-black text-slate-400 dark:text-slate-500 uppercase tracking-widest">Faculty / Credits</th>
                  <th className="px-8 py-5 text-[10px] font-black text-slate-400 dark:text-slate-500 uppercase tracking-widest">Anomaly Signature</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-50 dark:divide-white/5">
                {filtered.slice(0, 100).map(issue => (
                  <tr key={issue.id} className="hover:bg-amber-50/30 dark:hover:bg-amber-500/5 transition-colors group">
                    <td className="px-8 py-5 text-sm font-black text-slate-900 dark:text-white tracking-tight">{issue.course_code}</td>
                    <td className="px-8 py-5">
                      <div className="text-sm font-bold text-slate-700 dark:text-slate-300">{issue.course_name || <span className="text-rose-500 italic">Missing Signature</span>}</div>
                    </td>
                    <td className="px-8 py-5 text-center">
                      <div className="w-8 h-8 mx-auto flex items-center justify-center bg-slate-50 dark:bg-slate-900 rounded-lg text-xs font-black text-slate-900 dark:text-white border border-slate-100 dark:border-white/5">{issue.section_number ?? '—'}</div>
                    </td>
                    <td className="px-8 py-5">
                      <div className="text-xs font-black text-indigo-600 dark:text-indigo-400 uppercase">{issue.faculty_initials || <span className="text-rose-500">TBA</span>}</div>
                      <div className="text-[10px] text-slate-400 dark:text-slate-500 font-bold uppercase tracking-widest mt-0.5">{issue.credit_val ?? '0.0'} Credits</div>
                    </td>
                    <td className="px-8 py-5">
                      <div className="flex flex-wrap gap-1.5">
                        {issue.issues.map((iss, idx) => (
                          <span key={idx} className="text-[10px] font-black bg-rose-50 dark:bg-rose-500/10 text-rose-600 dark:text-rose-400 px-2.5 py-1 rounded-lg border border-rose-100 dark:border-rose-500/20 uppercase tracking-tighter">{iss}</span>
                        ))}
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
            {filtered.length > 100 && (
              <div className="p-6 text-center text-[10px] font-black text-slate-400 dark:text-slate-500 uppercase tracking-widest bg-slate-50/50 dark:bg-white/5">
                Truncated View: Showing 100 of {filtered.length} Alerts. Refine search for full access.
              </div>
            )}
          </div>
        )}
      </div>
    </div>
  );
}
