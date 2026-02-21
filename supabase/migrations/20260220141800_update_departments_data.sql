-- ==========================================
-- EWUMATE SCHEMA MIGRATION: Update Departments Data
-- ==========================================
-- Replaces initial placeholder departments with the exact official list
-- including proper full names and graduation credits.

-- Clear previous dummy data
TRUNCATE public.departments;

-- Insert exact official data
INSERT INTO public.departments (id, name, programs) VALUES
('cse', 'Dept. of Computer Science & Engineering', '[
    {"id": "cse", "name": "B.Sc. in Computer Science & Engineering", "credits": 140},
    {"id": "ice", "name": "B.Sc. in Information & Communications Engineering", "credits": 140}
]'::jsonb),

('ece', 'Dept. of Electronics & Communications Engineering', '[
    {"id": "ete", "name": "B.Sc. in Electronic & Telecommunication Engineering", "credits": 140}
]'::jsonb),

('eee', 'Dept. of Electrical & Electronic Engineering', '[
    {"id": "eee", "name": "B.Sc. in Electrical & Electronic Engineering", "credits": 140}
]'::jsonb),

('ce', 'Dept. of Civil Engineering', '[
    {"id": "ce", "name": "B.Sc. in Civil Engineering", "credits": 156.5}
]'::jsonb),

('pharmacy', 'Dept. of Pharmacy', '[
    {"id": "pharm", "name": "Bachelor of Pharmacy (B.Pharm) Professional", "credits": 158}
]'::jsonb),

('geb', 'Dept. of Genetic Engineering & Biotechnology', '[
    {"id": "geb", "name": "B.Sc. in Genetic Engineering & Biotechnology", "credits": 133}
]'::jsonb),

('mps', 'Dept. of Mathematical & Physical Sciences', '[
    {"id": "dsa", "name": "B.Sc. in Data Science & Analytics", "credits": 130},
    {"id": "math", "name": "B.Sc. (Hons) in Mathematics", "credits": 128}
]'::jsonb),

('business', 'Dept. of Business Administration', '[
    {"id": "bba", "name": "Bachelor of Business Administration", "credits": 123}
]'::jsonb),

('economics', 'Dept. of Economics', '[
    {"id": "eco", "name": "B.S.S. (Hons) in Economics", "credits": 123}
]'::jsonb),

('english', 'Dept. of English', '[
    {"id": "eng", "name": "B.A. (Hons) in English", "credits": 123}
]'::jsonb),

('sociology', 'Dept. of Sociology', '[
    {"id": "soc", "name": "B.S.S. (Hons) in Sociology", "credits": 123}
]'::jsonb),

('islm', 'Dept. of Information Studies & Library Management', '[
    {"id": "islm", "name": "B.S.S. in Info. Studies & Library Management", "credits": 123}
]'::jsonb),

('law', 'Dept. of Law', '[
    {"id": "law", "name": "LL.B. (Hons)", "credits": 135}
]'::jsonb);
