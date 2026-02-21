-- Create Ramadan Timetable table
CREATE TABLE IF NOT EXISTS public.ramadan_timetable (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    day_number INT NOT NULL,
    fasting_date DATE NOT NULL UNIQUE,
    sehri_time TIME NOT NULL,
    iftar_time TIME NOT NULL,
    region TEXT NOT NULL DEFAULT 'Dhaka',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.ramadan_timetable ENABLE ROW LEVEL SECURITY;

-- Allow public read access
CREATE POLICY "Allow public read access to ramadan_timetable"
ON public.ramadan_timetable FOR SELECT
USING (true);

-- Seed Data for Ramadan 2026 (Dhaka)
INSERT INTO public.ramadan_timetable (day_number, fasting_date, sehri_time, iftar_time, region)
VALUES
(1, '2026-02-19', '05:12', '17:58', 'Dhaka'),
(2, '2026-02-20', '05:11', '17:58', 'Dhaka'),
(3, '2026-02-21', '05:10', '17:59', 'Dhaka'),
(4, '2026-02-22', '05:09', '17:59', 'Dhaka'),
(5, '2026-02-23', '05:08', '18:00', 'Dhaka'),
(6, '2026-02-24', '05:07', '18:01', 'Dhaka'),
(7, '2026-02-25', '05:06', '18:01', 'Dhaka'),
(8, '2026-02-26', '05:05', '18:02', 'Dhaka'),
(9, '2026-02-27', '05:04', '18:02', 'Dhaka'),
(10, '2026-02-28', '05:03', '18:03', 'Dhaka'),
(11, '2026-03-01', '05:02', '18:03', 'Dhaka'),
(12, '2026-03-02', '05:01', '18:04', 'Dhaka'),
(13, '2026-03-03', '05:00', '18:04', 'Dhaka'),
(14, '2026-03-04', '04:59', '18:05', 'Dhaka'),
(15, '2026-03-05', '04:58', '18:05', 'Dhaka'),
(16, '2026-03-06', '04:57', '18:05', 'Dhaka'),
(17, '2026-03-07', '04:56', '18:06', 'Dhaka'),
(18, '2026-03-08', '04:55', '18:06', 'Dhaka'),
(19, '2026-03-09', '04:54', '18:07', 'Dhaka'),
(20, '2026-03-10', '04:52', '18:07', 'Dhaka'),
(21, '2026-03-11', '04:51', '18:08', 'Dhaka'),
(22, '2026-03-12', '04:50', '18:08', 'Dhaka'),
(23, '2026-03-13', '04:49', '18:08', 'Dhaka'),
(24, '2026-03-14', '04:48', '18:09', 'Dhaka'),
(25, '2026-03-15', '04:47', '18:09', 'Dhaka'),
(26, '2026-03-16', '04:45', '18:10', 'Dhaka'),
(27, '2026-03-17', '04:44', '18:10', 'Dhaka'),
(28, '2026-03-18', '04:43', '18:11', 'Dhaka'),
(29, '2026-03-19', '04:42', '18:11', 'Dhaka'),
(30, '2026-03-20', '04:40', '18:12', 'Dhaka')
ON CONFLICT (fasting_date) DO UPDATE SET
    sehri_time = EXCLUDED.sehri_time,
    iftar_time = EXCLUDED.iftar_time,
    day_number = EXCLUDED.day_number;
