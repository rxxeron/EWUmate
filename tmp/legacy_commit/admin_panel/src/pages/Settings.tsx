import { useEffect, useState } from 'react';
import { supabase } from '../lib/supabase';
import { Settings as SettingsIcon, Save, RefreshCw } from 'lucide-react';

export function Settings() {
  const [configs, setConfigs] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState<string | null>(null);

  useEffect(() => {
    fetchConfigs();
  }, []);

  async function fetchConfigs() {
    setLoading(true);
    const { data, error } = await supabase
      .from('app_config')
      .select('*')
      .order('key', { ascending: true });

    if (!error && data) {
      const formattedData = data.map(config => ({
        key: config.key,
        value: typeof config.value === 'object' ? JSON.stringify(config.value, null, 2) : String(config.value)
      }));
      setConfigs(formattedData);
    } else {
      console.error(error);
    }
    setLoading(false);
  }

  const handleUpdate = async (itemKey: string, newValueStr: string) => {
    setSaving(itemKey);
    let finalValue: any = newValueStr;
    
    try {
      if (newValueStr.trim().startsWith('{') || newValueStr.trim().startsWith('[')) {
        finalValue = JSON.parse(newValueStr);
      } else if (newValueStr === 'true') {
        finalValue = true;
      } else if (newValueStr === 'false') {
        finalValue = false;
      } else if (!isNaN(Number(newValueStr)) && newValueStr.trim() !== '') {
        finalValue = Number(newValueStr);
      }
    } catch (e) {
      console.log('Not valid JSON, saving as string');
    }

    const { error } = await supabase
      .from('app_config')
      .update({ value: finalValue })
      .eq('key', itemKey);

    if (error) {
      alert("Failed to update config: " + error.message);
    } else {
      await fetchConfigs();
    }
    setSaving(null);
  };

  const handleTextChange = (itemKey: string, val: string) => {
    setConfigs(configs.map(c => c.key === itemKey ? { ...c, value: val } : c));
  };

  if (loading) return <div className="p-6">Loading App Configuration...</div>;

  return (
    <div className="bg-white rounded-lg shadow max-w-4xl">
      <div className="p-6 border-b border-gray-200 flex justify-between items-center">
        <h2 className="text-2xl font-bold flex items-center gap-2 text-gray-800">
          <SettingsIcon className="w-6 h-6 text-indigo-600" />
          Global App Configuration (CMS)
        </h2>
        <button
          onClick={fetchConfigs}
          className="flex items-center gap-2 text-sm text-indigo-600 hover:text-indigo-800"
        >
          <RefreshCw className="w-4 h-4" /> Refresh
        </button>
      </div>

      <div className="p-6 space-y-6">
        <div className="bg-blue-50 border-l-4 border-blue-400 p-4 mb-6">
          <p className="text-sm text-blue-700">
            These settings directly affect the live application. Changing these values will update the mobile clients immediately without requiring an app store update.
          </p>
        </div>

        {configs.length === 0 ? (
          <p className="text-gray-500 italic">No configuration keys found in the app_config table.</p>
        ) : (
          configs.map((config) => (
            <div key={config.key} className="border border-gray-200 p-4 rounded-md bg-gray-50">
              <div className="flex justify-between items-start mb-2">
                <div>
                  <h3 className="font-semibold text-gray-800">{config.key}</h3>
                  <p className="text-xs text-gray-500 mb-2">Global configuration parameter (JSON)</p>
                </div>
              </div>
              
              <div className="flex gap-4 items-center">
                <textarea
                  value={config.value || ''}
                  onChange={(e) => handleTextChange(config.key, e.target.value)}
                  rows={String(config.value).length > 50 || String(config.value).includes('{') ? 6 : 1}
                  className="block w-full p-2 border border-gray-300 rounded shadow-sm focus:border-indigo-500 bg-white font-mono text-sm"
                />
                
                <button
                  onClick={() => handleUpdate(config.key, config.value)}
                  disabled={saving === config.key}
                  className="bg-indigo-600 text-white px-4 py-2 rounded hover:bg-indigo-700 disabled:opacity-50 flex items-center gap-2 whitespace-nowrap h-fit"
                >
                  <Save className="w-4 h-4" />
                  {saving === config.key ? 'Saving...' : 'Save'}
                </button>
              </div>
            </div>
          ))
        )}
      </div>
    </div>
  );
}