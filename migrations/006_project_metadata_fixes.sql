-- Migration 006: project metadata fixes
-- Run: psql "$NEON_DATABASE_URL" -f migrations/006_project_metadata_fixes.sql
-- Then re-seed: psql "$NEON_DATABASE_URL" -f seeds/projects.sql
--
-- 1. Rename the GPU project so seeds/projects.sql (which now uses the shorter
--    title from the current resume) upserts the existing row instead of
--    inserting a duplicate. Idempotent — no-op if already renamed.
-- 2. Correct the RAG-Powered Portfolio Chatbot row added by migration 004:
--    it still described Voyage AI embeddings, "Groq Llama 3.3 70B", and HyDE.
--    Reality (see rag-chatbot): Google Gemini gemini-embedding-001 @ 768d,
--    Groq openai/gpt-oss-120b, and no HyDE (hybrid vector + FTS with RRF).

UPDATE projects
SET title = 'GPU-Accelerated Vector Search Engine',
    updated_at = NOW()
WHERE title = 'GPU-Accelerated ANN Search with IVF-PQ Indexing';

UPDATE projects
SET description = '3-repo Go system powering this portfolio''s AI chat. SSE-streamed LLM responses, hybrid pgvector + full-text retrieval (Reciprocal Rank Fusion) over Google Gemini embeddings on Neon PostgreSQL.',
    bullets = '[
        "Built a 3-service system: portfolio-store (Neon PostgreSQL + pgvector), rag-chatbot (Go API on Render), and portfolio-website (Next.js on Vercel)",
        "Hybrid retrieval: pgvector cosine similarity + Postgres full-text search merged via Reciprocal Rank Fusion (RRF) — top-5 chunks per query at ~350-500 tokens of context",
        "Pluggable LLM backends (Groq openai/gpt-oss-120b primary, Gemini fallback) with SSE token streaming, prompt-injection guardrails, and query contextualization for pronoun resolution",
        "Topic filter uses the minimum vector distance across retrieved chunks to redirect off-topic questions without an LLM call"
    ]'::jsonb,
    tech_stack = ARRAY['Go', 'PostgreSQL', 'pgvector', 'Gemini', 'Groq', 'SSE', 'Neon', 'Render', 'Next.js'],
    updated_at = NOW()
WHERE title = 'RAG-Powered Portfolio Chatbot';
