import { useState, useEffect } from 'react';
import { supabase } from '../lib/supabase';
import { Mail } from 'lucide-react';

interface Feedback {
  id: string;
  user_id: string;
  message: string;
  status: 'pending' | 'in_progress' | 'resolved' | 'ignored';
  created_at: string;
  users: {
    email: string;
    raw_user_meta_data?: {
      name?: string;
    };
  };
}

export function Feedbacks() {
  const [feedbacks, setFeedbacks] = useState<Feedback[]>([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState<string>('all');

  useEffect(() => {
    fetchFeedbacks();
  }, []);

  const fetchFeedbacks = async () => {
    setLoading(true);
    try {
      const { data, error } = await supabase
        .from('feedbacks')
        .select(`
          *,
          users:auth.users!user_id(email, raw_user_meta_data)
        `)
        .order('created_at', { ascending: false });

      if (error) throw error;
      setFeedbacks(data as any);
    } catch (error) {
      console.error('Error fetching feedbacks:', error);
    } finally {
      setLoading(false);
    }
  };

  const updateStatus = async (id: string, newStatus: string) => {
    try {
      const { error } = await supabase
        .from('feedbacks')
        .update({ status: newStatus, updated_at: new Date().toISOString() })
        .eq('id', id);
        
      if (error) throw error;
      
      setFeedbacks(feedbacks.map(f => f.id === id ? { ...f, status: newStatus as any } : f));
    } catch (error) {
      console.error('Error updating status:', error);
      alert('Failed to update status');
    }
  };

  const filteredFeedbacks = filter === 'all' 
    ? feedbacks 
    : feedbacks.filter(f => f.status === filter);

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'pending': return 'bg-yellow-100 text-yellow-800 border-yellow-200';
      case 'in_progress': return 'bg-blue-100 text-blue-800 border-blue-200';
      case 'resolved': return 'bg-green-100 text-green-800 border-green-200';
      case 'ignored': return 'bg-gray-100 text-gray-800 border-gray-200';
      default: return 'bg-gray-100 text-gray-800 border-gray-200';
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center px-2">
        <h2 className="text-3xl font-extrabold text-gray-900 tracking-tight">User Feedback & Issues</h2>
        
        <select 
          className="border-gray-300 rounded-lg shadow-sm focus:ring-indigo-500 focus:border-indigo-500 text-sm font-medium p-2"
          value={filter}
          onChange={(e) => setFilter(e.target.value)}
        >
          <option value="all">All Feedbacks</option>
          <option value="pending">Pending</option>
          <option value="in_progress">In Progress</option>
          <option value="resolved">Resolved</option>
          <option value="ignored">Ignored</option>
        </select>
      </div>

      {loading ? (
        <div className="flex justify-center p-12">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-indigo-600"></div>
        </div>
      ) : filteredFeedbacks.length === 0 ? (
        <div className="bg-white rounded-xl shadow-sm border border-gray-100 p-12 text-center">
          <Mail className="mx-auto h-12 w-12 text-gray-300 mb-4" />
          <h3 className="text-lg font-medium text-gray-900">No feedbacks found</h3>
          <p className="mt-1 text-gray-500 text-sm">No feedbacks match the current filter.</p>
        </div>
      ) : (
        <div className="grid gap-6 gap-y-8">
          {filteredFeedbacks.map((feedback) => (
            <div key={feedback.id} className="bg-white/80 backdrop-blur-md rounded-2xl shadow-sm border border-indigo-100 p-6 flex flex-col md:flex-row gap-6 transition-all hover:shadow-md">
              <div className="flex-1">
                <div className="flex items-center gap-3 mb-3">
                  <span className={`px-2.5 py-1 text-xs font-bold rounded-full border ${getStatusColor(feedback.status)} uppercase tracking-wide`}>
                    {feedback.status.replace('_', ' ')}
                  </span>
                  <span className="text-sm font-medium text-gray-400">
                    {new Date(feedback.created_at).toLocaleString()}
                  </span>
                </div>
                <p className="text-gray-800 text-lg font-medium mb-4 whitespace-pre-wrap">{feedback.message}</p>
                <div className="flex items-center gap-2 text-sm text-gray-500 bg-gray-50 p-3 rounded-lg w-fit">
                  <Mail className="w-4 h-4 text-indigo-400" />
                  <span className="font-semibold text-gray-700">{feedback.users?.email || 'Unknown User'}</span>
                </div>
              </div>
              
              <div className="flex flex-col gap-2 min-w-[160px] border-l md:border-l-2 border-gray-100 pl-6 justify-center">
                <p className="text-xs font-semibold text-gray-400 uppercase tracking-widest mb-1">Set Status</p>
                <select
                  value={feedback.status}
                  onChange={(e) => updateStatus(feedback.id, e.target.value)}
                  className="w-full border-gray-200 rounded-lg shadow-sm text-sm focus:ring-indigo-500 focus:border-indigo-500 font-medium py-2 bg-white"
                >
                  <option value="pending">Pending</option>
                  <option value="in_progress">In Progress</option>
                  <option value="resolved">Resolved</option>
                  <option value="ignored">Ignored</option>
                </select>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}