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
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Course Data Quality</h1>
          <p className="text-gray-500 mt-1 text-sm">
            Auditing <span className="font-semibold text-indigo-600">{activeSemester || '...'}</span> course data for completeness
          </p>
        </div>
        <button
          onClick={runAudit}
          disabled={loading || !activeSemester}
          className="flex items-center gap-2 px-4 py-2 bg-white border border-gray-300 rounded-lg shadow-sm hover:bg-gray-50 text-gray-700 font-medium transition-colors disabled:opacity-50"
        >
          <RefreshCw className={`w-4 h-4 ${loading ? 'animate-spin' : ''}`} />
          Re-run Audit
        </button>
      </div>

      {/* Stats Cards */}
      {stats && (
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-5">
            <p className="text-xs font-semibold text-gray-400 uppercase tracking-wider">Total Sections</p>
            <p className="text-3xl font-bold text-gray-900 mt-1">{stats.totalSections}</p>
            <p className="text-xs text-gray-500 mt-1">{stats.totalUniqueCourses} unique courses</p>
          </div>
          <div className={`rounded-xl shadow-sm border p-5 ${stats.completePercent >= 95 ? 'bg-emerald-50 border-emerald-200' : stats.completePercent >= 80 ? 'bg-yellow-50 border-yellow-200' : 'bg-red-50 border-red-200'}`}>
            <p className="text-xs font-semibold text-gray-400 uppercase tracking-wider">Data Completeness</p>
            <p className={`text-3xl font-bold mt-1 ${stats.completePercent >= 95 ? 'text-emerald-700' : stats.completePercent >= 80 ? 'text-yellow-700' : 'text-red-700'}`}>{stats.completePercent}%</p>
            <p className="text-xs text-gray-500 mt-1">{issues.length} sections with issues</p>
          </div>
          <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-5">
            <p className="text-xs font-semibold text-gray-400 uppercase tracking-wider">Missing Faculty</p>
            <p className={`text-3xl font-bold mt-1 ${stats.missingFaculty > 0 ? 'text-amber-600' : 'text-green-600'}`}>{stats.missingFaculty}</p>
            <p className="text-xs text-gray-500 mt-1">{stats.missingName} missing names, {stats.missingCredits} missing credits</p>
          </div>
          <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-5">
            <p className="text-xs font-semibold text-gray-400 uppercase tracking-wider">Duplicates</p>
            <p className={`text-3xl font-bold mt-1 ${stats.duplicates > 0 ? 'text-red-600' : 'text-green-600'}`}>{stats.duplicates}</p>
            <p className="text-xs text-gray-500 mt-1">Same code + section</p>
          </div>
        </div>
      )}

      {/* Duplicates */}
      {duplicates.length > 0 && (
        <div className="bg-red-50 rounded-xl shadow-sm border border-red-200 overflow-hidden">
          <div className="px-6 py-4 border-b border-red-200 flex items-center gap-2">
            <Copy className="w-5 h-5 text-red-600" />
            <h3 className="text-lg font-bold text-red-800">Duplicate Sections ({duplicates.length})</h3>
          </div>
          <div className="p-6 grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-3">
            {duplicates.map(d => (
              <div key={d.key} className="bg-white p-3 rounded-lg border border-red-100 flex justify-between items-center">
                <span className="font-mono font-bold text-sm text-gray-900">{d.key}</span>
                <span className="bg-red-100 text-red-700 text-xs font-bold px-2 py-1 rounded-full">{d.count}x</span>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Issues Table */}
      <div className="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden">
        <div className="px-6 py-4 border-b border-gray-200 flex items-center justify-between">
          <div className="flex items-center gap-2">
            <AlertTriangle className="w-5 h-5 text-amber-500" />
            <h3 className="text-lg font-bold text-gray-800">Data Issues ({filtered.length})</h3>
          </div>
          <div className="relative w-64">
            <Search className="w-4 h-4 absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" />
            <input
              type="text"
              value={searchFilter}
              onChange={e => setSearchFilter(e.target.value)}
              placeholder="Filter by course code..."
              className="w-full pl-9 pr-3 py-2 border border-gray-200 rounded-lg text-sm focus:ring-indigo-500 focus:border-indigo-500"
            />
          </div>
        </div>
        
        {loading ? (
          <div className="p-12 text-center text-gray-500">Running audit...</div>
        ) : filtered.length === 0 ? (
          <div className="p-12 text-center">
            <ShieldCheck className="w-12 h-12 text-green-500 mx-auto mb-3" />
            <p className="text-lg font-semibold text-green-700">All Clear!</p>
            <p className="text-sm text-gray-500 mt-1">No data quality issues found.</p>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="min-w-full divide-y divide-gray-200">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Course Code</th>
                  <th className="px-6 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Course Name</th>
                  <th className="px-6 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Section</th>
                  <th className="px-6 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Faculty</th>
                  <th className="px-6 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Credits</th>
                  <th className="px-6 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Issues</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-200">
                {filtered.slice(0, 100).map(issue => (
                  <tr key={issue.id} className="hover:bg-amber-50/50 transition-colors">
                    <td className="px-6 py-3 text-sm font-mono font-bold text-gray-900">{issue.course_code}</td>
                    <td className="px-6 py-3 text-sm text-gray-700">{issue.course_name || <span className="text-red-500 italic">Missing</span>}</td>
                    <td className="px-6 py-3 text-sm text-gray-700">{issue.section_number ?? '—'}</td>
                    <td className="px-6 py-3 text-sm text-gray-700">{issue.faculty_initials || <span className="text-red-500 italic">TBA / Empty</span>}</td>
                    <td className="px-6 py-3 text-sm text-gray-700">{issue.credit_val ?? <span className="text-red-500 italic">Missing</span>}</td>
                    <td className="px-6 py-3">
                      <div className="flex flex-wrap gap-1">
                        {issue.issues.map((iss, idx) => (
                          <span key={idx} className="text-xs bg-amber-100 text-amber-800 px-2 py-0.5 rounded-full font-medium">{iss}</span>
                        ))}
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
            {filtered.length > 100 && (
              <div className="p-4 text-center text-sm text-gray-500 bg-gray-50">
                Showing first 100 of {filtered.length} issues. Use the search filter to narrow results.
              </div>
            )}
          </div>
        )}
      </div>
    </div>
  );
}
