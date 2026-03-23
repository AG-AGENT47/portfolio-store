-- Seed: education
-- Run: psql $NEON_DATABASE_URL -f seeds/education.sql
-- ARRAY[...] literal: PostgreSQL native array syntax for TEXT[].
-- gpa + gpa_scale: website renders "4.0/4.0" and "9.01/10" correctly without hardcoding.
-- display_order = 1 is most recent (UW-Madison shown first).

INSERT INTO education (institution, degree, field, start_date, end_date, gpa, gpa_scale, courses, display_order) VALUES
(
    'University of Wisconsin-Madison',
    'M.S.',
    'Computer Science',
    '2025-09-01',
    '2027-05-31',
    4.00,
    4.00,
    ARRAY[
        'Intro to Artificial Intelligence (CS 540)',
        'Machine Learning (CS 760)',
        'Computational Network Biology (CS 775)',
        'High Performance Computing for Applications in Engineering (CS 759)',
        'Data Exploration, Cleaning & Integration (CS 774)'
    ],
    1
),
(
    'Birla Institute of Technology and Science (BITS), Pilani',
    'B.E. + M.Sc. (Dual Degree)',
    'Computer Science + Biological Sciences',
    '2020-11-01',
    '2025-06-30',
    9.01,
    10.00,
    ARRAY[
        'Data Structures & Algorithms',
        'Database Systems',
        'Object-Oriented Programming',
        'Computer Networks',
        'Operating Systems',
        'Microprocessors & Interfacing',
        'Computer Architecture',
        'Theory of Computation',
        'Design & Analysis of Algorithms',
        'Discrete Structures for Computer Science',
        'Logic in Computer Science',
        'Probability & Statistics',
        'Human Computer Interaction',
        'Digital Design',
        'Compiler Construction',
        'Principles of Programming Language'
    ],
    2
)
ON CONFLICT (institution, degree, start_date) DO UPDATE
    SET end_date      = EXCLUDED.end_date,
        gpa           = EXCLUDED.gpa,
        gpa_scale     = EXCLUDED.gpa_scale,
        courses       = EXCLUDED.courses,
        display_order = EXCLUDED.display_order,
        updated_at    = NOW();
