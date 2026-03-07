# 🚀 Release Notes & Features

Welcome to the **EWUmate** release hub. This document outlines the core capabilities, feature sets, and functional boundaries of the current production release.

---

## 📅 Dynamic Schedule Manager

The heart of EWUmate. Unlike static scheduling apps, EWUmate intelligently adapts to the University's real-time events.

- **Automated Class Syncing:** Fetches your registered courses and dynamically builds a weekly timeline.
- **Holiday Awareness:** Automatically hides classes during listed Academic Calendar holidays (e.g., Eid vacations, National Holidays).
- **Ramadan Time Adjustments:** Natively supports shifting class block timings according to the University's specialized Ramadan schedule.
- **Makeup & Cancellation Toggles:** Allows students to mark individual sessions as "Canceled" or add "Makeup" classes which automatically reflect on the dashboard.

## 🗳️ Advising & Registration Planner

Plan your next semester without the stress of overlapping courses.

- **Conflict Engine:** A built-in validation engine that prevents you from adding two sections that share the exact same time slot.
- **Drafting Mode:** Create, save, and visualize your future semester weeks in advance before the official portal opens.
- **Criteria Matching:** Shows which sections are open to specific departments (e.g., "Allowed for CSE & EEE").

## 🔌 Offline-First Architecture

EWUmate is designed to survive University basement classrooms with zero cellular reception.

- **Local Alarms:** Push notifications for your next class are scheduled directly onto the device's native alarm system via `flutter_local_notifications`. You will get pinged 10 minutes before class, internet or no internet.
- **Persistent Caching:** Everything you look at is saved locally in a high-speed Hive/SharedPreferences cache. 

## 📊 Academic Progress Tracking

A localized version of your digital transcript.

- **Live CGPA Calculation:** As you complete courses or update estimated grades, your CGPA dynamically updates.
- **Credit Tracking:** Clear visualizations of "Credits Earned" vs "Credits Remaining" based on your enrolled degree program.
- **Semester History Dashboard:** View a breakdown of your performance across all past semesters.

## 🔔 Communication & Broadcasts

- **Real-Time Push Notifications:** Powered by Firebase Cloud Messaging (FCM).
- **Admin Broadcasts:** Receive urgent announcements (e.g., "Campus closed today due to heavy rain") universally.
- **Targeted Alerts:** Notifications related specifically to your registered sections or departments.

## 📥 Built-in University Catalog

The app maintains a fully searchable, offline-capable database of:
- All offered courses for the active semester (including faculty initials, room numbers, and timings).
- The complete Academic & Activities Calendar.
- The comprehensive list of Advising schedules and credit boundaries.

> **Technical Note:** This data is populated continuously by our isolated Azure Functions ingestion pipeline, meaning your app always has the most recent PDFs converted into readable data.

--- 

*EWUmate is continually evolving. For detailed system design and backend logic, refer to the [Architecture Report](architecture_report.md).*
