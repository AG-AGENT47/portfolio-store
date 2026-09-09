-- Seed: personal_info
-- Run: psql $NEON_DATABASE_URL -f seeds/personal_info.sql
-- ON CONFLICT DO UPDATE = upsert: safe to re-run, updates existing values in place.
-- To change a value: edit this file, re-run. No DELETE needed.
--
-- personal_info is a key/value store: adding a field = adding one row here,
-- not an ALTER TABLE. The website reads these keys directly (src/lib/db.ts).

INSERT INTO personal_info (key, value) VALUES
    -- ── Identity ────────────────────────────────────────────────────────────
    ('name',     'Avyakt Garg'),
    ('email',    'garg62@wisc.edu'),
    ('phone',    '(608) 259-0543'),
    ('linkedin', 'avyakt-garg'),
    ('github',   'https://github.com/AG-AGENT47'),
    ('location', 'Madison, Wisconsin'),
    ('bio',      'MS CS student at UW-Madison and ex-Uber SWE intern. I build at the intersection of machine learning and distributed systems — from Kafka-based notification engines at Uber to graph neural networks for clinical disease prediction. Experienced across the stack: Java SpringBoot and gRPC in production at Uber, PyTorch and OpenCV for research, and database-backed web apps. Currently in the MS program at UW-Madison, deepening expertise in ML systems and LLM infrastructure.'),
    ('tagline',  'Building at the intersection of ML and distributed systems'),

    -- ── Website hero ────────────────────────────────────────────────────────
    -- hero_eyebrow: the small mono line above the name. The site adds the
    --   framing em-dashes; store just the text.
    ('hero_eyebrow', 'mscs · uw–madison · ''25 → ''27'),
    -- hero_lede: 1–3 lines. Newline (E'...\n...') marks a line break.
    --   Wrap a phrase in *asterisks* to render it italic/emphasised.
    ('hero_lede', E'I build for *both sides of the stack* — distributed systems that don''t fall over, and ML infrastructure that actually ships.\nMarketplace platforms at Uber. CUDA kernels & RAG pipelines by night.'),
    -- hero_pills: "|"-separated. Last pill gets the accent ("open") treatment.
    ('hero_pills', 'software engineer|ml / ai infra|open to new-grad ''27'),

    -- ── Website "about" ─────────────────────────────────────────────────────
    -- Paragraph 1 of About is `bio` above. This is paragraph 2.
    ('about_p2', 'I''m a team player you can rely on. I leave the codebase cleaner than I found it. On weekends, I am out searching for frames.'),

    -- ── Website hero "meta" column (the now / reading / … list) ──────────────
    ('now_location', 'Madison, WI'),
    ('now_reading',  'Designing Data-Intensive Apps'),
    ('now_building', 'GPU kernels & RAG systems'),
    ('now_shooting', 'Fuji X-T4 · Pentax K1000'),
    -- portrait_caption: shown over the hero portrait. Site adds the [ brackets ].
    ('portrait_caption', 'portrait — 35mm, Madison ''26')
ON CONFLICT (key) DO UPDATE
    SET value      = EXCLUDED.value,
        updated_at = NOW();
