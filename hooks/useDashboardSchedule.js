import { useState, useEffect } from 'react';
import { format, addDays, isBefore, parse } from 'date-fns';

/**
 * Custom Hook: useDashboardSchedule
 * Implements the "Smart" Dashboard logic: 8 PM Rule, Disappear Rule, Chill Mode.
 * 
 * @param {Array} enrolledCourses - List of user's courses with schedule objects.
 * @param {Array} holidays - List of holiday objects { date: "YYYY-MM-DD", name: "Holiday Name" }
 * @returns {Object} { scheduleForDisplay, status, targetDateDisplay, holidayReason }
 */
export const useDashboardSchedule = (enrolledCourses, holidays = []) => {
  const [scheduleForDisplay, setScheduleForDisplay] = useState([]);
  const [status, setStatus] = useState('loading'); // 'loading' | 'subsequent' | 'chill' | 'holiday'
  const [targetDateDisplay, setTargetDateDisplay] = useState('');
  const [holidayReason, setHolidayReason] = useState(null);

  useEffect(() => {
    if (!enrolledCourses) return;

    // 1. establish "now"
    const now = new Date();
    const currentHour = now.getHours();

    // 2. The 8 PM Rule
    // If it's past 8 PM (20:00), we show tomorrow's schedule.
    let targetDate = now;
    let isTomorrow = false;

    if (currentHour >= 20) {
      targetDate = addDays(now, 1);
      isTomorrow = true;
    }

    const targetDayName = format(targetDate, 'EEEE'); // "Sunday", "Monday", etc.
    const targetDateString = format(targetDate, 'yyyy-MM-dd'); // For holiday check

    setTargetDateDisplay(isTomorrow ? `Tomorrow, ${format(targetDate, 'MMM do')}` : `Today, ${format(targetDate, 'MMM do')}`);

    // 2.5 Check for Holidays
    const holiday = holidays.find(h => h.date === targetDateString);
    if (holiday) {
      setStatus('holiday');
      setHolidayReason(holiday.name);
      setScheduleForDisplay([]);
      return;
    } else {
      setHolidayReason(null);
    }

    // Helper: Normalize Day Matching
    // Handles "ST" -> Sunday/Tuesday, "MW" -> Mon/Wed, "S" -> Sunday, etc.
    const isClassToday = (scheduleDay, targetDateDayName) => {
       if (!scheduleDay) return false;
       const sDay = scheduleDay.toUpperCase();
       const tDay = targetDateDayName.toUpperCase(); // SUNDAY, MONDAY...

       if (tDay === 'SUNDAY') return sDay.includes('SU') || (sDay.includes('S') && !sDay.includes('SAT'));
       if (tDay === 'MONDAY') return sDay.includes('M') && !sDay.includes('MAR');
       if (tDay === 'TUESDAY') return sDay.includes('T') && !sDay.includes('TH');
       if (tDay === 'WEDNESDAY') return sDay.includes('W');
       if (tDay === 'THURSDAY') return sDay.includes('TH') || sDay.includes('R');
       if (tDay === 'FRIDAY') return sDay.includes('F');
       if (tDay === 'SATURDAY') return sDay.includes('SAT') || sDay.includes('SA');
       
       return false;
    };

    // Helper: Parse Time to 24h for comparison
    const get24HTime = (timeStr) => {
        try {
            // cleaning
            const clean = timeStr.trim().toUpperCase();
            // If already HH:mm (24h), e.g. "14:30"
            if (!clean.includes('AM') && !clean.includes('PM') && clean.includes(':')) {
                return clean;
            }
            // Parse "02:30 PM"
            const parsed = parse(clean, 'hh:mm a', new Date());
            if (isNaN(parsed)) return timeStr; // fallback
            return format(parsed, 'HH:mm');
        } catch (e) {
            return timeStr;
        }
    };

    // 3. Filter courses for the target day
    let dailyCourses = enrolledCourses.flatMap(course => {
      // Find schedule entries that match the target day
      const dailySchedules = course.schedule.filter(s => isClassToday(s.day, targetDayName));
      
      return dailySchedules.map(sch => ({
        ...course,
        ...sch, // Flatten startTime, endTime, day into the object
        originalCourse: course
      }));
    });

    // 4. The Disappear Rule
    // If we are looking at "Today", filter out classes that have already ended.
    if (!isTomorrow) {
      const currentTimeString = format(now, 'HH:mm'); // e.g. "14:30"
      
      dailyCourses = dailyCourses.filter(cls => {
        // Convert class end time to 24h format for comparison
        const clsEnd24 = get24HTime(cls.endTime);
        return clsEnd24 >= currentTimeString;
      });
    }

    // Sort by start time (converting to comparable values)
    dailyCourses.sort((a, b) => get24HTime(a.startTime).localeCompare(get24HTime(b.startTime)));

    // 5. Chill Mode
    if (dailyCourses.length === 0) {
      setStatus('chill');
      setScheduleForDisplay([]);
    } else {
      setStatus('subsequent');
      setScheduleForDisplay(dailyCourses);
    }

  }, [enrolledCourses, holidays]);

  return { scheduleForDisplay, status, targetDateDisplay, holidayReason };
};
