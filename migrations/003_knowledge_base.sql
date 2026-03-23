-- Migration 003: Knowledge base and interaction tracking
-- Run: psql $NEON_DATABASE_URL -f migrations/003_knowledge_base.sql
-- Depends on: migration 002 (pgvector extension must be enabled first)

-- Pre-chunked text with Voyage AI embeddings for RAG retrieval.
-- embedding VECTOR(512): matches voyage-3-lite output dimensions exactly.
-- Dimension is fixed at model selection time — switching models requires
-- dropping and recreating this column (a new migration, not an edit here).
--
-- Chunking strategy (enforced in embed.py, reflected here for documentation):
--   One semantically complete thought = one chunk.
--   One chunk per experience bullet, per project bullet, per achievement,
--   per skill-category group, per education entry.
--   This gives tight, specific context — a query for "Kafka" returns exactly
--   the Kafka bullet, not the entire Uber job description.
CREATE TABLE IF NOT EXISTS knowledge_base (
    id          UUID        NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    content     TEXT        NOT NULL,          -- the enriched text chunk
    source      TEXT        NOT NULL,          -- e.g. 'uber_experience', 'graph_learning_project'
    source_type TEXT        NOT NULL CHECK (source_type IN (
                    'experience', 'project', 'education', 'achievement', 'skill', 'personal'
                )),
    metadata    JSONB       NOT NULL DEFAULT '{}', -- company, date, urls, etc.
    embedding   VECTOR(512),                  -- pre-computed via Voyage AI voyage-3-lite
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- IVFFlat approximate nearest-neighbor index using cosine distance.
-- Cosine similarity (<=>) measures the angle between vectors — captures semantic
-- meaning regardless of text length. Standard choice for all text RAG systems.
-- Voyage AI vectors are pre-normalized so cosine equals inner product.
--
-- lists = 10: clusters vectors into 10 buckets; at query time only the nearest
-- buckets are searched. For ~80 rows the speed gain is negligible, but building
-- this habit now means you understand why RAG is fast at 100,000 rows.
-- Chatbot query pattern: ORDER BY embedding <=> $query_vector LIMIT 5
CREATE INDEX IF NOT EXISTS knowledge_base_embedding_idx
    ON knowledge_base USING ivfflat (embedding vector_cosine_ops)
    WITH (lists = 10);

-- Chatbot interaction logs.
-- Written at runtime by rag-chatbot. Feeds the portfolio website's live metrics
-- dashboard (total queries, average latency, recent questions).
-- rating is user-provided (1–5), latency_ms is measured server-side.
CREATE TABLE IF NOT EXISTS interactions (
    id         UUID        NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    question   TEXT        NOT NULL,
    answer     TEXT        NOT NULL,
    latency_ms INT,
    rating     INT         CHECK (rating BETWEEN 1 AND 5),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
