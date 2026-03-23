# portfolio-store

Single source of truth database for Avyakt Garg's portfolio system. Contains the PostgreSQL schema, all seed data (resume content), and pre-computed vector embeddings for the RAG chatbot. No application server — just SQL and one Python script.

Both `portfolio-website` and `rag-chatbot` connect to this database using a connection string in their own `.env` files.

---

## Why Neon (not Supabase)

Supabase free tier **auto-pauses** after 7 days of inactivity. When a recruiter visits your portfolio after two weeks, the first database query triggers a cold-start that takes 5–30 seconds. The website appears broken.

Neon has no auto-pause on its free tier:
- **10 GB free storage** — vector embeddings for this portfolio are ~320 KB total
- **pgvector built-in** — `CREATE EXTENSION vector` works without any extra setup
- **Standard connection string** — `postgres://` URL, drop-in replacement if you ever migrate

---

## Prerequisites

- [Neon account](https://neon.tech) (free, sign up with GitHub)
- `psql` — PostgreSQL client (`brew install postgresql` on macOS)
- Python 3.10+ with pip — only needed to regenerate embeddings
- Voyage AI API key — free at [voyageai.com](https://www.voyageai.com), only needed to regenerate embeddings

---

## Setup: New Environment

### Step 1 — Create Neon project

1. Go to neon.tech, sign up with GitHub
2. Click **New Project** → name it `portfolio-store`
3. Copy the **pooled connection string** (recommended — uses pgBouncer for connection pooling)
4. It looks like: `postgres://user:password@host.neon.tech/dbname?sslmode=require`

```bash
export NEON_DATABASE_URL="postgres://user:password@host.neon.tech/dbname?sslmode=require"
```

### Step 2 — Run migrations in order

```bash
psql "$NEON_DATABASE_URL" -f migrations/001_core_tables.sql
psql "$NEON_DATABASE_URL" -f migrations/002_enable_pgvector.sql
psql "$NEON_DATABASE_URL" -f migrations/003_knowledge_base.sql
```

Run them in this exact order — migration 003 depends on the `vector` type from migration 002.

### Step 3 — Run seed files

```bash
psql "$NEON_DATABASE_URL" -f seeds/personal_info.sql
psql "$NEON_DATABASE_URL" -f seeds/skills.sql
psql "$NEON_DATABASE_URL" -f seeds/experience.sql
psql "$NEON_DATABASE_URL" -f seeds/education.sql
psql "$NEON_DATABASE_URL" -f seeds/projects.sql
psql "$NEON_DATABASE_URL" -f seeds/achievements.sql
```

All seed files use `ON CONFLICT DO UPDATE` (upsert) — safe to re-run at any time.

### Step 4 — Load pre-computed knowledge base embeddings

The `seeds/knowledge_base.sql` file is **already committed** to this repo with pre-computed Voyage AI embeddings. Just run it:

```bash
psql "$NEON_DATABASE_URL" -f seeds/knowledge_base.sql
```

Skip to Step 6 to verify. Only go to Step 5 if you changed resume content and need to regenerate embeddings.

### Step 5 — Regenerate embeddings (only when resume content changes)

```bash
# One-time: sign up at voyageai.com, get your API key
export VOYAGE_API_KEY="your_api_key_here"

pip install -r scripts/requirements.txt
python scripts/embed.py

# Then reload the knowledge base
psql "$NEON_DATABASE_URL" -f seeds/knowledge_base.sql
```

`embed.py` downloads nothing — it calls the Voyage AI API (200M free tokens, enough to re-embed thousands of times). Takes ~5 seconds for ~35 chunks.

### Step 6 — Verify

```bash
# Row counts — run all at once
psql "$NEON_DATABASE_URL" -c "
SELECT 'personal_info' AS table_name, COUNT(*) FROM personal_info
UNION ALL SELECT 'skills',       COUNT(*) FROM skills
UNION ALL SELECT 'experience',   COUNT(*) FROM experience
UNION ALL SELECT 'education',    COUNT(*) FROM education
UNION ALL SELECT 'projects',     COUNT(*) FROM projects
UNION ALL SELECT 'achievements', COUNT(*) FROM achievements
UNION ALL SELECT 'knowledge_base', COUNT(*) FROM knowledge_base;
"
```

Expected: 8, 26, 4, 2, 5, 4, ~35

```bash
# Confirm embeddings are 1024-dim (not NULL)
psql "$NEON_DATABASE_URL" -c "
SELECT id, source_type, vector_dims(embedding)
FROM knowledge_base LIMIT 5;
"
```

```bash
# Smoke test: cosine similarity search
psql "$NEON_DATABASE_URL" -c "
SELECT content, source_type,
       1 - (embedding <=> (SELECT embedding FROM knowledge_base WHERE source = 'uber_experience' LIMIT 1)) AS similarity
FROM knowledge_base
ORDER BY embedding <=> (SELECT embedding FROM knowledge_base WHERE source = 'uber_experience' LIMIT 1)
LIMIT 5;
"
```

The top result should be the Uber chunk itself (similarity ≈ 1.0). The next results should be other work experience chunks.

---

## Adding New Data Types

To add certifications, publications, talks, or any new content type — no changes needed in `portfolio-website` or `rag-chatbot`:

```
1. Create migrations/004_certifications.sql   ← DDL only
2. Create seeds/certifications.sql            ← seed data (with ON CONFLICT upsert)
3. Add chunks to scripts/embed.py             ← append to the CHUNKS list
4. Re-run: python scripts/embed.py            ← regenerates seeds/knowledge_base.sql
5. psql "$NEON_DATABASE_URL" -f migrations/004_certifications.sql
6. psql "$NEON_DATABASE_URL" -f seeds/certifications.sql
7. psql "$NEON_DATABASE_URL" -f seeds/knowledge_base.sql
```

The chatbot picks up new content automatically — the RAG query (`ORDER BY embedding <=> $query_vector`) searches all rows regardless of `source_type`.

---

## Updating Existing Data

All seed files use `ON CONFLICT DO UPDATE`. To update any value:

```bash
# 1. Edit the seed file (e.g. seeds/experience.sql)
# 2. Re-run the seed
psql "$NEON_DATABASE_URL" -f seeds/experience.sql

# 3. If you changed text that should be in the knowledge base, also update embeddings:
python scripts/embed.py
psql "$NEON_DATABASE_URL" -f seeds/knowledge_base.sql
```

---

## Connecting from Other Services

```bash
NEON_DATABASE_URL=postgres://user:password@host.neon.tech/dbname?sslmode=require
```

**Python:**
```python
import os, psycopg2
conn = psycopg2.connect(os.environ["NEON_DATABASE_URL"])
```

**Go:**
```go
db, err := sql.Open("pgx", os.Getenv("NEON_DATABASE_URL"))
```

For deployment (Vercel, Render, Fly.io): add `NEON_DATABASE_URL` as an environment variable in the deployment dashboard.

---

## Regenerating schema.sql

After running new migrations, regenerate the snapshot:

```bash
pg_dump "$NEON_DATABASE_URL" --schema-only --no-owner --no-privileges > schema.sql
```

`schema.sql` is committed for reference — it shows the full current shape of the database without reading all migration files. Never hand-edit it.

---

## Folder Structure

```
portfolio-store/
├── migrations/
│   ├── 001_core_tables.sql       ← personal_info, skills, experience, education, projects, achievements
│   ├── 002_enable_pgvector.sql   ← CREATE EXTENSION vector
│   └── 003_knowledge_base.sql    ← knowledge_base + interactions tables, IVFFlat index
├── seeds/
│   ├── personal_info.sql
│   ├── skills.sql
│   ├── experience.sql
│   ├── education.sql
│   ├── projects.sql
│   ├── achievements.sql
│   └── knowledge_base.sql        ← generated by embed.py, committed to repo
├── scripts/
│   ├── embed.py                  ← generates knowledge_base.sql with Voyage AI vectors
│   └── requirements.txt
├── schema.sql                    ← full schema snapshot (pg_dump, regenerated, not hand-edited)
├── README.md
└── CLAUDE.md
```
