import { useState, useEffect } from 'react';
import { supabaseAdmin as supabase } from '../lib/supabase';
import { Mail, User } from 'lucide-react';
import toast from 'react-hot-toast';
import type { Feedback } from '../types';

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
          profiles(full_name, student_id, program_code),
          comments:feedback_comments(*)
        `)
        .order('created_at', { ascending: false });

      if (error) throw error;
      
      // Sort comments within each feedback
      const sortedData = (data as any[]).map(f => ({
        ...f,
        comments: (f.comments || []).sort((a: any, b: any) => 
          new Date(a.created_at).getTime() - new Date(b.created_at).getTime()
        )
      }));

      setFeedbacks(sortedData);
    } catch (error) {
      console.error('Error fetching feedbacks:', error);
    } finally {
      setLoading(false);
    }
  };

  const updateStatus = async (id: string, newStatus: string) => {
    try {
      // Find the feedback to get the user_id
      const fb = feedbacks.find(f => f.id === id);
      if (!fb) return;

      const { error } = await supabase
        .from('feedbacks')
        .update({ 
          status: newStatus, 
          updated_at: new Date().toISOString() 
        })
        .eq('id', id);
        
      if (error) throw error;
      
      // Notify the user about the status change
      await supabase.from('notifications').insert([{
        user_id: fb.user_id,
        title: 'Feedback Status Updated',
        body: `Your feedback status has been changed to "${newStatus.replace('_', ' ').toUpperCase()}".`,
        type: 'system',
        alert_key: 'feedback_status_change'
      }]);

      setFeedbacks(feedbacks.map(f => f.id === id ? { ...f, status: newStatus as any } : f));
      toast.success(`Status updated to ${newStatus}`);
    } catch (error) {
      console.error('Error updating status:', error);
      toast.error('Failed to update status');
    }
  };

  const addComment = async (feedbackId: string, userId: string, comment: string) => {
    if (!comment.trim()) return;
    try {
      const { data: commentData, error: commentError } = await supabase
        .from('feedback_comments')
        .insert([{ feedback_id: feedbackId, comment, is_admin: true }])
        .select()
        .single();

      if (commentError) throw commentError;

      // Add notification for the user
      await supabase.from('notifications').insert([{
        user_id: userId,
        title: 'Feedback Update',
        body: `An admin commented on your feedback: "${comment.substring(0, 50)}${comment.length > 50 ? '...' : ''}"`,
        type: 'push_alert',
        alert_key: 'feedback_update'
      }]);

      setFeedbacks(feedbacks.map(f => 
        f.id === feedbackId 
          ? { ...f, comments: [...(f.comments || []), commentData] } 
          : f
      ));
      toast.success('Comment added & user notified');
    } catch (error) {
      console.error('Error adding comment:', error);
      toast.error('Failed to add comment');
    }
  };

  const updateComment = async (feedbackId: string, commentId: string, newText: string) => {
    try {
      const { error } = await supabase
        .from('feedback_comments')
        .update({ comment: newText, updated_at: new Date().toISOString() })
        .eq('id', commentId);

      if (error) throw error;

      setFeedbacks(feedbacks.map(f => 
        f.id === feedbackId 
          ? { ...f, comments: (f.comments || []).map(c => c.id === commentId ? { ...c, comment: newText } : c) } 
          : f
      ));
      toast.success('Comment updated');
    } catch (error) {
      console.error('Error updating comment:', error);
      toast.error('Failed to update comment');
    }
  };

  const deleteComment = async (feedbackId: string, commentId: string) => {
    if (!confirm('Delete this comment?')) return;
    try {
      const { error } = await supabase
        .from('feedback_comments')
        .delete()
        .eq('id', commentId);

      if (error) throw error;

      setFeedbacks(feedbacks.map(f => 
        f.id === feedbackId 
          ? { ...f, comments: (f.comments || []).filter(c => c.id !== commentId) } 
          : f
      ));
      toast.success('Comment deleted');
    } catch (error) {
      console.error('Error deleting comment:', error);
      toast.error('Failed to delete comment');
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
        <h2 className="text-3xl font-extrabold text-gray-900 dark:text-white tracking-tight">User Feedback & Issues</h2>
        
        <select 
          className="border-gray-300 dark:border-white/10 rounded-lg shadow-sm focus:ring-indigo-500 focus:border-indigo-500 text-sm font-medium p-2 dark:bg-slate-900 dark:text-white"
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
        <div className="bg-white dark:bg-slate-800 rounded-xl shadow-sm border border-gray-100 dark:border-white/5 p-12 text-center">
          <Mail className="mx-auto h-12 w-12 text-gray-300 dark:text-slate-700 mb-4" />
          <h3 className="text-lg font-medium text-gray-900 dark:text-white">No feedbacks found</h3>
          <p className="mt-1 text-gray-500 dark:text-slate-500 text-sm">No feedbacks match the current filter.</p>
        </div>
      ) : (
        <div className="grid gap-6 gap-y-8">
          {filteredFeedbacks.map((feedback) => (
            <div key={feedback.id} className="bg-white/80 dark:bg-slate-800/80 backdrop-blur-md rounded-2xl shadow-sm border border-indigo-100 dark:border-white/5 p-6 flex flex-col md:flex-row gap-6 transition-all hover:shadow-md">
              <div className="flex-1">
                <div className="flex items-center gap-3 mb-3">
                  <span className={`px-2.5 py-1 text-xs font-bold rounded-full border ${getStatusColor(feedback.status)} uppercase tracking-wide`}>
                    {feedback.status.replace('_', ' ')}
                  </span>
                  <span className="text-sm font-medium text-gray-400 dark:text-slate-500">
                    {new Date(feedback.created_at).toLocaleString()}
                  </span>
                </div>
                <p className="text-gray-800 dark:text-slate-200 text-lg font-medium mb-4 whitespace-pre-wrap">{feedback.message}</p>
                <div className="flex items-center gap-4 text-sm text-gray-500 dark:text-slate-400 bg-gray-50 dark:bg-slate-900/50 p-3 rounded-lg w-fit">
                  <div className="flex items-center gap-2">
                    <User className="w-4 h-4 text-indigo-400" />
                    <span className="font-bold text-gray-900 dark:text-white">{feedback.profiles?.full_name || 'Anonymous User'}</span>
                  </div>
                  <div className="text-xs border-l border-gray-200 dark:border-white/10 pl-4 font-medium text-gray-500 dark:text-slate-500">
                    ID: <span className="text-indigo-600 dark:text-indigo-400 font-bold">{feedback.profiles?.student_id || 'N/A'}</span>
                  </div>
                  <div className="text-xs border-l border-gray-200 dark:border-white/10 pl-4 font-medium text-gray-500 dark:text-slate-500 italic">
                    {feedback.profiles?.program_code || ''}
                  </div>
                </div>
              </div>
              
              <div className="flex flex-col gap-4 min-w-[300px] border-l md:border-l-2 border-gray-100 dark:border-white/5 pl-6">
                <div>
                  <p className="text-xs font-semibold text-gray-400 dark:text-slate-500 uppercase tracking-widest mb-1">Status</p>
                  <select
                    value={feedback.status}
                    onChange={(e) => updateStatus(feedback.id, e.target.value)}
                    className="w-full border-gray-200 dark:border-white/10 rounded-lg shadow-sm text-sm focus:ring-indigo-500 focus:border-indigo-500 font-medium py-2 bg-white dark:bg-slate-900 dark:text-white"
                  >
                    <option value="pending">Pending</option>
                    <option value="in_progress">In Progress</option>
                    <option value="resolved">Resolved</option>
                    <option value="ignored">Ignored</option>
                  </select>
                </div>

                <div className="flex-1 overflow-y-auto max-h-[300px] space-y-3 pr-2 scrollbar-thin">
                  <p className="text-xs font-semibold text-gray-400 dark:text-slate-500 uppercase tracking-widest mb-1">Comment History</p>
                  
                  {feedback.comments?.map((comment) => (
                    <div key={comment.id} className="bg-gray-50/50 dark:bg-slate-900/50 p-3 rounded-lg border border-gray-100 dark:border-white/10 relative group">
                      <textarea
                        defaultValue={comment.comment}
                        onBlur={(e) => {
                          if (e.target.value !== comment.comment) {
                            updateComment(feedback.id, comment.id, e.target.value);
                          }
                        }}
                        className="w-full bg-transparent border-none p-0 text-sm text-gray-700 dark:text-slate-300 resize-none focus:ring-0"
                      />
                      <div className="flex justify-between items-center mt-1">
                        <span className="text-[10px] text-gray-400 font-bold uppercase">
                          {comment.is_admin ? 'Admin' : 'User'} • {new Date(comment.created_at).toLocaleDateString()}
                        </span>
                        <button 
                          onClick={() => deleteComment(feedback.id, comment.id)}
                          className="text-[10px] text-red-400 opacity-0 group-hover:opacity-100 transition-opacity hover:text-red-600 font-bold"
                        >
                          DELETE
                        </button>
                      </div>
                    </div>
                  ))}

                  <div className="pt-2">
                    <textarea
                      placeholder="Add a comment and notify user..."
                      className="w-full h-20 border-indigo-100 dark:border-indigo-500/20 bg-indigo-50/30 dark:bg-indigo-500/5 rounded-lg shadow-sm text-sm focus:ring-indigo-500 focus:border-indigo-500 font-medium p-3 resize-none dark:text-white"
                      onKeyDown={(e) => {
                        if (e.key === 'Enter' && !e.shiftKey) {
                          e.preventDefault();
                          addComment(feedback.id, feedback.user_id, (e.target as HTMLTextAreaElement).value);
                          (e.target as HTMLTextAreaElement).value = '';
                        }
                      }}
                    />
                    <p className="text-[10px] text-indigo-400 dark:text-indigo-500 mt-1 italic">Press Enter to send notification</p>
                  </div>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}