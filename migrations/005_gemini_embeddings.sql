-- Migration 005: switch knowledge_base embeddings to Google Gemini
-- Run: psql "$NEON_DATABASE_URL" -f migrations/005_gemini_embeddings.sql
-- Then re-seed: psql "$NEON_DATABASE_URL" -f seeds/knowledge_base.sql
--
-- Why: Voyage AI voyage-3-lite is a legacy model whose free tier drops to
-- 3 requests/minute once the one-time trial credit is spent — every /chat
-- message needs one embedding call, so the chatbot was effectively capped at
-- ~3 answers/minute and later went fully down when the prod key stopped
-- working. Google gemini-embedding-001 is free at ~100 RPM with no card.
--
-- Model:      gemini-embedding-001
-- Dimensions: 768  (outputDimensionality=768; matches embed.py + embedder.go)
-- Task types: documents RETRIEVAL_DOCUMENT, queries RETRIEVAL_QUERY
--
-- Rollback: set EMBED_PROVIDER=voyage in rag-chatbot, restore the 512-dim
-- column + the prior seeds/knowledge_base.sql from git, re-seed.

-- The ivfflat index was built on an empty table (no centroids) and never
-- rebuilt, so it was dead weight. At ~46 rows an exact sequential cosine scan
-- is sub-millisecond — drop it. Re-introduce HNSW here only past a few
-- thousand rows.
DROP INDEX IF EXISTS knowledge_base_embedding_idx;

-- Dimensionality is fixed at model-selection time; changing it means a new
-- column, not an ALTER of the vector's typmod.
ALTER TABLE knowledge_base DROP COLUMN IF EXISTS embedding;
ALTER TABLE knowledge_base ADD COLUMN embedding VECTOR(768);

-- knowledge_base.sql TRUNCATEs and re-INSERTs every row, so no data backfill
-- is needed here — just run it after this migration.
