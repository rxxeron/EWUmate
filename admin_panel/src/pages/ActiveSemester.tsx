import { useEffect, useState } from 'react';
import { supabase } from '../lib/supabase';
import { Calendar, Save, RefreshCw, AlertCircle } from 'lucide-react';
import toast from 'react-hot-toast';
import { motion } from 'framer-motion';

interface SemesterTrack {
  track: string;
  current_semester_code: string;
  next_semester_code: string;
}

export function ActiveSemester() {
  const [tracks, setTracks] = useState<SemesterTrack[]>([]);
  const [loading, setLoading] = useState(false);
  const [saving, setSaving] = useState<string | null>(null);

  const [localValues, setLocalValues] = useState<Record<string, { current: string; next: string }>>({});

  useEffect(() => {
    fetchSemesters();
  }, []);

  const fetchSemesters = async () => {
    setLoading(true);
    const { data, error } = await supabase
      .from('active_semester')
      .select('track, current_semester_code, next_semester_code');
    
    if (error) {
      toast.error('Failed to load semesters: ' + error.message);
    } else if (data) {
      setTracks(data);
      const initial: Record<string, { current: string; next: string }> = {};
      data.forEach(t => {
        initial[t.track] = { current: t.current_semester_code, next: t.next_semester_code };
      });
      setLocalValues(initial);
    }
    setLoading(false);
  };

  const updateSemester = async (track: string) => {
    const values = localValues[track];
    if (!values) return;

    setSaving(track);
    const { error } = await supabase
      .from('active_semester')
      .update({ 
        current_semester_code: values.current,
        next_semester_code: values.next 
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
                <div>
                  <label className="block text-[10px] font-black text-slate-400 uppercase tracking-widest mb-2 ml-1">Current Semester Code</label>
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
                  <label className="block text-[10px] font-black text-slate-400 uppercase tracking-widest mb-2 ml-1">Next Semester Code</label>
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
                
                <button
                  onClick={() => updateSemester(t.track)}
                  disabled={saving === t.track}
                  className="w-full mt-4 flex items-center justify-center gap-3 bg-indigo-600 text-white py-4 rounded-2xl font-black text-[10px] uppercase tracking-[0.2em] hover:bg-indigo-700 disabled:opacity-50 transition-all shadow-lg shadow-indigo-100"
                >
                  {saving === t.track ? <RefreshCw className="w-4 h-4 animate-spin" /> : <Save className="w-4 h-4" />}
                  {saving === t.track ? 'Saving Matrix...' : 'Sync Track'}
                </button>
              </div>
            </motion.div>
          ))}
        </div>
      )}

    </div>
  );
}
