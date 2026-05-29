import { useState, useEffect } from 'react';
import { supabase, serviceRoleKey } from '../lib/supabase';
import { cn } from '../lib/utils';
import { RefreshCw, Send, Link as LinkIcon, Clock, Building, Target, BookmarkPlus, History, Copy, BellRing, Users, ShieldCheck, Package } from 'lucide-react'; 
import toast from 'react-hot-toast';
import type { NotificationTemplate } from '../types';

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
  const [activeTab, setActiveTab] = useState<'global' | 'department' | 'user' | 'status' | 'version'>('global');
  
  const [title, setTitle] = useState('');
  const [message, setMessage] = useState('');
  const [url, setUrl] = useState('');
  const [targetUserId, setTargetUserId] = useState('');
  const [targetDepartment, setTargetDepartment] = useState('');
  const [targetStatus, setTargetStatus] = useState('');
  const [targetVersion, setTargetVersion] = useState('');
  const [scheduledAt, setScheduledAt] = useState('');
  const [departments, setDepartments] = useState<string[]>([]);
  const [availableVersions, setAvailableVersions] = useState<string[]>([]);
  const [statuses] = useState<string[]>(['registered', 'course_history', 'completed']);

  const [loading, setLoading] = useState(false);

  // Templates & History state
  const [templates, setTemplates] = useState<NotificationTemplate[]>(loadTemplates());
  const [templateName, setTemplateName] = useState('');
  const [showTemplates, setShowTemplates] = useState(false);
  const [history, setHistory] = useState<any[]>([]);
  const [historyLoading, setHistoryLoading] = useState(false);

  useEffect(() => {
    async function fetchDepartments() {
      const { data, error } = await supabase.from('programs').select('department_name');
      if (data && !error) {
        const unique = Array.from(new Set(data.map(d => d.department_name).filter(Boolean))) as string[];
        unique.sort((a, b) => a.localeCompare(b));
        setDepartments(unique);
      }
    }
    async function fetchVersions() {
      const { data, error } = await supabase.from('profiles').select('app_version').not('app_version', 'is', null);
      if (data && !error) {
        const unique = Array.from(new Set(data.map(d => d.app_version).filter(Boolean))) as string[];
        unique.sort((a, b) => b.localeCompare(a)); 
        setAvailableVersions(unique);
      }
    }
    fetchDepartments();
    fetchVersions();
    fetchHistory();
  }, []);

  const resetForm = () => {
    setTitle('');
    setMessage('');
    setUrl('');
    setTargetUserId('');
    setTargetDepartment('');
    setTargetStatus('');
    setTargetVersion('');
    setScheduledAt('');
  };

  const sendNotification = async (mode: 'global' | 'department' | 'user' | 'status' | 'version') => {
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
        if (!targetUserId) throw new Error('User UUID is required');
        payload.targetUserId = targetUserId.trim();
      } else if (mode === 'department') {
        if (!targetDepartment) throw new Error('Department is required');
        payload.targetDepartment = targetDepartment;
      } else if (mode === 'status') {
        if (!targetStatus) throw new Error('Status is required');
        payload.targetStatus = targetStatus;
      } else if (mode === 'version') {
        if (!targetVersion) throw new Error('Version is required');
        payload.targetVersion = targetVersion;
      }

      const response = await fetch(`${import.meta.env.VITE_SUPABASE_URL}/functions/v1/broadcast`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${serviceRoleKey}`,
          'apikey': serviceRoleKey
        },
        body: JSON.stringify(payload)
      });

      if (!response.ok) {
        const body = await response.json();
        throw new Error(body.error || 'Deployment failed');
      }

      toast.success('Notification deployed successfully!');
      resetForm();
      fetchHistory();
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
        .not('alert_key', 'ilike', 'c_%') 
        .order('created_at', { ascending: false })
        .limit(200);
      
      if (error) throw error;

      const groupedHistory: Record<string, any> = {};
      
      (data || []).forEach((n: any) => {
        let groupKey = n.id; 
        if (n.alert_key) {
          const parts = n.alert_key.split('_');
          groupKey = parts.length >= 2 ? `${parts[0]}_${parts[1]}` : n.alert_key;
        }
        
        if (!groupedHistory[groupKey]) {
          groupedHistory[groupKey] = {
            ...n,
            stats: { success: 0, failed: 0 }
          };
        }
        
        if (n.is_dispatched) {
          groupedHistory[groupKey].stats.success++;
        } else {
          groupedHistory[groupKey].stats.failed++;
        }
      });

      setHistory(Object.values(groupedHistory).sort((a, b) => 
        new Date(b.created_at).getTime() - new Date(a.created_at).getTime()
      ).slice(0, 50));
    } catch (err) {
      console.error(err);
    } finally {
      setHistoryLoading(false);
    }
  };

  const handleSaveTemplate = () => {
    if (!title || !message) {
      toast.error('Fill in title and message');
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
    toast.success(`Template saved`);
  };

  const handleLoadTemplate = (t: NotificationTemplate) => {
    setTitle(t.title);
    setMessage(t.body);
    setUrl(t.url);
    setTargetDepartment(t.targetDepartment);
    toast.success(`Loaded: ${t.name}`);
  };

  return (
    <div className="w-full flex flex-col lg:flex-row gap-8 pb-12 animate-in fade-in duration-500">
      <div className="flex-1 space-y-8">
        <div className="flex flex-col gap-2">
          <h2 className="text-3xl font-extrabold text-gray-900 dark:text-white tracking-tight flex items-center gap-3">
            <BellRing className="w-8 h-8 text-indigo-600 dark:text-indigo-400" />
            Notification Control Center
          </h2>
          <p className="text-gray-500 dark:text-slate-400">Deploy alerts, announcements, and personalized messages to students.</p>
        </div>

        {/* Target Mode Selector */}
        <div className="grid grid-cols-1 md:grid-cols-3 lg:grid-cols-5 gap-3">
          {[
            { id: 'global', label: 'Global', icon: Target, color: 'bg-indigo-600', sub: 'All Users' },
            { id: 'department', label: 'Dept', icon: Building, color: 'bg-amber-600', sub: 'By Dept' },
            { id: 'status', label: 'Status', icon: ShieldCheck, color: 'bg-emerald-600', sub: 'Onboarding' },
            { id: 'version', label: 'Version', icon: Package, color: 'bg-blue-600', sub: 'App Version' },
            { id: 'user', label: 'Personal', icon: Users, color: 'bg-rose-600', sub: 'Direct UUID' },
          ].map((tab) => (
            <button
              key={tab.id}
              onClick={() => setActiveTab(tab.id as any)}
              className={`p-4 rounded-2xl border-2 text-left transition-all relative overflow-hidden group ${
                activeTab === tab.id 
                ? `border-transparent ring-2 ring-offset-2 bg-white dark:bg-slate-800 ring-indigo-500` 
                : 'border-gray-200 dark:border-white/10 bg-white dark:bg-slate-800 hover:border-gray-300 dark:hover:border-white/20'
              }`}
            >
              {activeTab === tab.id && (
                <div className={`absolute inset-0 opacity-10 dark:opacity-20 ${tab.color}`} />
              )}
              <tab.icon className={`w-6 h-6 mb-2 transition-colors ${activeTab === tab.id ? 'text-indigo-600' : 'text-gray-400 dark:text-slate-500'}`} />
              <p className={`font-bold text-sm block ${activeTab === tab.id ? 'text-gray-900 dark:text-white' : 'text-gray-500 dark:text-slate-400'}`}>{tab.label}</p>
              <p className="text-[10px] text-gray-400 dark:text-slate-500 font-medium">{tab.sub}</p>
            </button>
          ))}
        </div>

        {/* Dynamic Form Area */}
        <div className="bg-white dark:bg-slate-800 rounded-3xl shadow-xl shadow-indigo-100/50 dark:shadow-none border border-indigo-50 dark:border-white/5 overflow-hidden transition-all">
          <div className={`h-1.5 w-full ${activeTab === 'global' ? 'bg-indigo-600' : activeTab === 'department' ? 'bg-amber-600' : activeTab === 'status' ? 'bg-emerald-600' : activeTab === 'version' ? 'bg-blue-600' : 'bg-rose-600'}`} />
          <div className="p-8">
            <div className="flex justify-between items-center mb-8">
              <h3 className="text-xl font-bold text-gray-900 dark:text-white">
                {activeTab === 'global' && '🌍 Global Announcement'}
                {activeTab === 'department' && '🏢 Departmental Circular'}
                {activeTab === 'status' && '🛡️ Status Targeted Alert'}
                {activeTab === 'version' && '📦 Version Specific Deployment'}
                {activeTab === 'user' && '👤 Direct Personal Message'}
              </h3>
              <button onClick={() => setShowTemplates(!showTemplates)} className="text-xs font-bold text-indigo-600 dark:text-indigo-400 hover:bg-indigo-50 dark:hover:bg-white/5 px-3 py-1.5 rounded-lg transition-colors">
                {showTemplates ? 'CLOSE TEMPLATES' : 'USE TEMPLATE'}
              </button>
            </div>

            {showTemplates && (
              <div className="mb-8 p-6 bg-gray-50 dark:bg-slate-900 rounded-2xl border-2 border-dashed border-gray-200 dark:border-white/10">
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                  {templates.map(t => (
                    <button key={t.id} onClick={() => handleLoadTemplate(t)} className="p-3 bg-white dark:bg-slate-800 border border-gray-200 dark:border-white/10 rounded-xl text-left hover:border-indigo-400 transition-all">
                      <p className="font-bold text-gray-800 dark:text-slate-200 text-sm truncate">{t.name}</p>
                      <p className="text-xs text-gray-500 dark:text-slate-500 truncate">{t.title}</p>
                    </button>
                  ))}
                </div>
                {templates.length === 0 && <p className="text-center text-gray-400 text-sm italic py-4">No templates</p>}
              </div>
            )}

            <div className="space-y-6">
              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div className="md:col-span-2">
                  <label className="block text-xs font-bold text-gray-400 uppercase tracking-widest mb-2">Notification Title</label>
                  <input type="text" value={title} onChange={e => setTitle(e.target.value)} className="w-full border-gray-200 dark:border-white/10 rounded-xl bg-gray-50 dark:bg-slate-900 p-4 text-sm font-semibold text-slate-900 dark:text-white" placeholder="e.g. Maintenance Alert" />
                </div>
                <div className="md:col-span-2">
                  <label className="block text-xs font-bold text-gray-400 uppercase tracking-widest mb-2">Message Content</label>
                  <textarea rows={4} value={message} onChange={e => setMessage(e.target.value)} className="w-full border-gray-200 dark:border-white/10 rounded-xl bg-gray-50 dark:bg-slate-900 p-4 text-sm text-slate-900 dark:text-white" placeholder="Write message..." />
                </div>
                <div>
                  <label className="block text-xs font-bold text-gray-400 uppercase tracking-widest mb-2">Link (URL)</label>
                  <div className="relative">
                    <LinkIcon className="absolute left-4 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
                    <input type="url" value={url} onChange={e => setUrl(e.target.value)} className="w-full border-gray-200 dark:border-white/10 rounded-xl bg-gray-50 dark:bg-slate-900 p-4 pl-12 text-sm text-slate-900 dark:text-white" placeholder="https://..." />
                  </div>
                </div>
                <div>
                  <label className="block text-xs font-bold text-gray-400 uppercase tracking-widest mb-2">Schedule (Optional)</label>
                  <div className="relative">
                    <Clock className="absolute left-4 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
                    <input type="datetime-local" value={scheduledAt} onChange={e => setScheduledAt(e.target.value)} className="w-full border-gray-200 dark:border-white/10 rounded-xl bg-gray-50 dark:bg-slate-900 p-4 pl-12 text-sm text-slate-900 dark:text-white" />
                  </div>
                </div>

                {activeTab === 'department' && (
                  <div className="md:col-span-2">
                    <label className="block text-xs font-bold text-gray-400 uppercase tracking-widest mb-2">Target Dept</label>
                    <select value={targetDepartment} onChange={e => setTargetDepartment(e.target.value)} className="w-full border-gray-200 dark:border-white/10 rounded-xl bg-amber-50 dark:bg-amber-500/5 p-4 text-sm font-bold text-slate-900 dark:text-white">
                      <option value="">Select...</option>
                      {departments.map(d => <option key={d} value={d}>{d}</option>)}
                    </select>
                  </div>
                )}

                {activeTab === 'status' && (
                  <div className="md:col-span-2">
                    <label className="block text-xs font-bold text-gray-400 uppercase tracking-widest mb-2">User Status</label>
                    <select value={targetStatus} onChange={e => setTargetStatus(e.target.value)} className="w-full border-gray-200 dark:border-white/10 rounded-xl bg-emerald-50 dark:bg-emerald-500/5 p-4 text-sm font-bold text-slate-900 dark:text-white">
                      <option value="">Select...</option>
                      {statuses.map(s => <option key={s} value={s}>{s}</option>)}
                    </select>
                  </div>
                )}

                {activeTab === 'version' && (
                  <div className="md:col-span-2">
                    <label className="block text-xs font-bold text-gray-400 uppercase tracking-widest mb-2">App Version</label>
                    <select value={targetVersion} onChange={e => setTargetVersion(e.target.value)} className="w-full border-gray-200 dark:border-white/10 rounded-xl bg-blue-50 dark:bg-blue-500/5 p-4 text-sm font-bold text-slate-900 dark:text-white">
                      <option value="">Select...</option>
                      <option value="legacy">Legacy (None)</option>
                      {availableVersions.map(v => <option key={v} value={v}>{v}</option>)}
                    </select>
                  </div>
                )}

                {activeTab === 'user' && (
                  <div className="md:col-span-2">
                    <label className="block text-xs font-bold text-gray-400 uppercase tracking-widest mb-2">User UUID</label>
                    <input type="text" value={targetUserId} onChange={e => setTargetUserId(e.target.value)} className="w-full border-gray-200 dark:border-white/10 rounded-xl bg-rose-50 dark:bg-rose-500/5 p-4 text-sm font-mono text-slate-900 dark:text-white" placeholder="UUID..." />
                  </div>
                )}
              </div>

              <div className="flex gap-4 pt-4">
                <button onClick={() => sendNotification(activeTab)} disabled={loading} className={`flex-1 p-4 rounded-2xl text-white font-bold text-lg shadow-lg transition-all flex items-center justify-center gap-3 disabled:opacity-50 ${
                  activeTab === 'global' ? 'bg-indigo-600 hover:bg-indigo-700 shadow-indigo-200' :
                  activeTab === 'department' ? 'bg-amber-600 hover:bg-amber-700 shadow-amber-200' :
                  activeTab === 'status' ? 'bg-emerald-600 hover:bg-emerald-700 shadow-emerald-200' :
                  activeTab === 'version' ? 'bg-blue-600 hover:bg-blue-700 shadow-blue-200' :
                  'bg-rose-600 hover:bg-rose-700 shadow-rose-200'
                }`}>
                  <Send className="w-5 h-5" />
                  {loading ? 'Processing...' : 'Deploy Alert'}
                </button>
                <button onClick={handleSaveTemplate} className="bg-gray-100 dark:bg-slate-700 text-gray-600 dark:text-slate-300 p-4 rounded-2xl hover:bg-gray-200 dark:hover:bg-slate-600 transition-colors">
                  <BookmarkPlus className="w-6 h-6" />
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* History Sidebar */}
      <div className="w-full lg:w-96 space-y-6">
        <div className="bg-white dark:bg-slate-800 rounded-3xl border border-gray-200 dark:border-white/5 overflow-hidden flex flex-col h-[750px] shadow-sm">
          <div className="p-6 border-b border-gray-100 dark:border-white/5 flex items-center justify-between bg-gray-50/50 dark:bg-slate-900/50">
            <div className="flex items-center gap-3">
              <History className="w-5 h-5 text-indigo-500" />
              <h3 className="text-lg font-bold text-gray-900 dark:text-white">History</h3>
            </div>
            <button onClick={fetchHistory} className="p-2 hover:bg-white dark:hover:bg-slate-800 rounded-lg transition-colors text-gray-400">
              <RefreshCw className={cn("w-4 h-4", historyLoading && "animate-spin")} />
            </button>
          </div>

          <div className="flex-1 overflow-y-auto divide-y divide-gray-100 dark:divide-white/5 custom-scrollbar">
            {historyLoading && history.length === 0 ? (
              <div className="p-12 text-center text-gray-400 italic">Fetching...</div>
            ) : history.length === 0 ? (
              <div className="p-12 text-center text-gray-400 italic">No history.</div>
            ) : (
              history.map((n) => (
                <div key={n.id} className="p-5 hover:bg-slate-50/50 dark:hover:bg-white/5 transition-colors group">
                  <div className="flex items-start justify-between gap-3 mb-2">
                    <div className="flex-1 min-w-0">
                      <p className="font-bold text-gray-900 dark:text-white text-sm truncate">{n.title}</p>
                      <p className="text-xs text-gray-500 dark:text-slate-400 line-clamp-1">{n.body}</p>
                    </div>
                    <button onClick={() => { 
                        setTitle(n.title); setMessage(n.body); setUrl((n.payload as any)?.url || ''); 
                        if (n.alert_key?.startsWith('bcast_')) setActiveTab('global');
                        else if (n.alert_key?.startsWith('dept_')) setActiveTab('department');
                        else if (n.alert_key?.startsWith('status_')) setActiveTab('status');
                        else if (n.alert_key?.startsWith('ver_')) setActiveTab('version');
                        else setActiveTab('user');
                        window.scrollTo({ top: 0, behavior: 'smooth' }); 
                      }} className="p-1.5 text-indigo-400 bg-indigo-50 dark:bg-indigo-500/10 rounded-lg opacity-0 group-hover:opacity-100 transition-opacity">
                      <Copy className="w-3.5 h-3.5" />
                    </button>
                  </div>
                  <div className="flex flex-wrap items-center gap-2 mb-3">
                    <div className="flex items-center bg-emerald-50 dark:bg-emerald-500/10 border border-emerald-100 dark:border-emerald-500/20 rounded-md px-1.5 py-0.5">
                      <ShieldCheck className="w-3 h-3 text-emerald-600 dark:text-emerald-400 mr-1" />
                      <span className="text-[10px] font-bold text-emerald-700 dark:text-emerald-400">{n.stats?.success || 0}</span>
                    </div>
                    <div className="flex items-center bg-rose-50 dark:bg-rose-500/10 border border-rose-100 dark:border-rose-500/20 rounded-md px-1.5 py-0.5">
                      <Users className="w-3 h-3 text-rose-600 dark:text-rose-400 mr-1" />
                      <span className="text-[10px] font-bold text-rose-700 dark:text-rose-400">{n.stats?.failed || 0}</span>
                    </div>
                    <span className="text-[8px] px-1.5 py-0.5 rounded bg-indigo-50 dark:bg-slate-700 text-indigo-600 dark:text-slate-400 font-black uppercase tracking-wider">
                      {n.alert_key?.split('_')[0] || 'Direct'}
                    </span>
                  </div>
                  <div className="flex items-center justify-between text-[9px] text-gray-400 font-bold uppercase tracking-widest">
                    <span>{new Date(n.trigger_at).toLocaleDateString()}</span>
                    <span>{new Date(n.trigger_at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}</span>
                  </div>
                </div>
              ))
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
