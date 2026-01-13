import React, { createContext, useState, useEffect, useRef } from 'react';
import { doc, getDoc, collection, getDocs, query, where, onSnapshot } from 'firebase/firestore';
import { onAuthStateChanged } from 'firebase/auth';
import { db, auth } from '../firebaseConfig';
import { scheduleClassAlarms } from '../utils/notifications';

export const CourseContext = createContext();

export const CourseProvider = ({ children }) => {
  const [user, setUser] = useState(null);
  const [schedules, setSchedules] = useState([]);
  const [tasks, setTasks] = useState([]);
  const [holidays, setHolidays] = useState([]);
  const [semesterConfig, setSemesterConfig] = useState(null);
  const [loading, setLoading] = useState(true);
  
  // Ref to hold the user document listener so we can unsubscribe properly
  const userUnsubscribeRef = useRef(null);

  // Auto-calculate the semester ID based on today's date
  const [currentSemesterId, setCurrentSemesterId] = useState(() => {
    const now = new Date();
    const year = now.getFullYear();
    const month = now.getMonth() + 1; // 1-12

    // Conservative Strategy: 
    // Always default to the "ending" semester during transition months (May, Sept, Jan)
    // so we can read its calendar to find the exact "University Opens" date for the next one.
    
    // Jan (01): Could be Fall (prev year) or Spring. Usually Spring starts mid-Jan.
    // If Jan, let's assume Spring for simplicity, or check strict date.
    // May (05): Default to Spring.
    // Sept (09): Default to Summer.
    
    if (month <= 5) return `Spring${year}`;
    if (month > 5 && month <= 9) return `Summer${year}`;
    return `Fall${year}`;
  });

  // Schedule notifications whenever schedules change
  useEffect(() => {
    if (schedules.length > 0) {
      scheduleClassAlarms(schedules);
    }
  }, [schedules]);

  useEffect(() => {
    // 1. Initialize App with Auto-Detected Semester
    const initApp = async () => {
      try {
        console.log(`Auto-detected Active Semester: ${currentSemesterId}`);
        
        // 2. Check Auth
        const unsubscribeAuth = onAuthStateChanged(auth, async (currentUser) => {
          setUser(currentUser);
          if (currentUser) {
            await fetchUserData(currentUser.uid, currentSemesterId);
          } else {
            setSchedules([]);
            setLoading(false);
            // Cleanup user listener if logged out
            if (userUnsubscribeRef.current) {
                userUnsubscribeRef.current();
                userUnsubscribeRef.current = null;
            }
          }
        });
        
        // Return cleanup function to useEffect
        return () => {
            unsubscribeAuth();
            if (userUnsubscribeRef.current) {
                userUnsubscribeRef.current();
            }
        };
      } catch (e) {
        console.error("Init Error:", e);
      }
    };
    
    // We need to handle the promise returned by initApp to get the cleanup function
    const cleanupPromise = initApp();
    
    return () => {
        cleanupPromise.then(cleanup => cleanup && cleanup());
    };
  }, [currentSemesterId]); // Re-run if date calculations somehow change (rare in session)

  const fetchUserData = async (uid, semesterId) => {
    try {
      setLoading(true);
      
      const calendarCollection = `calendar_${semesterId}`;
      const calendarMetaRef = doc(db, calendarCollection, 'CALENDAR_META');
      const calendarSnap = await getDoc(calendarMetaRef);
      
      if (calendarSnap.exists()) {
        const data = calendarSnap.data();
        // data.allEvents and data.allDates are arrays.
        // We probably need to format them into a list of holiday objects { date, title }
        // For now, let's just assume we want to pass the raw dates or map them.
        // The dashboard expects: holidays array.
        
        // Let's try to map the simple logic from function output if possible, 
        // or just fetch all 'CALENDAR_EVENT' type docs if meta isn't sufficient.
        
        // Actually, let's fetch individual events if we want robust data
        // For efficiency, let's use the META if available.
        if (data.allEvents && data.allDates) {
            const mappedHolidays = data.allDates.map((dateStr, index) => ({
                date: dateStr,
                title: data.allEvents[index] || "Holiday"
            }));
            setHolidays(mappedHolidays);

            // INTELLIGENT SEMESTER SWITCHING
            // Check for "University Opens", "Reopens" or "Classes Begin" for the NEXT semester
            const nextSemKeywords = [
                "University Opens", 
                "University Reopens", 
                "Classes Begin", 
                "Semester Begins",
                "First Day of Classes",
                "Orientation for" 
            ];
            const nextSemInfo = mappedHolidays.find(h => 
                nextSemKeywords.some(kw => h.title.includes(kw))
            );

            if (nextSemInfo) {
                const switchDate = new Date(nextSemInfo.date);
                const now = new Date();
                
                // If today is AFTER or ON the start date of the detected event
                if (now >= switchDate) {
                    // Extract target semester from title if possible, or infer
                    // e.g. "University Reopens for Summer 2026"
                    const lowerTitle = nextSemInfo.title.toLowerCase();
                    const currentYear = now.getFullYear();
                    
                    // Try to extract year from title directly (e.g. "2026")
                    const yearMatch = nextSemInfo.title.match(/20\d{2}/);
                    const targetYear = yearMatch ? yearMatch[0] : currentYear;

                    let nextId = null;

                    if (lowerTitle.includes("summer")) nextId = `Summer${targetYear}`;
                    else if (lowerTitle.includes("fall")) nextId = `Fall${targetYear}`;
                    else if (lowerTitle.includes("spring")) {
                        // If we are in Fall (late year) and see Spring, it's likely next year
                        // But if we found the year in the string, use that (safest).
                        // If no year found in string, and we are in Dec, add 1.
                        const finalYear = yearMatch ? targetYear : (now.getMonth() > 9 ? currentYear + 1 : currentYear);
                        nextId = `Spring${finalYear}`;
                    }

                    // Verify we aren't already on that semester
                    if (nextId && nextId !== semesterId) {
                        console.log(`🚀 Auto-Switching Semester from ${semesterId} to ${nextId} based on Calendar Date: ${nextSemInfo.date}`);
                        setCurrentSemesterId(nextId);
                        // The state update will trigger useEffect -> re-run initApp -> re-fetch data
                        return; // Stop processing this old semester's data
                    }
                }
            }
        }

        // Extrapolate Semester Dates from Calendar Meta if available
        // Expected format in Meta: { semesterStart: "YYYY-MM-DD", advisingStart: "YYYY-MM-DD" }
        // If not present, we can try to guess from the holiday list (first/last), but explicit is better.
        if (data.semesterStart || data.advisingStart) {
             setSemesterConfig({
                 semesterStart: data.semesterStart,
                 advisingStart: data.advisingStart
             });
        }
      } else {
         // Fallback: Query collection
         const calQ = query(collection(db, calendarCollection));
         const calDocs = await getDocs(calQ);
         const evts = [];
         calDocs.forEach(d => {
             const val = d.data();
             if(val.type === 'CALENDAR_EVENT') {
                 evts.push({ date: val.date, title: val.event });
             }
         });
         setHolidays(evts);
      }

      // 2. Fetch User's Enrolled Courses from Firestore
      const userRef = doc(db, 'users', uid);
      
      // Clear any existing listener
      if (userUnsubscribeRef.current) {
          userUnsubscribeRef.current();
      }

      // Listen to user document changes in real-time
      const unsubscribeUser = onSnapshot(userRef, async (userSnap) => {
          if (userSnap.exists()) {
            const userData = userSnap.data();
            
            // Merge Firestore profile data into user state
            setUser(prevUser => ({
                ...prevUser,
                ...userData
            }));

            const enrolledSections = userData.enrolledSections || []; 
            const userTasks = userData.tasks || [];
            
            // Sort tasks by date (soonest first)
            userTasks.sort((a,b) => new Date(a.dueDate) - new Date(b.dueDate));
            setTasks(userTasks);
            
            if (enrolledSections.length > 0) {
                const coursesCollectionName = `courses_${semesterId}`;
                const coursesRef = collection(db, coursesCollectionName);
                
                // Batch query to handle > 10 courses
                const fetchedCourses = [];
                const chunks = [];
                // Create chunks of 10
                for (let i = 0; i < enrolledSections.length; i += 10) {
                    chunks.push(enrolledSections.slice(i, i + 10));
                }

                try {
                    const promises = chunks.map(chunk => {
                        const q = query(coursesRef, where('docId', 'in', chunk));
                        return getDocs(q);
                    });
                    
                    const snapshots = await Promise.all(promises);
                    snapshots.forEach(snap => {
                        snap.forEach(doc => fetchedCourses.push(doc.data()));
                    });
                    
                    setSchedules(fetchedCourses);
                } catch (err) {
                    console.error("Error fetching courses batch:", err);
                }
            } else {
                setSchedules([]);
            }
          }
          setLoading(false);
      });
      
      userUnsubscribeRef.current = unsubscribeUser;

    } catch (error) {
      console.error("Error fetching data:", error);
      setLoading(false);
    }
  };

  return (
    <CourseContext.Provider value={{ user, schedules, tasks, holidays, semesterConfig, loading, currentSemesterId }}>
      {children}
    </CourseContext.Provider>
  );
};
