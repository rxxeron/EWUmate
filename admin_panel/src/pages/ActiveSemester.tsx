import { useEffect, useState } from 'react';
import { supabase } from '../lib/supabase';
import { Calendar } from 'lucide-react';

export function ActiveSemester() {
  const [semester, setSemester] = useState('');
  const [loading, setLoading] = useState(false);
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    fetchSemester();
  }, []);

  const fetchSemester = async () => {
    setLoading(true);
    const { data } = await supabase
      .from('active_semester')
      .select('semester')
      .eq('id', 1)
      .single();
    if (data) setSemester(data.semester);
    setLoading(false);
  };

  const updateSemester = async () => {
    setSaving(true);
    await supabase.from('active_semester').upsert({ id: 1, semester });
    setSaving(false);
  };

  if (loading) return <div>Loading...</div>;

  return (
    <div className="bg-white rounded-lg shadow p-6 max-w-xl">
      <div className="flex items-center gap-2 mb-6">
        <Calendar className="w-6 h-6 text-indigo-600" />
        <h2 className="text-2xl font-bold">Active Semester Configuration</h2>
      </div>

      <div className="space-y-4">
        <div>
          <label className="block text-sm font-medium text-gray-700">Current Active Semester</label>
          <input
            type="text"
            value={semester}
            onChange={e => setSemester(e.target.value)}
            className="mt-1 block w-full p-2 border border-gray-300 rounded shadow-sm focus:border-indigo-500 text-black"
            placeholder="e.g. Spring 2026"
          />
        </div>

        <button
          onClick={updateSemester}
          disabled={saving}
          className="bg-indigo-600 text-white px-4 py-2 flex items-center justify-center rounded hover:bg-indigo-700 disabled:opacity-50"
        >
          {saving ? 'Saving...' : 'Save Changes'}
        </button>
      </div>
    </div>
  );
}
