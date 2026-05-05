import React, { useEffect, useState } from 'react';
import { supabase } from '../lib/supabase';
import { Calendar as CalendarIcon, Plus, Trash2, Loader2, Save, X } from 'lucide-react';
import toast from 'react-hot-toast';
import { motion, AnimatePresence } from 'framer-motion';
import type { CalendarEvent } from '../types';
import { cn } from '../lib/utils';

export function CalendarEditor() {
  const [tracks, setTracks] = useState<any[]>([]);
  const [selectedTrack, setSelectedTrack] = useState<string>('');
  const [activeSemester, setActiveSemester] = useState<string>('');
  const [tableName, setTableName] = useState<string>('');
  const [events, setEvents] = useState<CalendarEvent[]>([]);
  const [loading, setLoading] = useState<boolean>(true);

  // Form states
  const [showAddForm, setShowAddForm] = useState(false);
  const [newEvent, setNewEvent] = useState({ date: '', title: '', type: 'Holiday', targetTrack: '' });
  const [saving, setSaving] = useState(false);
  const [errorMsg, setErrorMsg] = useState('');

  const fetchActiveSemester = async () => {
    try {
      const { data, error } = await supabase.from('active_semester').select('*');
      if (error) throw error;
      
      if (data && data.length > 0) {
        setTracks(data);
        if (!selectedTrack) {
          const defaultTrack = data.find(s => s.track === 'tri_semester') || data[0];
          setSelectedTrack(defaultTrack.track);
          updateSemesterAndTable(defaultTrack);
        } else {
          const current = data.find(s => s.track === selectedTrack);
          if (current) updateSemesterAndTable(current);
        }
      } else {
        setErrorMsg('No active semester entries found in database.');
      }
    } catch (err: any) {
      console.error('Error fetching active semester:', err);
      setErrorMsg('Failed to fetch active semester context.');
    }
  };

  const updateSemesterAndTable = (trackData: any) => {
    const semesterCode = trackData.current_semester_code;
    setActiveSemester(semesterCode);
    let table = `calendar_${semesterCode.replace(/\s+/g, '').toLowerCase()}`;
    if (trackData.track === 'bi_semester') {
      table += '_phrm_llb';
    }
    setTableName(table);
  };

  const fetchEvents = async (table: string) => {
    setLoading(true);
    try {
      const { data, error } = await supabase
        .from(table)
        .select('*')
        .order('event_date', { ascending: true });
        
      if (error) {
        if (error.code === '42P01') {
          setEvents([]);
          setErrorMsg(`Table ${table} does not exist yet. Please upload a calendar first.`);
        } else {
          throw error;
        }
      } else {
        setEvents(data || []);
        setErrorMsg('');
      }
    } catch (err: any) {
      console.error('Error fetching events:', err);
      setErrorMsg(err.message || 'Error fetching calendar events.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchActiveSemester();
  }, [selectedTrack]);

  useEffect(() => {
    if (tableName) {
      fetchEvents(tableName);
    } else {
      setLoading(false);
    }
  }, [tableName]);

  const handleAddSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!tableName || !newEvent.date || !newEvent.title) return;
    
    setSaving(true);
    setErrorMsg('');
    try {
      const targetTrack = newEvent.targetTrack || selectedTrack;
      const payload = {
        event_date: new Date(newEvent.date).toISOString().split('T')[0],
        title: newEvent.title,
        type: newEvent.type,
        target_track: targetTrack === 'both' ? 'both' : targetTrack
      };

      if (targetTrack === 'both') {
        const triTable = `calendar_${activeSemester.replace(/\s+/g, '').toLowerCase()}`;
        const biTable = triTable + '_phrm_llb';
        
        await Promise.all([
          supabase.from(triTable).insert([{ ...payload, target_track: 'tri_semester' }]),
          supabase.from(biTable).insert([{ ...payload, target_track: 'bi_semester' }])
        ]);
        
        fetchEvents(tableName);
      } else {
        const targetTable = targetTrack === 'bi_semester' 
          ? `calendar_${activeSemester.replace(/\s+/g, '').toLowerCase()}_phrm_llb`
          : `calendar_${activeSemester.replace(/\s+/g, '').toLowerCase()}`;

        const { data, error } = await supabase.from(targetTable).insert([payload]).select().single();
        if (error) throw error;
        
        if (targetTable === tableName) {
          setEvents(prev => {
            const updated = [...prev, data];
            return updated.sort((a, b) => new Date(a.event_date).getTime() - new Date(b.event_date).getTime());
          });
        }
      }

      setShowAddForm(false);
      setNewEvent({ date: '', title: '', type: 'Holiday', targetTrack: '' });
      toast.success('Event added successfully');
    } catch (err: any) {
      console.error(err);
      setErrorMsg(err.message || 'Failed to add event');
    } finally {
      setSaving(false);
    }
  };

  const handleDelete = async (id: string) => {
    if (!id || !confirm('Are you sure you want to delete this event?')) return;
    
    const previousEvents = [...events];
    setEvents(prev => prev.filter(evt => evt.id !== id));
    
    try {
      const { error } = await supabase.from(tableName).delete().eq('id', id);
      if (error) throw error;
      toast.success('Event deleted');
    } catch (err: any) {
      console.error(err);
      setEvents(previousEvents);
      toast.error('Failed to delete: ' + err.message);
    }
  };

  const formatDate = (dateStr: string) => {
    if (!dateStr) return '';
    const d = new Date(dateStr);
    if (isNaN(d.getTime())) return dateStr;
    return d.toLocaleDateString(undefined, { weekday: 'short', month: 'short', day: 'numeric', year: 'numeric' });
  };

  return (
    <div className="space-y-8 animate-in fade-in duration-700">
      <div className="flex flex-col md:flex-row items-start md:items-center justify-between gap-6">
        <div>
          <h2 className="text-3xl font-black text-slate-900 tracking-tight flex items-center gap-4">
             <div className="p-3 bg-indigo-600 rounded-2xl text-white shadow-lg shadow-indigo-100">
               <CalendarIcon className="w-6 h-6" />
             </div>
             Calendar Manager
          </h2>
          <p className="text-slate-400 text-[10px] font-black uppercase tracking-[0.2em] mt-2 ml-1">
            Global Academic Timeline for <span className="text-indigo-600">{activeSemester || '...'}</span>
          </p>
        </div>

        <div className="flex flex-wrap items-center gap-3 w-full md:w-auto">
          {tracks.length > 1 && (
            <div className="flex bg-slate-100 p-1.5 rounded-2xl border border-slate-200 shadow-inner w-full sm:w-auto">
              {tracks.map(t => (
                <button
                  key={t.track}
                  onClick={() => setSelectedTrack(t.track)}
                  className={cn(
                    "flex-1 sm:flex-none px-4 py-2 text-[10px] font-black uppercase tracking-widest rounded-xl transition-all",
                    selectedTrack === t.track 
                      ? 'bg-white text-indigo-600 shadow-md' 
                      : 'text-slate-400 hover:text-slate-600'
                  )}
                >
                  {t.track.replace('_', ' ')}
                </button>
              ))}
            </div>
          )}
          <button
            onClick={() => setShowAddForm(true)}
            disabled={!tableName || !!errorMsg}
            className="w-full sm:w-auto flex items-center justify-center gap-2 px-6 py-3.5 bg-slate-900 text-white rounded-2xl shadow-xl shadow-slate-200 hover:bg-slate-800 disabled:opacity-50 transition-all text-[10px] font-black uppercase tracking-widest"
          >
            <Plus className="w-4 h-4" />
            Inject Event
          </button>
        </div>
      </div>

      {errorMsg && (
        <div className="bg-rose-50 text-rose-600 p-6 rounded-[1.5rem] border border-rose-100 font-bold text-sm shadow-sm flex items-center gap-3">
          <div className="w-2 h-2 rounded-full bg-rose-500 animate-pulse shrink-0" />
          {errorMsg}
        </div>
      )}

      <AnimatePresence>
        {showAddForm && (
          <motion.div 
            initial={{ opacity: 0, height: 0, y: -20 }}
            animate={{ opacity: 1, height: 'auto', y: 0 }}
            exit={{ opacity: 0, height: 0, y: -20 }}
            className="bg-white p-6 sm:p-8 rounded-[1.5rem] sm:rounded-[2.5rem] shadow-xl border border-indigo-50 relative overflow-hidden"
          >
            <button 
              onClick={() => setShowAddForm(false)}
              className="absolute top-6 right-6 p-2 text-slate-400 hover:text-slate-900 hover:bg-slate-50 rounded-xl transition-all"
            >
              <X className="w-5 h-5" />
            </button>
            <h2 className="text-xl font-black mb-6 text-slate-900 flex items-center gap-3 tracking-tight">
              <div className="p-2 bg-indigo-50 rounded-xl">
                <CalendarIcon className="w-5 h-5 text-indigo-500" />
              </div>
              Inject Calendar Record
            </h2>
            <form onSubmit={handleAddSubmit} className="space-y-6">
              <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
                <div>
                  <label className="block text-[10px] font-black text-slate-400 uppercase tracking-widest mb-2 ml-1">Event Date</label>
                  <input
                    type="date"
                    required
                    value={newEvent.date}
                    onChange={(e) => setNewEvent({ ...newEvent, date: e.target.value })}
                    className="w-full px-5 py-4 bg-slate-50 border border-slate-100 rounded-2xl focus:bg-white focus:ring-4 focus:ring-indigo-500/10 focus:border-indigo-500 outline-none transition-all font-black text-slate-900"
                  />
                </div>
                <div>
                  <label className="block text-[10px] font-black text-slate-400 uppercase tracking-widest mb-2 ml-1">Event Title</label>
                  <input
                    type="text"
                    required
                    placeholder="e.g., Eid-ul-Fitr"
                    value={newEvent.title}
                    onChange={(e) => setNewEvent({ ...newEvent, title: e.target.value })}
                    className="w-full px-5 py-4 bg-slate-50 border border-slate-100 rounded-2xl focus:bg-white focus:ring-4 focus:ring-indigo-500/10 focus:border-indigo-500 outline-none transition-all font-black text-slate-900 placeholder:text-slate-300"
                  />
                </div>
                <div>
                  <label className="block text-[10px] font-black text-slate-400 uppercase tracking-widest mb-2 ml-1">Event Type</label>
                  <select
                    value={newEvent.type}
                    onChange={(e) => setNewEvent({ ...newEvent, type: e.target.value })}
                    className="w-full px-5 py-4 bg-slate-50 border border-slate-100 rounded-2xl focus:bg-white focus:ring-4 focus:ring-indigo-500/10 focus:border-indigo-500 outline-none transition-all font-black text-slate-900 appearance-none cursor-pointer"
                  >
                    <option value="Holiday">Holiday</option>
                    <option value="General">General</option>
                    <option value="Exam">Exam / Academic</option>
                  </select>
                </div>
                <div>
                  <label className="block text-[10px] font-black text-slate-400 uppercase tracking-widest mb-2 ml-1">Target Track</label>
                  <select
                    value={newEvent.targetTrack || selectedTrack}
                    onChange={(e) => setNewEvent({ ...newEvent, targetTrack: e.target.value })}
                    className="w-full px-5 py-4 bg-slate-50 border border-slate-100 rounded-2xl focus:bg-white focus:ring-4 focus:ring-indigo-500/10 focus:border-indigo-500 outline-none transition-all font-black text-slate-900 appearance-none cursor-pointer"
                  >
                    <option value="tri_semester">Tri-Semester</option>
                    <option value="bi_semester">Bi-Semester (PHRM/LLB)</option>
                    <option value="both">Both Tracks</option>
                  </select>
                </div>
              </div>
              <div className="flex justify-end pt-2">
                <button
                  type="submit"
                  disabled={saving}
                  className="flex items-center gap-3 px-8 py-4 bg-indigo-600 text-white rounded-2xl hover:bg-indigo-700 disabled:opacity-50 transition-all shadow-lg shadow-indigo-100 text-[10px] font-black uppercase tracking-widest"
                >
                  {saving ? <Loader2 className="w-4 h-4 animate-spin" /> : <Save className="w-4 h-4" />}
                  {saving ? 'Synchronizing...' : 'Save Matrix Record'}
                </button>
              </div>
            </form>
          </motion.div>
        )}
      </AnimatePresence>

      {/* Events Table */}
      <div className="bg-white rounded-[1.5rem] sm:rounded-[2.5rem] border border-slate-200/60 shadow-sm overflow-hidden flex flex-col">
        <div className="overflow-x-auto custom-scrollbar">
          <table className="w-full">
            <thead className="bg-slate-50/50 border-b border-slate-100">
              <tr>
                <th className="px-6 sm:px-8 py-5 text-left text-[10px] font-black text-slate-400 uppercase tracking-widest">Date</th>
                <th className="px-6 sm:px-8 py-5 text-left text-[10px] font-black text-slate-400 uppercase tracking-widest">Event & Context</th>
                <th className="hidden sm:table-cell px-8 py-5 text-left text-[10px] font-black text-slate-400 uppercase tracking-widest">Classification</th>
                <th className="px-6 sm:px-8 py-5 text-right text-[10px] font-black text-slate-400 uppercase tracking-widest">Control</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-50">
              {loading ? (
                <tr>
                  <td colSpan={4} className="px-8 py-24 text-center">
                    <Loader2 className="w-10 h-10 animate-spin mx-auto mb-4 text-indigo-500" />
                    <p className="text-slate-400 font-bold text-[10px] uppercase tracking-widest">Scanning academic timeline...</p>
                  </td>
                </tr>
              ) : events.length === 0 ? (
                <tr>
                  <td colSpan={4} className="px-8 py-24 text-center">
                    <div className="w-20 h-20 bg-slate-50 rounded-3xl flex items-center justify-center mx-auto mb-6">
                       <CalendarIcon className="w-10 h-10 text-slate-200" />
                    </div>
                    <h3 className="text-lg font-black text-slate-900">No Records Found</h3>
                    <p className="text-slate-400 text-sm font-medium mt-2">The academic timeline for this quadrant is currently empty.</p>
                  </td>
                </tr>
              ) : (
                events.map((evt, i) => (
                  <motion.tr 
                    key={evt.id} 
                    initial={{ opacity: 0, x: -10 }}
                    animate={{ opacity: 1, x: 0 }}
                    transition={{ delay: i * 0.02 }}
                    className="hover:bg-slate-50/50 group transition-all"
                  >
                    <td className="px-6 sm:px-8 py-6">
                      <div className="text-xs sm:text-sm font-black text-slate-900 group-hover:text-indigo-600 transition-colors">
                        {formatDate(evt.event_date)}
                      </div>
                    </td>
                    <td className="px-6 sm:px-8 py-6">
                      <div className="text-sm font-black text-slate-900 group-hover:tracking-tight transition-all">{evt.title}</div>
                      <div className="text-[9px] font-black text-slate-400 uppercase tracking-widest mt-0.5">{evt.target_track}</div>
                    </td>
                    <td className="hidden sm:table-cell px-8 py-6">
                      <span className={cn(
                        "inline-flex items-center px-3 py-1 rounded-full text-[9px] font-black uppercase tracking-widest shadow-sm border",
                        evt.type?.toLowerCase().includes('holiday') 
                          ? 'bg-rose-50 text-rose-600 border-rose-100' 
                          : (evt.type?.toLowerCase().includes('exam') ? 'bg-amber-50 text-amber-600 border-amber-100' : 'bg-indigo-50 text-indigo-600 border-indigo-100')
                      )}>
                        {evt.type || 'General'}
                      </span>
                    </td>
                    <td className="px-6 sm:px-8 py-6 text-right">
                      <button
                        onClick={() => handleDelete(evt.id)}
                        className="p-3 text-slate-300 hover:text-rose-500 hover:bg-rose-50 rounded-2xl transition-all"
                        title="Delete Event"
                      >
                        <Trash2 className="w-5 h-5" />
                      </button>
                    </td>
                  </motion.tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}