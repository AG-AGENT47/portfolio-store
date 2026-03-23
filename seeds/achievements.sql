-- Seed: achievements
-- Run: psql $NEON_DATABASE_URL -f seeds/achievements.sql
-- ON CONFLICT (title, organization) DO UPDATE: upsert — safe to re-run.
-- display_order = 1 is most prestigious (MITACS shown first).

INSERT INTO achievements (title, organization, description, date, category, display_order) VALUES
(
    'Globalink Research Scholarship',
    'MITACS, Canada',
    'Selected from 30,000+ applicants worldwide for a fully-funded research internship at the University of Saskatchewan, Canada. One of the most competitive undergraduate research fellowships in Canada.',
    '2023-02-01',
    'scholarship',
    1
),
(
    'Scholarship Awardee',
    'AWaDH, Government of India',
    'Awarded by the Agriculture and Water Technology Development Hub (AWaDH) under the Government of India for research contributions in AI applications for the agriculture domain.',
    '2022-04-01',
    'scholarship',
    2
),
(
    'Gold Medalist',
    'Delhi Public School R.K. Puram',
    'Awarded for 9 consecutive years of academic excellence across school career.',
    '2019-05-01',
    'award',
    3
),
(
    '86th Rank — Junior Science Talent Search Examination (JSTSE)',
    'Directorate of Education, Delhi',
    'Ranked 86th in the state-level science merit scholarship examination conducted by the Directorate of Education, Government of NCT of Delhi.',
    '2017-02-01',
    'competition',
    4
)
ON CONFLICT (title, organization) DO UPDATE
    SET description   = EXCLUDED.description,
        date          = EXCLUDED.date,
        category      = EXCLUDED.category,
        display_order = EXCLUDED.display_order,
        updated_at    = NOW();
