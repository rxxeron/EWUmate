-- Custom ENUM Types

CREATE TYPE public."academic_track" AS ENUM ('tri_semester', 'bi_semester', 'all');
CREATE TYPE public."enrollment_status" AS ENUM ('enrolled', 'completed', 'dropped', 'retaken');
CREATE TYPE public."notification_type" AS ENUM ('system', 'broadcast', 'push_alert', 'reminder', 'task_reminder', 'direct_message');
CREATE TYPE public."scholarship_tier" AS ENUM ('merit_100', 'deans_list', 'medha_lalon');
CREATE TYPE public."task_status" AS ENUM ('pending', 'completed', 'missed');
