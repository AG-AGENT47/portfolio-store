-- Seed: skills
-- Run: psql $NEON_DATABASE_URL -f seeds/skills.sql
-- ON CONFLICT DO NOTHING: idempotent — re-running adds no duplicates.
-- display_order controls the exact render sequence on the portfolio website.
-- Proficiency levels assigned honestly based on actual usage depth.

-- Languages
INSERT INTO skills (name, category, proficiency, years_of_experience, display_order) VALUES
    ('Java',       'language', 'expert',       3, 1),
    ('Python',     'language', 'expert',       4, 2),
    ('C/C++',      'language', 'advanced',     3, 3),
    ('SQL',        'language', 'intermediate', 3, 4),
    ('HTML',       'language', 'intermediate', 2, 5),
    ('JavaScript', 'language', 'intermediate', 2, 6),
    ('LaTeX',      'language', 'intermediate', 3, 7)
ON CONFLICT (name) DO NOTHING;

-- Frameworks / Libraries
INSERT INTO skills (name, category, proficiency, years_of_experience, display_order) VALUES
    ('SpringBoot',   'framework', 'advanced', 2, 1),
    ('TensorFlow',   'framework', 'advanced', 3, 2),
    ('PyTorch',      'framework', 'advanced', 3, 3),
    ('Scikit-learn', 'framework', 'advanced', 3, 4),
    ('OpenCV',       'framework', 'advanced', 2, 5),
    ('GraphSAGE',    'framework', 'advanced', 1, 6),
    ('Node2Vec',     'framework', 'advanced', 1, 7),
    ('Pandas',       'framework', 'expert',   4, 8),
    ('NumPy',        'framework', 'expert',   4, 9)
ON CONFLICT (name) DO NOTHING;

-- GPU / HPC
INSERT INTO skills (name, category, proficiency, years_of_experience, display_order) VALUES
    ('CUDA',         'framework', 'intermediate', 1, 10),
    ('PyTorch Geometric', 'framework', 'intermediate', 1, 11)
ON CONFLICT (name) DO NOTHING;

-- Tools / Platforms
INSERT INTO skills (name, category, proficiency, years_of_experience, display_order) VALUES
    ('OpenMP', 'tool', 'intermediate', 1, 12),
    ('CMake',  'tool', 'intermediate', 1, 13)
ON CONFLICT (name) DO NOTHING;

INSERT INTO skills (name, category, proficiency, years_of_experience, display_order) VALUES
    ('Kafka',     'tool', 'advanced',     1, 1),
    ('gRPC',      'tool', 'advanced',     1, 2),
    ('REST',      'tool', 'advanced',     3, 3),
    ('FastAPI',   'tool', 'advanced',     2, 4),
    ('Docker',    'tool', 'intermediate', 2, 5),
    ('Git',       'tool', 'expert',       4, 6),
    ('MVC',       'tool', 'advanced',     2, 7),
    ('Mockito',   'tool', 'intermediate', 1, 8),
    ('Streamlit', 'tool', 'intermediate', 1, 9),
    ('Agile',     'tool', 'intermediate', 2, 10),
    ('JIRA',      'tool', 'intermediate', 2, 11),
    ('JavaFX',    'framework', 'intermediate', 1, 12),
    ('MySQL',     'tool', 'intermediate', 1, 14)
ON CONFLICT (name) DO NOTHING;
