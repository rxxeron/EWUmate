"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.onBroadcastCreated = exports.onAdvisingSlotUpdated = exports.sendTestNotification = exports.sendScheduledNotification = exports.debugUserSchedule = exports.triggerScheduleImmediate = exports.generateDailySchedule = void 0;
const functions = require("firebase-functions");
const admin = require("firebase-admin");
const tasks_1 = require("@google-cloud/tasks");
admin.initializeApp();
const db = admin.firestore();
const tasksClient = new tasks_1.CloudTasksClient();
// Configuration
const PROJECT_ID = JSON.parse(process.env.FIREBASE_CONFIG || '{}').projectId;
const LOCATION = "us-central1"; // Adjust if your functions are elsewhere
const QUEUE = "notification-queue"; // You MUST create this queue in Cloud Console
/**
 * 1. Scheduled Function: Runs every night at 8:00 PM (Dhaka Time)
 */
exports.generateDailySchedule = functions.pubsub
    .schedule("0 20 * * *") // 8:00 PM daily
    .timeZone("Asia/Dhaka")
    .onRun(async (_context) => {
    console.log("Running Scheduled Generation (Next Day)");
    await runSchedulerLogic(true); // targetNextDay = true
});
/**
 * 2. Manual Trigger: Runs immediately when called via HTTP.
 * Useful for "First time deploying".
 * It targets "Tomorrow" by default, or "Today" if you logic prefers.
 * Let's assume on deploy they want to schedule for TOMORROW (standard flow) or TODAY (catch up)?
 * User said "trigger for once and then it will active daily".
 * Usually this means "Run the logic now".
 * If it's 2 AM, running it now for "Tomorrow" is fine.
 */
exports.triggerScheduleImmediate = functions.https.onRequest(async (req, res) => {
    console.log("Running Manual Generation");
    await runSchedulerLogic(true); // Same logic as scheduled
    res.send("Schedule generation triggered.");
});
/**
 * 2a. Debug Trigger: Runs schedule logic for a SPECIFIC user and prints logs to response.
 * Call: /debugUserSchedule?uid=USER_ID
 */
exports.debugUserSchedule = functions.https.onRequest(async (req, res) => {
    var _a, _b;
    const userId = req.query.uid;
    if (!userId) {
        res.status(400).send("Missing 'uid' query parameter");
        return;
    }
    const logs = [];
    const log = (msg) => logs.push(msg);
    try {
        log(`Debugging Schedule for User: ${userId}`);
        const userDoc = await db.collection("users").doc(userId).get();
        if (!userDoc.exists) {
            log("User not found in Firestore");
            res.send(logs.join('\n'));
            return;
        }
        const userData = userDoc.data() || {};
        const fcmToken = await getUserFCMToken(userId);
        log(`FCM Token Found: ${!!fcmToken}`);
        if (!fcmToken)
            log(`Token: ${userData.fcmToken ? 'Using userData' : 'Missing'}`);
        const enrolledIds = userData.enrolledSections || [];
        log(`Enrolled Sections: ${enrolledIds.join(', ')}`);
        if (enrolledIds.length === 0) {
            log("No enrolled sections found.");
            res.send(logs.join('\n'));
            return;
        }
        const semSnap = await db.collection(`users/${userId}/semesterProgress`)
            .orderBy("lastUpdated", "desc")
            .limit(1)
            .get();
        if (semSnap.empty) {
            log("No semester progress found (Active Semester unknown).");
            res.send(logs.join('\n'));
            return;
        }
        const semesterCode = semSnap.docs[0].id;
        log(`Active Semester: ${semesterCode}`);
        // Logic check
        const targetDate = new Date();
        targetDate.setDate(targetDate.getDate() + 1);
        const dayMap = ["S", "M", "T", "W", "R", "F", "A"];
        const dayLetter = dayMap[targetDate.getDay()];
        log(`Target Date: ${targetDate.toISOString().split('T')[0]} (Day: ${dayLetter})`);
        // Course Details
        const courseDetails = [];
        for (const code of enrolledIds) {
            const doc = await db.collection(`courses_${semesterCode}`).doc(code).get();
            if (doc.exists) {
                courseDetails.push(Object.assign({ id: doc.id }, doc.data()));
                log(`Found Course: ${code} - Day: ${(_a = doc.data()) === null || _a === void 0 ? void 0 : _a.day} - Sessions: ${JSON.stringify((_b = doc.data()) === null || _b === void 0 ? void 0 : _b.sessions)}`);
            }
            else {
                log(`MISSING Course Doc: ${code} in courses_${semesterCode}`);
            }
        }
        // Processing Logic Mirror
        // ... (Simplified check)
        const matchesDay = (dayStr, targetDay) => {
            if (!dayStr)
                return false;
            const days = dayStr.toUpperCase().split(/\s+/);
            for (const d of days) {
                if (d.includes(targetDay))
                    return true;
            }
            return false;
        };
        const todaysClasses = courseDetails.filter(c => {
            if (c.sessions && Array.isArray(c.sessions)) {
                return c.sessions.some((s) => matchesDay(s.day, dayLetter));
            }
            return matchesDay(c.day, dayLetter);
        });
        log(`Classes found for ${dayLetter}: ${todaysClasses.map(c => c.code || c.courseCode).join(', ')}`);
        if (todaysClasses.length === 0) {
            log("No classes scheduled for target day.");
        }
        else {
            log(`Would schedule ${todaysClasses.length * 3} notifications.`);
        }
        res.send(logs.join('\n'));
    }
    catch (e) {
        log(`Error: ${e.toString()}`);
        res.status(500).send(logs.join('\n'));
    }
});
/**
 * Core Logic Shared by Schedule and Manual Trigger
 */
async function runSchedulerLogic(targetNextDay) {
    // 1. Determine Target Date
    const now = new Date();
    // Convert to Dhaka time for accurate day calculation? 
    // The server might be in UTC. 
    // Let's just work with UTC+6 offset manually or trust the environment.
    // Simplest: Add 1 day to current server time.
    const targetDate = new Date(now);
    if (targetNextDay) {
        targetDate.setDate(targetDate.getDate() + 1);
    }
    // Get Day Letter (S, M, T, W, R, F, A)
    const dayMap = ["S", "M", "T", "W", "R", "F", "A"]; // Sun=0 -> S
    const dayLetter = dayMap[targetDate.getDay()];
    const dateString = targetDate.toISOString().split('T')[0];
    console.log(`Generating schedule for Day: ${dayLetter} (${dateString})`);
    // 2. Fetch all users
    const usersSnap = await db.collection("users").get();
    const promises = [];
    for (const userDoc of usersSnap.docs) {
        promises.push(processUserSchedule(userDoc, dayLetter, targetDate));
    }
    await Promise.all(promises);
    console.log("Generation complete.");
}
/**
 * Process a single user's schedule for the day
 */
async function processUserSchedule(userDoc, dayLetter, targetDate) {
    var _a;
    const userId = userDoc.id;
    const userData = userDoc.data();
    const fcmToken = await getUserFCMToken(userId);
    if (!fcmToken) {
        console.log(`Skipping user ${userId}: No FCM token`);
        return;
    }
    // 1. Get Enrolled Courses
    const enrolledIds = userData.enrolledSections || [];
    if (enrolledIds.length === 0)
        return;
    // 2. Fetch Active Semester
    const semSnap = await db.collection(`users/${userId}/semesterProgress`)
        .orderBy("lastUpdated", "desc")
        .limit(1)
        .get();
    if (semSnap.empty)
        return;
    const semDoc = semSnap.docs[0];
    const semesterCode = semDoc.id;
    // 3. Fetch Course Details (Batch)
    const coursesToFetch = enrolledIds;
    const courseDetails = [];
    const chunks = chunkArray(coursesToFetch, 10);
    for (const chunk of chunks) {
        const q = await db.collection(`courses_${semesterCode}`)
            .where(admin.firestore.FieldPath.documentId(), 'in', chunk)
            .get();
        q.forEach((d) => courseDetails.push(Object.assign({ id: d.id }, d.data())));
    }
    // 3b. Fetch Exceptions (Cancellations/Makeups)
    const scheduleDoc = await db.collection(`users/${userId}/schedule`).doc(semesterCode).get();
    const exceptions = scheduleDoc.exists ? (((_a = scheduleDoc.data()) === null || _a === void 0 ? void 0 : _a.exceptions) || []) : [];
    // Helper to check if class is cancelled
    const dateString = targetDate.toISOString().split('T')[0];
    const isCancelled = (code) => {
        return exceptions.some((e) => e.date === dateString &&
            e.courseCode === code &&
            e.type === 'cancel');
    };
    // Helper to find makeup classes for today
    const makeups = exceptions.filter((e) => e.date === dateString &&
        e.type === 'makeup').map((e) => ({
        code: e.courseCode,
        startTime: e.startTime,
        room: e.room || "TBA",
        original: {},
        isMakeup: true
    }));
    // Helper to properly match day (handles "M W", "T R", "MW", etc.)
    const matchesDay = (dayStr, targetDay) => {
        if (!dayStr)
            return false;
        // Split by space or check each character
        const days = dayStr.toUpperCase().split(/\s+/);
        // Also check for combined formats like "MW"
        for (const d of days) {
            if (d.includes(targetDay))
                return true;
        }
        return false;
    };
    // 4. Filter for Target Day AND Not Cancelled
    let todaysClasses = courseDetails.filter(c => {
        // Check if cancelled first (optimization)
        if (isCancelled(c.code || c.courseCode))
            return false;
        if (c.sessions && Array.isArray(c.sessions)) {
            return c.sessions.some((s) => matchesDay(s.day, dayLetter));
        }
        return matchesDay(c.day, dayLetter);
    }).map(c => {
        let session;
        if (c.sessions) {
            session = c.sessions.find((s) => matchesDay(s.day, dayLetter));
        }
        else {
            session = { startTime: c.startTime, room: c.room };
        }
        return {
            code: c.code || c.courseCode,
            startTime: (session === null || session === void 0 ? void 0 : session.startTime) || "TBA",
            room: (session === null || session === void 0 ? void 0 : session.room) || c.room || "TBA",
            original: c,
            isMakeup: false
        };
    });
    // Merge Regular + Makeup
    todaysClasses = [...todaysClasses, ...makeups];
    if (todaysClasses.length === 0)
        return;
    // 5. Sort by time
    todaysClasses.sort((a, b) => parseTime(a.startTime) - parseTime(b.startTime));
    // 6. Apply Rules & Schedule
    // TIMEZONE FIX: Class times are in Dhaka local time (UTC+6)
    // We need to convert to UTC for Cloud Tasks scheduling
    const DHAKA_OFFSET_HOURS = 6;
    for (let i = 0; i < todaysClasses.length; i++) {
        const cls = todaysClasses[i];
        const clsMinutes = parseTime(cls.startTime);
        // Create date in Dhaka time, then convert to UTC
        const clsDateDhaka = new Date(targetDate);
        clsDateDhaka.setHours(Math.floor(clsMinutes / 60), clsMinutes % 60, 0, 0);
        // Subtract 6 hours to convert Dhaka -> UTC
        const clsDateUTC = new Date(clsDateDhaka.getTime() - (DHAKA_OFFSET_HOURS * 60 * 60 * 1000));
        // Rule A: Morning Class (8:00 or 8:30 AM) -> 1 Hour Before
        if (clsMinutes === 480 || clsMinutes === 510) {
            await scheduleNotificationTask(fcmToken, cls.code, cls.room, clsDateUTC, 60, "1 hr");
        }
        // Calculate GAP
        let gapMinutes = 999;
        if (i > 0) {
            const prev = todaysClasses[i - 1];
            const prevStart = parseTime(prev.startTime);
            // Assuming gap based on start times for simplicity, or approximated end
            gapMinutes = clsMinutes - (prevStart + 90);
        }
        // Rule B & C
        if (gapMinutes > 30) {
            await scheduleNotificationTask(fcmToken, cls.code, cls.room, clsDateUTC, 30, "30 min");
        }
        await scheduleNotificationTask(fcmToken, cls.code, cls.room, clsDateUTC, 10, "10 min");
        await scheduleNotificationTask(fcmToken, cls.code, cls.room, clsDateUTC, 5, "5 min");
    }
}
async function scheduleNotificationTask(token, code, room, classTime, minutesBefore, label) {
    const triggerTime = new Date(classTime.getTime() - (minutesBefore * 60 * 1000));
    const now = new Date();
    if (triggerTime <= now)
        return;
    const queuePath = tasksClient.queuePath(PROJECT_ID, LOCATION, QUEUE);
    const url = `https://${LOCATION}-${PROJECT_ID}.cloudfunctions.net/sendScheduledNotification`;
    const payload = {
        token,
        title: "Upcoming Class",
        body: `You Have ${code} Class within ${label} at ${room}`,
        data: { click_action: "FLUTTER_NOTIFICATION_CLICK" }
    };
    const task = {
        httpRequest: {
            httpMethod: 'POST',
            url,
            body: Buffer.from(JSON.stringify(payload)).toString('base64'),
            headers: { 'Content-Type': 'application/json' },
        },
        scheduleTime: { seconds: triggerTime.getTime() / 1000 },
    };
    try {
        await tasksClient.createTask({ parent: queuePath, task });
    }
    catch (e) {
        console.error(`Failed to schedule task: ${e}`);
    }
}
/**
 * 3. Worker Function: Sends the actual FCM
 * NO SOUND, HIGH VIBRATION
 */
exports.sendScheduledNotification = functions.https.onRequest(async (req, res) => {
    const { token, title, body, data } = req.body;
    if (!token) {
        res.status(400).send("Missing token");
        return;
    }
    try {
        await admin.messaging().send({
            token,
            notification: {
                title,
                body,
            },
            data,
            android: {
                priority: 'high',
                notification: {
                    channelId: 'high_importance_channel',
                    priority: 'high',
                    defaultSound: false,
                    defaultVibrateTimings: false,
                    vibrateTimingsMillis: [0, 800, 400, 800, 400, 800, 400, 800, 400, 800],
                    visibility: 'public',
                }
            }
        });
        res.status(200).send("Sent");
    }
    catch (e) {
        console.error("FCM Send Error", e);
        res.status(500).send(e.toString());
    }
});
/**
 * 4. Test Trigger: Sends a generic test notification to verify channel config.
 * Call with ?token=YOUR_FCM_TOKEN
 */
exports.sendTestNotification = functions.https.onRequest(async (req, res) => {
    const token = req.query.token || req.body.token;
    if (!token) {
        res.status(400).send("Missing 'token' query parameter or body field.");
        return;
    }
    try {
        await admin.messaging().send({
            token,
            notification: {
                title: "Test Notification",
                body: "This is a test of the High Priority Channel (No Sound, Vibration Only).",
            },
            data: { click_action: "FLUTTER_NOTIFICATION_CLICK" },
            android: {
                priority: 'high',
                notification: {
                    channelId: 'high_importance_channel',
                    priority: 'high',
                    defaultSound: false,
                    defaultVibrateTimings: false,
                    vibrateTimingsMillis: [0, 800, 400, 800, 400, 800, 400, 800, 400, 800],
                    visibility: 'public',
                }
            }
        });
        res.status(200).send("Test Notification Sent!");
    }
    catch (e) {
        console.error("Test Send Error", e);
        res.status(500).send(e.toString());
    }
});
// --- Helpers ---
async function getUserFCMToken(uid) {
    const tokensSnap = await db.collection(`users/${uid}/fcm_tokens`)
        .orderBy('lastUpdated', 'desc')
        .limit(1)
        .get();
    if (tokensSnap.empty)
        return null;
    return tokensSnap.docs[0].data().token;
}
function chunkArray(myArray, chunk_size) {
    const results = [];
    while (myArray.length) {
        results.push(myArray.splice(0, chunk_size));
    }
    return results;
}
function parseTime(timeStr) {
    if (!timeStr)
        return 0;
    try {
        const lower = timeStr.toLowerCase().trim();
        const parts = lower.match(/(\d+):(\d+)\s*(am|pm)?/);
        if (!parts)
            return 0;
        let h = parseInt(parts[1]);
        const m = parseInt(parts[2]);
        const ampm = parts[3];
        if (ampm) {
            if (ampm === 'pm' && h < 12)
                h += 12;
            if (ampm === 'am' && h === 12)
                h = 0;
        }
        return h * 60 + m;
    }
    catch (_e) {
        return 0;
    }
}
// ============================================
// ADVISING NOTIFICATIONS (Cloud Tasks Approach)
// ============================================
/**
 * 5. Firestore Trigger: When a user's advisingSlot is updated, schedule notifications
 */
exports.onAdvisingSlotUpdated = functions.firestore
    .document('users/{userId}')
    .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    const userId = context.params.userId;
    // Check if advisingSlot changed
    const beforeSlot = before.advisingSlot;
    const afterSlot = after.advisingSlot;
    // If no new slot or slot unchanged, skip
    if (!afterSlot || !afterSlot.startTime)
        return;
    if (beforeSlot && beforeSlot.startTime === afterSlot.startTime)
        return;
    console.log(`Scheduling advising alerts for user ${userId}`);
    // Get FCM Token
    const fcmToken = await getUserFCMToken(userId);
    if (!fcmToken) {
        console.log(`No FCM token for user ${userId}`);
        return;
    }
    // Parse advising time (Firestore Timestamp or Date)
    let advisingTime;
    if (afterSlot.startTime.toDate) {
        advisingTime = afterSlot.startTime.toDate();
    }
    else if (afterSlot.startTime instanceof Date) {
        advisingTime = afterSlot.startTime;
    }
    else {
        // Try parsing as string "10:00 AM" with today's date
        // This requires knowing the advising DATE too
        console.log("Could not parse advisingSlot.startTime");
        return;
    }
    const displayTime = afterSlot.displayTime || "your advising time";
    // Schedule 3 notifications: 1 hour, 30 min, 5 min before
    await scheduleAdvisingTask(fcmToken, advisingTime, 60, displayTime);
    await scheduleAdvisingTask(fcmToken, advisingTime, 30, displayTime);
    await scheduleAdvisingTask(fcmToken, advisingTime, 5, displayTime);
    console.log(`Scheduled 3 advising alerts for user ${userId}`);
});
/**
 * Helper: Schedule a single advising notification via Cloud Tasks
 */
async function scheduleAdvisingTask(token, advisingTime, minutesBefore, displayTime) {
    const triggerTime = new Date(advisingTime.getTime() - (minutesBefore * 60 * 1000));
    const now = new Date();
    if (triggerTime <= now)
        return;
    const queuePath = tasksClient.queuePath(PROJECT_ID, LOCATION, QUEUE);
    const url = `https://${LOCATION}-${PROJECT_ID}.cloudfunctions.net/sendScheduledNotification`;
    let body;
    if (minutesBefore >= 60) {
        body = `Advising starts in 1 hour (${displayTime}). Get ready!`;
    }
    else if (minutesBefore >= 30) {
        body = `Advising starts in 30 minutes! (${displayTime})`;
    }
    else {
        body = `Advising starts in 5 minutes! Log in to EWU Portal NOW!`;
    }
    const payload = {
        token,
        title: "Advising Alert",
        body,
        data: { click_action: "FLUTTER_NOTIFICATION_CLICK", type: "advising" }
    };
    const task = {
        httpRequest: {
            httpMethod: 'POST',
            url,
            body: Buffer.from(JSON.stringify(payload)).toString('base64'),
            headers: { 'Content-Type': 'application/json' },
        },
        scheduleTime: { seconds: triggerTime.getTime() / 1000 },
    };
    try {
        await tasksClient.createTask({ parent: queuePath, task });
    }
    catch (e) {
        console.error(`Failed to schedule advising task: ${e}`);
    }
}
// ============================================
// ADMIN BROADCASTS (Cloud Tasks Approach)
// ============================================
/**
 * 6. Admin Broadcast Trigger (Replaces Python implementation)
 * Handles both "Send Now" and "Scheduled" broadcasts via Cloud Tasks.
 */
exports.onBroadcastCreated = functions.firestore
    .document('admin_broadcasts/{broadcastId}')
    .onCreate(async (snap, context) => {
    const data = snap.data();
    const broadcastId = context.params.broadcastId;
    if (!data)
        return;
    const title = data.title;
    const body = data.body;
    const link = data.link;
    const scheduledAt = data.scheduledAt; // Timestamp
    if (data.status === 'sent' || data.status === 'scheduled')
        return;
    if (!title || !body)
        return;
    console.log(`Processing Broadcast: ${title}`);
    // Check for Specific Schedule
    let triggerDate = new Date();
    if (scheduledAt) {
        // Firestore Timestamp to Date
        if (scheduledAt.toDate) {
            triggerDate = scheduledAt.toDate();
        }
        else if (scheduledAt.seconds) {
            triggerDate = new Date(scheduledAt.seconds * 1000);
        }
        else if (typeof scheduledAt === 'string') {
            triggerDate = new Date(scheduledAt);
        }
    }
    const now = new Date();
    // If trigger time is in future (> 1 min buffer), schedule it
    if (triggerDate.getTime() > now.getTime() + 60000) {
        console.log(`Scheduling broadcast for ${triggerDate.toISOString()}`);
        // Mark as scheduled in Firestore
        await snap.ref.update({ status: 'scheduled' });
        // Schedule Cloud Task
        await scheduleBroadcastTask(broadcastId, title, body, link, triggerDate);
        return;
    }
    // Otherwise SEND NOW
    console.log("Sending broadcast immediately...");
    await sendBroadcastImmediate(title, body, link);
    await snap.ref.update({
        status: 'sent',
        sentAt: admin.firestore.FieldValue.serverTimestamp()
    });
});
/**
 * Helper: Schedule Broadcast via Cloud Task
 */
async function scheduleBroadcastTask(broadcastId, title, body, link, triggerDate) {
    const queuePath = tasksClient.queuePath(PROJECT_ID, LOCATION, QUEUE);
    const url = `https://${LOCATION}-${PROJECT_ID}.cloudfunctions.net/sendScheduledNotification`;
    const payload = {
        topic: 'all_users',
        title,
        body,
        data: {
            click_action: "FLUTTER_NOTIFICATION_CLICK",
            link: link || "",
            broadcastId
        }
    };
    const task = {
        httpRequest: {
            httpMethod: 'POST',
            url,
            body: Buffer.from(JSON.stringify(payload)).toString('base64'),
            headers: { 'Content-Type': 'application/json' },
        },
        scheduleTime: { seconds: triggerDate.getTime() / 1000 },
    };
    try {
        await tasksClient.createTask({ parent: queuePath, task });
        console.log(`Broadcast task created for ${triggerDate.toISOString()}`);
    }
    catch (e) {
        console.error(`Failed to schedule broadcast task: ${e}`);
        await db.collection('admin_broadcasts').doc(broadcastId).update({
            status: 'error',
            error: `Task Schedule Failed: ${e}`
        });
    }
}
/**
 * Helper: Send Broadcast Immediately
 */
async function sendBroadcastImmediate(title, body, link) {
    const message = {
        notification: { title, body },
        data: {
            click_action: "FLUTTER_NOTIFICATION_CLICK",
            link: link || ""
        },
        topic: 'all_users'
    };
    await admin.messaging().send(message);
}
//# sourceMappingURL=index.js.map