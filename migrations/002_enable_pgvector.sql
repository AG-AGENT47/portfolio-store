-- Migration 002: Enable pgvector extension
-- Run: psql $NEON_DATABASE_URL -f migrations/002_enable_pgvector.sql
-- Must run before migration 003 — the knowledge_base table requires the VECTOR type.
--
-- pgvector adds:
--   VECTOR(n) type      — fixed-dimension float array
--   <=>  operator       — cosine distance   (standard for text RAG)
--   <#>  operator       — negative inner product
--   <->  operator       — L2 (Euclidean) distance
--
-- IF NOT EXISTS makes this idempotent — safe to re-run in any environment.

CREATE EXTENSION IF NOT EXISTS vector;
