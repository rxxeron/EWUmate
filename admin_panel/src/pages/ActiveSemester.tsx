import { useEffect, useState } from 'react';
import { supabase } from '../lib/supabase';
import { Calendar, Save, RefreshCw, AlertCircle } from 'lucide-react';
import toast from 'react-hot-toast';
import { motion } from 'framer-motion';

interface SemesterTrack {
  track: string;
  current_semester_code: string;
  next_semester_code: string;
  is_advising_open: boolean;
  is_next_semester_open: boolean;
}

export function ActiveSemester() {
  const [tracks, setTracks] = useState<SemesterTrack[]>([]);
  const [loading, setLoading] = useState(false);
  const [saving, setSaving] = useState<string | null>(null);

  const [localValues, setLocalValues] = useState<Record<string, { 
    current: string; 
    next: string;
    isAdvisingOpen: boolean;
    isNextSemesterOpen: boolean;
  }>>({});

  useEffect(() => {
    fetchSemesters();
  }, []);

  const fetchSemesters = async () => {
    setLoading(true);
    const { data, error } = await supabase
      .from('active_semester')
      .select('track, current_semester_code, next_semester_code, is_advising_open, is_next_semester_open');
    
    if (error) {
      toast.error('Failed to load semesters: ' + error.message);
    } else if (data) {
      setTracks(data);
      const initial: Record<string, { 
        current: string; 
        next: string;
        isAdvisingOpen: boolean;
        isNextSemesterOpen: boolean;
      }> = {};
      data.forEach(t => {
        initial[t.track] = { 
          current: t.current_semester_code, 
          next: t.next_semester_code,
          isAdvisingOpen: t.is_advising_open || false,
          isNextSemesterOpen: t.is_next_semester_open || false
        };
      });
      setLocalValues(initial);
    }
    setLoading(false);
  };

  const updateSemester = async (track: string) => {
    const values = localValues[track];
    if (!values) return;

    const normalize = (val: string) => val.toLowerCase().replace(/[\s\-_]+/g, '');
    
    setSaving(track);
    const { error } = await supabase
      .from('active_semester')
      .update({ 
        current_semester_code: normalize(values.current),
        next_semester_code: normalize(values.next),
        is_advising_open: values.isAdvisingOpen,
        is_next_semester_open: values.isNextSemesterOpen
      })
      .eq('track', track);

    if (error) {
      toast.error(`Failed to update ${track}: ` + error.message);
    } else {
      toast.success(`${track} updated successfully!`);
      fetchSemesters();
    }
    setSaving(null);
  };

  if (loading) return (
    <div className="flex flex-col items-center justify-center h-64 space-y-4">
      <RefreshCw className="w-8 h-8 text-indigo-600 animate-spin" />
      <p className="text-slate-400 font-bold text-[10px] uppercase tracking-widest animate-pulse">Synchronizing semester tracks...</p>
    </div>
  );

  return (
    <div className="space-y-8 animate-in fade-in duration-700">
      <div className="bg-slate-900 rounded-[1.5rem] sm:rounded-[2.5rem] p-6 sm:p-10 text-white shadow-2xl relative overflow-hidden group">
        <div className="absolute top-0 right-0 p-10 opacity-10 group-hover:rotate-12 transition-transform duration-700">
           <Calendar className="w-48 h-48" />
        </div>
        <div className="relative z-10">
          <div className="flex items-center gap-4 mb-4">
            <div className="p-3 bg-white/10 backdrop-blur-md rounded-2xl border border-white/10">
              <Calendar className="w-8 h-8 text-indigo-400" />
            </div>
            <h2 className="text-2xl sm:text-4xl font-black tracking-tight">Active Semester</h2>
          </div>
          <p className="text-indigo-100/70 max-w-xl text-sm font-medium leading-relaxed">
            Configure the current and next semester codes for each academic track. 
            This dynamically updates the Courses Catalog, File Parser, and Mobile Dashboard across the entire ecosystem.
          </p>
        </div>
      </div>

      {tracks.length === 0 ? (
        <div className="bg-amber-50 border border-amber-100 p-8 rounded-[2rem] flex items-start gap-5 shadow-sm">
          <div className="p-3 bg-white rounded-2xl shadow-sm">
             <AlertCircle className="w-6 h-6 text-amber-500 shrink-0" />
          </div>
          <div>
            <h3 className="text-amber-900 font-black tracking-tight">No Tracks Configured</h3>
            <p className="text-amber-700/70 text-sm font-medium mt-1">
              Navigate to the <a href="/academic-data" className="font-black text-amber-900 underline">Global Data</a> quadrant to initialize your academic tracks.
            </p>
          </div>
        </div>
      ) : (
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
          {tracks.map((t, i) => (
            <motion.div 
              key={t.track} 
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: i * 0.1 }}
              className="bg-white rounded-[2rem] shadow-sm border border-slate-100 p-8 hover:shadow-xl hover:border-indigo-100 transition-all group"
            >
              <div className="flex items-center justify-between mb-8">
                <span className="px-4 py-1.5 bg-indigo-50 text-indigo-600 rounded-full text-[10px] font-black uppercase tracking-widest border border-indigo-100">
                  {t.track.replace('_', ' ')}
                </span>
                <div className="p-2 bg-slate-50 rounded-xl text-slate-300 group-hover:text-indigo-400 transition-colors">
                  <Calendar className="w-5 h-5" />
                </div>
              </div>
              
              <div className="space-y-6">
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                  <div>
                    <label className="block text-[10px] font-black text-slate-400 uppercase tracking-widest mb-2 ml-1">Current Semester</label>
                    <input
                      type="text"
                      value={localValues[t.track]?.current || ''}
                      onChange={(e) => setLocalValues(prev => ({
                        ...prev,
                        [t.track]: { ...prev[t.track], current: e.target.value }
                      }))}
                      className="w-full px-5 py-4 bg-slate-50 border border-slate-100 rounded-2xl focus:bg-white focus:ring-4 focus:ring-indigo-500/10 focus:border-indigo-500 outline-none transition-all font-black text-slate-900 placeholder:text-slate-300"
                      placeholder="e.g. Spring 2026"
                    />
                  </div>
                  <div>
                    <label className="block text-[10px] font-black text-slate-400 uppercase tracking-widest mb-2 ml-1">Next Semester</label>
                    <input
                      type="text"
                      value={localValues[t.track]?.next || ''}
                      onChange={(e) => setLocalValues(prev => ({
                        ...prev,
                        [t.track]: { ...prev[t.track], next: e.target.value }
                      }))}
                      className="w-full px-5 py-4 bg-slate-50 border border-slate-100 rounded-2xl focus:bg-white focus:ring-4 focus:ring-indigo-500/10 focus:border-indigo-500 outline-none transition-all font-black text-slate-900 placeholder:text-slate-300"
                      placeholder="e.g. Summer 2026"
                    />
                  </div>
                </div>

                <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                   <div 
                    onClick={() => setLocalValues(prev => ({
                      ...prev,
                      [t.track]: { ...prev[t.track], isAdvisingOpen: !prev[t.track].isAdvisingOpen }
                    }))}
                    className={`p-4 rounded-2xl border transition-all cursor-pointer flex items-center justify-between ${
                      localValues[t.track]?.isAdvisingOpen 
                        ? 'bg-emerald-50 border-emerald-100' 
                        : 'bg-slate-50 border-slate-100'
                    }`}
                   >
                      <div>
                        <div className={`text-[10px] font-black uppercase tracking-widest mb-0.5 ${
                          localValues[t.track]?.isAdvisingOpen ? 'text-emerald-600' : 'text-slate-400'
                        }`}>Advising</div>
                        <div className="text-xs font-bold text-slate-900">
                          {localValues[t.track]?.isAdvisingOpen ? 'OPEN' : 'CLOSED'}
                        </div>
                      </div>
                      <div className={`w-10 h-5 rounded-full relative transition-colors ${
                        localValues[t.track]?.isAdvisingOpen ? 'bg-emerald-500' : 'bg-slate-200'
                      }`}>
                        <div className={`absolute top-1 w-3 h-3 bg-white rounded-full transition-all ${
                          localValues[t.track]?.isAdvisingOpen ? 'left-6' : 'left-1'
                        }`} />
                      </div>
                   </div>

                   <div 
                    onClick={() => setLocalValues(prev => ({
                      ...prev,
                      [t.track]: { ...prev[t.track], isNextSemesterOpen: !prev[t.track].isNextSemesterOpen }
                    }))}
                    className={`p-4 rounded-2xl border transition-all cursor-pointer flex items-center justify-between ${
                      localValues[t.track]?.isNextSemesterOpen 
                        ? 'bg-blue-50 border-blue-100' 
                        : 'bg-slate-50 border-slate-100'
                    }`}
                   >
                      <div>
                        <div className={`text-[10px] font-black uppercase tracking-widest mb-0.5 ${
                          localValues[t.track]?.isNextSemesterOpen ? 'text-blue-600' : 'text-slate-400'
                        }`}>Next Semester</div>
                        <div className="text-xs font-bold text-slate-900">
                          {localValues[t.track]?.isNextSemesterOpen ? 'VISIBLE' : 'HIDDEN'}
                        </div>
                      </div>
                      <div className={`w-10 h-5 rounded-full relative transition-colors ${
                        localValues[t.track]?.isNextSemesterOpen ? 'bg-blue-500' : 'bg-slate-200'
                      }`}>
                        <div className={`absolute top-1 w-3 h-3 bg-white rounded-full transition-all ${
                          localValues[t.track]?.isNextSemesterOpen ? 'left-6' : 'left-1'
                        }`} />
                      </div>
                   </div>
                </div>
                
                <button
                  onClick={() => updateSemester(t.track)}
                  disabled={saving === t.track}
                  className="w-full mt-4 flex items-center justify-center gap-3 bg-indigo-600 text-white py-4 rounded-2xl font-black text-[10px] uppercase tracking-[0.2em] hover:bg-indigo-700 disabled:opacity-50 transition-all shadow-lg shadow-indigo-100"
                >
                  {saving === t.track ? <RefreshCw className="w-4 h-4 animate-spin" /> : <Save className="w-4 h-4" />}
                  {saving === t.track ? 'Saving Track...' : 'Sync Configuration'}
                </button>
              </div>
            </motion.div>
          ))}
        </div>
      )}

    </div>
  );
}
