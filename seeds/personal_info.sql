-- Seed: personal_info
-- Run: psql $NEON_DATABASE_URL -f seeds/personal_info.sql
-- ON CONFLICT DO UPDATE = upsert: safe to re-run, updates existing values in place.
-- To change a value: edit this file, re-run. No DELETE needed.

INSERT INTO personal_info (key, value) VALUES
    ('name',     'Avyakt Garg'),
    ('email',    'garg62@wisc.edu'),
    ('phone',    '(608) 259-0543'),
    ('linkedin', 'avyakt-garg'),
    ('github',   'https://github.com/AG-AGENT47'),
    ('location', 'Madison, Wisconsin'),
    ('bio',      'MS CS student at UW-Madison and ex-Uber SWE intern. I build at the intersection of machine learning and distributed systems — from Kafka-based notification engines at Uber to graph neural networks for clinical disease prediction. Experienced across the stack: Java SpringBoot and gRPC in production at Uber, PyTorch and OpenCV for research, and database-backed web apps. Currently in the MS program at UW-Madison, deepening expertise in ML systems and LLM infrastructure.'),
    ('tagline',  'Building at the intersection of ML and distributed systems')
ON CONFLICT (key) DO UPDATE
    SET value      = EXCLUDED.value,
        updated_at = NOW();
