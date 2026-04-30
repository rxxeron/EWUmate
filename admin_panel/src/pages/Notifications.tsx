import { useState, useEffect } from 'react';
import { supabase } from '../lib/supabase';
import { Send, Link as LinkIcon, Clock, Building, Target, BookmarkPlus, History, Copy, BellRing, Users } from 'lucide-react'; 
import toast from 'react-hot-toast';
import type { Notification, NotificationTemplate } from '../types';

const TEMPLATES_KEY = 'ewumate_notification_templates';

function loadTemplates(): NotificationTemplate[] {
  try {
    return JSON.parse(localStorage.getItem(TEMPLATES_KEY) || '[]');
  } catch {
    return [];
  }
}

function saveTemplates(templates: NotificationTemplate[]) {
  localStorage.setItem(TEMPLATES_KEY, JSON.stringify(templates));
}

export function Notifications() {
  const [activeTab, setActiveTab] = useState<'global' | 'department' | 'user'>('global');
  
  const [title, setTitle] = useState('');
  const [message, setMessage] = useState('');
  const [url, setUrl] = useState('');
  const [targetUserId, setTargetUserId] = useState('');
  const [targetDepartment, setTargetDepartment] = useState('');
  const [scheduledAt, setScheduledAt] = useState('');
  const [departments, setDepartments] = useState<string[]>([]);

  const [loading, setLoading] = useState(false);

  // Templates & History state
  const [templates, setTemplates] = useState<NotificationTemplate[]>(loadTemplates());
  const [templateName, setTemplateName] = useState('');
  const [showTemplates, setShowTemplates] = useState(false);
  const [history, setHistory] = useState<Notification[]>([]);
  const [historyLoading, setHistoryLoading] = useState(false);
  const [showHistory, setShowHistory] = useState(false);

  useEffect(() => {
    async function fetchDepartments() {
      const { data, error } = await supabase.from('programs').select('department_name');
      if (data && !error) {
        const unique = Array.from(new Set(data.map(d => d.department_name).filter(Boolean))) as string[];
        unique.sort((a, b) => a.localeCompare(b));
        setDepartments(unique);
      }
    }
    fetchDepartments();
  }, []);

  const resetForm = () => {
    setTitle('');
    setMessage('');
    setUrl('');
    setTargetUserId('');
    setTargetDepartment('');
    setScheduledAt('');
  };

  const sendNotification = async (mode: 'global' | 'department' | 'user') => {
    if (!title || !message) {
      toast.error('Title and message are required');
      return;
    }

    setLoading(true);
    try {
      let utcIsoString = undefined;
      if (scheduledAt) {
         const bdtDate = new Date(scheduledAt + '+06:00');
         utcIsoString = bdtDate.toISOString();
      }

      const payload: any = {
        title,
        body: message,
        link: url || undefined,
        scheduledAt: utcIsoString
      };

      if (mode === 'user') {
        if (!targetUserId) throw new Error('User UUID is required for User Specific notifications');
        payload.targetUserId = targetUserId.trim();
      } else if (mode === 'department') {
        if (!targetDepartment) throw new Error('Department selection is required');
        payload.targetDepartment = targetDepartment;
      }
      // Global doesn't need extra keys

      // Manual fetch with ANON key to bypass ES256 algorithm mismatch issue
      const response = await fetch(`${import.meta.env.VITE_SUPABASE_URL}/functions/v1/broadcast`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${import.meta.env.VITE_SUPABASE_ANON_KEY}`,
          'apikey': import.meta.env.VITE_SUPABASE_ANON_KEY
        },
        body: JSON.stringify(payload)
      });

      if (!response.ok) {
        let errorMsg = `Error ${response.status}`;
        try {
          const body = await response.json();
          if (body.error) errorMsg = body.error;
        } catch (e) {
          const text = await response.text();
          if (text) errorMsg = text;
        }
        throw new Error(errorMsg);
      }

      toast.success('Notification deployed successfully!');
      resetForm();
      if (showHistory) fetchHistory();
    } catch (err: any) {
      toast.error(err.message || 'Deployment failed');
    } finally {
      setLoading(false);
    }
  };

  const fetchHistory = async () => {
    setHistoryLoading(true);
    try {
      const { data, error } = await supabase
        .from('notifications')
        .select('*')
        .order('trigger_at', { ascending: false })
        .limit(100);
      
      if (error) throw error;

      // De-duplicate broadcasts by alert_key
      const seenKeys = new Set<string>();
      const unique: Notification[] = [];
      
      (data || []).forEach((n: any) => {
        if (n.alert_key) {
          const baseKey = n.alert_key.split('_')[0]; 
          if (!seenKeys.has(baseKey)) {
            seenKeys.add(baseKey);
            unique.push(n);
          }
        } else {
          unique.push(n);
        }
      });

      setHistory(unique.slice(0, 30));
    } catch (err) {
      console.error(err);
    } finally {
      setHistoryLoading(false);
    }
  };

  const handleSaveTemplate = () => {
    if (!title || !message) {
      toast.error('Fill in title and message before saving template');
      return;
    }
    const name = templateName.trim() || `Template ${templates.length + 1}`;
    const newTemplate: NotificationTemplate = {
      id: Date.now().toString(),
      name,
      title,
      body: message,
      url,
      targetDepartment,
      createdAt: new Date().toISOString()
    };
    const updated = [...templates, newTemplate];
    setTemplates(updated);
    saveTemplates(updated);
    setTemplateName('');
    toast.success(`Template "${name}" saved`);
  };

  const handleLoadTemplate = (t: NotificationTemplate) => {
    setTitle(t.title);
    setMessage(t.body);
    setUrl(t.url);
    setTargetDepartment(t.targetDepartment);
    toast.success(`Loaded: ${t.name}`);
  };

  return (
    <div className="max-w-4xl space-y-8 pb-12">
      <div className="flex flex-col gap-2">
        <h2 className="text-3xl font-extrabold text-gray-900 tracking-tight flex items-center gap-3">
          <BellRing className="w-8 h-8 text-indigo-600" />
          Notification Control Center
        </h2>
        <p className="text-gray-500">Deploy alerts, announcements, and personalized messages to the student base.</p>
      </div>

      {/* Target Mode Selector */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        {[
          { id: 'global', label: 'Global Broadcast', icon: Target, color: 'bg-indigo-600', sub: 'To All Active Users' },
          { id: 'department', label: 'Department Wise', icon: Building, color: 'bg-amber-600', sub: 'By Academic Dept' },
          { id: 'user', label: 'User Specific', icon: Users, color: 'bg-rose-600', sub: 'Individual UUID' },
        ].map((tab) => (
          <button
            key={tab.id}
            onClick={() => { setActiveTab(tab.id as any); resetForm(); }}
            className={`p-5 rounded-2xl border-2 text-left transition-all relative overflow-hidden group ${
              activeTab === tab.id 
              ? `border-transparent ring-2 ring-offset-2 ${tab.id === 'global' ? 'ring-indigo-500' : tab.id === 'department' ? 'ring-amber-500' : 'ring-rose-500'}` 
              : 'border-gray-200 bg-white hover:border-gray-300'
            }`}
          >
            {activeTab === tab.id && (
              <div className={`absolute inset-0 opacity-10 ${tab.color}`} />
            )}
            <tab.icon className={`w-8 h-8 mb-3 transition-colors ${activeTab === tab.id ? (tab.id === 'global' ? 'text-indigo-600' : tab.id === 'department' ? 'text-amber-600' : 'text-rose-600') : 'text-gray-400 group-hover:text-gray-600'}`} />
            <p className={`font-bold block ${activeTab === tab.id ? 'text-gray-900' : 'text-gray-500'}`}>{tab.label}</p>
            <p className="text-xs text-gray-400 font-medium">{tab.sub}</p>
          </button>
        ))}
      </div>

      {/* Dynamic Form Area */}
      <div className="bg-white rounded-3xl shadow-xl shadow-indigo-100/50 border border-indigo-50 overflow-hidden transition-all">
        <div className={`h-1.5 w-full ${activeTab === 'global' ? 'bg-indigo-600' : activeTab === 'department' ? 'bg-amber-600' : 'bg-rose-600'}`} />
        <div className="p-8">
          <div className="flex justify-between items-center mb-8">
            <h3 className="text-xl font-bold text-gray-900">
              {activeTab === 'global' && '🌍 Global Announcement'}
              {activeTab === 'department' && '🏢 Departmental Circular'}
              {activeTab === 'user' && '👤 Direct Personal Message'}
            </h3>
            <div className="flex gap-2">
              <button onClick={() => setShowTemplates(!showTemplates)} className="text-xs font-bold text-indigo-600 hover:bg-indigo-50 px-3 py-1.5 rounded-lg transition-colors">
                {showTemplates ? 'CLOSE TEMPLATES' : 'USE TEMPLATE'}
              </button>
            </div>
          </div>

          {showTemplates && (
            <div className="mb-8 p-6 bg-gray-50 rounded-2xl border-2 border-dashed border-gray-200 animate-in fade-in slide-in-from-top-4">
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                {templates.map(t => (
                  <button 
                    key={t.id} 
                    onClick={() => handleLoadTemplate(t)}
                    className="p-3 bg-white border border-gray-200 rounded-xl text-left hover:border-indigo-400 hover:shadow-sm transition-all"
                  >
                    <p className="font-bold text-gray-800 text-sm truncate">{t.name}</p>
                    <p className="text-xs text-gray-500 truncate">{t.title}</p>
                  </button>
                ))}
              </div>
              {templates.length === 0 && <p className="text-center text-gray-400 text-sm italic py-4">No saved templates</p>}
            </div>
          )}

          <div className="space-y-6">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div className="md:col-span-2">
                <label className="block text-xs font-bold text-gray-400 uppercase tracking-widest mb-2">Notification Title</label>
                <input
                  type="text"
                  value={title}
                  onChange={e => setTitle(e.target.value)}
                  className="w-full border-gray-200 rounded-xl bg-gray-50 p-4 text-sm focus:ring-2 focus:ring-indigo-500 transition-all font-semibold"
                  placeholder="e.g. System Maintenance"
                />
              </div>

              <div className="md:col-span-2">
                <label className="block text-xs font-bold text-gray-400 uppercase tracking-widest mb-2">Message Content</label>
                <textarea
                  rows={4}
                  value={message}
                  onChange={e => setMessage(e.target.value)}
                  className="w-full border-gray-200 rounded-xl bg-gray-50 p-4 text-sm focus:ring-2 focus:ring-indigo-500 transition-all"
                  placeholder="Write your message here..."
                />
              </div>

              <div>
                <label className="block text-xs font-bold text-gray-400 uppercase tracking-widest mb-2">Attached Link (URL)</label>
                <div className="relative">
                  <LinkIcon className="absolute left-4 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
                  <input
                    type="url"
                    value={url}
                    onChange={e => setUrl(e.target.value)}
                    className="w-full border-gray-200 rounded-xl bg-gray-50 p-4 pl-12 text-sm focus:ring-2 focus:ring-indigo-500 transition-all"
                    placeholder="https://ewumate.app/..."
                  />
                </div>
              </div>

              <div>
                <label className="block text-xs font-bold text-gray-400 uppercase tracking-widest mb-2">Schedule Deployment (Optional)</label>
                <div className="relative">
                  <Clock className="absolute left-4 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
                  <input
                    type="datetime-local"
                    value={scheduledAt}
                    onChange={e => setScheduledAt(e.target.value)}
                    className="w-full border-gray-200 rounded-xl bg-gray-50 p-4 pl-12 text-sm focus:ring-2 focus:ring-indigo-500 transition-all"
                  />
                </div>
              </div>

              {activeTab === 'department' && (
                <div className="md:col-span-2 animate-in fade-in slide-in-from-left-4">
                  <label className="block text-xs font-bold text-gray-400 uppercase tracking-widest mb-2">Target Department</label>
                  <select
                    value={targetDepartment}
                    onChange={e => setTargetDepartment(e.target.value)}
                    className="w-full border-gray-200 rounded-xl bg-amber-50 p-4 text-sm font-bold focus:ring-2 focus:ring-amber-500 transition-all"
                  >
                    <option value="">Select Department...</option>
                    {departments.map(d => <option key={d} value={d}>{d}</option>)}
                  </select>
                </div>
              )}

              {activeTab === 'user' && (
                <div className="md:col-span-2 animate-in fade-in slide-in-from-left-4">
                  <label className="block text-xs font-bold text-gray-400 uppercase tracking-widest mb-2">Target User UUID</label>
                  <input
                    type="text"
                    value={targetUserId}
                    onChange={e => setTargetUserId(e.target.value)}
                    className="w-full border-gray-200 rounded-xl bg-rose-50 p-4 text-sm font-mono focus:ring-2 focus:ring-rose-500 transition-all"
                    placeholder="00000000-0000-0000-0000-000000000000"
                  />
                </div>
              )}
            </div>

            <div className="flex gap-4 pt-4">
              <button
                onClick={() => sendNotification(activeTab)}
                disabled={loading}
                className={`flex-1 p-4 rounded-2xl text-white font-bold text-lg shadow-lg transition-all flex items-center justify-center gap-3 disabled:opacity-50 ${
                  activeTab === 'global' ? 'bg-indigo-600 hover:bg-indigo-700 shadow-indigo-200' :
                  activeTab === 'department' ? 'bg-amber-600 hover:bg-amber-700 shadow-amber-200' :
                  'bg-rose-600 hover:bg-rose-700 shadow-rose-200'
                }`}
              >
                <Send className="w-5 h-5" />
                {loading ? 'Processing...' : `Deploy ${activeTab === 'global' ? 'Global' : activeTab === 'department' ? 'Dept' : 'Direct'} Alert`}
              </button>
              <button
                onClick={handleSaveTemplate}
                className="bg-gray-100 text-gray-600 p-4 rounded-2xl hover:bg-gray-200 transition-colors"
                title="Save as Template"
              >
                <BookmarkPlus className="w-6 h-6" />
              </button>
            </div>
          </div>
        </div>
      </div>

      {/* History Section */}
      <div className="bg-white rounded-3xl border border-gray-200 overflow-hidden">
        <button
          onClick={() => { setShowHistory(!showHistory); if (!showHistory) fetchHistory(); }}
          className="w-full p-6 flex items-center justify-between hover:bg-gray-50 transition-colors"
        >
          <div className="flex items-center gap-3">
            <div className="p-2 bg-indigo-50 rounded-lg text-indigo-600">
              <History className="w-5 h-5" />
            </div>
            <h3 className="text-lg font-bold text-gray-900">Deployment History</h3>
          </div>
          <span className={`text-gray-400 transition-transform ${showHistory ? 'rotate-180' : ''}`}>▼</span>
        </button>

        {showHistory && (
          <div className="border-t border-gray-100 animate-in fade-in slide-in-from-top-2">
            <div className="divide-y divide-gray-100">
              {historyLoading ? (
                <div className="p-12 text-center text-gray-400 italic">Fetching records...</div>
              ) : history.length === 0 ? (
                <div className="p-12 text-center text-gray-400 italic">No recent deployments found.</div>
              ) : (
                history.map(n => (
                  <div key={n.id} className="p-6 flex items-start justify-between group hover:bg-slate-50/50 transition-colors">
                    <div className="flex-1">
                      <div className="flex items-center gap-2 mb-1">
                        <div className={`w-2 h-2 rounded-full ${n.is_dispatched ? 'bg-emerald-500' : 'bg-amber-500'}`} />
                        <span className="font-bold text-gray-900">{n.title}</span>
                      </div>
                      <p className="text-sm text-gray-500 line-clamp-1">{n.body}</p>
                      <div className="flex items-center gap-3 mt-2">
                        <span className="text-[10px] font-bold text-gray-400 uppercase tracking-widest">
                          {new Date(n.trigger_at).toLocaleString()}
                        </span>
                        {n.alert_key?.startsWith('bcast_') ? (
                          <span className="bg-indigo-100 text-indigo-700 text-[8px] px-1.5 py-0.5 rounded font-bold uppercase">Broadcast</span>
                        ) : n.alert_key?.startsWith('dept_') ? (
                          <span className="bg-amber-100 text-amber-700 text-[8px] px-1.5 py-0.5 rounded font-bold uppercase">Dept: {n.alert_key.split('_')[1]}</span>
                        ) : (
                          <span className="bg-rose-100 text-rose-700 text-[8px] px-1.5 py-0.5 rounded font-bold uppercase">Direct: {n.user_id?.substring(0, 8)}...</span>
                        )}
                      </div>
                    </div>
                    <button 
                      onClick={() => { 
                        setTitle(n.title); 
                        setMessage(n.body); 
                        setUrl((n.payload as any)?.url || ''); 
                        if (n.alert_key?.startsWith('bcast_')) setActiveTab('global');
                        else if (n.alert_key?.startsWith('dept_')) {
                          setActiveTab('department');
                          setTargetDepartment(n.alert_key.split('_')[1]);
                        } else {
                          setActiveTab('user');
                          setTargetUserId(n.user_id);
                        }
                        window.scrollTo({ top: 0, behavior: 'smooth' }); 
                      }}
                      className="p-2 text-indigo-400 opacity-0 group-hover:opacity-100 transition-opacity hover:bg-indigo-50 rounded-lg"
                    >
                      <Copy className="w-5 h-5" />
                    </button>
                  </div>
                ))
              )}
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
