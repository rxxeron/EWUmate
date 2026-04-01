import { useEffect, useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { supabase } from '../lib/supabase';
import { ArrowLeft, GraduationCap, BookOpen, History, Activity } from 'lucide-react';

export function UserDetails() {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const [user, setUser] = useState<any>(null);
  const [completedCourses, setCompletedCourses] = useState<any[]>([]);
  const [currentEnrollments, setCurrentEnrollments] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

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
      
      // Fetch exact enrollments if UUIDs are present
      if (userData.enrolled_sections && userData.enrolled_sections.length > 0) {
        const { data: enrollmentsData } = await supabase
          .from('enrollments')
          .select('*')
          .in('id', userData.enrolled_sections);
          
        if (enrollmentsData) {
          // Fetch sections from semester-specific tables to get section numbers
          const sectionIds = enrollmentsData.map((e: any) => e.section_id).filter(Boolean);
          
          if (sectionIds.length > 0) {
            const sectionsMap: Record<string, any> = {};
            const { data: springData } = await supabase.from('courses_spring2026').select('id, section_number, course_name').in('id', sectionIds);
            const { data: summerData } = await supabase.from('courses_summer2026').select('id, section_number, course_name').in('id', sectionIds);
            
            if (springData) springData.forEach((s: any) => sectionsMap[s.id] = s);
            if (summerData) summerData.forEach((s: any) => sectionsMap[s.id] = s);
            
            enrollmentsData.forEach((e: any) => {
               if (e.section_id && sectionsMap[e.section_id]) {
                  e._sectionDetails = sectionsMap[e.section_id];
               }
            });
          }

          setCurrentEnrollments(enrollmentsData);
        }
      }
    }

    // Fetch exact completed courses
    const { data: coursesData, error: coursesError } = await supabase
      .from('completed_courses')
      .select('*')
      .eq('user_id', userId)
      .order('semester_code', { ascending: false });

    if (!coursesError && coursesData) {
      setCompletedCourses(coursesData);
    }

    setLoading(false);
  }

  if (loading) {
    return <div className="p-8 text-center text-gray-500 font-medium animate-pulse">Loading user profile...</div>;
  }

  if (!user) {
    return (
      <div className="p-8 text-center">
        <h2 className="text-2xl font-bold text-red-600 mb-4">User Not Found</h2>
        <button onClick={() => navigate('/users')} className="text-indigo-600 hover:text-indigo-800 font-medium">
          &larr; Back to Users
        </button>
      </div>
    );
  }

  return (
    <div className="max-w-5xl mx-auto space-y-6">
      {/* Header */}
      <div className="flex items-center gap-4 mb-6">
        <button 
          onClick={() => navigate(-1)} 
          className="p-2 bg-white rounded-full shadow-sm hover:bg-gray-50 border border-gray-200 transition-colors"
          title="Go Back"
        >
          <ArrowLeft className="w-5 h-5 text-gray-600" />
        </button>
        <div>
          <h1 className="text-3xl font-extrabold text-gray-900 tracking-tight">{user.full_name || 'Unknown Student'}</h1>
          <p className="text-indigo-600 font-medium flex items-center gap-2 mt-1">
            {user.student_id ? `ID: ${user.student_id}` : 'No Student ID'} 
            <span className="text-gray-300">•</span>
            <span className="text-gray-500">{user.nickname ? `"${user.nickname}"` : ''}</span>
          </p>
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        
        {/* Left Column: Academic Summary & Status */}
        <div className="space-y-6">
          <div className="bg-white rounded-xl shadow-sm border border-gray-100 p-6">
            <h3 className="text-lg font-bold text-gray-800 border-b border-gray-100 pb-3 mb-4 flex items-center gap-2">
              <GraduationCap className="w-5 h-5 text-indigo-500" />
              Academic Standing
            </h3>
            <div className="space-y-4">
              <div>
                <p className="text-sm font-medium text-gray-500 uppercase tracking-wider">Program</p>
                <p className="text-gray-900 font-medium mt-1">{user.program_name || user.program_code || 'N/A'}</p>
                <p className="text-sm text-gray-500 mt-0.5">{user.department_name || 'No department info'}</p>
              </div>
              <div className="grid grid-cols-2 gap-4 pt-2 border-t border-gray-50">
                <div>
                  <p className="text-xs font-semibold text-gray-500 uppercase tracking-wider">CGPA</p>
                  <p className="text-2xl font-bold text-gray-900 mt-1">{user.cgpa?.toFixed(2) || '0.00'}</p>
                </div>
                <div>
                  <p className="text-xs font-semibold text-gray-500 uppercase tracking-wider">Credits</p>
                  <p className="text-2xl font-bold text-gray-900 mt-1">{user.total_credits_earned || '0'}</p>
                </div>
              </div>
            </div>
          </div>

          <div className="bg-white rounded-xl shadow-sm border border-gray-100 p-6">
            <h3 className="text-lg font-bold text-gray-800 border-b border-gray-100 pb-3 mb-4 flex items-center gap-2">
              <Activity className="w-5 h-5 text-emerald-500" />
              App Status
            </h3>
            <div className="space-y-3">
              <div className="flex justify-between items-center">
                <span className="text-sm text-gray-500">Onboarding</span>
                <span className={`px-2.5 py-1 text-xs font-semibold rounded-full ${user.onboarding_status === 'onboarded' ? 'bg-green-100 text-green-800' : 'bg-yellow-100 text-yellow-800'}`}>
                  {user.onboarding_status || 'Pending'}
                </span>
              </div>
              <div className="flex justify-between items-center">
                <span className="text-sm text-gray-500">Joined Date</span>
                <span className="text-sm font-medium text-gray-900">
                  {new Date(user.created_at).toLocaleDateString()}
                </span>
              </div>
              <div className="flex justify-between items-center">
                <span className="text-sm text-gray-500">Last Active</span>
                <span className="text-sm font-medium text-gray-900">
                  {new Date(user.updated_at).toLocaleDateString()}
                </span>
              </div>
              <div className="flex justify-between items-center">
                <span className="text-sm text-gray-500">Scholarship</span>
                <span className="text-sm font-medium text-gray-900">{user.scholarship_status || 'None'}</span>
              </div>
            </div>
          </div>
        </div>

        {/* Right Column: Detailed Info (Enrollments & History) */}
        <div className="md:col-span-2 space-y-6">
          
          <div className="bg-white rounded-xl shadow-sm border border-gray-100 overflow-hidden">
             <div className="px-6 py-4 border-b border-gray-100 bg-gray-50/50 flex items-center justify-between">
                <h3 className="text-lg font-bold text-gray-800 flex items-center gap-2">
                  <BookOpen className="w-5 h-5 text-blue-500" />
                  Current Enrollments
                </h3>
                <span className="text-sm font-semibold bg-blue-100 text-blue-800 px-2 py-1 rounded-md">
                  {user.enrolled_credits || 0} Current Credits
                </span>
             </div>
             <div className="p-0 max-h-[400px] overflow-y-auto">
               {(!user.enrolled_sections || user.enrolled_sections.length === 0) ? (
                 <p className="p-6 text-gray-500 text-center italic">No active course enrollments found for this semester.</p>
               ) : (
                 <ul className="divide-y divide-gray-100">
                   {user.enrolled_sections.map((sec: any, idx: number) => {
                     // Check if it's a string (e.g. "Spring2026_ENG102_1" or "uuid")
                     if (typeof sec === 'string') {
                       // Try to find the matched enrollment data from the database
                       const matchingEnrollment = currentEnrollments.find((e: any) => e.id === sec);
                       
                       if (matchingEnrollment) {
                         const secDetails = matchingEnrollment._sectionDetails;
                         const sectionNum = secDetails?.section_number || 'N/A';
                         const courseName = secDetails?.course_name;
                         
                         return (
                           <li key={idx} className="p-4 px-6 hover:bg-gray-50 transition-colors">
                             <div className="flex justify-between items-start">
                               <div>
                                 <p className="text-sm font-bold text-gray-900">{matchingEnrollment.course_code || 'Unknown'}</p>
                                 {courseName && <p className="text-xs text-gray-600 mt-0.5">{courseName}</p>}
                                 <p className="text-xs text-gray-500 mt-1 max-w-[200px] truncate" title={matchingEnrollment.id}>ID: <span className="font-mono text-[10px] bg-gray-100 px-1 rounded">{matchingEnrollment.id.substring(0,8)}...</span></p>
                               </div>
                               <div className="text-right flex flex-col items-end gap-1.5">
                                 <span className="inline-flex items-center px-2 py-1 rounded text-[10px] font-semibold bg-blue-50 text-blue-700">
                                   Section {sectionNum}
                                 </span>
                                 <span className="inline-flex items-center px-2 py-1 rounded text-[10px] font-semibold bg-indigo-50 text-indigo-700 uppercase">
                                   {matchingEnrollment.semester_code || matchingEnrollment.status || 'Enrolled'}
                                 </span>
                               </div>
                             </div>
                           </li>
                         );
                       }

                       // Fallback to split logic if missing from DB or not a UUID
                       const parts = sec.split('_');
                       if (parts.length >= 2) {
                         const courseCode = parts[1];
                         const sectionNum = parts.length >= 3 ? parts[2] : 'N/A';
                         return (
                           <li key={idx} className="p-4 px-6 hover:bg-gray-50 transition-colors">
                             <div className="flex justify-between items-start">
                               <div>
                                 <p className="text-sm font-bold text-gray-900">{courseCode}</p>
                                 <p className="text-xs text-gray-500 mt-1 uppercase tracking-wider">{parts[0]}</p>
                               </div>
                               <div className="text-right">
                                 <span className="inline-flex items-center px-2 py-1 rounded text-xs font-semibold bg-blue-50 text-blue-700">
                                   Section {sectionNum}
                                 </span>
                               </div>
                             </div>
                           </li>
                         );
                       } else {
                         // Raw UUID without a DB record
                         return (
                           <li key={idx} className="p-4 px-6 hover:bg-red-50/50 transition-colors bg-gray-50/30">
                             <div className="flex justify-between items-start">
                               <div>
                                 <p className="text-sm font-bold text-red-800">Orphaned Enrollment</p>
                                 <p className="text-xs font-mono text-gray-500 mt-1 truncate max-w-[200px]">{sec}</p>
                               </div>
                               <div className="text-right">
                                 <span className="inline-flex items-center px-2 py-1 rounded text-[10px] font-bold bg-red-100 text-red-600">
                                   ID Only
                                 </span>
                               </div>
                             </div>
                           </li>
                         );
                       }
                     }
                     // Fallback if it actually is an object in some cases
                     return (
                       <li key={idx} className="p-4 px-6 hover:bg-gray-50 transition-colors">
                         <div className="flex justify-between items-start">
                           <div>
                             <p className="text-sm font-bold text-gray-900">{sec.course_code || 'Unknown Course'}</p>
                             <p className="text-sm text-gray-600 mt-1">{sec.course_title || 'No Title'}</p>
                           </div>
                           <div className="text-right">
                             <span className="inline-flex items-center px-2 py-1 rounded text-xs font-semibold bg-gray-100 text-gray-800">
                               Section {sec.section || 'N/A'}
                             </span>
                             <p className="text-xs text-gray-500 mt-2">{sec.credits ? `${sec.credits} Credits` : ''}</p>
                           </div>
                         </div>
                       </li>
                     );
                   })}
                 </ul>
               )}
             </div>
          </div>

          <div className="bg-white rounded-xl shadow-sm border border-gray-100 overflow-hidden">
             <div className="px-6 py-4 border-b border-gray-100 bg-gray-50/50 flex items-center justify-between">
                <h3 className="text-lg font-bold text-gray-800 flex items-center gap-2">
                  <History className="w-5 h-5 text-amber-500" />
                  Academic History Summary
                </h3>
                <span className="text-sm font-semibold bg-amber-100 text-amber-800 px-2 py-1 rounded-md">
                  {completedCourses.length || 0} Courses Completed
                </span>
             </div>
             <div className="p-6">
                {(!completedCourses || completedCourses.length === 0) ? (
                 <p className="text-gray-500 text-center italic py-4">No past academic history synced yet.</p>
                ) : (
                  <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 max-h-[300px] overflow-y-auto pr-2">
                    {completedCourses.map((record: any, idx: number) => {
                      return (
                        <div key={idx} className="border border-gray-200 rounded-lg p-3 bg-gray-50">
                          <p className="text-xs font-bold text-indigo-600 uppercase tracking-widest mb-1">{record.semester_code || 'Unknown Semester'}</p>
                          <p className="text-sm text-gray-800 font-medium truncate" title={record.course_code}>{record.course_code}</p>
                          <div className="flex justify-between items-center mt-2">
                            <span className="text-xs text-gray-500">Grade: <span className="font-bold text-gray-800">{record.grade || '-'}</span></span>
                            <span className="text-xs text-gray-500">Cr: {record.credits || '-'}</span>
                          </div>
                        </div>
                      );
                    })}
                  </div>
                )}
             </div>
          </div>

        </div>
      </div>
    </div>
  );
}