-- Migration 007: project links
-- Run: psql "$NEON_DATABASE_URL" -f migrations/007_project_links.sql
--
-- Adds the GitHub links that were missing, and points the RAG chatbot's
-- "live demo" at this site's own chat section (#chat) instead of the raw
-- Render URL. Idempotent — seeds/projects.sql now carries the same values.

UPDATE projects
SET github_url = 'https://github.com/AG-AGENT47/rag-chatbot',
    live_url   = '#chat',
    updated_at = NOW()
WHERE title = 'RAG-Powered Portfolio Chatbot';

UPDATE projects
SET github_url = 'https://github.com/AG-AGENT47/parallel-vector-database',
    updated_at = NOW()
WHERE title = 'GPU-Accelerated Vector Search Engine';
