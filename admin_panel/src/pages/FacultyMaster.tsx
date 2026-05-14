import { useEffect, useState } from 'react';
import { supabase } from '../lib/supabase';
import { Users, Search, Mail, Phone, Filter, ChevronLeft, ChevronRight } from 'lucide-react';
import { motion } from 'framer-motion';
import type { Faculty } from '../types';
import { Skeleton } from '../components/Skeleton';

export function FacultyMaster() {
  const [faculty, setFaculty] = useState<Faculty[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [page, setPage] = useState(0);
  const pageSize = 100;

  const [stats, setStats] = useState({ total: 0, filtered: 0 });

  useEffect(() => {
    fetchFaculty();
  }, [page, searchTerm]);

  async function fetchFaculty() {
    setLoading(true);
    let query = supabase
      .from('faculty_master')
      .select('*', { count: 'exact' })
      .order('short_name', { ascending: true })
      .range(page * pageSize, (page + 1) * pageSize - 1);

    if (searchTerm) {
      query = query.or(`full_name.ilike.%${searchTerm}%,short_name.ilike.%${searchTerm}%`);
    }

    const { data, error, count } = await query;

    if (!error && data) {
      setFaculty(data as Faculty[]);
      setStats(prev => ({ 
        total: searchTerm ? prev.total : (count || 0), 
        filtered: count || 0 
      }));
    }

    // One-time total fetch if not searching
    if (!searchTerm && !stats.total) {
      const { count: totalCount } = await supabase.from('faculty_master').select('*', { count: 'exact', head: true });
      setStats(prev => ({ ...prev, total: totalCount || 0 }));
    }

    setLoading(false);
  }

  return (
    <div className="space-y-8 animate-in fade-in duration-700">
      <div className="flex flex-col md:flex-row items-start md:items-center justify-between gap-6">
        <div>
          <h2 className="text-3xl font-black text-slate-900 tracking-tight flex items-center gap-4">
             <div className="p-3 bg-indigo-600 rounded-2xl text-white shadow-lg shadow-indigo-100">
               <Users className="w-6 h-6" />
             </div>
             Faculty Master
          </h2>
          <div className="flex items-center gap-2 mt-2 ml-1">
             <p className="text-slate-400 text-xs font-black uppercase tracking-[0.2em]">Central Directory</p>
             <div className="w-1 h-1 rounded-full bg-slate-300" />
             <p className="text-indigo-600 text-xs font-black uppercase tracking-widest">{stats.total.toLocaleString()} Professors</p>
          </div>
        </div>
      </div>

      <div className="bg-white/70 backdrop-blur-xl p-4 sm:p-6 rounded-[1.5rem] sm:rounded-[2.5rem] border border-slate-200/60 shadow-sm space-y-6">
        <div className="flex items-center justify-between mb-2">
          <div className="flex items-center gap-3 text-slate-900">
             <Filter className="w-4 h-4" />
             <span className="text-[10px] font-black uppercase tracking-widest">Search Faculty Hub</span>
          </div>
          {searchTerm && (
            <span className="text-[10px] font-black text-indigo-500 uppercase tracking-widest bg-indigo-50 px-3 py-1 rounded-full">
              {stats.filtered} Results Found
            </span>
          )}
        </div>
        
        <div className="relative group">
          <div className="absolute inset-y-0 left-4 flex items-center pointer-events-none transition-transform group-focus-within:scale-110">
            <Search className="h-4 w-4 text-slate-400 group-focus-within:text-indigo-500" />
          </div>
          <input
            type="text"
            value={searchTerm}
            onChange={(e) => { setSearchTerm(e.target.value); setPage(0); }}
            className="block w-full pl-12 pr-4 py-3.5 bg-slate-50 border border-slate-100 rounded-2xl text-sm font-bold text-slate-900 placeholder:text-slate-300 focus:bg-white focus:ring-4 focus:ring-indigo-500/10 focus:border-indigo-500 transition-all outline-none"
            placeholder="Search by name or initials (e.g. AIA)..."
          />
        </div>
      </div>

      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
        {loading ? (
          Array.from({ length: 8 }).map((_, i) => (
            <div key={i} className="bg-white p-6 rounded-[2rem] border border-slate-100 space-y-4">
              <Skeleton className="w-16 h-16 rounded-2xl" />
              <Skeleton className="w-3/4 h-6 rounded-lg" />
              <Skeleton className="w-1/2 h-4 rounded-lg" />
              <div className="pt-4 space-y-2">
                <Skeleton className="w-full h-4 rounded-lg" />
                <Skeleton className="w-full h-4 rounded-lg" />
              </div>
            </div>
          ))
        ) : faculty.length === 0 ? (
          <div className="col-span-full py-24 text-center">
            <div className="w-20 h-20 bg-slate-50 rounded-3xl flex items-center justify-center mx-auto mb-6">
               <Search className="w-10 h-10 text-slate-200" />
            </div>
            <h3 className="text-lg font-black text-slate-900">No Faculty Found</h3>
            <p className="text-slate-400 text-sm font-medium mt-2">Try searching by initials or a different part of the name.</p>
          </div>
        ) : (
          faculty.map((f, i) => (
            <motion.div
              key={f.id}
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: i * 0.05 }}
              className="bg-white p-6 rounded-[2rem] border border-slate-100 hover:shadow-xl hover:border-indigo-100 transition-all group"
            >
              <div className="flex items-start justify-between mb-4">
                <div className="w-16 h-16 rounded-2xl bg-slate-50 border border-slate-100 overflow-hidden relative shadow-sm group-hover:scale-105 transition-transform">
                  {f.photo_url ? (
                    <img src={f.photo_url} alt={f.short_name} className="w-full h-full object-cover" />
                  ) : (
                    <div className="w-full h-full flex items-center justify-center bg-indigo-50 text-indigo-500 font-black text-xl uppercase">
                      {f.short_name.substring(0, 2)}
                    </div>
                  )}
                </div>
                <div className="px-3 py-1 bg-indigo-50 text-indigo-600 rounded-full text-[10px] font-black uppercase tracking-widest border border-indigo-100">
                  {f.short_name}
                </div>
              </div>

              <div className="min-h-[3.5rem]">
                <h3 className="text-lg font-black text-slate-900 leading-tight group-hover:text-indigo-600 transition-colors">
                  {f.full_name || 'N/A'}
                </h3>
                <p className="text-[10px] font-bold text-slate-400 uppercase tracking-widest mt-1">
                  {f.designation_name || 'Faculty Member'}
                </p>
              </div>

              <div className="mt-6 pt-6 border-t border-slate-50 space-y-3">
                <div className="flex items-center gap-3 text-slate-500">
                   <Mail className="w-4 h-4" />
                   <span className="text-xs font-bold truncate">{f.email || 'No email registered'}</span>
                </div>
                <div className="flex items-center gap-3 text-slate-500">
                   <Phone className="w-4 h-4" />
                   <span className="text-xs font-bold">{f.phone || 'No phone registered'}</span>
                </div>
              </div>
            </motion.div>
          ))
        )}
      </div>

      {!loading && faculty.length > 0 && (
        <div className="flex items-center justify-center gap-3 pt-8">
          <button
            onClick={() => setPage(p => Math.max(0, p - 1))}
            disabled={page === 0}
            className="p-3 bg-white border border-slate-200 rounded-2xl text-slate-600 hover:bg-slate-50 hover:shadow-md disabled:opacity-30 transition-all"
          >
            <ChevronLeft className="h-5 w-5" />
          </button>
          
          <div className="px-6 py-3 bg-white border border-slate-200 rounded-2xl text-xs font-black text-slate-900 shadow-sm">
            Page {page + 1}
          </div>

          <button
            onClick={() => setPage(p => p + 1)}
            disabled={faculty.length < pageSize}
            className="p-3 bg-white border border-slate-200 rounded-2xl text-slate-600 hover:bg-slate-50 hover:shadow-md disabled:opacity-30 transition-all"
          >
            <ChevronRight className="h-5 w-5" />
          </button>
        </div>
      )}
    </div>
  );
}
