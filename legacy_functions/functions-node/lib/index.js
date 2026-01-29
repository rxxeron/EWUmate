import functions from "firebase-functions";
import admin from "firebase-admin";
import { CloudTasksClient } from "@google-cloud/tasks";
import { format, addDays, startOfDay } from 'date-fns';
import { utcToZonedTime } from 'date-fns-tz';
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
    const dueDate = task.dueDate.toDate();
    const notificationTime = new Date(dueDate.getTime() - 24 * 60 * 60 * 1000);
    if (notificationTime < new Date())
        return;
    const courseName = task.courseName || "";
    const taskType = task.type || "task";
    const title = "Task Reminder";
    const body = `You have an upcoming ${taskType} for ${courseName}.`;
    const notificationTaskId = `task-reminder-${userId}-${taskId}`;
    await scheduleNotificationTask(notificationTaskId, userId, fcmToken, title, body, notificationTime);
});
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
    const promises = usersSnap.docs.map(doc => processUserForNotifications(doc.id, doc.data(), targetDay, dateString));
    await Promise.all(promises);
}
async function processUserForNotifications(userId, userData, targetDay, dateString) {
    var _a;
    const { fcmToken, weeklySchedule } = userData;
    if (!fcmToken || !weeklySchedule || !((_a = weeklySchedule[targetDay]) === null || _a === void 0 ? void 0 : _a.length))
        return;
    const targetDate = startOfDay(new Date(dateString));
    for (const classInfo of weeklySchedule[targetDay]) {
        const startTimeStr = classInfo.time.split('-')[0].trim();
        const [time, modifier] = startTimeStr.split(' ');
        const timeParts = time.split(':').map(Number);
        let hours = timeParts[0];
        const minutes = timeParts[1];
        if (modifier === 'PM' && hours < 12)
            hours += 12;
        if (modifier === 'AM' && hours === 12)
            hours = 0;
        const classDateTime = new Date(targetDate);
        classDateTime.setHours(hours, minutes, 0, 0);
        const notificationTime = new Date(classDateTime.getTime() - 10 * 60 * 1000);
        if (notificationTime < new Date())
            continue;
        const courseName = classInfo.title || classInfo.courseCode;
        const classType = courseName.toLowerCase().includes("lab") ? "Lab" : "Class";
        const room = classInfo.room || "N/A";
        const title = "Class Reminder";
        const body = `You have a ${courseName} ${classType} in 10 minutes at ${room}.`;
        const safeCourseCode = classInfo.courseCode.replace(/\s+/g, '-');
        const notificationTaskId = `class-reminder-${userId}-${safeCourseCode}-${dateString}`;
        await scheduleNotificationTask(notificationTaskId, userId, fcmToken, title, body, notificationTime);
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
// --- 4. Weekly Schedule Generation ---
async function generateWeeklyScheduleForUser(userId, enrolledSections) {
    var _a, _b;
    const appInfoDoc = await db.collection("config").doc("app_info").get();
    const semesterId = (_b = (_a = appInfoDoc.data()) === null || _a === void 0 ? void 0 : _a.currentSemester) === null || _b === void 0 ? void 0 : _b.replace(/\s/g, '');
    if (!semesterId) {
        console.error(`Cannot generate schedule for user ${userId}: Current semester is not configured.`);
        return;
    }
    const courseCollectionName = `courses_${semesterId}`;
    const weeklySchedule = {
        Saturday: [], Sunday: [], Monday: [], Tuesday: [], Wednesday: [], Thursday: [], Friday: [],
    };
    if (!enrolledSections || enrolledSections.length === 0) {
        await db.collection("users").doc(userId).update({ weeklySchedule });
        return;
    }
    const coursesQuery = await db.collection(courseCollectionName).where('id', 'in', enrolledSections).get();
    const enrolledCourseDetails = coursesQuery.docs.map(doc => doc.data());
    for (const course of enrolledCourseDetails) {
        for (const session of course.sessions) {
            const day = session.day;
            if (weeklySchedule[day]) {
                weeklySchedule[day].push({
                    title: course.courseName,
                    courseCode: course.code,
                    time: `${session.startTime}-${session.endTime}`,
                    room: session.room || "TBA",
                });
            }
        }
    }
    await db.collection("users").doc(userId).update({ weeklySchedule });
}
// --- 5. Triggers and Other Functions ---
export const onEnrollmentChange = functions.firestore
    .document("users/{userId}")
    .onUpdate(async (change, context) => {
    const beforeData = change.before.data();
    const afterData = change.after.data();
    if (JSON.stringify(beforeData.enrolledSections) !== JSON.stringify(afterData.enrolledSections)) {
        await generateWeeklyScheduleForUser(context.params.userId, afterData.enrolledSections || []);
    }
});
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
/**
 * ADMIN-ONLY: Regenerates the 'weeklySchedule' for all users based on their 'enrolledSections'.
 */
export const regenerateAllSchedules = functions.runWith({ timeoutSeconds: 300, memory: '1GB' }).https.onCall(async (data, context) => {
    const secret = data.secret;
    const expectedSecret = await _getAdminSecret();
    if (!expectedSecret || secret !== expectedSecret) {
        throw new functions.https.HttpsError('unauthenticated', 'Invalid admin secret.');
    }
    console.log("ADMIN: Starting regeneration of all user schedules.");
    const usersSnap = await db.collection("users").get();
    if (usersSnap.empty) {
        return { success: true, message: "No users found." };
    }
    const promises = [];
    usersSnap.forEach(doc => {
        const userData = doc.data();
        promises.push(generateWeeklyScheduleForUser(doc.id, userData.enrolledSections || []));
    });
    try {
        await Promise.all(promises);
        console.log(`ADMIN: Finished regenerating schedules for ${promises.length} users.`);
        return { success: true, processed: promises.length, message: `Processed ${promises.length} users.` };
    }
    catch (error) {
        console.error("ADMIN: Error regenerating all schedules:", error);
        throw new functions.https.HttpsError('internal', 'An error occurred during schedule regeneration.');
    }
});
//# sourceMappingURL=index.js.map