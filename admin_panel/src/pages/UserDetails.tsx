import { useEffect, useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { supabaseAdmin as supabase } from '../lib/supabase';
import { 
  ArrowLeft, RefreshCw, Users, CheckCircle2, Clipboard, 
  CalendarClock, AlertTriangle, Clock, Edit, Save, 
  X, Plus, Trash2, Shield, Activity, Zap, GraduationCap, BookOpen
} from 'lucide-react';
import { motion } from 'framer-motion';
import toast from 'react-hot-toast';
import type { Profile, Enrollment, CompletedCourse, Task, CourseMark, UserSemesterState } from '../types';
import { CardSkeleton, Skeleton } from '../components/Skeleton';
import { cn } from '../lib/utils';

export function UserDetails() {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const [activeTab, setActiveTab] = useState('overview');
  
  const [user, setUser] = useState<Profile | null>(null);
  const [completedCourses, setCompletedCourses] = useState<CompletedCourse[]>([]);
  const [currentEnrollments, setCurrentEnrollments] = useState<Enrollment[]>([]);
  const [tasks, setTasks] = useState<Task[]>([]);
  const [marks, setMarks] = useState<CourseMark[]>([]);
  const [semesterState, setSemesterState] = useState<UserSemesterState | null>(null);
  const [loading, setLoading] = useState(true);
  const [syncing, setSyncing] = useState(false);
  const [rebuilding, setRebuilding] = useState(false);
  const [saving, setSaving] = useState(false);
  const [isEditingProfile, setIsEditingProfile] = useState(false);
  const [editForm, setEditForm] = useState<Partial<Profile>>({});
  
  const [isAddingCourse, setIsAddingCourse] = useState(false);
  const [courseForm, setCourseForm] = useState<Partial<CompletedCourse>>({});
  const [availablePrograms, setAvailablePrograms] = useState<any[]>([]);

  useEffect(() => {
    if (id) {
      fetchUser(id);
      fetchPrograms();
    }
  }, [id]);

  async function fetchPrograms() {
    try {
      const { data } = await supabase.from('programs').select('program_code, name, department_name, track');
      if (data) setAvailablePrograms(data);
    } catch (e) {
      console.error('Failed to fetch programs:', e);
    }
  }

  const startAddingCourse = () => {
    setCourseForm({
      semester_code: '',
      course_code: '',
      grade: 'A',
      credits: 3.0,
      user_id: id
    });
    setIsAddingCourse(true);
  };

  const handleAddCourse = async () => {
    if (!id || !courseForm.course_code || !courseForm.semester_code) return;
    setSaving(true);
    const normalizedForm = { 
      ...courseForm, 
      course_code: courseForm.course_code?.toUpperCase().replace(/\s+/g, ''),
      user_id: id 
    };

    try {
      const { error } = await supabase
        .from('completed_courses')
        .insert([normalizedForm]);
      
      if (error) throw error;
      toast.success('Course added');
      setIsAddingCourse(false);
      handleSyncData();
    } catch (err: any) {
      toast.error('Failed to add course: ' + err.message);
    } finally {
      setSaving(false);
    }
  };

  const handleDeleteCourse = async (courseId: string) => {
    if (!confirm('Are you sure you want to delete this course history record?')) return;
    try {
      const { error } = await supabase
        .from('completed_courses')
        .delete()
        .eq('id', courseId);
      
      if (error) throw error;
      toast.success('Course record deleted');
      handleSyncData();
    } catch (err: any) {
      toast.error('Delete failed: ' + err.message);
    }
  };

  const handleDeleteEnrollment = async (enrollmentId: string) => {
    if (!confirm('Are you sure you want to remove this course from current enrollments? This will affect the user\'s schedule.')) return;
    try {
      const { error } = await supabase
        .from('enrollments')
        .delete()
        .eq('id', enrollmentId);
      
      if (error) throw error;
      toast.success('Enrollment removed');
      fetchUser(id!);
    } catch (err: any) {
      toast.error('Removal failed: ' + err.message);
    }
  };

  const startEditing = () => {
    if (user) {
      setEditForm({
        full_name: user.full_name,
        student_id: user.student_id,
        program_code: user.program_code,
        program_name: user.program_name,
        department_name: user.department_name,
        cgpa: user.cgpa,
        total_credits_earned: user.total_credits_earned,
        track: user.track,
        onboarding_status: user.onboarding_status
      });
      setIsEditingProfile(true);
    }
  };

  const handleUpdateProfile = async () => {
    if (!id) return;
    setSaving(true);
    try {
      const { error } = await supabase
        .from('profiles')
        .update(editForm)
        .eq('id', id);
      
      if (error) throw error;
      toast.success('Profile updated successfully');
      setIsEditingProfile(false);
      fetchUser(id);
    } catch (err: any) {
      toast.error('Update failed: ' + err.message);
    } finally {
      setSaving(false);
    }
  };

  async function fetchUser(userId: string) {
    setLoading(true);
    
    try {
      const { data: userData, error: userError } = await supabase
        .from('profiles')
        .select('*')
        .eq('id', userId)
        .single();

      if (userError) throw userError;
      if (userData) setUser(userData as Profile);

      const track = userData.track || 'tri_semester';
      const { data: activeSem } = await supabase
        .from('active_semester')
        .select('current_semester_code')
        .eq('track', track)
        .maybeSingle();

      const semesterCode = activeSem?.current_semester_code;

      // 3. Fetch Semester State (Schedule Cache)
      if (semesterCode) {
        try {
          const { data: stateData } = await supabase
            .from('user_semester_states')
            .select('*')
            .eq('user_id', userId)
            .eq('semester_code', semesterCode)
            .maybeSingle();
          
          if (stateData) setSemesterState(stateData as UserSemesterState);
        } catch (e) {
          console.error('Failed to fetch semester state:', e);
        }
      }

      // 4. Fetch Enrollments
      try {
        let enrollmentsQuery = supabase
          .from('enrollments')
          .select('*')
          .eq('user_id', userId);
          
        if (semesterCode) {
          enrollmentsQuery = enrollmentsQuery.eq('semester_code', semesterCode);
        }
        
        const { data: enrollmentsData } = await enrollmentsQuery;

        if (enrollmentsData) {
          const sectionIds = enrollmentsData.map((e: Enrollment) => e.section_id).filter(Boolean);
          if (sectionIds.length > 0 && semesterCode) {
            const cleanSem = semesterCode.replace(/\s+/g, '').replace(/_/g, '').toLowerCase();
            const courseTable = `courses_${cleanSem}`;
            
            const sectionsMap: Record<string, { id: string; section_number: number | null; course_name: string | null }> = {};
            const { data: semCourses } = await supabase.from(courseTable).select('id, section_number, course_name').in('id', sectionIds);
            
            if (semCourses) semCourses.forEach((s: any) => sectionsMap[s.id] = s);

            enrollmentsData.forEach((e: any) => {
               if (e.section_id && sectionsMap[e.section_id]) { 
                 e._sectionDetails = sectionsMap[e.section_id]; 
               }
            });
          }
          setCurrentEnrollments(enrollmentsData as Enrollment[]);
        }
      } catch (e) {
        console.error('Failed to fetch enrollments:', e);
      }

      // 5. Fetch Other Data
      try {
        const { data: coursesData } = await supabase.from('completed_courses').select('*').eq('user_id', userId).order('semester_code', { ascending: false });
        if (coursesData) setCompletedCourses(coursesData as CompletedCourse[]);
      } catch (e) {
        console.error('Failed to fetch completed courses:', e);
      }

      try {
        const { data: tasksData } = await supabase.from('tasks').select('*').eq('user_id', userId).order('due_date', { ascending: false }).limit(50);
        if (tasksData) setTasks(tasksData as Task[]);
      } catch (e) {
        console.error('Failed to fetch tasks:', e);
      }

      try {
        const { data: marksData } = await supabase.from('semester_course_marks').select('*').eq('user_id', userId);
        if (marksData && semesterCode) {
          const cleanSem = semesterCode.replace(/\s+/g, '').replace(/_/g, '').toLowerCase();
          const courseTable = `courses_${cleanSem}`;
          const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
          const uuidCodes = marksData.map((m: CourseMark) => m.course_code).filter(c => c && uuidRegex.test(c));
          
          if (uuidCodes.length > 0) {
            const { data: semCourses } = await supabase.from(courseTable).select('id, course_code').in('id', uuidCodes);
            if (semCourses) {
              const courseMap: Record<string, string> = {};
              semCourses.forEach((s: any) => courseMap[s.id] = s.course_code);
              marksData.forEach((m: CourseMark) => {
                if (courseMap[m.course_code]) {
                  m.course_code = courseMap[m.course_code];
                }
              });
            }
          }
          
          const filteredMarks = marksData.filter((m: CourseMark) => m.course_code && m.course_code.length <= 15 && !m.course_code.includes('-'));
          setMarks(filteredMarks as CourseMark[]);
        }
      } catch (e) {
        console.error('Failed to fetch marks:', e);
      }
    } catch (err: any) {
      console.error('Critical fetch error:', err);
    }
    setLoading(false);
  }

  const handleSyncData = async () => {
    if (!id) return;
    setSyncing(true);
    try {
      const { data, error } = await supabase.functions.invoke('sync-academic-stats', {
        body: { user_id: id }
      });
      if (error) throw error;
      toast.success(`Sync complete: CGPA ${data?.cgpa ?? '?'}`, { duration: 4000 });
      fetchUser(id);
    } catch (err: any) {
      toast.error('Sync failed: ' + err.message);
    } finally {
      setSyncing(false);
    }
  };

  const handleRebuildSchedule = async () => {
    if (!id) return;
    setRebuilding(true);
    const toastId = toast.loading('Rebuilding schedule cache...');
    try {
      const { error } = await supabase.functions.invoke('sync-schedule', {
        body: { user_id: id }
      });
      if (error) throw error;
      toast.success('Schedule rebuilt successfully!', { id: toastId });
      fetchUser(id);
    } catch (err: any) {
      toast.error('Rebuild failed: ' + err.message, { id: toastId });
    } finally {
      setRebuilding(false);
    }
  };

  if (loading) {
    return (
      <div className="space-y-8 animate-in fade-in duration-500">
        <div className="flex justify-between items-center">
          <div className="flex items-center gap-4">
            <Skeleton className="w-12 h-12 rounded-2xl" />
            <div className="space-y-2">
              <Skeleton className="w-48 h-8" />
              <Skeleton className="w-32 h-4" />
            </div>
          </div>
          <div className="flex gap-2">
            <Skeleton className="w-24 h-10 rounded-xl" />
            <Skeleton className="w-32 h-10 rounded-xl" />
          </div>
        </div>
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
          <CardSkeleton />
          <CardSkeleton />
          <CardSkeleton />
          <CardSkeleton />
        </div>
      </div>
    );
  }

  if (!user) return <div className='text-center py-24'><h3 className='text-lg font-black text-slate-900'>User not found</h3></div>;

  const days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];

  return (
    <div className='space-y-8 animate-in fade-in duration-700'>
      {/* Header */}
      <div className='flex flex-col md:flex-row items-start md:items-center justify-between gap-6'>
        <div className='flex items-center gap-5'>
          <button 
            onClick={() => navigate('/users')} 
            className='p-3 bg-white border border-slate-200 rounded-2xl text-slate-600 hover:bg-slate-50 hover:shadow-md transition-all'
          >
            <ArrowLeft className='h-5 w-5' />
          </button>
          <div className="flex items-center gap-4">
            <div className="w-16 h-16 rounded-[1.5rem] bg-indigo-100 flex items-center justify-center font-black text-2xl text-indigo-500 shadow-inner">
               {user.full_name?.substring(0, 1)}
            </div>
            <div>
              <h1 className='text-3xl font-black text-slate-900 tracking-tight'>{user.full_name || 'Unknown User'}</h1>
              <div className="flex items-center gap-2 mt-1">
                <span className='text-[10px] font-black bg-indigo-50 text-indigo-500 px-2 py-0.5 rounded-full uppercase tracking-widest'>{user.student_id || 'N/A'}</span>
                <span className='text-[10px] font-black bg-slate-100 text-slate-500 px-2 py-0.5 rounded-full uppercase tracking-widest'>{user.track?.replace('_', ' ') || 'Tri-Semester'}</span>
              </div>
            </div>
          </div>
        </div>
        
        <div className='flex flex-wrap sm:flex-nowrap gap-2 w-full md:w-auto'>
          <button 
            onClick={startEditing} 
            className='flex-1 sm:flex-none flex items-center justify-center gap-2 px-5 py-3 bg-white border border-slate-200 text-slate-700 rounded-2xl hover:bg-slate-50 text-[10px] font-black uppercase tracking-widest shadow-sm transition-all'
          >
            <Edit className='h-4 w-4' />
            Edit Profile
          </button>
          <button 
            onClick={handleSyncData} 
            disabled={syncing} 
            className='flex-1 sm:flex-none flex items-center justify-center gap-2 px-5 py-3 bg-indigo-600 text-white rounded-2xl hover:bg-indigo-700 disabled:opacity-50 text-[10px] font-black uppercase tracking-widest shadow-lg shadow-indigo-100 transition-all'
          >
            <RefreshCw className={`h-4 w-4 ${syncing ? 'animate-spin' : ''}`} />
            {syncing ? 'Syncing...' : 'Sync Portal'}
          </button>
          <button 
            onClick={handleRebuildSchedule} 
            disabled={rebuilding} 
            className='flex-1 sm:flex-none flex items-center justify-center gap-2 px-5 py-3 bg-emerald-600 text-white rounded-2xl hover:bg-emerald-700 disabled:opacity-50 text-[10px] font-black uppercase tracking-widest shadow-lg shadow-emerald-100 transition-all'
          >
            <CalendarClock className={`h-4 w-4 ${rebuilding ? 'animate-spin' : ''}`} />
            {rebuilding ? 'Rebuilding...' : 'Fix Schedule'}
          </button>
        </div>
      </div>

      {/* Navigation Tabs - Scrollable on Mobile */}
      <div className='w-full overflow-x-auto hide-scrollbar -mx-4 px-4 sm:mx-0 sm:px-0'>
        <div className='bg-white/50 backdrop-blur-md p-1.5 rounded-[1.5rem] border border-slate-200/60 inline-flex gap-1 min-w-full sm:min-w-0'>
          {['overview', 'enrollments', 'schedule', 'history', 'tasks', 'marks'].map(tab => (
            <button 
              key={tab} 
              onClick={() => setActiveTab(tab)} 
              className={cn(
                'px-6 py-2.5 rounded-xl text-[10px] font-black uppercase tracking-widest transition-all whitespace-nowrap',
                activeTab === tab 
                ? 'bg-slate-900 text-white shadow-xl shadow-slate-200' 
                : 'text-slate-500 hover:text-slate-900 hover:bg-white'
              )}
            >
              {tab}
            </button>
          ))}
        </div>
      </div>

      {/* Tab Content */}
      <motion.div 
        key={activeTab}
        initial={{ opacity: 0, y: 10 }}
        animate={{ opacity: 1, y: 0 }}
        className='mt-2'
      >
        {activeTab === 'overview' && (
          <div className='grid grid-cols-1 lg:grid-cols-3 gap-8'>
            <div className="lg:col-span-2 space-y-8">
              <div className='grid grid-cols-1 md:grid-cols-2 gap-6'>
                <motion.div whileHover={{ y: -4 }} className='bg-white p-8 rounded-[2rem] shadow-sm border border-slate-100'>
                  <div className="flex items-center gap-4 mb-6">
                    <div className="p-3 bg-indigo-50 rounded-2xl">
                      <Shield className="w-6 h-6 text-indigo-600" />
                    </div>
                    <h3 className='text-lg font-black text-slate-900 tracking-tight'>Academic Standing</h3>
                  </div>
                  <dl className='space-y-6'>
                    <div>
                      <dt className='text-[10px] font-black text-slate-400 uppercase tracking-[0.15em] mb-1'>Selected Program</dt>
                      <dd className='text-sm font-bold text-slate-900'>{user.program_name || user.program_code || 'N/A'}</dd>
                    </div>
                    <div className='grid grid-cols-1 sm:grid-cols-2 gap-4 sm:gap-8'>
                      <div>
                        <dt className='text-[10px] font-black text-slate-400 uppercase tracking-[0.15em] mb-1'>Current CGPA</dt>
                        <dd className='text-2xl sm:text-3xl font-black text-indigo-600'>{user.cgpa?.toFixed(2) || '0.00'}</dd>
                      </div>
                      <div>
                        <dt className='text-[10px] font-black text-slate-400 uppercase tracking-[0.15em] mb-1'>Credits Earned</dt>
                        <dd className='text-2xl sm:text-3xl font-black text-slate-900'>{user.total_credits_earned || 0}</dd>
                      </div>
                    </div>
                  </dl>
                </motion.div>
                
                <motion.div whileHover={{ y: -4 }} className='bg-white p-8 rounded-[2rem] shadow-sm border border-slate-100'>
                  <div className="flex items-center gap-4 mb-6">
                    <div className="p-3 bg-emerald-50 rounded-2xl">
                      <Activity className="w-6 h-6 text-emerald-600" />
                    </div>
                    <h3 className='text-lg font-black text-slate-900 tracking-tight'>System Diagnostics</h3>
                  </div>
                  <div className='space-y-5'>
                    <div className='flex items-center justify-between p-3 bg-slate-50 rounded-2xl border border-slate-100'>
                      <span className='text-[10px] font-black text-slate-400 uppercase tracking-widest'>Onboarding</span>
                      <span className={cn(
                        'text-[10px] font-black px-3 py-1 rounded-full uppercase tracking-widest shadow-sm',
                        user.onboarding_status === 'completed' ? 'bg-emerald-500 text-white' : 'bg-amber-500 text-white'
                      )}>
                        {user.onboarding_status?.replace('_', ' ') || 'Unknown'}
                      </span>
                    </div>
                    <div className='flex items-center justify-between p-3 bg-slate-50 rounded-2xl border border-slate-100'>
                      <span className='text-[10px] font-black text-slate-400 uppercase tracking-widest'>Engagement</span>
                      <span className='text-sm font-black text-slate-900'>{user.app_open_count || 0} Sessions</span>
                    </div>
                    <div className='flex items-center justify-between p-3 bg-slate-50 rounded-2xl border border-slate-100'>
                      <span className='text-[10px] font-black text-slate-400 uppercase tracking-widest'>Last Sync</span>
                      <span className='text-xs font-bold text-slate-900'>{user.last_active_at ? new Date(user.last_active_at).toLocaleDateString() : 'Never'}</span>
                    </div>
                  </div>
                </motion.div>
              </div>

              {/* Quick Actions */}
              <div className="bg-slate-900 rounded-[2rem] p-8 shadow-xl text-white overflow-hidden relative group">
                <div className="absolute top-0 right-0 p-8 opacity-10 group-hover:scale-110 transition-transform">
                   <Zap className="w-32 h-32" />
                </div>
                <div className="relative z-10">
                  <h3 className='text-xl font-black tracking-tight mb-2'>Fast Recovery</h3>
                  <p className='text-indigo-200/70 text-xs font-medium mb-6 max-w-md'>If the user is reporting missing schedules or incorrect CGPA, use these force-recovery tools to rebuild their data state.</p>
                  <div className="flex flex-wrap gap-4">
                     <button onClick={handleSyncData} className="px-6 py-3 bg-white text-slate-900 rounded-2xl text-[10px] font-black uppercase tracking-widest hover:bg-indigo-50 transition-all flex items-center gap-2">
                        <RefreshCw className="w-3 h-3" /> Force Data Sync
                     </button>
                     <button onClick={handleRebuildSchedule} className="px-6 py-3 bg-indigo-500 text-white rounded-2xl text-[10px] font-black uppercase tracking-widest hover:bg-indigo-400 transition-all flex items-center gap-2">
                        <CalendarClock className="w-3 h-3" /> Regenerate Grid
                     </button>
                  </div>
                </div>
              </div>
            </div>

            {/* Sidebar / Timeline */}
            <div className="space-y-8">
              <div className='bg-white p-8 rounded-[2rem] shadow-sm border border-slate-100'>
                <h3 className='text-lg font-black text-slate-900 tracking-tight mb-6 flex items-center gap-3'>
                  <div className="w-2 h-2 rounded-full bg-indigo-500" />
                  Activity Timeline
                </h3>
                <div className='space-y-8 relative before:absolute before:left-[11px] before:top-2 before:bottom-2 before:w-[2px] before:bg-slate-100'>
                  {[
                    { label: 'Last App Session', date: user.last_active_at, icon: Clock, color: 'bg-indigo-500' },
                    { label: 'Account Registered', date: user.created_at, icon: Users, color: 'bg-emerald-500' }
                  ].map((event, i) => (
                    <div key={i} className="relative pl-10">
                      <div className={cn("absolute left-0 top-1 w-6 h-6 rounded-full flex items-center justify-center text-white z-10 shadow-lg", event.color)}>
                        <event.icon className="w-3 h-3" />
                      </div>
                      <div className="flex flex-col">
                        <span className="text-[10px] font-black text-slate-900 uppercase tracking-widest">{event.label}</span>
                        <span className="text-[10px] font-bold text-slate-400 mt-1">
                          {event.date ? new Date(event.date).toLocaleString([], { dateStyle: 'medium', timeStyle: 'short' }) : 'Pending...'}
                        </span>
                      </div>
                    </div>
                  ))}
                  
                  <div className="relative pl-10 opacity-50">
                     <div className="absolute left-0 top-1 w-6 h-6 rounded-full bg-slate-200 flex items-center justify-center text-slate-400 z-10">
                        <Shield className="w-3 h-3" />
                     </div>
                     <div className="flex flex-col">
                        <span className="text-[10px] font-black text-slate-400 uppercase tracking-widest">Initial Onboarding</span>
                        <span className="text-[10px] font-bold text-slate-300 mt-1 italic">Historical logs not available</span>
                     </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        )}

        {activeTab === 'schedule' && (
          <div className='space-y-6'>
            {!semesterState?.weekly_grid_cache ? (
              <div className='bg-amber-50 border border-amber-200 p-12 rounded-[2rem] text-center'>
                <div className="w-16 h-16 bg-white rounded-2xl flex items-center justify-center mx-auto mb-6 shadow-sm">
                  <AlertTriangle className='h-8 w-8 text-amber-500' />
                </div>
                <h3 className='text-xl font-black text-amber-900'>No Schedule Cache Found</h3>
                <p className='text-amber-700/70 text-sm font-medium mt-2 max-w-md mx-auto'>
                  The mobile app won't show any classes because the schedule hasn't been generated for this user in the current semester.
                </p>
                <button 
                  onClick={handleRebuildSchedule} 
                  className='mt-8 px-8 py-3 bg-amber-600 text-white rounded-2xl font-black text-xs uppercase tracking-widest hover:bg-amber-700 transition-all shadow-lg shadow-amber-100'
                >
                  Generate Schedule Now
                </button>
              </div>
            ) : (
              <div className='grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6'>
                {days.map(day => {
                  const dailyClasses = semesterState.weekly_grid_cache![day] || [];
                  return (
                    <motion.div 
                      key={day} 
                      whileHover={{ y: -4 }}
                      className='bg-white rounded-[2rem] shadow-sm border border-slate-100 overflow-hidden flex flex-col'
                    >
                      <div className='px-6 py-4 bg-slate-50/50 border-b border-slate-50 font-black text-[10px] text-slate-400 uppercase tracking-widest'>{day}</div>
                      <div className='p-6 space-y-4 min-h-[200px]'>
                        {dailyClasses.length === 0 ? (
                          <div className='h-full flex flex-col items-center justify-center text-[10px] text-slate-300 font-bold uppercase tracking-widest py-8'>
                             <Clock className="w-8 h-8 opacity-10 mb-2" />
                             No classes
                          </div>
                        ) : (
                          dailyClasses.map((cls, idx) => (
                            <div key={idx} className='p-4 bg-slate-50 border border-slate-100 rounded-2xl group hover:bg-white hover:border-indigo-100 transition-all'>
                              <div className='flex justify-between items-start mb-2'>
                                <span className='text-xs font-black text-slate-900'>{cls.courseCode}</span>
                                <span className='text-[8px] bg-white px-2 py-0.5 rounded-full border border-slate-200 text-slate-400 font-black uppercase tracking-widest'>{cls.type}</span>
                              </div>
                              <p className='text-[10px] font-bold text-slate-500 line-clamp-1 mb-3'>{cls.courseName}</p>
                              <div className='flex items-center gap-2 text-[10px] text-indigo-500 font-black mb-3'>
                                <Clock className='w-3 h-3' />
                                {cls.startTime} - {cls.endTime}
                              </div>
                              <div className='flex items-center justify-between mt-auto pt-2 border-t border-slate-100'>
                                <span className='text-[9px] font-black text-slate-900 bg-white px-2 py-1 rounded-lg border border-slate-100'>{cls.room}</span>
                                <span className='text-[9px] text-indigo-400 font-black uppercase tracking-tighter'>{cls.faculty}</span>
                              </div>
                            </div>
                          ))
                        )}
                      </div>
                    </motion.div>
                  );
                })}
              </div>
            )}
          </div>
        )}

        {activeTab === 'enrollments' && (
          <div className='bg-white p-8 rounded-[2rem] shadow-sm border border-slate-100'>
            <div className="flex items-center justify-between mb-8">
              <h3 className='text-xl font-black text-slate-900 tracking-tight'>Current Semester Enrollments</h3>
              <div className="px-4 py-1.5 bg-emerald-50 text-emerald-600 rounded-full text-[10px] font-black uppercase tracking-widest">Live Session</div>
            </div>
            <div className='grid grid-cols-1 md:grid-cols-2 gap-6'>
              {currentEnrollments.length > 0 ? currentEnrollments.map((enr, i) => (
                <motion.div 
                  key={i} 
                  whileHover={{ y: -2 }}
                  className='border border-slate-100 rounded-[2rem] p-6 flex justify-between items-center bg-slate-50/50 hover:bg-white hover:border-indigo-100 hover:shadow-md transition-all group'
                >
                  <div className="flex items-center gap-4">
                    <div className="w-12 h-12 rounded-2xl bg-white shadow-sm flex items-center justify-center font-black text-indigo-500 border border-slate-100">
                       {i + 1}
                    </div>
                    <div>
                      <h4 className='font-black text-slate-900'>{enr.course_code} <span className="text-indigo-500 text-xs ml-1">Section {enr._sectionDetails?.section_number || (enr as any).section || 'N/A'}</span></h4>
                      <p className='text-[10px] font-bold text-slate-400 uppercase tracking-widest mt-1'>{enr._sectionDetails?.course_name || 'Generic Enrollment Record'}</p>
                    </div>
                  </div>
                  <div className='flex items-center gap-3'>
                    <button 
                      onClick={() => handleDeleteEnrollment(enr.id)}
                      className='p-3 text-slate-300 hover:text-rose-500 hover:bg-rose-50 rounded-2xl transition-all'
                      title='Remove enrollment'
                    >
                      <Trash2 className='w-5 h-5' />
                    </button>
                  </div>
                </motion.div>
              )) : (
                <div className="md:col-span-2 py-12 text-center">
                   <div className="w-16 h-16 bg-slate-50 rounded-2xl flex items-center justify-center mx-auto mb-4">
                      <BookOpen className="w-8 h-8 text-slate-300" />
                   </div>
                   <p className='text-slate-400 font-bold text-sm uppercase tracking-widest'>No active enrollments found</p>
                </div>
              )}
            </div>
          </div>
        )}

        {activeTab === 'history' && (
          <div className='bg-white rounded-[2rem] shadow-sm border border-slate-100 overflow-hidden'>
            <div className='px-8 py-6 border-b border-slate-50 flex items-center justify-between bg-slate-50/30'>
              <div>
                <h3 className='text-lg font-black text-slate-900 tracking-tight'>Academic History</h3>
                <p className="text-[10px] font-bold text-slate-400 uppercase tracking-widest">Complete course records from previous semesters</p>
              </div>
              <button 
                onClick={startAddingCourse}
                className='flex items-center gap-2 px-5 py-2.5 bg-indigo-600 text-white rounded-2xl hover:bg-indigo-700 text-[10px] font-black uppercase tracking-widest transition-all shadow-lg shadow-indigo-100'
              >
                <Plus className='w-4 h-4' />
                Add Record
              </button>
            </div>
            <div className='overflow-x-auto'>
              <table className='w-full'>
                <thead className="bg-slate-50/50">
                  <tr>
                    <th className='text-left px-8 py-4 text-[10px] font-black text-slate-400 uppercase tracking-widest'>Semester</th>
                    <th className='text-left px-8 py-4 text-[10px] font-black text-slate-400 uppercase tracking-widest'>Course Info</th>
                    <th className='text-left px-8 py-4 text-[10px] font-black text-slate-400 uppercase tracking-widest'>Grade</th>
                    <th className='text-left px-8 py-4 text-[10px] font-black text-slate-400 uppercase tracking-widest text-center'>Credits</th>
                    <th className='text-right px-8 py-4 text-[10px] font-black text-slate-400 uppercase tracking-widest'>Actions</th>
                  </tr>
                </thead>
                <tbody className='divide-y divide-slate-50'>
                  {completedCourses.map((c, i) => (
                    <tr key={i} className='hover:bg-slate-50/50 group transition-colors'>
                      <td className='px-8 py-5'>
                        <span className="text-xs font-black text-slate-900">{c.semester_code}</span>
                      </td>
                      <td className='px-8 py-5'>
                        <div className="font-black text-sm text-slate-900">{c.course_code}</div>
                        <div className="flex items-center gap-2 mt-0.5">
                          <div className={cn(
                            "text-[9px] font-bold uppercase tracking-widest",
                            ['F', 'W', 'I'].includes(c.grade) ? "text-slate-400" : "text-indigo-500"
                          )}>
                            {['F', 'W', 'I'].includes(c.grade) ? 'Attempted' : 'Passed'}
                          </div>
                          {completedCourses.filter(cc => cc.course_code.toUpperCase() === c.course_code.toUpperCase()).length > 1 && (
                            <span className="text-[8px] bg-amber-100 text-amber-600 px-1.5 py-0.5 rounded font-black uppercase tracking-tighter flex items-center gap-1">
                              <RefreshCw className="w-2 h-2" /> Retake
                            </span>
                          )}
                        </div>
                      </td>
                      <td className='px-8 py-5'>
                        <span className={cn(
                          'px-3 py-1 rounded-lg font-black text-xs border',
                          c.grade === 'F' ? 'bg-rose-50 text-rose-500 border-rose-100' : 'bg-emerald-50 text-emerald-600 border-emerald-100'
                        )}>{c.grade}</span>
                      </td>
                      <td className='px-8 py-5 text-center'>
                        <span className="text-sm font-black text-slate-700">{c.credits}</span>
                      </td>
                      <td className='px-8 py-5 text-right'>
                        <button 
                          onClick={() => handleDeleteCourse(c.id)}
                          className='p-2 text-slate-300 hover:text-rose-500 hover:bg-rose-50 rounded-xl transition-colors'
                        >
                          <Trash2 className='w-4 h-4' />
                        </button>
                      </td>
                    </tr>
                  ))}
                  {completedCourses.length === 0 && (
                    <tr>
                      <td colSpan={5} className='py-16 text-center'>
                         <div className="text-slate-300 font-bold text-sm uppercase tracking-widest italic">No academic history records</div>
                      </td>
                    </tr>
                  )}
                </tbody>
              </table>
            </div>
          </div>
        )}

        {activeTab === 'tasks' && (
          <div className='bg-white p-8 rounded-[2rem] shadow-sm border border-slate-100'>
            <h3 className='text-lg font-black text-slate-900 tracking-tight mb-8'>Student Task Ledger</h3>
            <div className='grid grid-cols-1 md:grid-cols-2 gap-4'>
              {tasks.length > 0 ? tasks.map((t, i) => (
                <div key={i} className='flex items-center justify-between p-5 border border-slate-100 rounded-[1.5rem] bg-slate-50/50 hover:bg-white hover:shadow-md transition-all'>
                  <div className='flex items-center gap-4'>
                    <div className={cn(
                      "w-10 h-10 rounded-xl flex items-center justify-center shadow-sm",
                      t.is_completed ? "bg-emerald-500 text-white" : t.is_missed ? "bg-rose-500 text-white" : "bg-amber-500 text-white"
                    )}>
                      {t.is_completed ? <CheckCircle2 className='h-5 w-5' /> : t.is_missed ? <AlertTriangle className='h-5 w-5' /> : <Clipboard className='h-5 w-5' />}
                    </div>
                    <div>
                      <p className='font-black text-slate-900 text-sm'>{t.title}</p>
                      <p className='text-[10px] font-bold text-indigo-500 uppercase tracking-widest'>{t.course_code}</p>
                    </div>
                  </div>
                  <div className="text-right">
                    <span className='text-[10px] font-black text-slate-400 uppercase tracking-widest'>{new Date(t.due_date).toLocaleDateString([], { month: 'short', day: 'numeric' })}</span>
                  </div>
                </div>
              )) : (
                <div className="md:col-span-2 py-12 text-center text-slate-300 font-bold text-sm uppercase tracking-widest">
                   Clean Task List
                </div>
              )}
            </div>
          </div>
        )}

        {activeTab === 'marks' && (
          <div className='bg-white p-8 rounded-[2rem] shadow-sm border border-slate-100'>
            <div className="flex items-center justify-between mb-8">
              <h3 className='text-xl font-black text-slate-900 tracking-tight'>Portal Performance Data</h3>
              <div className="px-4 py-1.5 bg-indigo-50 text-indigo-600 rounded-full text-[10px] font-black uppercase tracking-widest">Live Grade Report</div>
            </div>
            
            <div className='grid grid-cols-1 xl:grid-cols-2 gap-8'>
              {marks.length > 0 ? marks.map((m: any, i) => {
                const components = [
                  { key: 'mid', label: 'Midterm', obt: m.obt_mid, dist: m.dist_mid },
                  { key: 'final', label: 'Final', obt: m.obt_final, dist: m.dist_final },
                  { key: 'assignment', label: 'Assignment', obt: m.obt_assignment, dist: m.dist_assignment },
                  { key: 'attendance', label: 'Attendance', obt: m.obt_attendance, dist: m.dist_attendance },
                  { key: 'lab', label: 'Lab', obt: m.obt_lab, dist: m.dist_lab },
                  { key: 'presentation', label: 'Presentation', obt: m.obt_presentation, dist: m.dist_presentation },
                  { key: 'viva', label: 'Viva', obt: m.obt_viva, dist: m.dist_viva },
                  { key: 'project', label: 'Project', obt: m.obt_project, dist: m.dist_project },
                  { key: 'term_paper', label: 'Term Paper', obt: m.obt_term_paper, dist: m.dist_term_paper },
                  { key: 'class_performance', label: 'Class Performance', obt: m.obt_class_performance, dist: m.dist_class_performance },
                ];

                const activeComponents = components.filter(c => c.dist && c.dist > 0);

                return (
                  <motion.div 
                    key={i} 
                    whileHover={{ scale: 1.01 }}
                    className='border border-slate-100 rounded-[2.5rem] overflow-hidden bg-slate-50/50 shadow-sm'
                  >
                    <div className='px-8 py-6 bg-white border-b border-slate-100 flex items-center justify-between'>
                      <div>
                        <h4 className='font-black text-slate-900 text-lg'>{m.course_code}</h4>
                        <p className="text-[9px] font-bold text-slate-400 uppercase tracking-widest">Graded Component Breakdown</p>
                      </div>
                      <span className='text-[10px] font-black px-3 py-1 bg-indigo-50 text-indigo-600 rounded-full border border-indigo-100 uppercase tracking-widest'>{m.semester_code}</span>
                    </div>
                    
                    <div className='p-8 space-y-3'>
                      {m.dist_quiz && m.dist_quiz > 0 && (
                        <div className='bg-white p-5 rounded-2xl border border-slate-100 shadow-sm group hover:border-indigo-100 transition-all'>
                          <div className='flex justify-between items-center'>
                            <div>
                               <span className="text-[10px] font-black text-slate-400 uppercase tracking-widest block mb-1">Quizzes ({m.quiz_strategy === 'best_n' ? `Best ${m.quiz_n}` : m.quiz_strategy === 'average_n' ? `Avg of ${m.quiz_n}` : 'All'})</span>
                               <div className="flex gap-1">
                                  {m.obt_quizzes?.map((q: any, qi: number) => (
                                     <span key={qi} className="px-2 py-0.5 bg-slate-50 border border-slate-100 rounded text-[10px] font-black text-slate-900">{q}</span>
                                  ))}
                               </div>
                            </div>
                            <span className='text-lg font-black text-indigo-600'>{(m.obt_quizzes?.reduce((a:number,b:number)=>a+b,0)/ (m.obt_quizzes?.length || 1)).toFixed(1)} <span className="text-slate-300 text-xs font-bold">/ {m.dist_quiz}</span></span>
                          </div>
                        </div>
                      )}

                      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                        {activeComponents.map((comp, idx) => (
                          <div key={idx} className='bg-white p-4 rounded-2xl border border-slate-100 flex flex-col justify-center shadow-sm group hover:border-indigo-100 transition-all'>
                            <span className='text-[10px] font-black text-slate-400 uppercase tracking-widest block mb-1'>{comp.label}</span>
                            <div className="flex items-baseline gap-1">
                               <span className='text-lg font-black text-slate-900'>{comp.obt ?? '-'}</span>
                               <span className="text-xs font-bold text-slate-300">/ {comp.dist}</span>
                            </div>
                          </div>
                        ))}
                      </div>
                    </div>
                  </motion.div>
                );
              }) : (
                <div className="xl:col-span-2 py-24 text-center">
                   <div className="w-20 h-20 bg-slate-50 rounded-3xl flex items-center justify-center mx-auto mb-6">
                      <GraduationCap className="w-10 h-10 text-slate-200" />
                   </div>
                   <p className="text-slate-300 font-bold text-sm uppercase tracking-widest">No graded performance data synced yet</p>
                </div>
              )}
            </div>
          </div>
        )}
      </motion.div>

      {isEditingProfile && (
        <div className='fixed inset-0 bg-black/50 backdrop-blur-sm z-50 flex items-center justify-center p-4'>
          <div className='bg-white rounded-2xl shadow-xl w-full max-w-2xl overflow-hidden'>
            <div className='px-6 py-4 border-b border-gray-100 flex items-center justify-between bg-gray-50'>
              <h3 className='text-lg font-bold text-gray-900'>Edit Student Profile</h3>
              <button onClick={() => setIsEditingProfile(false)} className='p-2 hover:bg-gray-200 rounded-full transition-colors'>
                <X className='h-5 w-5 text-gray-500' />
              </button>
            </div>
            <div className='p-6 space-y-4 max-h-[70vh] overflow-y-auto'>
              <div className='grid grid-cols-1 md:grid-cols-2 gap-4'>
                <div className='space-y-1'>
                  <label className='text-xs font-bold text-gray-500 uppercase'>Full Name</label>
                  <input 
                    type='text' 
                    value={editForm.full_name || ''} 
                    onChange={e => setEditForm({...editForm, full_name: e.target.value})}
                    className='w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 outline-none'
                  />
                </div>
                <div className='space-y-1'>
                  <label className='text-xs font-bold text-gray-500 uppercase'>Student ID</label>
                  <input 
                    type='text' 
                    value={editForm.student_id || ''} 
                    onChange={e => setEditForm({...editForm, student_id: e.target.value})}
                    className='w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 outline-none'
                  />
                </div>
                <div className='space-y-1 md:col-span-2'>
                  <label className='text-xs font-bold text-gray-500 uppercase'>Select Program</label>
                  <select 
                    value={editForm.program_code || ''} 
                    onChange={e => {
                      const prog = availablePrograms.find(p => p.program_code === e.target.value);
                      if (prog) {
                        setEditForm({
                          ...editForm, 
                          program_code: prog.program_code,
                          program_name: prog.name,
                          department_name: prog.department_name,
                          track: prog.track
                        });
                      } else {
                        setEditForm({...editForm, program_code: e.target.value});
                      }
                    }}
                    className='w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 outline-none'
                  >
                    <option value=''>-- Choose a Program --</option>
                    {availablePrograms.map(p => (
                      <option key={p.program_code} value={p.program_code}>{p.program_code} - {p.name}</option>
                    ))}
                  </select>
                </div>
                <div className='space-y-1'>
                  <label className='text-xs font-bold text-gray-500 uppercase'>Program Name (Display)</label>
                  <input 
                    type='text' 
                    value={editForm.program_name || ''} 
                    onChange={e => setEditForm({...editForm, program_name: e.target.value})}
                    className='w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 outline-none bg-gray-50'
                  />
                </div>
                <div className='space-y-1'>
                  <label className='text-xs font-bold text-gray-500 uppercase'>Department Name (Display)</label>
                  <input 
                    type='text' 
                    value={editForm.department_name || ''} 
                    onChange={e => setEditForm({...editForm, department_name: e.target.value})}
                    className='w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 outline-none bg-gray-50'
                  />
                </div>
                <div className='space-y-1'>
                  <label className='text-xs font-bold text-gray-500 uppercase'>CGPA</label>
                  <input 
                    type='number' 
                    step='0.01'
                    value={editForm.cgpa || 0} 
                    onChange={e => setEditForm({...editForm, cgpa: parseFloat(e.target.value)})}
                    className='w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 outline-none'
                  />
                </div>
                <div className='space-y-1'>
                  <label className='text-xs font-bold text-gray-500 uppercase'>Total Credits</label>
                  <input 
                    type='number' 
                    value={editForm.total_credits_earned || 0} 
                    onChange={e => setEditForm({...editForm, total_credits_earned: parseInt(e.target.value)})}
                    className='w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 outline-none'
                  />
                </div>
                <div className='space-y-1'>
                  <label className='text-xs font-bold text-gray-500 uppercase'>Track</label>
                  <select 
                    value={editForm.track || 'tri_semester'} 
                    onChange={e => setEditForm({...editForm, track: e.target.value as any})}
                    className='w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 outline-none'
                  >
                    <option value='tri_semester'>Tri-Semester</option>
                    <option value='bi_semester'>Bi-Semester</option>
                  </select>
                </div>
                <div className='space-y-1'>
                  <label className='text-xs font-bold text-gray-500 uppercase'>Onboarding Status</label>
                  <select 
                    value={editForm.onboarding_status || 'registered'} 
                    onChange={e => setEditForm({...editForm, onboarding_status: e.target.value})}
                    className='w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 outline-none'
                  >
                    <option value='registered'>Registered</option>
                    <option value='course_history'>Course History</option>
                    <option value='completed'>Completed</option>
                  </select>
                </div>
              </div>
            </div>
            <div className='px-6 py-4 border-t border-gray-100 flex items-center justify-end gap-3 bg-gray-50'>
              <button 
                onClick={() => setIsEditingProfile(false)}
                className='px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-100 rounded-lg transition-colors'
              >
                Cancel
              </button>
              <button 
                onClick={handleUpdateProfile}
                disabled={saving}
                className='flex items-center gap-2 px-6 py-2 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700 disabled:opacity-50 text-sm font-bold shadow-md shadow-indigo-200 transition-all'
              >
                {saving ? <RefreshCw className='h-4 w-4 animate-spin' /> : <Save className='h-4 w-4' />}
                {saving ? 'Saving...' : 'Save Changes'}
              </button>
            </div>
          </div>
        </div>
      )}

      {isAddingCourse && (
        <div className='fixed inset-0 bg-black/50 backdrop-blur-sm z-50 flex items-center justify-center p-4'>
          <div className='bg-white rounded-2xl shadow-xl w-full max-w-md overflow-hidden'>
            <div className='px-6 py-4 border-b border-gray-100 flex items-center justify-between bg-gray-50'>
              <h3 className='text-lg font-bold text-gray-900'>Add Course Record</h3>
              <button onClick={() => setIsAddingCourse(false)} className='p-2 hover:bg-gray-200 rounded-full transition-colors'>
                <X className='h-5 w-5 text-gray-500' />
              </button>
            </div>
            <div className='p-6 space-y-4'>
              <div className='space-y-1'>
                <label className='text-xs font-bold text-gray-500 uppercase'>Semester Code</label>
                <input 
                  type='text' 
                  placeholder='e.g. Summer 2026'
                  value={courseForm.semester_code || ''} 
                  onChange={e => setCourseForm({...courseForm, semester_code: e.target.value})}
                  className='w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 outline-none'
                />
              </div>
              <div className='space-y-1'>
                <label className='text-xs font-bold text-gray-500 uppercase'>Course Code</label>
                <input 
                  type='text' 
                  placeholder='e.g. CSE103'
                  value={courseForm.course_code || ''} 
                  onChange={e => setCourseForm({...courseForm, course_code: e.target.value.toUpperCase()})}
                  className='w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 outline-none'
                />
              </div>
              <div className='grid grid-cols-2 gap-4'>
                <div className='space-y-1'>
                  <label className='text-xs font-bold text-gray-500 uppercase'>Grade</label>
                  <select 
                    value={courseForm.grade || 'A'} 
                    onChange={e => setCourseForm({...courseForm, grade: e.target.value})}
                    className='w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 outline-none'
                  >
                    {['A', 'A-', 'B+', 'B', 'B-', 'C+', 'C', 'C-', 'D+', 'D', 'F', 'I', 'W'].map(g => (
                      <option key={g} value={g}>{g}</option>
                    ))}
                  </select>
                </div>
                <div className='space-y-1'>
                  <label className='text-xs font-bold text-gray-500 uppercase'>Credits</label>
                  <input 
                    type='number' 
                    step='0.5'
                    value={courseForm.credits || 3.0} 
                    onChange={e => setCourseForm({...courseForm, credits: parseFloat(e.target.value)})}
                    className='w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 outline-none'
                  />
                </div>
              </div>
            </div>
            <div className='px-6 py-4 border-t border-gray-100 flex items-center justify-end gap-3 bg-gray-50'>
              <button 
                onClick={() => setIsAddingCourse(false)}
                className='px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-100 rounded-lg transition-colors'
              >
                Cancel
              </button>
              <button 
                onClick={handleAddCourse}
                disabled={saving || !courseForm.course_code || !courseForm.semester_code}
                className='flex items-center gap-2 px-6 py-2 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700 disabled:opacity-50 text-sm font-bold shadow-md'
              >
                {saving ? <RefreshCw className='h-4 w-4 animate-spin' /> : <Plus className='h-4 w-4' />}
                {saving ? 'Adding...' : 'Add Record'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
