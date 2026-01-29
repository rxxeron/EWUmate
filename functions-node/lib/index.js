import functions from "firebase-functions";
import admin from "firebase-admin";
import { CloudTasksClient } from "@google-cloud/tasks";
import { format, addDays, startOfDay, parse } from 'date-fns';
import { utcToZonedTime, zonedTimeToUtc } from 'date-fns-tz';
admin.initializeApp();
const db = admin.firestore();
const tasksClient = new CloudTasksClient();
const PROJECT_ID = JSON.parse(process.env.FIREBASE_CONFIG || "{}").projectId;
const LOCATION = "us-central1";
const QUEUE = "notification-queue";
/**
 * Fetches the admin secret key from Firestore configuration.
 */
async function _getAdminSecret() {
    var _a;
    try {
        const doc = await db.collection('config').doc('admin').get();
        if (doc.exists) {
            return ((_a = doc.data()) === null || _a === void 0 ? void 0 : _a.secret_key) || '';
        }
        console.warn("Admin secret document not found in config/admin.");
        return '';
    }
    catch (error) {
        console.error("Error fetching admin secret:", error);
        return '';
    }
}
// --- 1. Notification Sending (Task Handler) ---
export const sendScheduledNotification = functions.https.onRequest(async (req, res) => {
    const { userId, fcmToken, title, body } = req.body;
    if (!userId || !fcmToken || !title || !body) {
        console.error("Invalid payload received:", req.body);
        res.status(400).send("Bad Request: Missing payload fields.");
        return;
    }
    // 1. Save to History
    try {
        await db.collection('users').doc(userId).collection('notifications').add({
            title,
            body,
            type: 'reminder',
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            read: false
        });
    }
    catch (e) {
        console.error("Error saving notification history:", e);
    }
    const message = {
        notification: { title, body },
        token: fcmToken,
        apns: { payload: { aps: { sound: "default" } } },
        android: { notification: { sound: "default" } },
    };
    try {
        console.log(`Sending notification to user ${userId}: "${body}"`);
        await admin.messaging().send(message);
        res.status(200).send("Notification sent successfully.");
    }
    catch (error) {
        console.error(`Failed to send notification to user ${userId}:`, error);
        res.status(200).send("Notification failed but task is acknowledged.");
    }
});
// --- 2. Task Notification Scheduling ---
// --- 2. Task Notification Scheduling ---
export const onTaskCreate = functions.firestore
    .document("users/{userId}/tasks/{taskId}")
    .onCreate(async (snap, context) => {
    var _a;
    const task = snap.data();
    const userId = context.params.userId;
    const taskId = context.params.taskId;
    if (!task || !task.dueDate)
        return;
    const userDoc = await db.collection("users").doc(userId).get();
    const fcmToken = (_a = userDoc.data()) === null || _a === void 0 ? void 0 : _a.fcmToken;
    if (!fcmToken)
        return;
    await scheduleForTask(userId, taskId, fcmToken, task);
});
async function scheduleForTask(userId, taskId, fcmToken, task) {
    const dueDateUTC = task.dueDate.toDate();
    const timeZone = "Asia/Dhaka";
    const courseName = task.courseName || "your course";
    const taskType = task.type || "task";
    const baseTitle = `Upcoming ${taskType}`;
    const zonedDueDate = utcToZonedTime(dueDateUTC, timeZone);
    const prevNight = new Date(zonedDueDate);
    prevNight.setDate(prevNight.getDate() - 1);
    prevNight.setHours(20, 0, 0, 0);
    const morningDue = new Date(zonedDueDate);
    morningDue.setHours(8, 0, 0, 0);
    const now = new Date();
    if (prevNight > now) {
        const body = `${taskType} for ${courseName} is due tomorrow.`;
        await scheduleNotificationTask(`task-prev-${userId}-${taskId}`, userId, fcmToken, baseTitle, body, prevNight);
    }
    if (morningDue > now) {
        const body = `${taskType} for ${courseName} is due today!`;
        await scheduleNotificationTask(`task-morn-${userId}-${taskId}`, userId, fcmToken, baseTitle, body, morningDue);
    }
}
// --- 3. Class Notification Scheduling ---
export const generateDailySchedule = functions.pubsub
    .schedule("0 20 * * *").timeZone("Asia/Dhaka")
    .onRun(() => runSchedulerLogic(true));
async function runSchedulerLogic(targetNextDay) {
    const usersSnap = await db.collection("users").get();
    if (usersSnap.empty)
        return;
    const timeZone = "Asia/Dhaka";
    const now = new Date();
    let targetDate = utcToZonedTime(now, timeZone);
    if (targetNextDay) {
        targetDate = addDays(targetDate, 1);
    }
    const targetDay = format(targetDate, 'EEEE');
    const dateString = format(targetDate, 'yyyy-MM-dd');
    console.log(`Scheduling class notifications for: ${targetDay}`);
    const promises = usersSnap.docs.map((doc) => processUserForNotifications(doc.id, doc.data(), targetDay, dateString));
    await Promise.all(promises);
}
// Helper to parse "09:30 AM" to minutes
const getMinutes = (timeStr) => {
    // timeStr: "09:30 AM" or "9:30 AM"
    const [t, m] = timeStr.trim().split(' ');
    const [hh, mm] = t.split(':').map(Number);
    let h = hh;
    if (m === 'PM' && h < 12)
        h += 12;
    if (m === 'AM' && h === 12)
        h = 0;
    return h * 60 + mm;
};
async function processUserForNotifications(userId, userData, targetDay, dateString) {
    const { fcmToken, weeklySchedule } = userData;
    const baseClasses = (weeklySchedule === null || weeklySchedule === void 0 ? void 0 : weeklySchedule[targetDay]) || [];
    if (!fcmToken)
        return;
    // --- Fetch User Exceptions for this date ---
    const exceptionsSnap = await db.collection("users").doc(userId).collection("schedule_exceptions")
        .where("date", "==", dateString)
        .get();
    const exceptions = exceptionsSnap.docs.map((d) => d.data());
    // 1. Identify cancelled course codes
    const cancelledCodes = exceptions
        .filter((ex) => ex.type === 'cancel' || ex.type === 'cancellation')
        .map((ex) => ex.courseCode.replace(/\s+/g, '').toUpperCase());
    // 2. Filter base classes and add makeups
    const finalClasses = baseClasses.filter((c) => {
        const code = c.courseCode.replace(/\s+/g, '').toUpperCase();
        return !cancelledCodes.includes(code);
    });
    const makeups = exceptions.filter((ex) => ex.type === 'makeup');
    for (const m of makeups) {
        finalClasses.push({
            title: m.courseName || m.courseCode,
            courseCode: m.courseCode,
            time: `${m.startTime}-${m.endTime}`,
            room: m.room || "TBA"
        });
    }
    if (!finalClasses.length)
        return;
    const targetDateStart = startOfDay(new Date(dateString));
    // 3. Sort Classes by Start Time
    const parsedClasses = finalClasses.map((c) => {
        const [startStr, endStr] = c.time.split('-');
        return Object.assign(Object.assign({}, c), { startMins: getMinutes(startStr), endMins: getMinutes(endStr), startStr: startStr.trim() });
    }).sort((a, b) => a.startMins - b.startMins);
    let lastEndTimeMins = -999;
    for (const cls of parsedClasses) {
        let gap = cls.startMins - lastEndTimeMins;
        if (lastEndTimeMins === -999)
            gap = 999;
        const offsets = gap > 30 ? [30, 10, 5] : [10, 5];
        for (const offset of offsets) {
            const notifyTime = new Date(targetDateStart.getTime() + (cls.startMins * 60 * 1000) - (offset * 60 * 1000));
            if (notifyTime < new Date())
                continue;
            const courseName = cls.title || cls.courseCode;
            const room = cls.room || "Room TBA";
            const title = "Class Reminder";
            const body = `Your ${courseName} class starts in ${offset} minutes at ${room}.`;
            const safeCode = cls.courseCode.replace(/\s+/g, '');
            const taskId = `cls-${userId}-${safeCode}-${dateString}-${offset}m`;
            await scheduleNotificationTask(taskId, userId, fcmToken, title, body, notifyTime);
        }
        lastEndTimeMins = cls.endMins;
    }
}
async function scheduleNotificationTask(taskId, userId, fcmToken, title, body, time) {
    const queuePath = tasksClient.queuePath(PROJECT_ID, LOCATION, QUEUE);
    const url = `https://us-central1-${PROJECT_ID}.cloudfunctions.net/sendScheduledNotification`;
    const payload = { userId, fcmToken, title, body };
    const task = {
        name: `${queuePath}/tasks/${taskId}`,
        httpRequest: {
            httpMethod: 'POST',
            url,
            headers: { 'Content-Type': 'application/json' },
            body: Buffer.from(JSON.stringify(payload)).toString('base64'),
        },
        scheduleTime: { seconds: time.getTime() / 1000 },
    };
    try {
        await tasksClient.createTask({ parent: queuePath, task });
    }
    catch (error) {
        // If the task already exists, it's not an error in our case.
        if (error.code === 6) { // 6 = ALREADY_EXISTS
            console.log(`Task ${taskId} already exists. Skipping.`);
        }
        else {
            console.error(`Failed to schedule task ${taskId} for user ${userId}:`, error);
        }
    }
}
// --- 6. Admin Functions ---
/**
 * ADMIN-ONLY: Manually triggers notification scheduling for all users for the current day.
 */
export const triggerScheduleImmediateCurrentDay = functions.https.onCall(async (data, context) => {
    const secret = data.secret;
    const expectedSecret = await _getAdminSecret();
    if (!expectedSecret || secret !== expectedSecret) {
        throw new functions.https.HttpsError('unauthenticated', 'Invalid admin secret.');
    }
    console.log("ADMIN: Manually running schedule generation for the current day.");
    try {
        await runSchedulerLogic(false); // false means for current day
        return { success: true, message: "Schedule generation for current day triggered." };
    }
    catch (error) {
        console.error("ADMIN: Error triggering immediate schedule:", error);
        throw new functions.https.HttpsError('internal', 'An error occurred while triggering the schedule.');
    }
});
// onEnrollmentChange is now handled by Python backend to centralize logic.
// --- 7. Advising Notifications ---
export const onAdvisingSlotAssigned = functions.firestore
    .document("users/{userId}")
    .onUpdate(async (change, context) => {
    const after = change.after.data();
    const before = change.before.data();
    const userId = context.params.userId;
    const fcmToken = after.fcmToken;
    if (!fcmToken)
        return;
    // Detect if any advisingSlot_* field changed
    const afterKeys = Object.keys(after).filter(k => k.startsWith('advisingSlot_'));
    for (const key of afterKeys) {
        const slotAfter = after[key];
        const slotBefore = before[key];
        // If slot is new or changed
        if (slotAfter && JSON.stringify(slotAfter) !== JSON.stringify(slotBefore)) {
            const semester = key.replace('advisingSlot_', '');
            // Format date manually or simply use the string from JSON
            const dateStr = slotAfter.date; // "03 December 2025"
            const timeStr = slotAfter.startTime; // "09:00 AM"
            const title = "Advising Slot Assigned";
            const body = `Your advising time for ${semester} is ${dateStr} at ${timeStr}.`;
            console.log(`Sending advising notification to ${userId}`);
            const message = {
                notification: { title, body },
                token: fcmToken
            };
            try {
                // 1. Save assignment notification to History
                await admin.firestore().collection('users').doc(userId).collection('notifications').add({
                    title,
                    body,
                    type: 'advising',
                    createdAt: admin.firestore.FieldValue.serverTimestamp(),
                    read: false,
                    semester: semester
                });
                // 2. Send immediate assignment notification
                await admin.messaging().send(message);
                // 3. Schedule Reminder 90 minutes BEFORE the slot
                if (dateStr && timeStr) {
                    const timeZone = "Asia/Dhaka";
                    // Parse "03 December 2025 09:00 AM"
                    const parsedLocal = parse(`${dateStr} ${timeStr}`, 'dd MMMM yyyy hh:mm a', new Date());
                    // Convert local parse (interpreted as Dhaka) to absolute UTC
                    const slotTimeUtc = zonedTimeToUtc(parsedLocal, timeZone);
                    // Subtract 90 minutes
                    const reminderTime = new Date(slotTimeUtc.getTime() - (90 * 60 * 1000));
                    if (reminderTime > new Date()) {
                        const reminderTitle = "Advising Reminder";
                        const reminderBody = `Your advising slot starts in 1 hour 30 minutes!`;
                        const taskId = `adv-rem-${userId}-${semester}-${reminderTime.getTime()}`;
                        await scheduleNotificationTask(taskId, userId, fcmToken, reminderTitle, reminderBody, reminderTime);
                        console.log(`Scheduled advising reminder for ${userId} at ${reminderTime.toISOString()}`);
                    }
                }
            }
            catch (e) {
                console.error(`Error processing advising notification for ${userId}:`, e);
            }
        }
    }
});
// --- 8. Admin Broadcast Trigger ---
export const onBroadcastCreated = functions.firestore
    .document("admin_broadcasts/{broadcastId}")
    .onCreate(async (snap, context) => {
    const data = snap.data();
    if (!data)
        return;
    const title = data.title;
    const body = data.body;
    const link = data.link || "";
    if (!title || !body) {
        console.log("Broadcast missing title or body. Skipping.");
        return;
    }
    console.log(`Sending broadcast: ${title}`);
    const message = {
        notification: { title, body },
        data: {
            click_action: "FLUTTER_NOTIFICATION_CLICK",
            link: link
        },
        topic: 'all_users'
    };
    try {
        await admin.messaging().send(message);
        // Update status
        await snap.ref.update({ status: "sent", sentAt: admin.firestore.FieldValue.serverTimestamp() });
    }
    catch (e) {
        console.error("Error sending broadcast:", e);
        await snap.ref.update({ status: "failed", error: String(e) });
    }
});
/**
 * ONE-TIME MIGRATION: Purges all scheduled tasks and reschedules everything.
 */
export const systemNotificationReset = functions.https.onCall(async (data, context) => {
    const secret = data.secret;
    const expectedSecret = await _getAdminSecret();
    if (!expectedSecret || secret !== expectedSecret) {
        throw new functions.https.HttpsError('unauthenticated', 'Invalid admin secret.');
    }
    const queuePath = tasksClient.queuePath(PROJECT_ID, LOCATION, QUEUE);
    console.log(`Resetting system. Queue: ${queuePath}`);
    try {
        await tasksClient.purgeQueue({ name: queuePath });
        console.log("Queue purged successfully.");
    }
    catch (e) {
        console.error("Purge failed:", e);
    }
    // 1. Reschedule Classes (Today & Tomorrow)
    console.log("Rescheduling classes...");
    await runSchedulerLogic(false);
    await runSchedulerLogic(true);
    // 2. Reschedule Tasks for all users
    console.log("Rescheduling tasks for all users...");
    const usersSnap = await db.collection("users").get();
    let taskCount = 0;
    for (const userDoc of usersSnap.docs) {
        const userId = userDoc.id;
        const userData = userDoc.data();
        const fcmToken = userData.fcmToken;
        if (!fcmToken)
            continue;
        const tasksSnap = await db.collection("users").doc(userId).collection("tasks").get();
        for (const taskDoc of tasksSnap.docs) {
            await scheduleForTask(userId, taskDoc.id, fcmToken, taskDoc.data());
            taskCount++;
        }
    }
    return { success: true, message: `System reset finished. ${taskCount} tasks rescheduled.` };
});
//# sourceMappingURL=index.js.map