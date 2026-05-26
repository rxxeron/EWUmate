import { useState, useEffect } from 'react';
import { supabaseAdmin as supabase } from '../lib/supabase';
import { 
  Clock, 
  Check, 
  X, 
  Eye, 
  Trash2, 
  Search, 
  User, 
  RefreshCw, 
  HardDrive,
  FileText
} from 'lucide-react';
import toast from 'react-hot-toast';
import { motion, AnimatePresence } from 'framer-motion';
import type { FacultyOfficeHour, DriveAccount } from '../types';

export function OfficeHoursModeration() {
  const [hours, setHours] = useState<FacultyOfficeHour[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedStatus, setSelectedStatus] = useState<'pending' | 'approved' | 'rejected'>('pending');
  const [submittingId, setSubmittingId] = useState<string | null>(null);

  // Storage Pools state
  const [driveAccounts, setDriveAccounts] = useState<DriveAccount[]>([]);

  useEffect(() => {
    fetchOfficeHours();
    fetchDriveAccounts();
  }, []);

  async function fetchDriveAccounts() {
    try {
      const { data, error } = await supabase
        .from('drive_accounts')
        .select('*')
        .order('email', { ascending: true });

      if (error) throw error;
      setDriveAccounts(data || []);
    } catch (err: any) {
      console.error('Error fetching drive accounts:', err);
      toast.error('Failed to load drive accounts.');
    }
  }

  async function fetchOfficeHours() {
    setLoading(true);
    try {
      const { data, error } = await supabase
        .from('faculty_office_hours')
        .select(`
          *,
          profiles:submitted_by(full_name, student_id)
        `)
        .order('created_at', { ascending: false });

      if (error) throw error;
      setHours(data || []);
    } catch (err: any) {
      console.error('Error fetching office hours:', err);
      toast.error('Failed to load office hours.');
    } finally {
      setLoading(false);
    }
  }

  // Handle status update of a single slot
  async function handleUpdateStatus(id: string, newStatus: 'approved' | 'rejected') {
    setSubmittingId(id);
    try {
      const { error } = await supabase
        .from('faculty_office_hours')
        .update({ status: newStatus, updated_at: new Date().toISOString() })
        .eq('id', id);

      if (error) throw error;

      // Notify the submitter if possible
      const item = hours.find(h => h.id === id);
      if (item && item.submitted_by) {
        let title = '';
        let body = '';
        if (newStatus === 'approved') {
          title = 'Office Hour Approved!';
          body = `Your submitted office hour slot for ${item.faculty_initials} (${item.day} ${item.start_time} - ${item.end_time}) has been approved and is now active in the directory.`;
        } else if (newStatus === 'rejected') {
          title = 'Office Hour Rejected';
          body = `Your submitted office hour slot for ${item.faculty_initials} (${item.day} ${item.start_time} - ${item.end_time}) was reviewed and rejected.`;
        }

        if (title && body) {
          await supabase.from('notifications').insert([{
            user_id: item.submitted_by,
            title,
            body,
            type: 'push_alert',
            alert_key: `office_hour_status_${id}_${Date.now()}`,
            is_dispatched: false,
            trigger_at: new Date().toISOString()
          }]);
        }
      }

      setHours(prev => prev.map(h => h.id === id ? { ...h, status: newStatus, updated_at: new Date().toISOString() } : h));
      toast.success(`Slot successfully ${newStatus}`);
    } catch (err: any) {
      console.error('Error updating slot status:', err);
      toast.error('Failed to update slot status.');
    } finally {
      setSubmittingId(null);
    }
  }

  // Handle status update of all slots sharing the same file proof (Batch action)
  async function handleBatchUpdateStatus(driveFileId: string, newStatus: 'approved' | 'rejected') {
    setSubmittingId(driveFileId);
    try {
      // Find all slots in this batch matching the current tab status
      const batchSlots = groupedSubmissions.find(g => g.driveFileId === driveFileId)?.slots || [];
      if (batchSlots.length === 0) return;

      const ids = batchSlots.map(s => s.id);

      const { error } = await supabase
        .from('faculty_office_hours')
        .update({ status: newStatus, updated_at: new Date().toISOString() })
        .in('id', ids);

      if (error) throw error;

      // Dispatch notifications to the submitter (once per batch)
      const representative = batchSlots[0];
      if (representative && representative.submitted_by) {
        const slotsDesc = batchSlots.map(s => `${s.day} ${s.start_time}-${s.end_time}`).join(', ');
        let title = '';
        let body = '';
        if (newStatus === 'approved') {
          title = 'Office Hours Approved!';
          body = `Your office hours submission for ${representative.faculty_initials} (${slotsDesc}) has been approved and is now live.`;
        } else if (newStatus === 'rejected') {
          title = 'Office Hours Rejected';
          body = `Your office hours submission for ${representative.faculty_initials} (${slotsDesc}) was reviewed and rejected.`;
        }

        if (title && body) {
          await supabase.from('notifications').insert([{
            user_id: representative.submitted_by,
            title,
            body,
            type: 'push_alert',
            alert_key: `office_hour_batch_${driveFileId}_${Date.now()}`,
            is_dispatched: false,
            trigger_at: new Date().toISOString()
          }]);
        }
      }

      setHours(prev => prev.map(h => ids.includes(h.id) ? { ...h, status: newStatus, updated_at: new Date().toISOString() } : h));
      toast.success(`Batch successfully ${newStatus} (${ids.length} slots)`);
    } catch (err: any) {
      console.error('Error batch updating status:', err);
      toast.error('Failed to perform batch update.');
    } finally {
      setSubmittingId(null);
    }
  }

  // Handle permanent delete of a single slot
  async function handleDeleteSlot(id: string) {
    if (!window.confirm('Are you sure you want to permanently delete this office hour slot?')) return;

    setSubmittingId(id);
    try {
      const { error } = await supabase
        .from('faculty_office_hours')
        .delete()
        .eq('id', id);

      if (error) throw error;

      setHours(prev => prev.filter(h => h.id !== id));
      toast.success('Slot permanently deleted.');
    } catch (err: any) {
      console.error('Error deleting slot:', err);
      toast.error('Failed to delete slot.');
    } finally {
      setSubmittingId(null);
    }
  }

  // Handle permanent delete of a whole batch
  async function handleDeleteBatch(driveFileId: string) {
    if (!window.confirm('Are you sure you want to permanently delete all slots associated with this submission proof?')) return;

    setSubmittingId(driveFileId);
    try {
      const batchSlots = groupedSubmissions.find(g => g.driveFileId === driveFileId)?.slots || [];
      if (batchSlots.length === 0) return;

      const ids = batchSlots.map(s => s.id);

      const { error } = await supabase
        .from('faculty_office_hours')
        .delete()
        .in('id', ids);

      if (error) throw error;

      setHours(prev => prev.filter(h => !ids.includes(h.id)));
      toast.success('Batch permanently deleted.');
    } catch (err: any) {
      console.error('Error deleting batch:', err);
      toast.error('Failed to delete batch.');
    } finally {
      setSubmittingId(null);
    }
  }



  // Format file size nicely
  function formatBytes(bytes: number, decimals = 2) {
    if (!bytes || bytes === 0) return '0 Bytes';
    const k = 1024;
    const dm = decimals < 0 ? 0 : decimals;
    const sizes = ['Bytes', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(dm)) + ' ' + sizes[i];
  }

  // Filter hours based on search term
  const filteredHours = hours.filter(h => {
    const matchesSearch = 
      h.faculty_initials.toLowerCase().includes(searchTerm.toLowerCase()) ||
      h.file_name.toLowerCase().includes(searchTerm.toLowerCase()) ||
      (h.day || '').toLowerCase().includes(searchTerm.toLowerCase()) ||
      (h.profiles?.full_name || '').toLowerCase().includes(searchTerm.toLowerCase()) ||
      (h.profiles?.student_id || '').toLowerCase().includes(searchTerm.toLowerCase());

    return matchesSearch;
  });

  // Group filtered hours by drive_file_id (batch groups) matching selected tab status
  interface GroupedSubmission {
    driveFileId: string;
    fileName: string;
    facultyInitials: string;
    submittedBy: string | null;
    uploaderName: string;
    uploaderStudentId: string;
    createdAt: string;
    slots: FacultyOfficeHour[];
  }

  const groupedSubmissions: GroupedSubmission[] = [];

  filteredHours.forEach(h => {
    if (h.status !== selectedStatus) return;

    let group = groupedSubmissions.find(g => g.driveFileId === h.drive_file_id);
    if (!group) {
      group = {
        driveFileId: h.drive_file_id,
        fileName: h.file_name,
        facultyInitials: h.faculty_initials,
        submittedBy: h.submitted_by,
        uploaderName: h.profiles?.full_name || 'Anonymous Student',
        uploaderStudentId: h.profiles?.student_id || 'N/A',
        createdAt: h.created_at,
        slots: []
      };
      groupedSubmissions.push(group);
    }
    group.slots.push(h);
  });

  // Sort grouped submissions by date (newest first)
  groupedSubmissions.sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime());

  // Metrics
  const counts = {
    total: hours.length,
    pending: hours.filter(h => h.status === 'pending').length,
    approved: hours.filter(h => h.status === 'approved').length,
    rejected: hours.filter(h => h.status === 'rejected').length,
  };

  // Dedicated office hours drive usage details
  const officeHoursDrive = driveAccounts.find(acc => acc.purpose === 'office_hours');

  return (
    <div className="space-y-8 animate-in fade-in duration-700">
      
      {/* Header Area */}
      <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-6 px-2">
        <div>
          <h2 className="text-3xl font-black text-slate-900 dark:text-white tracking-tight flex items-center gap-4">
            <div className="p-3 bg-gradient-to-tr from-cyan-500 to-indigo-500 rounded-2xl text-white shadow-lg shadow-indigo-100 dark:shadow-indigo-900/20">
              <Clock className="w-6 h-6" />
            </div>
            Faculty Hours Moderation
          </h2>
          <p className="text-slate-400 dark:text-slate-500 text-[10px] font-black uppercase tracking-[0.2em] mt-2 ml-1">
            Moderate crowdsourced office hour submissions and check proof verifications
          </p>
        </div>
        
        <button
          onClick={fetchOfficeHours}
          className="flex items-center gap-2 px-4 py-2.5 bg-slate-100 hover:bg-slate-200 dark:bg-white/5 dark:hover:bg-white/10 text-slate-700 dark:text-slate-200 text-xs font-bold uppercase tracking-wider rounded-xl transition-all border border-slate-200/50 dark:border-white/5 shadow-sm active:scale-95"
        >
          <RefreshCw className={`w-3.5 h-3.5 ${loading ? 'animate-spin' : ''}`} />
          Refresh Registry
        </button>
      </div>

      {/* Summary Metrics */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        {[
          { label: 'Pending Review', count: counts.pending, color: 'text-sky-500 dark:text-sky-400', bg: 'bg-sky-500/5 border-sky-500/10', glow: counts.pending > 0 },
          { label: 'Active Slots', count: counts.approved, color: 'text-emerald-500 dark:text-emerald-400', bg: 'bg-emerald-500/5 border-emerald-500/10' },
          { label: 'Rejected Slots', count: counts.rejected, color: 'text-rose-500 dark:text-rose-400', bg: 'bg-rose-500/5 border-rose-500/10' },
          { label: 'Total Submitted', count: counts.total, color: 'text-indigo-500 dark:text-indigo-400', bg: 'bg-indigo-500/5 border-indigo-500/10' }
        ].map((stat, i) => (
          <div 
            key={i} 
            className={`p-6 bg-white dark:bg-slate-800 rounded-3xl border border-slate-200/60 dark:border-white/5 shadow-sm flex flex-col relative overflow-hidden transition-all duration-300 ${
              stat.glow ? 'ring-2 ring-sky-500/40 animate-pulse shadow-sky-500/5' : ''
            }`}
          >
            <span className="text-[10px] font-black text-slate-400 dark:text-slate-500 uppercase tracking-widest">{stat.label}</span>
            <span className={`text-3xl font-black mt-2 tracking-tight ${stat.color}`}>{stat.count}</span>
            <div className={`absolute -right-2 -bottom-2 w-12 h-12 rounded-full ${stat.bg} pointer-events-none`} />
          </div>
        ))}
      </div>

      {/* Drive Account Sync Metrics */}
      {officeHoursDrive && (
        <div className="bg-white/70 dark:bg-slate-800/70 backdrop-blur-xl p-8 rounded-[2rem] border border-slate-200/60 dark:border-white/5 shadow-sm space-y-4">
          <div className="flex justify-between items-center">
            <div>
              <h3 className="text-lg font-black text-slate-900 dark:text-white tracking-tight flex items-center gap-2">
                <HardDrive className="w-5 h-5 text-cyan-500" />
                Office Hours Verification Storage Node
              </h3>
              <p className="text-slate-400 dark:text-slate-500 text-[10px] font-black uppercase tracking-wider mt-0.5">
                Segregated Google Drive Storage Account
              </p>
            </div>
            <span className={`px-2 py-1 rounded-md text-[9px] font-black uppercase tracking-wider border ${
              officeHoursDrive.is_active 
                ? 'bg-emerald-500/10 text-emerald-400 border-emerald-500/20' 
                : 'bg-rose-500/10 text-rose-400 border-rose-500/20'
            }`}>
              {officeHoursDrive.is_active ? 'Active Node' : 'Inactive'}
            </span>
          </div>

          <div className="p-4 bg-slate-50 dark:bg-slate-950/40 border border-slate-100 dark:border-white/5 rounded-2xl flex flex-col gap-3">
            <div className="flex justify-between items-end">
              <div>
                <span className="text-[10px] font-bold text-slate-400 dark:text-slate-500 block truncate" title={officeHoursDrive.email}>
                  Node: {officeHoursDrive.email}
                </span>
                <span className="text-xl font-black text-slate-800 dark:text-white mt-1">
                  {formatBytes(officeHoursDrive.used_bytes)} <span className="text-xs font-normal text-slate-400 dark:text-slate-500">used of</span> {formatBytes(officeHoursDrive.total_capacity_bytes)}
                </span>
              </div>
              <span className="text-xs font-black text-cyan-500">
                {((officeHoursDrive.used_bytes / officeHoursDrive.total_capacity_bytes) * 100).toFixed(2)}% Capacity
              </span>
            </div>

            <div className="w-full h-2.5 bg-slate-200 dark:bg-slate-800 rounded-full overflow-hidden">
              <div 
                className="h-full bg-gradient-to-r from-cyan-500 to-blue-500 transition-all duration-500" 
                style={{ width: `${Math.min((officeHoursDrive.used_bytes / officeHoursDrive.total_capacity_bytes) * 100, 100)}%` }}
              />
            </div>
          </div>
        </div>
      )}

      {/* Advanced Filter Bar */}
      <div className="bg-white/70 dark:bg-slate-800/70 backdrop-blur-xl p-6 rounded-[2rem] border border-slate-200/60 dark:border-white/5 shadow-sm space-y-6">
        
        {/* Status Tabs */}
        <div className="flex flex-wrap gap-2 border-b border-slate-100 dark:border-white/5 pb-4">
          {[
            { id: 'pending', label: 'Pending Review', count: counts.pending },
            { id: 'approved', label: 'Approved Directory', count: counts.approved },
            { id: 'rejected', label: 'Rejected Queue', count: counts.rejected }
          ].map(tab => (
            <button
              key={tab.id}
              onClick={() => setSelectedStatus(tab.id as any)}
              className={`flex items-center gap-2.5 px-5 py-2.5 rounded-xl font-bold text-xs uppercase tracking-wider transition-all ${
                selectedStatus === tab.id
                ? 'bg-cyan-500 text-black shadow-md shadow-cyan-500/10 scale-102 font-black'
                : 'text-slate-500 hover:text-slate-900 dark:text-slate-400 dark:hover:text-white hover:bg-slate-100 dark:hover:bg-white/5'
              }`}
            >
              <span>{tab.label}</span>
              <span className={`px-1.5 py-0.5 rounded-md text-[9px] font-black ${
                selectedStatus === tab.id ? 'bg-black/20 text-black' : 'bg-slate-100 dark:bg-slate-900 text-slate-500 dark:text-slate-400'
              }`}>
                {tab.count}
              </span>
            </button>
          ))}
        </div>

        {/* Search */}
        <div className="relative">
          <input
            type="text"
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            placeholder="Search by faculty initials, proof filename, day, or student uploader details..."
            className="block w-full pl-11 pr-4 py-3 bg-slate-50 dark:bg-slate-900 border border-slate-100 dark:border-white/10 rounded-2xl text-sm font-semibold text-slate-900 dark:text-white placeholder:text-slate-300 dark:placeholder:text-slate-600 focus:bg-white dark:focus:bg-slate-800 focus:ring-4 focus:ring-cyan-500/10 focus:border-cyan-500 outline-none transition-all"
          />
          <div className="absolute inset-y-0 left-4 flex items-center pointer-events-none text-slate-400">
            <Search className="w-4 h-4" />
          </div>
        </div>

      </div>

      {/* Grouped Moderation Cards List */}
      <div className="space-y-6">
        {loading ? (
          <div className="bg-white dark:bg-slate-800 rounded-[2rem] border border-slate-200/60 dark:border-white/5 p-24 flex flex-col items-center justify-center gap-4">
            <div className="animate-spin rounded-full h-10 w-10 border-4 border-cyan-500 border-t-transparent"></div>
            <p className="text-gray-400 dark:text-slate-500 font-black text-xs uppercase tracking-[0.2em]">Loading submissions queue...</p>
          </div>
        ) : groupedSubmissions.length === 0 ? (
          <div className="bg-white dark:bg-slate-800 rounded-[2rem] border border-slate-200/60 dark:border-white/5 p-20 text-center flex flex-col items-center justify-center">
            <div className="bg-slate-50 dark:bg-slate-900/50 w-20 h-20 rounded-3xl flex items-center justify-center mb-6">
              <Clock className="h-10 w-10 text-slate-300 dark:text-slate-700" />
            </div>
            <h3 className="text-xl font-black text-slate-900 dark:text-white">Moderation Queue Empty</h3>
            <p className="mt-2 text-slate-500 dark:text-slate-500 text-sm max-w-sm">
              No office hour submissions found matching the selected status filter.
            </p>
          </div>
        ) : (
          <div className="grid grid-cols-1 gap-6">
            <AnimatePresence>
              {groupedSubmissions.map((group, idx) => (
                <motion.div
                  key={group.driveFileId}
                  initial={{ opacity: 0, y: 12 }}
                  animate={{ opacity: 1, y: 0 }}
                  exit={{ opacity: 0, scale: 0.98 }}
                  transition={{ duration: 0.3, delay: Math.min(idx * 0.03, 0.4) }}
                  className="bg-white dark:bg-slate-800 border border-slate-200/60 dark:border-white/5 rounded-[2rem] p-6 lg:p-8 shadow-sm space-y-6 overflow-hidden transition-all duration-300 hover:shadow-md"
                >
                  
                  {/* Uploader Profile & Faculty Header */}
                  <div className="flex flex-col lg:flex-row justify-between items-start lg:items-center gap-4 pb-5 border-b border-slate-100 dark:border-white/5">
                    
                    {/* User and Target Faculty Info */}
                    <div className="flex flex-wrap items-center gap-4">
                      {/* Faculty Circle Badge */}
                      <div className="px-4 py-2.5 bg-gradient-to-tr from-cyan-500 to-indigo-500 rounded-2xl text-white font-black text-lg shadow-md shadow-cyan-500/10">
                        {group.facultyInitials}
                      </div>

                      <div>
                        <div className="flex items-center gap-2">
                          <span className="font-bold text-sm text-slate-800 dark:text-white">Submitted by:</span>
                          <span className="text-xs font-semibold text-slate-500 dark:text-slate-400 flex items-center gap-1">
                            <User className="w-3.5 h-3.5 text-cyan-500" />
                            {group.uploaderName}
                          </span>
                          <span className="px-2 py-0.5 text-[9px] font-mono font-bold bg-indigo-50 dark:bg-indigo-500/10 text-indigo-500 rounded border border-indigo-100 dark:border-indigo-500/20">
                            {group.uploaderStudentId}
                          </span>
                        </div>
                        
                        <div className="text-[10px] text-slate-400 dark:text-slate-500 font-bold uppercase tracking-wider mt-1">
                          Submission Date: {new Date(group.createdAt).toLocaleString()}
                        </div>
                      </div>
                    </div>

                    {/* Batch Actions */}
                    <div className="flex items-center gap-2 self-stretch lg:self-auto justify-end">
                      {/* View Proof button */}
                      <a
                        href={`https://drive.google.com/file/d/${group.driveFileId}/view`}
                        target="_blank"
                        rel="noopener noreferrer"
                        className="flex items-center gap-2 px-4 py-2 bg-slate-50 hover:bg-slate-100 dark:bg-slate-900 dark:hover:bg-white/5 text-slate-600 dark:text-slate-300 text-xs font-bold uppercase tracking-wider rounded-xl border border-slate-200/50 dark:border-white/5 transition-all shadow-sm shrink-0"
                      >
                        <Eye className="w-4 h-4 text-cyan-500" />
                        <span>View Verification Proof</span>
                      </a>

                      {selectedStatus === 'pending' && (
                        <>
                          <button
                            disabled={submittingId === group.driveFileId}
                            onClick={() => handleBatchUpdateStatus(group.driveFileId, 'approved')}
                            className="flex items-center gap-1.5 px-4 py-2 bg-emerald-500/15 hover:bg-emerald-500 text-emerald-400 hover:text-white text-xs font-black uppercase tracking-wider rounded-xl border border-emerald-500/20 transition-all disabled:opacity-50"
                            title="Approve All Slots"
                          >
                            <Check className="w-4 h-4" />
                            <span>Approve All</span>
                          </button>

                          <button
                            disabled={submittingId === group.driveFileId}
                            onClick={() => handleBatchUpdateStatus(group.driveFileId, 'rejected')}
                            className="flex items-center gap-1.5 px-4 py-2 bg-rose-500/15 hover:bg-rose-500 text-rose-400 hover:text-white text-xs font-black uppercase tracking-wider rounded-xl border border-rose-500/20 transition-all disabled:opacity-50"
                            title="Reject All Slots"
                          >
                            <X className="w-4 h-4" />
                            <span>Reject All</span>
                          </button>
                        </>
                      )}

                      {(selectedStatus === 'approved' || selectedStatus === 'rejected') && (
                        <button
                          disabled={submittingId === group.driveFileId}
                          onClick={() => handleDeleteBatch(group.driveFileId)}
                          className="flex items-center gap-1.5 px-4 py-2 bg-slate-100 hover:bg-rose-500 dark:bg-slate-900 dark:hover:bg-rose-600 text-rose-400 hover:text-white text-xs font-black uppercase tracking-wider rounded-xl border border-slate-200/50 dark:border-white/5 transition-all disabled:opacity-50"
                          title="Permanently Delete Submission Group"
                        >
                          <Trash2 className="w-4 h-4" />
                          <span>Delete Group</span>
                        </button>
                      )}
                    </div>
                  </div>

                  {/* Body: Render slots list */}
                  <div className="space-y-4">
                    <div className="text-[10px] font-black text-slate-400 dark:text-slate-500 uppercase tracking-widest">
                      Reported Slots ({group.slots.length})
                    </div>

                    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                      {group.slots.map(slot => (
                        <div 
                          key={slot.id}
                          className="p-4 bg-slate-50/50 dark:bg-slate-900/30 border border-slate-100 dark:border-white/5 rounded-2xl relative overflow-hidden transition-all duration-300 hover:border-slate-200 dark:hover:border-white/10"
                        >
                          <div className="flex justify-between items-start">
                            <div>
                              <span className="px-2 py-0.5 text-[9px] font-black bg-cyan-500/10 text-cyan-500 rounded border border-cyan-500/10 uppercase tracking-wide">
                                {slot.day}
                              </span>
                              <div className="font-bold text-sm text-slate-800 dark:text-white tracking-tight mt-2 flex items-center gap-2">
                                <Clock className="w-4 h-4 text-slate-400 shrink-0" />
                                {slot.start_time} - {slot.end_time}
                              </div>
                            </div>

                            {/* Single Slot Controls */}
                            {selectedStatus === 'pending' && (
                              <div className="flex items-center gap-1">
                                <button
                                  disabled={submittingId === slot.id}
                                  onClick={() => handleUpdateStatus(slot.id, 'approved')}
                                  className="p-1.5 bg-emerald-500/10 hover:bg-emerald-500 text-emerald-400 hover:text-white rounded-lg border border-emerald-500/20 transition-all disabled:opacity-50"
                                  title="Approve Slot"
                                >
                                  <Check className="w-3.5 h-3.5" />
                                </button>
                                <button
                                  disabled={submittingId === slot.id}
                                  onClick={() => handleUpdateStatus(slot.id, 'rejected')}
                                  className="p-1.5 bg-rose-500/10 hover:bg-rose-500 text-rose-400 hover:text-white rounded-lg border border-rose-500/20 transition-all disabled:opacity-50"
                                  title="Reject Slot"
                                >
                                  <X className="w-3.5 h-3.5" />
                                </button>
                              </div>
                            )}

                            {selectedStatus === 'approved' && (
                              <button
                                disabled={submittingId === slot.id}
                                onClick={() => handleUpdateStatus(slot.id, 'rejected')}
                                className="p-1.5 bg-rose-500/10 hover:bg-rose-500 text-rose-400 hover:text-white rounded-lg border border-rose-500/20 transition-all disabled:opacity-50"
                                title="Deactivate/Reject Slot"
                              >
                                <X className="w-3.5 h-3.5" />
                              </button>
                            )}

                            {selectedStatus === 'rejected' && (
                              <div className="flex items-center gap-1">
                                <button
                                  disabled={submittingId === slot.id}
                                  onClick={() => handleUpdateStatus(slot.id, 'approved')}
                                  className="p-1.5 bg-emerald-500/10 hover:bg-emerald-500 text-emerald-400 hover:text-white rounded-lg border border-emerald-500/20 transition-all disabled:opacity-50"
                                  title="Approve/Restore Slot"
                                >
                                  <Check className="w-3.5 h-3.5" />
                                </button>
                                <button
                                  disabled={submittingId === slot.id}
                                  onClick={() => handleDeleteSlot(slot.id)}
                                  className="p-1.5 bg-slate-100 hover:bg-rose-500 dark:bg-slate-950 dark:hover:bg-rose-600 text-rose-400 hover:text-white rounded-lg border border-slate-200/50 dark:border-white/5 transition-all disabled:opacity-50"
                                  title="Delete Permanently"
                                >
                                  <Trash2 className="w-3.5 h-3.5" />
                                </button>
                              </div>
                            )}
                          </div>
                        </div>
                      ))}
                    </div>
                  </div>

                  {/* Attachment metadata info */}
                  <div className="pt-4 border-t border-slate-100 dark:border-white/5 flex flex-wrap items-center justify-between text-[10px] text-slate-400 dark:text-slate-500 font-bold uppercase tracking-wider gap-2">
                    <span className="flex items-center gap-1.5">
                      <FileText className="w-3.5 h-3.5 text-cyan-500" />
                      Attachment: <span className="text-slate-500 dark:text-slate-400 font-mono select-all normal-case">{group.fileName}</span>
                    </span>
                    <span>Google File ID: {group.driveFileId.slice(0, 16)}...</span>
                  </div>

                </motion.div>
              ))}
            </AnimatePresence>
          </div>
        )}
      </div>

    </div>
  );
}
