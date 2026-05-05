import { useEffect, useState } from 'react';
import { useSearchParams } from 'react-router-dom';
import { supabase } from '../lib/supabase';
import { BookOpen, Search, ChevronLeft, ChevronRight, Calendar, Filter, Zap } from 'lucide-react';
import { motion } from 'framer-motion';
import type { CourseSection, Semester } from '../types';
import { Skeleton } from '../components/Skeleton';

export function CoursesList() {
  const [searchParams, setSearchParams] = useSearchParams();
  const [courses, setCourses] = useState<CourseSection[]>([]);
  const [semesters, setSemesters] = useState<Semester[]>([]);
  const [selectedSemester, setSelectedSemester] = useState<string>('');
  const [loading, setLoading] = useState(true);
  const searchTerm = searchParams.get('q') || '';
  const page = parseInt(searchParams.get('page') || '0');
  const pageSize = 20;

  const setPage = (p: number | ((prev: number) => number)) => {
    const newPage = typeof p === 'function' ? p(page) : p;
    setSearchParams(prev => { prev.set('page', String(newPage)); return prev; });
  };

  const setSearchTerm = (val: string) => {
    setSearchParams(prev => {
      if (val) prev.set('q', val); else prev.delete('q');
      prev.set('page', '0');
      return prev;
    });
  };

  useEffect(() => {
    fetchSemesters();
  }, []);

  async function fetchSemesters() {
    const { data } = await supabase.from('semesters').select('*').order('created_at', { ascending: false });
    if (data && data.length > 0) {
      setSemesters(data);
      const active = data.find(s => s.is_active);
      setSelectedSemester(active ? active.code : data[0].code);
    }
  }

  useEffect(() => {
    if (selectedSemester) {
      fetchCourses();
    }
  }, [selectedSemester, page, searchTerm]);

  async function fetchCourses() {
    setLoading(true);
    let tableName = `courses_${selectedSemester.toLowerCase().replace(/_/g, '')}`;

    let query = supabase
      .from(tableName)
      .select('id, course_code, course_name, section_number, faculty_initials, credit_val', { count: 'exact' })
      .range(page * pageSize, (page + 1) * pageSize - 1)
      .order('course_code', { ascending: true })
      .order('section_number', { ascending: true });

    if (searchTerm) {
      query = query.or(`course_code.ilike.%${searchTerm}%,course_name.ilike.%${searchTerm}%`);
    }

    const { data, error } = await query;

    if (!error && data) {
      setCourses(data);
    } else {
      setCourses([]);
    }
    setLoading(false);
  }

  return (
    <div className="space-y-8 animate-in fade-in duration-700">
      <div className="flex flex-col md:flex-row items-start md:items-center justify-between gap-6">
        <div>
          <h2 className="text-3xl font-black text-slate-900 tracking-tight flex items-center gap-4">
             <div className="p-3 bg-indigo-600 rounded-2xl text-white shadow-lg shadow-indigo-100">
               <BookOpen className="w-6 h-6" />
             </div>
             Course Catalog
          </h2>
          <p className="text-slate-400 text-[10px] font-black uppercase tracking-[0.2em] mt-2 ml-1">Academic Repository Intelligence</p>
        </div>

        <div className="relative w-full md:w-auto">
          <select
            value={selectedSemester}
            onChange={(e) => {
              setSelectedSemester(e.target.value);
              setPage(0);
            }}
            className="w-full md:w-64 pl-4 pr-10 py-3.5 bg-slate-900 text-white rounded-2xl appearance-none font-black text-xs uppercase tracking-widest focus:ring-4 focus:ring-indigo-500/20 transition-all outline-none shadow-xl shadow-slate-200 cursor-pointer"
          >
            {semesters.map(s => (
              <option key={s.code} value={s.code} className="bg-slate-900">{s.title || s.code}</option>
            ))}
          </select>
          <div className="absolute inset-y-0 right-4 flex items-center pointer-events-none text-indigo-400">
             <Calendar className="w-4 h-4" />
          </div>
        </div>
      </div>

      {/* Filter Bar */}
      <div className="bg-white/70 backdrop-blur-xl p-4 sm:p-6 rounded-[1.5rem] sm:rounded-[2.5rem] border border-slate-200/60 shadow-sm">
        <div className="flex items-center gap-3 text-slate-900 mb-4 ml-1">
           <Filter className="w-4 h-4" />
           <span className="text-[10px] font-black uppercase tracking-widest">Instant Filter</span>
        </div>
        
        <div className="relative group">
          <div className="absolute inset-y-0 left-4 flex items-center pointer-events-none transition-transform group-focus-within:scale-110">
            <Search className="h-4 w-4 text-slate-400 group-focus-within:text-indigo-500" />
          </div>
          <input
            type="text"
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="block w-full pl-12 pr-4 py-4 bg-slate-50 border border-slate-100 rounded-2xl text-sm font-bold text-slate-900 placeholder:text-slate-300 focus:bg-white focus:ring-4 focus:ring-indigo-500/10 focus:border-indigo-500 transition-all outline-none"
            placeholder="Search course code or title..."
          />
        </div>
      </div>

      {/* Courses Table */}
      <div className="bg-white rounded-[1.5rem] sm:rounded-[2.5rem] border border-slate-200/60 shadow-sm overflow-hidden flex flex-col">
        <div className="overflow-x-auto custom-scrollbar">
          <table className="w-full">
            <thead className="bg-slate-50/50 border-b border-slate-100">
              <tr>
                <th className="px-6 sm:px-8 py-5 text-left text-[10px] font-black text-slate-400 uppercase tracking-widest">Course Code</th>
                <th className="px-6 sm:px-8 py-5 text-left text-[10px] font-black text-slate-400 uppercase tracking-widest">Title & Information</th>
                <th className="hidden sm:table-cell px-8 py-5 text-center text-[10px] font-black text-slate-400 uppercase tracking-widest">Section</th>
                <th className="hidden lg:table-cell px-8 py-5 text-center text-[10px] font-black text-slate-400 uppercase tracking-widest">Credits</th>
                <th className="px-6 sm:px-8 py-5 text-right text-[10px] font-black text-slate-400 uppercase tracking-widest">Faculty</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-50">
              {loading ? (
                Array.from({ length: 5 }).map((_, i) => (
                  <tr key={i}>
                    <td className="px-8 py-6"><Skeleton className="w-32 h-8 rounded-xl" /></td>
                    <td className="px-8 py-6"><Skeleton className="w-64 h-8 rounded-xl" /></td>
                    <td className="hidden sm:table-cell px-8 py-6"><Skeleton className="w-16 h-8 rounded-xl mx-auto" /></td>
                    <td className="hidden lg:table-cell px-8 py-6"><Skeleton className="w-16 h-8 rounded-xl mx-auto" /></td>
                    <td className="px-8 py-6"><Skeleton className="w-24 h-8 rounded-xl ml-auto" /></td>
                  </tr>
                ))
              ) : courses.length === 0 ? (
                <tr>
                  <td colSpan={5} className="px-8 py-24 text-center">
                    <div className="w-20 h-20 bg-slate-50 rounded-3xl flex items-center justify-center mx-auto mb-6">
                       <Search className="w-10 h-10 text-slate-200" />
                    </div>
                    <h3 className="text-lg font-black text-slate-900">No Courses Found</h3>
                    <p className="text-slate-400 text-sm font-medium mt-2">Try scanning a different semester or adjusting your search.</p>
                  </td>
                </tr>
              ) : (
                courses.map((course, i) => (
                  <motion.tr 
                    key={course.id} 
                    initial={{ opacity: 0, y: 10 }}
                    animate={{ opacity: 1, y: 0 }}
                    transition={{ delay: i * 0.02 }}
                    className="hover:bg-slate-50/50 transition-all group"
                  >
                    <td className="px-6 sm:px-8 py-6">
                      <div className="text-sm font-black text-indigo-600 tracking-tight group-hover:scale-105 transition-transform origin-left">
                        {course.course_code}
                      </div>
                    </td>
                    <td className="px-6 sm:px-8 py-6">
                      <div className="text-sm font-black text-slate-900 line-clamp-1">{course.course_name || 'N/A'}</div>
                      <div className="sm:hidden flex items-center gap-2 mt-1">
                        <span className="text-[9px] font-black text-indigo-500 uppercase">Sec {course.section_number}</span>
                        <span className="text-[9px] font-black text-slate-400 uppercase">•</span>
                        <span className="text-[9px] font-black text-slate-400 uppercase">{course.credit_val} Credits</span>
                      </div>
                    </td>
                    <td className="hidden sm:table-cell px-8 py-6 text-center">
                      <span className="px-3 py-1 bg-indigo-50 text-indigo-600 rounded-lg text-[10px] font-black border border-indigo-100">
                        {course.section_number}
                      </span>
                    </td>
                    <td className="hidden lg:table-cell px-8 py-6 text-center">
                      <div className="text-sm font-black text-slate-900">{course.credit_val ? `${course.credit_val}` : 'N/A'}</div>
                    </td>
                    <td className="px-6 sm:px-8 py-6 text-right">
                      <div className="inline-flex items-center gap-2 px-3 py-1.5 rounded-2xl bg-slate-50 text-slate-900 border border-slate-100 font-black text-[10px] uppercase tracking-tighter">
                        <Zap className="w-3 h-3 text-amber-500" />
                        {course.faculty_initials || 'TBA'}
                      </div>
                    </td>
                  </motion.tr>
                ))
              )}
            </tbody>
          </table>
        </div>

        {!loading && (
          <div className="px-8 py-6 bg-slate-50/50 border-t border-slate-100 flex flex-col md:flex-row items-center justify-between gap-6">
            <div className="text-[10px] font-black text-slate-400 uppercase tracking-widest">
              Catalog Page <span className="text-slate-900">{page + 1}</span> of Global Database
            </div>
            
            <div className="flex items-center gap-3">
              <button
                onClick={() => setPage(p => Math.max(0, p - 1))}
                disabled={page === 0}
                className="p-3 bg-white border border-slate-200 rounded-2xl text-slate-600 hover:bg-slate-50 hover:shadow-md disabled:opacity-30 transition-all"
              >
                <ChevronLeft className="h-5 w-5" />
              </button>
              
              <div className="px-6 py-3 bg-white border border-slate-200 rounded-2xl text-xs font-black text-slate-900 shadow-sm">
                {page + 1}
              </div>

              <button
                onClick={() => setPage(p => p + 1)}
                disabled={courses.length < pageSize}
                className="p-3 bg-white border border-slate-200 rounded-2xl text-slate-600 hover:bg-slate-50 hover:shadow-md disabled:opacity-30 transition-all"
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