import { useEffect, useState } from 'react';
import { supabase } from '../lib/supabase';
import { Settings as SettingsIcon, RefreshCw } from 'lucide-react';
import toast from 'react-hot-toast';
import { cn } from '../lib/utils';

export function Settings() {
  const [loading, setLoading] = useState(true);
  const [versionStats, setVersionStats] = useState<Record<string, { count: number, students: any[] }>>({});
  const [expandedVersions, setExpandedVersions] = useState<Set<string>>(new Set());
  const [updateConfig, setUpdateConfig] = useState<any>(null);

  useEffect(() => {
    fetchConfigs();
    fetchVersionStats();
  }, []);

  async function fetchVersionStats() {
    try {
      const { data } = await supabase.from('profiles').select('app_version, full_name, student_id');
      if (data) {
        const stats: Record<string, { count: number, students: any[] }> = {};
        data.forEach(p => {
          const v = p.app_version || 'Unknown / Older';
          if (!stats[v]) stats[v] = { count: 0, students: [] };
          stats[v].count++;
          stats[v].students.push(p);
        });
        setVersionStats(stats);
      }
    } catch (e) {
      console.error('Failed to fetch version stats:', e);
    }
  }

  const toggleVersionExpand = (version: string) => {
    const newExpanded = new Set(expandedVersions);
    if (newExpanded.has(version)) {
      newExpanded.delete(version);
    } else {
      newExpanded.add(version);
    }
    setExpandedVersions(newExpanded);
  };

  async function fetchConfigs() {
    setLoading(true);
    const { data, error } = await supabase
      .from('app_config')
      .select('*')
      .order('key', { ascending: true });

    if (!error && data) {
      const updateInfo = data.find(c => c.key === 'update_info');
      if (updateInfo) setUpdateConfig(updateInfo);
    }
    setLoading(false);
  }

  const handleUpdate = async (itemKey: string, updates: any) => {
    const { error } = await supabase
      .from('app_config')
      .update(updates)
      .eq('key', itemKey);

    if (error) {
      toast.error('Failed to update config: ' + error.message);
    } else {
      toast.success('Configuration saved');
      await fetchConfigs();
    }
  };

  if (loading) return (
    <div className="flex items-center justify-center p-12">
      <RefreshCw className="w-8 h-8 text-indigo-500 animate-spin" />
    </div>
  );

  return (
    <div className="space-y-8 w-full">
      <div className="flex justify-between items-center">
        <h2 className="text-3xl font-extrabold text-gray-900 dark:text-white tracking-tight flex items-center gap-3">
          <SettingsIcon className="w-8 h-8 text-indigo-600 dark:text-indigo-400" />
          App Config & Version CMS
        </h2>
        <button
          onClick={() => { fetchConfigs(); fetchVersionStats(); }}
          className="bg-white dark:bg-slate-800 border border-gray-200 dark:border-white/5 px-4 py-2 rounded-lg shadow-sm text-sm font-medium hover:bg-gray-50 dark:hover:bg-white/10 flex items-center gap-2 transition-all text-slate-700 dark:text-slate-300"
        >
          <RefreshCw className="w-4 h-4" /> Refresh Data
        </button>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
        <div className="lg:col-span-3 space-y-8">
          {/* Version Management Card */}
          <div className="bg-white dark:bg-slate-800 rounded-2xl shadow-sm border border-indigo-100 dark:border-white/5 overflow-hidden">
            <div className="p-6 bg-gradient-to-r from-indigo-50 to-white dark:from-slate-900 dark:to-slate-800 border-b border-indigo-100 dark:border-white/5">
              <h3 className="text-lg font-bold text-gray-900 dark:text-white flex items-center gap-2">
                <RefreshCw className="w-5 h-5 text-indigo-500 dark:text-indigo-400" />
                Active Version Settings
              </h3>
            </div>
            <div className="p-6 space-y-6">
              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div>
                  <label className="block text-xs font-bold text-gray-400 dark:text-slate-500 uppercase tracking-widest mb-2">Target Live Version</label>
                  <input 
                    type="text"
                    defaultValue={updateConfig?.latest_version || ''}
                    onBlur={(e) => handleUpdate('update_info', { latest_version: e.target.value })}
                    className="w-full border-gray-200 dark:border-white/10 rounded-xl bg-gray-50 dark:bg-slate-900 p-3 text-sm focus:ring-2 focus:ring-indigo-500 transition-all font-mono text-slate-900 dark:text-white"
                    placeholder="e.g. 2.0.1"
                  />
                </div>
                <div>
                  <label className="block text-xs font-bold text-gray-400 dark:text-slate-500 uppercase tracking-widest mb-2">Update Download URL</label>
                  <input 
                    type="text"
                    defaultValue={updateConfig?.download_url || ''}
                    onBlur={(e) => handleUpdate('update_info', { download_url: e.target.value })}
                    className="w-full border-gray-200 dark:border-white/10 rounded-xl bg-gray-50 dark:bg-slate-900 p-3 text-sm focus:ring-2 focus:ring-indigo-500 transition-all text-slate-900 dark:text-white"
                    placeholder="https://..."
                  />
                </div>
              </div>

              <div className="flex items-center justify-between p-4 bg-indigo-50/50 dark:bg-indigo-500/5 rounded-xl border border-indigo-100 dark:border-indigo-500/10">
                <div>
                  <h4 className="font-bold text-gray-900 dark:text-white">Show Update Prompt to Users</h4>
                  <p className="text-xs text-gray-500 dark:text-slate-500">When enabled, students on older versions will see the update alert.</p>
                </div>
                <button
                  onClick={() => handleUpdate('update_info', { value: { ...updateConfig?.value, update_available: !updateConfig?.value?.update_available } })}
                  className={`relative inline-flex h-6 w-11 items-center rounded-full transition-colors ${updateConfig?.value?.update_available ? 'bg-indigo-600' : 'bg-gray-200 dark:bg-slate-700'}`}
                >
                  <span className={`inline-block h-4 w-4 transform rounded-full bg-white transition-transform ${updateConfig?.value?.update_available ? 'translate-x-6' : 'translate-x-1'}`} />
                </button>
              </div>
            </div>
          </div>

          {/* Available Versions List */}
          <div className="bg-white dark:bg-slate-800 rounded-2xl shadow-sm border border-gray-200 dark:border-white/5 overflow-hidden">
            <div className="p-6 border-b border-gray-100 dark:border-white/5 bg-gray-50/50 dark:bg-slate-900/50">
              <h3 className="text-lg font-bold text-gray-900 dark:text-white">Detected App Versions & User Adoption</h3>
              <p className="text-xs text-gray-500 dark:text-slate-500">Live breakdown of which versions your students are currently using.</p>
            </div>
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 divide-y md:divide-y-0 divide-gray-100 dark:divide-white/5">
              {Object.entries(versionStats).sort((a, b) => b[1].count - a[1].count).map(([version, data], idx) => {
                const totalUsers = Object.values(versionStats).reduce((acc, curr) => acc + curr.count, 0);
                const percentage = totalUsers > 0 ? (data.count / totalUsers) * 100 : 0;
                const isLatest = version === updateConfig?.latest_version;
                const isExpanded = expandedVersions.has(version);

                return (
                  <div key={version} className={cn(
                    "hover:bg-gray-50/50 dark:hover:bg-white/5 transition-colors border-gray-100 dark:border-white/5",
                    idx % 2 !== 1 && "md:border-r",
                    (idx + 1) % 3 !== 0 && "lg:border-r",
                    "border-b"
                  )}>
                    <div 
                      onClick={() => toggleVersionExpand(version)}
                      className="p-6 flex items-center justify-between cursor-pointer"
                    >
                      <div className="flex-1 min-w-0">
                        <div className="flex items-center gap-3 mb-2">
                          <span className={`text-lg font-mono font-bold truncate ${isLatest ? 'text-indigo-600 dark:text-indigo-400' : 'text-gray-700 dark:text-slate-300'}`}>
                            {/^\d/.test(version) ? `v${version}` : version}
                          </span>
                          {isLatest && (
                            <span className="bg-emerald-100 dark:bg-emerald-500/10 text-emerald-700 dark:text-emerald-400 text-[9px] px-2 py-0.5 rounded-full font-black uppercase tracking-wider shrink-0">
                              Live
                            </span>
                          )}
                        </div>
                        <div className="flex items-center gap-4">
                          <div className="flex-1 bg-gray-100 dark:bg-slate-900 rounded-full h-1.5">
                            <div 
                              className={`h-1.5 rounded-full transition-all duration-1000 ${isLatest ? 'bg-indigo-500' : 'bg-gray-400 dark:bg-slate-700'}`}
                              style={{ width: `${percentage}%` }}
                            />
                          </div>
                          <span className="text-[10px] text-gray-400 dark:text-slate-500 font-black uppercase tracking-widest shrink-0">
                            {isExpanded ? '▲' : '▼'}
                          </span>
                        </div>
                      </div>
                      <div className="text-right ml-6 shrink-0">
                        <p className="text-xl font-black text-gray-900 dark:text-white leading-none">{data.count}</p>
                        <p className="text-[9px] font-black text-gray-400 dark:text-slate-500 uppercase tracking-widest mt-1">Users</p>
                      </div>
                    </div>

                    {isExpanded && (
                      <div className="px-6 pb-6 bg-gray-50/30 dark:bg-slate-900/30">
                        <div className="border border-gray-200 dark:border-white/5 rounded-xl overflow-hidden shadow-sm">
                          <table className="w-full text-left text-sm">
                            <thead className="bg-white dark:bg-slate-800 border-b border-gray-200 dark:border-white/5 text-gray-400 dark:text-slate-500 text-[9px] font-black uppercase tracking-widest">
                              <tr>
                                <th className="px-3 py-2">Name</th>
                                <th className="px-3 py-2 text-right">ID</th>
                              </tr>
                            </thead>
                            <tbody className="divide-y divide-gray-100 dark:divide-white/5 bg-white dark:bg-slate-800">
                              {data.students.slice(0, 50).map((student: any) => (
                                <tr key={student.student_id} className="hover:bg-gray-50 dark:hover:bg-white/5 transition-colors">
                                  <td className="px-3 py-2 font-bold text-slate-700 dark:text-slate-300 text-xs truncate max-w-[120px]">{student.full_name || 'N/A'}</td>
                                  <td className="px-3 py-2 font-mono text-slate-500 dark:text-slate-500 text-[10px] text-right">{student.student_id || 'N/A'}</td>
                                </tr>
                              ))}
                            </tbody>
                          </table>
                        </div>
                      </div>
                    )}
                  </div>
                );
              })}
              {Object.keys(versionStats).length === 0 && (
                <div className="col-span-2 p-12 text-center text-gray-500 dark:text-slate-500 italic">
                  No version data detected from students yet.
                </div>
              )}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}