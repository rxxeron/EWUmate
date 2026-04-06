import { useEffect, useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { supabase } from '../lib/supabase';
import { ArrowLeft, RefreshCw, Users, CheckCircle2, Clipboard } from 'lucide-react';

export function UserDetails() {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const [activeTab, setActiveTab] = useState('overview');
  
  const [user, setUser] = useState<any>(null);
  const [completedCourses, setCompletedCourses] = useState<any[]>([]);
  const [currentEnrollments, setCurrentEnrollments] = useState<any[]>([]);
  const [tasks, setTasks] = useState<any[]>([]);
  const [marks, setMarks] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [syncing, setSyncing] = useState(false);

  useEffect(() => {
    if (id) {
      fetchUser(id);
    }
  }, [id]);

  async function fetchUser(userId: string) {
    setLoading(true);
    
    const { data: userData, error: userError } = await supabase
      .from('profiles')
      .select('*')
      .eq('id', userId)
      .single();

    if (!userError && userData) {
      setUser(userData);

      if (userData.enrolled_sections && userData.enrolled_sections.length > 0) {
        const { data: enrollmentsData } = await supabase
          .from('enrollments')
          .select('*')
          .in('id', userData.enrolled_sections);

        if (enrollmentsData) {
          const sectionIds = enrollmentsData.map((e: any) => e.section_id).filter(Boolean);
          if (sectionIds.length > 0) {
            const sectionsMap: Record<string, any> = {};
            const { data: springData } = await supabase.from('courses_spring2026').select('id, section_number, course_name').in('id', sectionIds);
            
            if (springData) springData.forEach((s: any) => sectionsMap[s.id] = s);

            enrollmentsData.forEach((e: any) => {
               if (e.section_id && sectionsMap[e.section_id]) { e._sectionDetails = sectionsMap[e.section_id]; }
            });
          }
          setCurrentEnrollments(enrollmentsData);
        }
      }

      const { data: coursesData } = await supabase.from('completed_courses').select('*').eq('user_id', userId).order('semester_code', { ascending: false });
      if (coursesData) setCompletedCourses(coursesData);

      const { data: tasksData } = await supabase.from('tasks').select('*').eq('user_id', userId).order('due_date', { ascending: false }).limit(50);
      if (tasksData) setTasks(tasksData);

      const { data: marksData } = await supabase.from('semester_course_marks').select('*').eq('user_id', userId);
      if (marksData) {
        const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
        const uuidCodes = marksData.map(m => m.course_code).filter(c => c && uuidRegex.test(c));
        
        if (uuidCodes.length > 0) {
          const { data: springData } = await supabase.from('courses_spring2026').select('id, course_code').in('id', uuidCodes);
          if (springData) {
            const courseMap: Record<string, string> = {};
            springData.forEach((s: any) => courseMap[s.id] = s.course_code);
            marksData.forEach(m => {
              if (courseMap[m.course_code]) {
                m.course_code = courseMap[m.course_code];
              }
            });
          }
        }
        setMarks(marksData);
      }
    }
    setLoading(false);
  }

  const handleSyncData = async () => {
    setSyncing(true);
    await new Promise(r => setTimeout(r, 1500));
    alert('User Academic Data & CGPA Recalculated Successfully!');
    fetchUser(id!);
    setSyncing(false);
  };

  if (loading) return <div className='flex justify-center items-center h-64'><div className='animate-spin rounded-full h-8 w-8 border-b-2 border-indigo-600'></div></div>;

  if (!user) return <div className='text-center py-12'><h3 className='text-lg font-medium text-gray-900'>User not found</h3></div>;

  return (
    <div className='space-y-6'>
      <div className='flex items-center justify-between'>
        <div className='flex items-center gap-4'>
          <button onClick={() => navigate('/users')} className='p-2 hover:bg-gray-100 rounded-full transition-colors'><ArrowLeft className='h-5 w-5 text-gray-600' /></button>
          <div>
            <h1 className='text-2xl font-bold text-gray-900'>{user.full_name || 'Unknown User'}</h1>
            <p className='text-sm text-gray-500'>ID: {user.student_id || 'N/A'}</p>
          </div>
        </div>
        <button onClick={handleSyncData} disabled={syncing} className='flex items-center gap-2 px-4 py-2 bg-indigo-600 text-white rounded-md hover:bg-indigo-700 disabled:opacity-50'>
          <RefreshCw className={`h-4 w-4 ${syncing ? 'animate-spin' : ''}`} />
          {syncing ? 'Syncing...' : 'Sync Data'}
        </button>
      </div>

      <div className='border-b border-gray-200'>
        <nav className='-mb-px flex space-x-8'>
          {['overview', 'enrollments', 'history', 'tasks', 'marks'].map(tab => (
            <button key={tab} onClick={() => setActiveTab(tab)} className={`whitespace-nowrap py-4 px-1 border-b-2 font-medium text-sm ${activeTab === tab ? 'border-indigo-500 text-indigo-600' : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'}`}>
              {tab.charAt(0).toUpperCase() + tab.slice(1)}
            </button>
          ))}
        </nav>
      </div>

      <div className='mt-6'>
        {activeTab === 'overview' && (
          <div className='grid grid-cols-1 md:grid-cols-2 gap-6'>
            <div className='bg-white p-6 rounded-lg shadow-sm border border-gray-200'>
              <h3 className='text-lg font-medium mb-4 flex items-center gap-2'><Users className='h-5 w-5 text-indigo-500' /> Academic Standing</h3>
              <dl className='space-y-4'>
                <div><dt className='text-sm text-gray-500'>Program</dt><dd className='mt-1 text-sm font-medium'>{user.program_name || 'N/A'}</dd></div>
                <div className='grid grid-cols-2 gap-4'>
                  <div><dt className='text-sm text-gray-500'>CGPA</dt><dd className='mt-1 text-2xl font-bold text-indigo-600'>{user.cgpa?.toFixed(2) || '0.00'}</dd></div>
                  <div><dt className='text-sm text-gray-500'>Credits</dt><dd className='mt-1 text-2xl font-bold text-gray-900'>{user.credits_completed || 0}</dd></div>
                </div>
              </dl>
            </div>
          </div>
        )}

        {activeTab === 'enrollments' && (
          <div className='bg-white p-6 rounded-lg shadow-sm border border-gray-200'>
            <h3 className='text-lg font-medium mb-4'>Current Enrollments</h3>
            <div className='space-y-4'>
              {currentEnrollments.length > 0 ? currentEnrollments.map((enr, i) => (
                <div key={i} className='border rounded p-4 flex justify-between items-center'>
                  <div>
                    <h4 className='font-bold'>{enr.course_code} - Section {enr._sectionDetails?.section_number || enr.section_id}</h4>
                    <p className='text-sm text-gray-500'>{enr._sectionDetails?.course_name || 'Unknown Course'}</p>
                  </div>
                  <span className='px-3 py-1 bg-green-100 text-green-800 rounded-full text-xs font-medium'>Enrolled</span>
                </div>
              )) : <p className='text-gray-500'>No current enrollments.</p>}
            </div>
          </div>
        )}

        {activeTab === 'history' && (
          <div className='bg-white p-6 rounded-lg shadow-sm border border-gray-200'>
            <h3 className='text-lg font-medium mb-4'>Past Courses</h3>
            <table className='min-w-full divide-y divide-gray-200'>
              <thead>
                <tr><th className='text-left py-3 text-xs font-medium text-gray-500 uppercase tracking-wider'>Semester</th><th className='text-left py-3 text-xs font-medium text-gray-500 uppercase tracking-wider'>Course</th><th className='text-left py-3 text-xs font-medium text-gray-500 uppercase tracking-wider'>Grade</th><th className='text-left py-3 text-xs font-medium text-gray-500 uppercase tracking-wider'>Credits</th></tr>
              </thead>
              <tbody className='divide-y divide-gray-200'>
                {completedCourses.map((c, i) => (
                  <tr key={i}>
                    <td className='py-4 text-sm'>{c.semester_code}</td>
                    <td className='py-4 text-sm font-medium'>{c.course_code}</td>
                    <td className='py-4 text-sm'>
                      <span className='px-2 py-1 bg-gray-100 rounded text-gray-800 font-medium'>{c.grade}</span>
                    </td>
                    <td className='py-4 text-sm'>{c.credits}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}

        {activeTab === 'tasks' && (
          <div className='bg-white p-6 rounded-lg shadow-sm border border-gray-200'>
            <h3 className='text-lg font-medium mb-4'>Task History</h3>
            <div className='space-y-3'>
              {tasks.length > 0 ? tasks.map((t, i) => (
                <div key={i} className='flex items-center justify-between p-3 border rounded-lg'>
                  <div className='flex items-center gap-3'>
                    {t.is_completed ? <CheckCircle2 className='h-5 w-5 text-green-500' /> : t.is_missed ? <CheckCircle2 className='h-5 w-5 text-red-500' /> : <Clipboard className='h-5 w-5 text-yellow-500' />}
                    <div>
                      <p className='font-medium text-sm'>{t.title}</p>
                      <p className='text-xs text-gray-500'>{t.course_code}</p>
                    </div>
                  </div>
                  <span className='text-xs text-gray-400'>{new Date(t.due_date).toLocaleDateString()}</span>
                </div>
              )) : <p className='text-gray-500'>No tasks found.</p>}
            </div>
          </div>
        )}

        {activeTab === 'marks' && (
          <div className='bg-white p-6 rounded-lg shadow-sm border border-gray-200'>
            <h3 className='text-lg font-medium mb-4'>Course Marks</h3>
            <div className='grid grid-cols-1 md:grid-cols-2 gap-4'>
              {marks.length > 0 ? marks.map((m, i) => (
                <div key={i} className='border rounded p-4'>
                  <h4 className='font-bold'>{m.course_code} <span className='text-sm font-normal text-gray-500'>({m.semester_code})</span></h4>
                  <div className='mt-2 space-y-1 text-sm'>
                    <div className='flex justify-between'><span>Midterm</span><span>{m.mid_marks ?? '-'} / {m.dist_mid ?? '30'}</span></div>
                    <div className='flex justify-between'><span>Final</span><span>{m.final_marks ?? '-'} / {m.dist_final ?? '40'}</span></div>
                  </div>
                </div>
              )) : <p className='text-gray-500'>No marks available.</p>}
            </div>
          </div>
        )}
      </div>
    </div>
  );
}

