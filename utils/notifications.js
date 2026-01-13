import * as Notifications from 'expo-notifications';
import * as Device from 'expo-device';
import Constants from 'expo-constants';
import { Platform } from 'react-native';
import { differenceInMinutes, parseISO, subHours, subMinutes, parse, nextDay, isBefore, addWeeks, setHours, setMinutes } from 'date-fns';

// 1. Configure how notifications appear when app is in foreground
Notifications.setNotificationHandler({
  handleNotification: async () => ({
    shouldShowAlert: true,
    shouldPlaySound: true,
    shouldSetBadge: false,
  }),
});

// 2. Register for Push Notifications (Get Permission)
export async function registerForPushNotificationsAsync() {
  if (Platform.OS === 'android') {
    // 1. Default Channel
    await Notifications.setNotificationChannelAsync('default', {
      name: 'Default',
      importance: Notifications.AndroidImportance.MAX,
      vibrationPattern: [0, 250, 250, 250],
      lightColor: '#FF231F7C',
    });

    // 2. Alarm Channel (High Priority, Sound) for 8:30 Classes
    await Notifications.setNotificationChannelAsync('alarm-channel', {
      name: 'Class Alarm',
      importance: Notifications.AndroidImportance.MAX,
      sound: true,
      vibrationPattern: [0, 500, 200, 500, 200, 500, 1000, 500, 200, 500], // Long vibration
      enableVibrate: true,
      lockscreenVisibility: Notifications.AndroidNotificationVisibility.PUBLIC,
      audioAttributes: { usage: Notifications.AndroidAudioUsage.ALARM }
    });

    // 3. Vibration Channel (High Sensitive Vibration, No Sound) for Regular Classes
    await Notifications.setNotificationChannelAsync('vibration-channel', {
      name: 'Class Alert',
      importance: Notifications.AndroidImportance.HIGH,
      sound: null, // No Sound
      enableVibrate: true,
      vibrationPattern: [0, 100, 50, 100, 50, 100, 50, 100], // Rapid "High Sensitive" Vibration
    });
  }

  // Set action categories (e.g., Stop Alarm)
  await Notifications.setNotificationCategoryAsync('alarm-actions', [
      { identifier: 'STOP_ALARM', buttonTitle: 'STOP', options: { isDestructive: true } },
  ]);

  if (Device.isDevice) {
    const { status: existingStatus } = await Notifications.getPermissionsAsync();
    let finalStatus = existingStatus;
    
    if (existingStatus !== 'granted') {
      const { status } = await Notifications.requestPermissionsAsync();
      finalStatus = status;
    }
    
    if (finalStatus !== 'granted') {
      // alert('Failed to get push token for push notification!');
      return;
    }
  }
}

// 3. Class Schedule Logic
export async function scheduleClassAlarms(courses) {
    // To avoid duplicates, we should ideally cancel old class notifications
    // But cancelling ALL might kill task notifications. 
    // Best practice: Store notification IDs or use a specific identifier logic.
    // For this prototype, we'll assume we wipe class-related IDs if we had storage, 
    // but here we just append schedules. Note: Running this multiple times will duplicate alerts.
    
    // Day Map
    const dayMap = { 'Sunday': 0, 'Monday': 1, 'Tuesday': 2, 'Wednesday': 3, 'Thursday': 4, 'Friday': 5, 'Saturday': 6 };
    const now = new Date();

    for (const course of courses) {
        if (!course.schedule) continue;

        for (const sch of course.schedule) {
            // sch.day (e.g., "Monday"), sch.startTime (e.g., "08:30" or "08:30 AM")
            if (!sch.day || !sch.startTime) continue;

            const targetDayIdx = dayMap[sch.day];
            if (targetDayIdx === undefined) continue;

            // Clean Time
            let cleanTime = sch.startTime.replace(/\s+/g, '').toUpperCase();
            // Handle AM/PM or 24h
            let hours = 0, minutes = 0;
            
            try {
                // Try parsing "08:30" or "08:30AM"
                const parsedTime = parse(cleanTime, cleanTime.includes('M') ? 'hh:mma' : 'HH:mm', new Date());
                hours = parsedTime.getHours();
                minutes = parsedTime.getMinutes();
            } catch (e) { console.log('Time parse error', sch.startTime); continue; }

            // Logic: Calculate next occurrence of this day/time
            // Start from Today
            let nextClassDate = setMinutes(setHours(new Date(), hours), minutes);
            
            // Adjust day
            const currentDayIdx = now.getDay();
            const diff = (targetDayIdx - currentDayIdx + 7) % 7;
            
            if (diff === 0) {
                 // It's today. If time has passed, add 1 week
                 if (isBefore(nextClassDate, now)) {
                     nextClassDate = addWeeks(nextClassDate, 1);
                 }
            } else {
                 nextClassDate = addWeeks(nextClassDate, 0); // Reset to base week
                 // Add diff days
                 nextClassDate.setDate(now.getDate() + diff); 
            }
            
            // Re-set time just in case setDate shifted something (rare with DST but possible)
            nextClassDate = setMinutes(setHours(nextClassDate, hours), minutes);

            // --- 8:30 AM Rule ---
            if (hours === 8 && minutes === 30) {
                // "Ring like alarm... from 7 am for 1 minute... break 15 mins... again ring"
                const alarmTimes = [
                    { time: setMinutes(setHours(new Date(nextClassDate), 7), 0), label: 'First Alarm' }, // 7:00
                    { time: setMinutes(setHours(new Date(nextClassDate), 7), 16), label: 'Second Alarm' }, // 7:16 (1 min ring + 15 min break)
                    // Add more if needed.
                ];

                for (const at of alarmTimes) {
                     if (isBefore(at.time, now)) continue; // Skip if alarm time passed already

                     await Notifications.scheduleNotificationAsync({
                         content: {
                             title: `⏰ WAKE UP! Class Alert`,
                             body: `You have ${course.courseName} class at 8:30! (Tap to Stop)`,
                             sound: true, 
                             categoryIdentifier: 'alarm-actions',
                             data: { type: 'ALARM' },
                             ...(Platform.OS === 'android' ? { channelId: 'alarm-channel' } : {})
                         },
                         trigger: { date: at.time }, 
                     });
                }

            } else {
                // --- Normal Rule ---
                // "Before 10-20 minutes" -> Let's pick 15 minutes
                const alertTime = subMinutes(nextClassDate, 15);
                if (isBefore(alertTime, now)) continue;

                await Notifications.scheduleNotificationAsync({
                    content: {
                        title: `Class Reminder`,
                        body: `You Have Class OF ${course.code || course.docId} at ${course.room} in 15 mins`,
                        shouldPlaySound: false, // No ring
                        data: { type: 'CLASS_REMINDER' },
                        ...(Platform.OS === 'android' ? { channelId: 'vibration-channel' } : {})
                    },
                    trigger: { date: alertTime }
                });
            }
        }
    }
}


// 3. Smart Scheduling Logic
export async function scheduleTaskNotification(task) {
  const { type, dueDate, courseCode, courseName } = task;
  const due = parseISO(dueDate);
  const now = new Date();

  const timeUntilDue = differenceInMinutes(due, now);
  if (timeUntilDue <= 0) return; // Cannot schedule for past

  let triggerSeconds = 0;
  let body = "";
  let title = `Upcoming ${type}`;

  const typeLower = type.toLowerCase();

  // Logic per User Requirement
  if (typeLower.includes('presentation')) {
      // "IF presentation then send a notification to be well prepared."
      // Schedule for 12 hours before (Preparation) OR 1 hour before?
      // Let's do a meaningful "Prep" time. say 4 hours before if possible.
      
      const prepTime = subHours(due, 4); // 4 hours before
      if (differenceInMinutes(prepTime, now) > 0) {
          triggerSeconds = differenceInMinutes(prepTime, now) * 60;
          body = `Be well prepared and dress sharply! Your ${courseCode} presentation is in 4 hours.`;
      } else {
          // If < 4 hours left, schedule for 15 mins from now? Or just ignore
          triggerSeconds = 0; // Immediate if enabled, or skip
      }

  } else if (typeLower.includes('quiz') || typeLower.includes('viva')) {
      // "IF quiz or viva then send a notification for being prepared before going for it."
      // 1 hour before
      const reminderTime = subHours(due, 1);
      if (differenceInMinutes(reminderTime, now) > 0) {
          triggerSeconds = differenceInMinutes(reminderTime, now) * 60;
          body = `Time to review your notes! ${type} for ${courseCode} starts in 1 hour.`;
      }

  } else if (typeLower.includes('assignment')) {
      // "IF assignment then send a last moment notification to check for the assignments properly"
      // "also here should be shown the left time for the due time and date"
      // 2 hours before
      const checkTime = subHours(due, 2);
      if (differenceInMinutes(checkTime, now) > 0) {
          triggerSeconds = differenceInMinutes(checkTime, now) * 60;
          body = `Last Moment Check! Assignment for ${courseCode} is due in 2 hours. Submit correctly!`;
      } else {
          // Fallback: 30 mins before if < 2 hours
          const urgent = subMinutes(due, 30);
           if (differenceInMinutes(urgent, now) > 0) {
              triggerSeconds = differenceInMinutes(urgent, now) * 60;
              body = `Hurry! Assignment due in 30 minutes!`;
           }
      }
  }

  // If we found a valid time to schedule
  if (triggerSeconds > 0 && body) {
      await Notifications.scheduleNotificationAsync({
        content: {
          title,
          body,
          data: { taskId: task.id },
        },
        trigger: { seconds: triggerSeconds },
      });
      console.log(`Scheduled notification for ${type} in ${triggerSeconds/60} minutes.`);
  }
}
