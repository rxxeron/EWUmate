# EWUmate Project Roadmap & Status

This document outlines the current progress, planned features, and remaining tasks for the EWUmate application.

## ✅ Completed Recently
- **Advising System**:
    - Integrated Smart Generator with "Enroll in Option" functionality.
    - Manual Planner with conflict detection and persistent saving to Firestore.
- **Transition Flow**:
    - Two-step "Next Semester Setup" process.
    - Simplified grade submission that updates global academic history (`courseHistory` and `completedCourses`).
    - Integrated course search and modification directly during the transition step.
- **Identity & Profile**:
    - Registration screen enhanced to collect **Student ID** and **Phone Number**.
    - Profile screen redesigned with a premium **Academic Snapshot** (2x2 grid) showing CGPA, Credits, and Remaining Credits.
    - Dynamic display of **Advising Slots** and **Departmental** info.
- **Backend Optimization**:
    - Renamed optimized Python codebase to `functions` for direct Firebase deployment.
    - Aligned Firestore structure with the standard user document fields.

## 🚀 Planned Ahead (Immediate Next Steps)
### 1. Advanced Notification Engine (Node.js)
We are moving the `functions-node` logic to handle sophisticated scheduling via Cloud Tasks:
- **Class Notifications**:
    - **Logic for Breaks > 30m**: Send a notification at start, then reminders at 10 minutes and 5 minutes before the next class (with vibration).
    - **Logic for Breaks < 30m**: Send reminders at 10 minutes and 5 minutes before.
- **Task Reminders**:
    - **Night Before**: Notification at 8:00 PM the night before the due date.
    - **Morning Of**: Notification at 8:00 AM on the day it is due.

### 2. Functional Deployment
- Deploy the updated Python `on_enrollment_change` function.
- Finalize and deploy the Node.js `notification-queue` logic.

### 3. Polish & Quality Assurance
- **Scholarship Warnings**: Implement warnings if credit count falls below the required threshold during enrollment.
- **Printable Grade Sheets**: Finalize the PDF export for the Degree Progress screen.
- **End-to-End Testing**: Verify the transition flow from Semester Setup $\rightarrow$ Schedule Generation $\rightarrow$ Live Calendar.

## 🛠️ Folder Structure Notes
- `/functions`: Optimized Python backend (Schedule generation, Exam parsing).
- `/functions-node`: Notification and Cloud Tasks logic (Work in progress).
- `/lib/features`: Core Flutter application logic.

---
*Status Update: 2026-01-27*
