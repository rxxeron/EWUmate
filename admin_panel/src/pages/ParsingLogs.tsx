import React, { useEffect, useState } from 'react';
import { supabase } from '../lib/supabase';
import { Activity, RefreshCcw, FileText, CheckCircle2, XCircle, Clock } from 'lucide-react';

interface ParsingLog {
  id: string;
  file_name: string;
  file_type: string;
  status: string;
  metrics: any;
  created_at: string;
}

export function ParsingLogs() {
  const [logs, setLogs] = useState<ParsingLog[]>([]);
  const [loading, setLoading] = useState(true);

  const fetchLogs = async () => {
    setLoading(true);
    try {
      const { data, error } = await supabase
        .from('parsing_logs')
        .select('*')
        .order('created_at', { ascending: false })
        .limit(100);

      if (error) {
        console.error('Error fetching logs:', error);
        return;
      }
      setLogs(data || []);
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchLogs();
    
    // Subscribe to realtime updates on parsing_logs table
    const subscription = supabase
      .channel('public:parsing_logs')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'parsing_logs' }, () => {
        fetchLogs();
      })
      .subscribe();

    return () => {
      supabase.removeChannel(subscription);
    };
  }, []);

  const getStatusIcon = (status: string) => {
    switch (status.toLowerCase()) {
      case 'completed': return <CheckCircle2 className="w-5 h-5 text-green-500" />;
      case 'failed': return <XCircle className="w-5 h-5 text-red-500" />;
      case 'processing': return <Clock className="w-5 h-5 text-yellow-500 animate-pulse" />;
      default: return <Activity className="w-5 h-5 text-gray-400" />;
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Database Activity Logs</h1>
          <p className="text-gray-500 mt-1 text-sm">Monitor automated parser changes and database updates</p>
        </div>
        <button
          onClick={fetchLogs}
          className="flex items-center gap-2 px-4 py-2 bg-white border border-gray-300 rounded-lg shadow-sm hover:bg-gray-50 text-gray-700 font-medium transition-colors"
        >
          <RefreshCcw className={`w-4 h-4 ${loading ? 'animate-spin' : ''}`} />
          Refresh
        </button>
      </div>

      <div className="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden">
        <table className="min-w-full divide-y divide-gray-200">
          <thead className="bg-gray-50">
            <tr>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Status</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">File & Type</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Metrics (Changes)</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Time</th>
            </tr>
          </thead>
          <tbody className="bg-white divide-y divide-gray-200">
            {logs.length === 0 ? (
               <tr>
               <td colSpan={4} className="px-6 py-12 text-center text-gray-500">
                 No parser activity logs found.
               </td>
             </tr>
            ) : (
              logs.map((log) => (
                <tr key={log.id} className="hover:bg-gray-50 transition-colors">
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="flex items-center gap-2">
                       {getStatusIcon(log.status)}
                       <span className="capitalize font-medium text-sm text-gray-700">{log.status}</span>
                    </div>
                  </td>
                  <td className="px-6 py-4">
                    <div className="flex items-center gap-3">
                      <FileText className="w-5 h-5 text-indigo-400" />
                      <div>
                         <p className="text-sm font-medium text-gray-900 border-b border-dashed border-gray-300 pb-0.5 mb-0.5 inline-block">{log.file_name}</p>
                         <p className="text-xs text-gray-500 uppercase tracking-wide font-semibold">{log.file_type}</p>
                      </div>
                    </div>
                  </td>
                  <td className="px-6 py-4">
                    <div className="text-sm text-gray-700 bg-gray-50 p-2.5 rounded-lg border border-gray-100 divide-y divide-gray-100 text-left">
                      {log.metrics ? (
                        <>
                          {log.metrics.upserted !== undefined && (
                             <div className="py-0.5 flex justify-between gap-4">
                                <span className="text-gray-500">Upserted:</span> 
                                <span className="font-semibold text-green-600">{log.metrics.upserted}</span>
                             </div>
                          )}
                          {log.metrics.deleted !== undefined && (
                             <div className="py-0.5 flex justify-between gap-4">
                                <span className="text-gray-500">Deleted:</span> 
                                <span className="font-semibold text-red-600">{log.metrics.deleted}</span>
                             </div>
                          )}
                          {log.metrics.count !== undefined && (
                             <div className="py-0.5 flex justify-between gap-4">
                                <span className="text-gray-500">Events Processed:</span> 
                                <span className="font-semibold text-indigo-600">{log.metrics.count}</span>
                             </div>
                          )}
                          {log.metrics.error && (
                             <div className="py-0.5 flex justify-between gap-4">
                                <span className="text-gray-500">Error:</span> 
                                <span className="font-semibold text-red-600 truncate max-w-xs" title={log.metrics.error}>{log.metrics.error}</span>
                             </div>
                          )}
                           {Object.keys(log.metrics).length === 0 && <span className="text-gray-400 italic">No metrics returned</span>}
                        </>
                      ) : (
                        <span className="text-gray-400 italic">Processing...</span>
                      )}
                    </div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                    {new Date(log.created_at).toLocaleString()}
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
