-- Migration 004: Add RAG chatbot project and update featured project list
-- Run: psql $NEON_DATABASE_URL -f migrations/004_update_featured_projects.sql

-- Add RAG-Powered Portfolio Chatbot as a featured project
INSERT INTO projects (title, category, description, bullets, tech_stack, github_url, live_url, is_featured, display_order) VALUES
(
    'RAG-Powered Portfolio Chatbot',
    'personal',
    '3-repo Go system powering this portfolio''s AI chat. SSE-streamed LLM responses, hybrid vector+FTS retrieval with Voyage AI embeddings on Neon PostgreSQL.',
    '[
        "Built a 3-service system: portfolio-store (Neon PostgreSQL + pgvector), rag-chatbot (Go API on Render), and portfolio-website (Next.js on Vercel)",
        "Hybrid retrieval: pgvector cosine similarity + full-text search merged via Reciprocal Rank Fusion (RRF) — top-5 chunks per query at ~350–500 tokens context",
        "Pluggable LLM backends (Groq Llama 3.3 70B primary, Gemini 1.5 Flash fallback) with SSE token streaming and prompt injection guardrails",
        "Query contextualization for pronoun resolution, prompt-injection guardrails, and a topic filter (cosine distance > 0.75 redirects off-topic questions without an LLM call)"
    ]'::jsonb,
    ARRAY['Go', 'PostgreSQL', 'pgvector', 'Voyage AI', 'Groq', 'SSE', 'Neon', 'Render', 'Next.js'],
    NULL,
    'https://rag-chatbot-qge9.onrender.com',
    TRUE,
    0
)
ON CONFLICT (title) DO UPDATE
    SET description   = EXCLUDED.description,
        bullets       = EXCLUDED.bullets,
        tech_stack    = EXCLUDED.tech_stack,
        live_url      = EXCLUDED.live_url,
        is_featured   = TRUE,
        display_order = 0,
        updated_at    = NOW();

-- Mark GPU IVF-PQ as featured (was coursework but represents graduate HPC depth)
UPDATE projects
SET is_featured = TRUE, display_order = 1, updated_at = NOW()
WHERE title = 'GPU-Accelerated ANN Search with IVF-PQ Indexing';

-- Reorder remaining featured projects
UPDATE projects SET display_order = 2, updated_at = NOW() WHERE title = 'Graph Learning for Heart Disease Prediction';
UPDATE projects SET display_order = 3, updated_at = NOW() WHERE title = 'Patterning Protein Localisation in Endothelial Cells';
UPDATE projects SET is_featured = TRUE, display_order = 4, updated_at = NOW() WHERE title = 'Deep Learning Framework for ICP Prediction using OCT Scans';
