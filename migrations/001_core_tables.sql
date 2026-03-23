-- Migration 001: Core tables for portfolio data
-- Run: psql $NEON_DATABASE_URL -f migrations/001_core_tables.sql
-- Design notes:
--   - gen_random_uuid() is built-in since PostgreSQL 13, no extension needed
--   - UUID PKs over SERIAL: better for distributed systems and future merges
--   - display_order INT: controls UI sort order from DB, no frontend sorting logic needed

-- Key/value store for personal information.
-- Using key/value pattern instead of one column per field:
-- adding a new field = adding one row, not ALTER TABLE.
CREATE TABLE IF NOT EXISTS personal_info (
    id         UUID        NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    key        TEXT        NOT NULL UNIQUE,
    value      TEXT        NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Skills with enum-like TEXT CHECK constraints.
-- TEXT CHECK is simpler than CREATE TYPE at this scale:
-- ALTER TYPE to add a value is painful; CHECK on TEXT is one ALTER TABLE.
CREATE TABLE IF NOT EXISTS skills (
    id                  UUID        NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    name                TEXT        NOT NULL UNIQUE,
    category            TEXT        NOT NULL CHECK (category    IN ('language', 'framework', 'tool', 'concept')),
    proficiency         TEXT        NOT NULL CHECK (proficiency IN ('beginner', 'intermediate', 'advanced', 'expert')),
    years_of_experience INT,
    display_order       INT         NOT NULL DEFAULT 0,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Work experience.
-- bullets JSONB: stores ordered array of bullet strings.
-- JSONB preferred over TEXT[] because bullets may later carry metadata:
-- {"text": "Built Kafka engine", "metric": "3X retention"} — zero migration needed.
-- end_date NULL + is_current TRUE is the canonical pattern for ongoing roles.
-- Sentinel dates like 9999-12-31 break date arithmetic and look odd in dashboards.
CREATE TABLE IF NOT EXISTS experience (
    id            UUID        NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    company       TEXT        NOT NULL,
    role          TEXT        NOT NULL,
    location      TEXT,
    start_date    DATE        NOT NULL,
    end_date      DATE,                       -- NULL when is_current = TRUE
    is_current    BOOLEAN     NOT NULL DEFAULT FALSE,
    description   TEXT,
    bullets       JSONB,                      -- ["Built X", "Improved Y by 80%"]
    display_order INT         NOT NULL DEFAULT 0,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (company, role, start_date)
);

-- Education.
-- courses TEXT[]: plain array — courses are atomic strings with no future metadata need.
-- gpa + gpa_scale: lets website render "9.01/10" vs "4.0/4.0" without hardcoding the scale.
CREATE TABLE IF NOT EXISTS education (
    id            UUID          NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    institution   TEXT          NOT NULL,
    degree        TEXT          NOT NULL,
    field         TEXT          NOT NULL,
    start_date    DATE          NOT NULL,
    end_date      DATE,
    gpa           NUMERIC(4, 2),
    gpa_scale     NUMERIC(4, 2),
    courses       TEXT[],
    display_order INT           NOT NULL DEFAULT 0,
    created_at    TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    UNIQUE (institution, degree, start_date)
);

-- Projects and research.
-- tech_stack TEXT[]: machine-readable tag list — website renders as pill badges.
-- is_featured BOOLEAN: "homepage featured" vs "full portfolio page" distinction.
-- category CHECK: covers all meaningful project types at this scale.
CREATE TABLE IF NOT EXISTS projects (
    id            UUID        NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    title         TEXT        NOT NULL UNIQUE,
    category      TEXT        NOT NULL CHECK (category IN ('research', 'personal', 'coursework', 'professional')),
    description   TEXT,
    bullets       JSONB,                      -- ordered array of bullet strings
    tech_stack    TEXT[],
    github_url    TEXT,
    live_url      TEXT,
    collaborator  TEXT,
    is_featured   BOOLEAN     NOT NULL DEFAULT FALSE,
    display_order INT         NOT NULL DEFAULT 0,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Awards, scholarships, competitions.
CREATE TABLE IF NOT EXISTS achievements (
    id            UUID        NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    title         TEXT        NOT NULL,
    organization  TEXT        NOT NULL,
    description   TEXT,
    date          DATE,
    category      TEXT        NOT NULL CHECK (category IN ('scholarship', 'award', 'competition', 'recognition')),
    display_order INT         NOT NULL DEFAULT 0,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (title, organization)
);
