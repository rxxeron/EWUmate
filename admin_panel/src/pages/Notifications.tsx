import { useState, useEffect } from 'react';
import { supabase } from '../lib/supabase';
import { Send, Link as LinkIcon, Clock, Building, Target } from 'lucide-react'; 

export function Notifications() {
  const [title, setTitle] = useState('');
  const [message, setMessage] = useState('');
  const [url, setUrl] = useState('');
  const [targetUserId, setTargetUserId] = useState('');
  const [targetDepartment, setTargetDepartment] = useState('');
  const [scheduledAt, setScheduledAt] = useState('');
  const [departments, setDepartments] = useState<string[]>([]);

  const [loading, setLoading] = useState(false);
  const [success, setSuccess] = useState('');

  useEffect(() => {
    async function fetchDepartments() {
      const { data, error } = await supabase
        .from('programs')
        .select('department_name');
        
      if (data && !error) {
        // Filter out empty descriptions and keep unique departments
        const unique = Array.from(new Set(data.map(d => d.department_name).filter(Boolean)));
        // Sort alphabetically
        unique.sort((a, b) => a.localeCompare(b));
        setDepartments(unique);
      }
    }
    fetchDepartments();
  }, []);

  const sendNotification = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setSuccess('');

    try {
      let utcIsoString = undefined;
      
      if (scheduledAt) {
         // Force parse the local browser input as implicitly BDT (+06:00)
         const bdtDate = new Date(scheduledAt + '+06:00');
         utcIsoString = bdtDate.toISOString();
      }

      const payload = {
        title,
        body: message,
        link: url || undefined,
        targetUserId: targetUserId || undefined,
        targetDepartment: targetDepartment || undefined,
        scheduledAt: utcIsoString
      };

      // Call the newly updated broadcast edge function
      const { error } = await supabase.functions.invoke('broadcast', {
        body: payload
      });

      if (error) throw error;

      setSuccess('Notice sent/scheduled successfully!');
      setTitle('');
      setMessage('');
      setUrl('');
      setTargetUserId('');
      setTargetDepartment('');
      setScheduledAt('');

    } catch (err: any) {
      alert("Failed to send notification: " + err.message);
    }

    setLoading(false);
  };

  return (
    <div className="bg-white rounded-lg shadow p-6 max-w-3xl">
      <div className="flex items-center gap-2 mb-6">
        <Send className="w-6 h-6 text-indigo-600" />
        <h2 className="text-2xl font-bold text-gray-800">Advanced Notification Broadcast</h2>
      </div>

      {success && <div className="mb-6 p-4 bg-emerald-100 text-emerald-800 rounded border border-emerald-200">{success}</div>}

      <form onSubmit={sendNotification} className="space-y-6">
        {/* Core Content */}
        <div className="space-y-4">
          <h3 className="text-lg font-semibold border-b pb-2">1. Alert Content</h3>
          <div>
            <label className="block text-sm font-medium text-gray-700">Notification Title</label>
            <input
              type="text"
              required
              value={title}
              onChange={e => setTitle(e.target.value)}
              className="mt-1 block w-full p-2 border border-gray-300 rounded shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
              placeholder="e.g. Schedule Update"
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700">Message / Body</label>
            <textarea
              required
              rows={3}
              value={message}
              onChange={e => setMessage(e.target.value)}
              className="mt-1 block w-full p-2 border border-gray-300 rounded shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
              placeholder="Enter the alert text here..."
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 flex items-center gap-2">
              <LinkIcon className="w-4 h-4" /> Destination Link (Optional)
            </label>
            <input
              type="url"
              value={url}
              onChange={e => setUrl(e.target.value)}
              className="mt-1 block w-full p-2 border border-gray-300 rounded shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
              placeholder="e.g. https://ewumate.app/updates"
            />
          </div>
        </div>

        {/* Targeting & Scheduling */}
        <div className="space-y-4 border-t pt-4">
          <h3 className="text-lg font-semibold border-b pb-2">2. Targeting & Timing (Optional)</h3>
          
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 flex items-center gap-2">
                <Building className="w-4 h-4" /> Specific Department
              </label>
              <select
                value={targetDepartment}
                onChange={e => setTargetDepartment(e.target.value)}
                className="mt-1 block w-full p-2 border border-gray-300 rounded shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
              >
                <option value="">All Departments (Global Broadcast)</option>
                {departments.map((dept) => (
                  <option key={dept} value={dept}>
                    {dept}
                  </option>
                ))}
              </select>
              <p className="text-xs text-gray-500 mt-1">Leave as "All Departments" to broadcast to everyone.</p>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 flex items-center gap-2">
                <Target className="w-4 h-4" /> Specific User ID (UUID)
              </label>
              <input
                type="text"
                value={targetUserId}
                onChange={e => setTargetUserId(e.target.value)}
                className="mt-1 block w-full p-2 border border-gray-300 rounded shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                placeholder="00000000-0000-0000-0000-000000000000"
              />
              <p className="text-xs text-gray-500 mt-1">Leave blank to broadcast exactly to the department above.</p>
            </div>

            <div className="md:col-span-2">
              <label className="block text-sm font-medium text-gray-700 flex items-center gap-2">
                <Clock className="w-4 h-4" /> Schedule Deployment (BDT)
              </label>
              <input
                type="datetime-local"
                value={scheduledAt}
                onChange={e => setScheduledAt(e.target.value)}
                className="mt-1 block p-2 border border-gray-300 rounded shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
              />
              <p className="text-xs text-emerald-600 mt-1 font-medium bg-emerald-50 inline-block p-1 rounded">
                Pick a time in local Bangladesh Time (BDT). It automatically converts to strict UTC for database integrity.
              </p>
            </div>
          </div>
        </div>

        <button
          type="submit"
          disabled={loading}
          className="w-full bg-indigo-600 text-white px-4 py-3 font-semibold flex items-center justify-center rounded-lg hover:bg-indigo-700 disabled:opacity-50 transition-all shadow-md mt-6"
        >
          {loading ? 'Processing Instructions...' : 'Deploy Global Payload'}
        </button>
      </form>
    </div>
  );
}
