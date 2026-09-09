# portfolio-store

Single source of truth for Avyakt Garg's portfolio system: the PostgreSQL schema,
all seed data (résumé content), and the pre-computed vector embeddings the chatbot
retrieves against. No application server — just SQL plus one Python script.

```
portfolio-website  ─┐
                    ├─►  portfolio-store  (Neon Postgres + pgvector)
rag-chatbot        ─┘
```

- **`portfolio-website`** reads the six structured tables at build time (ISR, ≤ 1 h).
- **`rag-chatbot`** reads the `knowledge_base` vectors live on every question.

See **[`UPDATING.md`](UPDATING.md)** for how to change content and get it onto the
live site.

---

## Why Neon (not Supabase)

Supabase's free tier **auto-pauses** after 7 days idle — a recruiter visiting
after two weeks hits a 5–30 s cold start and the site looks broken. Neon's free
tier does not auto-pause: 10 GB storage (this whole DB is < 1 MB), `pgvector`
built in, standard `postgres://` connection string.

---

## Prerequisites

- A [Neon](https://neon.tech) project (free).
- `psql` — `brew install libpq` (keg-only: add `/opt/homebrew/opt/libpq/bin` to `PATH`) or `brew install postgresql`.
- Python 3.10+ — only to **regenerate** embeddings.
- A **Google AI Studio API key** (`GEMINI_API_KEY`) — free, no card, from
  <https://aistudio.google.com/apikey>. Only needed to regenerate embeddings.

```bash
export NEON_DATABASE_URL="postgres://user:pass@ep-xxxx-pooler.neon.tech/dbname?sslmode=require"
```

Use the **pooled** connection string (host contains `-pooler`).

---

## Setup: fresh database

### 1. Migrations — in order

```bash
psql "$NEON_DATABASE_URL" -f migrations/001_core_tables.sql        # personal_info, skills, experience, education, projects, achievements
psql "$NEON_DATABASE_URL" -f migrations/002_enable_pgvector.sql    # CREATE EXTENSION vector
psql "$NEON_DATABASE_URL" -f migrations/003_knowledge_base.sql     # knowledge_base + interactions
psql "$NEON_DATABASE_URL" -f migrations/004_update_featured_projects.sql   # adds the "RAG-Powered Portfolio Chatbot" project + featured ordering
psql "$NEON_DATABASE_URL" -f migrations/005_gemini_embeddings.sql  # drop dead ivfflat index; embedding VECTOR(512 → 768) for Gemini
psql "$NEON_DATABASE_URL" -f migrations/006_project_metadata_fixes.sql   # rename GPU project; correct RAG chatbot row
psql "$NEON_DATABASE_URL" -f migrations/007_project_links.sql            # project GitHub links; RAG live demo -> #chat
```

Migrations are append-only and run in filename order — never edit an applied one,
write a new one. Migration 003 created a `VECTOR(512)` column and an ivfflat
index for the original Voyage embedder; **migration 005 supersedes both** (768-dim
for Gemini, no index — an exact scan over 50 rows is sub-millisecond). The inline
comments in 003 describe the state *at the time it was written*.

### 2. Seeds — every file is an idempotent upsert (`ON CONFLICT DO UPDATE`)

```bash
psql "$NEON_DATABASE_URL" -f seeds/personal_info.sql
psql "$NEON_DATABASE_URL" -f seeds/skills.sql
psql "$NEON_DATABASE_URL" -f seeds/experience.sql
psql "$NEON_DATABASE_URL" -f seeds/education.sql
psql "$NEON_DATABASE_URL" -f seeds/projects.sql
psql "$NEON_DATABASE_URL" -f seeds/achievements.sql
psql "$NEON_DATABASE_URL" -f seeds/knowledge_base.sql   # pre-computed 768-dim Gemini vectors, committed — no API call needed
```

`seeds/knowledge_base.sql` is a **generated file** (`TRUNCATE` + re-`INSERT`); it
is committed with real vectors so a fresh setup needs no API key.

### 3. Regenerate embeddings — only when résumé content changes

```bash
# Edit scripts/embed.py first if the change is new information (the CHUNKS list).
export GEMINI_API_KEY="AIza..."
python scripts/embed.py                                 # stdlib urllib only — no pip install; ~10 s for 50 chunks
psql "$NEON_DATABASE_URL" -f seeds/knowledge_base.sql   # reload
```

`scripts/embed.py` calls the Gemini `embedContent` REST API
(`gemini-embedding-001`, `outputDimensionality=768`, `taskType=RETRIEVAL_DOCUMENT`)
and rewrites `seeds/knowledge_base.sql`. It must stay in sync with the query-side
embedder in `rag-chatbot/internal/rag/embedder.go`.

A one-shot helper for the 512→768 migration + reseed:
`bash scripts/apply_gemini_migration.sh`.

### 4. Verify

```bash
psql "$NEON_DATABASE_URL" -c "
SELECT 'personal_info'   AS t, COUNT(*) FROM personal_info
UNION ALL SELECT 'skills',         COUNT(*) FROM skills
UNION ALL SELECT 'experience',     COUNT(*) FROM experience
UNION ALL SELECT 'education',      COUNT(*) FROM education
UNION ALL SELECT 'projects',       COUNT(*) FROM projects
UNION ALL SELECT 'projects (featured)', COUNT(*) FROM projects WHERE is_featured
UNION ALL SELECT 'achievements',   COUNT(*) FROM achievements
UNION ALL SELECT 'knowledge_base', COUNT(*) FROM knowledge_base;
"
```

Approximate expected counts (they grow as content is added): personal_info 17,
skills 42, experience 7, education 2, projects 11 (5 featured), achievements 4,
knowledge_base **50**.

```bash
# Embeddings must be 768-dim and non-NULL
psql "$NEON_DATABASE_URL" -c "SELECT count(*), vector_dims(embedding) FROM knowledge_base GROUP BY 2;"
# expect: 50 | 768

# Smoke test: nearest neighbours to the Uber chunk should be other work chunks
psql "$NEON_DATABASE_URL" -c "
SELECT source, source_type,
       1 - (embedding <=> (SELECT embedding FROM knowledge_base WHERE source LIKE 'uber%' LIMIT 1)) AS similarity
FROM knowledge_base
ORDER BY embedding <=> (SELECT embedding FROM knowledge_base WHERE source LIKE 'uber%' LIMIT 1)
LIMIT 5;
"
```

---

## Adding a new data type (certifications, publications, talks…)

No change needed in `portfolio-website` query wiring only if it's a new *table*
the website already renders — otherwise it also needs a query + component there.
The chatbot picks up any new `knowledge_base` rows automatically (retrieval is
table-agnostic).

```
1. migrations/008_<type>.sql   — DDL only (next unused number)
2. seeds/<type>.sql            — data, ON CONFLICT upsert
3. scripts/embed.py            — append chunks to the CHUNKS list
4. python scripts/embed.py     — regenerates seeds/knowledge_base.sql
5. psql -f migrations/008_<type>.sql ; psql -f seeds/<type>.sql ; psql -f seeds/knowledge_base.sql
```

---

## Updating existing data

All seed files upsert, so: edit the seed file → re-run it → (if the text is in
the knowledge base) `python scripts/embed.py` and reload `knowledge_base.sql`.
Full walkthrough, including how the change reaches the live website, in
**[`UPDATING.md`](UPDATING.md)**.

To apply the current résumé-driven batch to an **existing** DB (migrations 004 +
006, the content seeds, and the regenerated 50-chunk knowledge base — skips the
destructive migration 005):

```bash
bash scripts/apply_resume_updates.sh   # reads NEON_DATABASE_URL, or rag-chatbot/.env
```

---

## Connecting from the other services

Same database, two env-var names:

| Repo | Variable |
|---|---|
| `rag-chatbot` | `NEON_DATABASE_URL` |
| `portfolio-website` | `DATABASE_URL` |

```python
import os, psycopg2; conn = psycopg2.connect(os.environ["NEON_DATABASE_URL"])
```
```go
pool, err := pgxpool.New(ctx, os.Getenv("NEON_DATABASE_URL"))
```

For deploys, set the variable in the Vercel / Render dashboard.

---

## Layout

```
portfolio-store/
├── migrations/
│   ├── 001_core_tables.sql          personal_info, skills, experience, education, projects, achievements
│   ├── 002_enable_pgvector.sql      CREATE EXTENSION vector
│   ├── 003_knowledge_base.sql       knowledge_base + interactions  (original VECTOR(512) + ivfflat — see 005)
│   ├── 004_update_featured_projects.sql   adds the RAG chatbot project, sets featured ordering
│   ├── 005_gemini_embeddings.sql    drop ivfflat, embedding VECTOR(512 → 768) for Gemini
│   ├── 006_project_metadata_fixes.sql  rename GPU project; fix RAG chatbot row (Voyage→Gemini)
│   └── 007_project_links.sql           project GitHub links; RAG live demo → #chat
├── seeds/
│   ├── personal_info.sql  skills.sql  experience.sql  education.sql  projects.sql  achievements.sql
│   └── knowledge_base.sql           GENERATED by embed.py — 50 chunks, 768-dim Gemini vectors, committed
├── scripts/
│   ├── embed.py                     builds knowledge_base.sql via Gemini gemini-embedding-001 (stdlib only)
│   ├── apply_resume_updates.sh     one-shot: migrations 004+006 + content seeds + knowledge_base reseed
│   ├── apply_gemini_migration.sh    one-shot: run migration 005 + reseed + verify
│   └── requirements.txt             psycopg2-binary — only for optional DB tooling, not embed.py
├── UPDATING.md                      how to change content and get it onto the site
├── README.md
└── CLAUDE.md
```

> There is no committed `schema.sql` snapshot. To produce one on demand:
> `pg_dump "$NEON_DATABASE_URL" --schema-only --no-owner --no-privileges > schema.sql`.
