import React, { useEffect, useState } from 'react';
import { supabase } from '../lib/supabase';
import { Calendar as CalendarIcon, Plus, Trash2, Loader2, Save, X } from 'lucide-react';
import toast from 'react-hot-toast';
import type { CalendarEvent } from '../types';



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
        // Default to tri_semester if not already selected
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
        // Table might not exist yet if not parsed
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
    } catch (err: any) {
      console.error(err);
      setErrorMsg(err.message || 'Failed to add event');
    } finally {
      setSaving(false);
    }
  };

  const handleDelete = async (id: string) => {
    // Replaced window.confirm with toast-based confirmation or simple non-blocking check
    // In a premium UI we might use a modal, but for now we'll stick to a more reliable flow
    if (!id) return;
    
    // Optimistic UI: instantly remove from array so the UI feels immediate
    const previousEvents = [...events];
    setEvents(prev => prev.filter(evt => evt.id !== id));
    
    try {
      const { error } = await supabase.from(tableName).delete().eq('id', id);
      if (error) throw error;
    } catch (err: any) {
      console.error(err);
      setEvents(previousEvents); // Rollback UI if delete fails
      toast.error('Failed to delete: ' + err.message);
    }
  };

  // Add date formatting helper
  const formatDate = (dateStr: string) => {
    if (!dateStr) return '';
    const d = new Date(dateStr);
    if (isNaN(d.getTime())) return dateStr;
    return d.toLocaleDateString(undefined, { weekday: 'short', year: 'numeric', month: 'short', day: 'numeric' });
  };

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Calendar Manager</h1>
          <p className="text-gray-500 mt-1 text-sm">
            Manually inject holidays or modify dates for <span className="font-semibold text-indigo-600">{activeSemester || 'Loading...'}</span>
          </p>
        </div>
        <div className="flex flex-col md:flex-row gap-3 items-end md:items-center">
          {tracks.length > 1 && (
            <div className="flex bg-gray-100 p-1 rounded-lg border border-gray-200">
              {tracks.map(t => (
                <button
                  key={t.track}
                  onClick={() => setSelectedTrack(t.track)}
                  className={`px-3 py-1.5 text-xs font-bold rounded-md transition-all ${
                    selectedTrack === t.track 
                      ? 'bg-white text-indigo-600 shadow-sm' 
                      : 'text-gray-500 hover:text-gray-700'
                  }`}
                >
                  {t.track.replace('_', ' ').toUpperCase()}
                </button>
              ))}
            </div>
          )}
          <button
            onClick={() => setShowAddForm(true)}
            disabled={!tableName || !!errorMsg}
            className="flex items-center gap-2 px-4 py-2 bg-indigo-600 text-white rounded-lg shadow-sm hover:bg-indigo-700 disabled:opacity-50 transition-colors"
          >
            <Plus className="w-4 h-4" />
            Add Holiday / Event
          </button>
        </div>
      </div>

      {errorMsg && (
        <div className="bg-red-50 text-red-600 p-4 rounded-lg border border-red-200">
          {errorMsg}
        </div>
      )}

      {showAddForm && (
        <div className="bg-white p-6 rounded-xl shadow-sm border border-indigo-100 relative">
          <button 
            onClick={() => setShowAddForm(false)}
            className="absolute top-4 right-4 text-gray-400 hover:text-gray-600"
          >
            <X className="w-5 h-5" />
          </button>
          <h2 className="text-lg font-semibold mb-4 text-gray-800 flex items-center gap-2">
            <CalendarIcon className="w-5 h-5 text-indigo-500" />
            Inject Calendar Record
          </h2>
          <form onSubmit={handleAddSubmit} className="space-y-4">
            <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Event Date</label>
                <input
                  type="date"
                  required
                  value={newEvent.date}
                  onChange={(e) => setNewEvent({ ...newEvent, date: e.target.value })}
                  className="w-full rounded-lg border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 text-sm"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Event Title</label>
                <input
                  type="text"
                  required
                  placeholder="e.g., Eid-ul-Fitr"
                  value={newEvent.title}
                  onChange={(e) => setNewEvent({ ...newEvent, title: e.target.value })}
                  className="w-full rounded-lg border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 text-sm"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Event Type</label>
                <select
                  value={newEvent.type}
                  onChange={(e) => setNewEvent({ ...newEvent, type: e.target.value })}
                  className="w-full rounded-lg border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 text-sm"
                >
                  <option value="Holiday">Holiday</option>
                  <option value="General">General</option>
                  <option value="Exam">Exam / Academic</option>
                </select>
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Target Track</label>
                <select
                  value={newEvent.targetTrack || selectedTrack}
                  onChange={(e) => setNewEvent({ ...newEvent, targetTrack: e.target.value })}
                  className="w-full rounded-lg border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 text-sm"
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
                className="flex items-center gap-2 px-4 py-2 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700 disabled:opacity-50"
              >
                {saving ? <Loader2 className="w-4 h-4 animate-spin" /> : <Save className="w-4 h-4" />}
                {saving ? 'Saving...' : 'Save to Calendar'}
              </button>
            </div>
          </form>
        </div>
      )}

      <div className="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden">
        <table className="min-w-full divide-y divide-gray-200">
          <thead className="bg-gray-50">
            <tr>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider w-32">Date</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Event Name & Details</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider w-24">Type</th>
              <th className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider w-24">Actions</th>
            </tr>
          </thead>
          <tbody className="bg-white divide-y divide-gray-200">
            {loading ? (
              <tr>
                <td colSpan={4} className="px-6 py-12 text-center text-gray-500">
                  <Loader2 className="w-6 h-6 animate-spin mx-auto mb-2 text-indigo-500" />
                  Loading calendar events...
                </td>
              </tr>
            ) : events.length === 0 ? (
              <tr>
                <td colSpan={4} className="px-6 py-12 text-center text-gray-500">
                  No records found in {tableName}.
                </td>
              </tr>
            ) : (
              events.map((evt) => (
                <tr key={evt.id} className="hover:bg-gray-50">
                  <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900 border-l-2 border-transparent hover:border-indigo-400">
                    {formatDate(evt.event_date)}
                  </td>
                  <td className="px-6 py-4">
                    <div className="text-sm text-gray-900 font-semibold">{evt.title}</div>
                    <div className="text-xs text-gray-500">{evt.target_track}</div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <span className={`inline-flex items-center px-2 py-0.5 rounded text-xs font-medium ${
                      evt.type?.toLowerCase().includes('holiday') 
                        ? 'bg-red-100 text-red-800' 
                        : (evt.type?.toLowerCase().includes('exam') ? 'bg-orange-100 text-orange-800' : 'bg-blue-100 text-blue-800')
                    }`}>
                      {evt.type || 'General'}
                    </span>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                    <button
                      onClick={() => handleDelete(evt.id)}
                      className="text-red-500 hover:text-red-700 bg-red-50 hover:bg-red-100 p-1.5 rounded-md transition-colors"
                      title="Delete Event"
                    >
                      <Trash2 className="w-4 h-4" />
                    </button>
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}