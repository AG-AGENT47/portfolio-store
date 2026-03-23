-- Seed: experience
-- Run: psql $NEON_DATABASE_URL -f seeds/experience.sql
-- ON CONFLICT (company, role, start_date) DO UPDATE: upsert — safe to re-run.
-- bullets is JSONB array of strings — each bullet is one self-contained achievement.
-- display_order = 1 is most recent (upcoming Uber 2026 shown first).

INSERT INTO experience (company, role, location, start_date, end_date, is_current, description, bullets, display_order) VALUES
(
    'Uber',
    'Software Engineer Intern',
    'Hyderabad, India',
    '2026-05-11',
    NULL,
    FALSE,
    'Upcoming Summer 2026 SWE internship at Uber.',
    '[]'::jsonb,
    1
),
(
    'Uber',
    'Software Engineer Intern',
    'Hyderabad, India',
    '2024-07-01',
    '2025-06-30',
    FALSE,
    'Backend engineering on Uber AI Solutions — knowledge work marketplace and developer tooling.',
    '[
        "Developed an upcoming knowledge work marketplace for 5+ countries covering data annotation and ML model training workflows",
        "Implemented a rate-card system in Java SpringBoot using MVC architecture; developed gRPC APIs for cross-service integration",
        "Created a Kafka-based notification engine with optimized cadence scheduling — improved customer retention funnel 3X",
        "Built a debug tool with 7 automated checks for Uber AI Solutions — reduced developer dependency on recurring issues by 80%"
    ]'::jsonb,
    2
),
(
    'University of Saskatchewan',
    'Mitacs Research Intern',
    'Saskatoon, SK, Canada',
    '2023-05-01',
    '2023-08-31',
    FALSE,
    'Biomedical data analysis and database engineering under Prof. Jaswant Singh.',
    '[
        "Collaborated with Prof. Jaswant Singh (biomedical sciences) on cattle health and reproduction data analysis",
        "Automated daily cattle weighing via RFID-based (Radio Frequency Identification) data collection and analysis system — saved 3,000+ hours/year of manual work",
        "Revamped cattle management database with 6,600+ entries — achieved 90% faster queries via optimized genealogy links and indexing"
    ]'::jsonb,
    3
),
(
    'Indian Institute of Technology, Ropar',
    'Research Intern',
    'Ropar, Punjab, India',
    '2022-07-01',
    '2022-09-30',
    FALSE,
    'ML for IoT-based cattle health monitoring under faculty supervision.',
    '[
        "Trained and evaluated ML models (machine learning classification algorithms) for cattle health monitoring using farm-based IoT sensor data",
        "Analyzed 4,000+ data points for cattle behavior prediction including movement patterns and estrus detection"
    ]'::jsonb,
    4
),
(
    'MapmyIndia',
    'Software Intern',
    'New Delhi, India',
    '2022-05-01',
    '2022-07-31',
    FALSE,
    'Web application development using mapping APIs and routing algorithms.',
    '[
        "Built a web app for delivery executives using the Traveling Salesman Problem (TSP) algorithm for optimal multi-stop trip routing",
        "Integrated an interactive map API (HTML, CSS, JavaScript) with dynamic resizing and custom marker placement features"
    ]'::jsonb,
    5
)
ON CONFLICT (company, role, start_date) DO UPDATE
    SET location      = EXCLUDED.location,
        description   = EXCLUDED.description,
        bullets       = EXCLUDED.bullets,
        end_date      = EXCLUDED.end_date,
        is_current    = EXCLUDED.is_current,
        display_order = EXCLUDED.display_order,
        updated_at    = NOW();
