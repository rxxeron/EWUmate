import { useEffect, useState } from 'react';
import { supabase } from '../lib/supabase';
import { Calendar, Save, RefreshCw, AlertCircle } from 'lucide-react';
import toast from 'react-hot-toast';

interface SemesterTrack {
  track: string;
  current_semester_code: string;
  next_semester_code: string;
}

export function ActiveSemester() {
  const [tracks, setTracks] = useState<SemesterTrack[]>([]);
  const [loading, setLoading] = useState(false);
  const [saving, setSaving] = useState<string | null>(null);

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
    }
    setLoading(false);
  };

  const updateSemester = async (track: string, current: string, next: string) => {
    setSaving(track);
    const { error } = await supabase
      .from('active_semester')
      .update({ 
        current_semester_code: current,
        next_semester_code: next 
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
      <p className="text-gray-500 animate-pulse">Synchronizing semester tracks...</p>
    </div>
  );

  return (
    <div className="max-w-4xl space-y-8">
      <div className="bg-gradient-to-r from-indigo-600 to-blue-700 rounded-2xl p-8 text-white shadow-xl relative overflow-hidden">
        <div className="relative z-10">
          <div className="flex items-center gap-3 mb-2">
            <Calendar className="w-8 h-8 text-indigo-200" />
            <h2 className="text-3xl font-extrabold tracking-tight">Active Semester</h2>
          </div>
          <p className="text-indigo-100 max-w-xl">
            Configure the current and next semester codes for each academic track. 
            This dynamically updates the Courses Catalog, File Parser, and Mobile Dashboard.
          </p>
        </div>
        <div className="absolute -right-16 -bottom-16 w-64 h-64 bg-white/10 rounded-full blur-3xl"></div>
      </div>

      {tracks.length === 0 ? (
        <div className="bg-amber-50 border border-amber-200 p-6 rounded-xl flex items-start gap-4">
          <AlertCircle className="w-6 h-6 text-amber-600 shrink-0 mt-0.5" />
          <div>
            <h3 className="text-amber-800 font-bold">No Tracks Configured</h3>
            <p className="text-amber-700 text-sm mt-1">
              Go to <a href="/academic-data" className="font-bold underline">Global Data</a> to initialize your academic tracks (e.g. tri_semester).
            </p>
          </div>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          {tracks.map((t) => (
            <div key={t.track} className="bg-white rounded-xl shadow-sm border border-gray-200 p-6 hover:shadow-md transition-shadow">
              <div className="flex items-center justify-between mb-6">
                <span className="px-3 py-1 bg-indigo-50 text-indigo-700 rounded-full text-xs font-bold uppercase tracking-wider">
                  {t.track.replace('_', ' ')}
                </span>
                <Calendar className="w-5 h-5 text-gray-300" />
              </div>
              
              <div className="space-y-4">
                <div>
                  <label className="block text-xs font-bold text-gray-500 uppercase mb-1.5 ml-1">Current Semester</label>
                  <input
                    type="text"
                    defaultValue={t.current_semester_code}
                    onBlur={(e) => t.current_semester_code = e.target.value}
                    className="w-full px-4 py-3 bg-gray-50 border border-gray-200 rounded-lg focus:ring-2 focus:ring-indigo-500 outline-none transition-all font-medium text-gray-900"
                    placeholder="e.g. Spring 2026"
                  />
                </div>
                <div>
                  <label className="block text-xs font-bold text-gray-500 uppercase mb-1.5 ml-1">Next Semester</label>
                  <input
                    type="text"
                    defaultValue={t.next_semester_code}
                    onBlur={(e) => t.next_semester_code = e.target.value}
                    className="w-full px-4 py-3 bg-gray-50 border border-gray-200 rounded-lg focus:ring-2 focus:ring-indigo-500 outline-none transition-all font-medium text-gray-900"
                    placeholder="e.g. Summer 2026"
                  />
                </div>
                
                <button
                  onClick={() => updateSemester(t.track, t.current_semester_code, t.next_semester_code)}
                  disabled={saving === t.track}
                  className="w-full mt-2 flex items-center justify-center gap-2 bg-indigo-600 text-white py-3 rounded-lg font-bold hover:bg-indigo-700 disabled:opacity-50 transition-colors shadow-sm"
                >
                  {saving === t.track ? <RefreshCw className="w-4 h-4 animate-spin" /> : <Save className="w-4 h-4" />}
                  {saving === t.track ? 'Saving...' : 'Sync Track'}
                </button>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
