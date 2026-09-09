#!/usr/bin/env bash
# One-shot: migrate knowledge_base to 768-dim Gemini embeddings and re-seed.
# Run from anywhere:  bash portfolio-store/scripts/apply_gemini_migration.sh
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"          # …/portfolio-store
WORKSPACE="$(cd "$REPO_ROOT/.." && pwd)"

# psql from Homebrew libpq is keg-only — make sure it's reachable.
export PATH="/opt/homebrew/opt/libpq/bin:/usr/local/opt/libpq/bin:$PATH"
command -v psql >/dev/null || { echo "ERROR: psql not found. brew install libpq"; exit 1; }

# Connection string: prefer an already-exported one, else read rag-chatbot/.env.
URL="${NEON_DATABASE_URL:-}"
if [ -z "$URL" ]; then
  URL="$(grep -E '^NEON_DATABASE_URL=' "$WORKSPACE/rag-chatbot/.env" | cut -d= -f2- | tr -d '"' | tr -d "'")"
fi
[ -n "$URL" ] || { echo "ERROR: NEON_DATABASE_URL not set and not found in rag-chatbot/.env"; exit 1; }

echo "== before =="
psql "$URL" -c "SELECT count(*) AS rows, vector_dims(embedding) AS dims FROM knowledge_base GROUP BY 2;"

echo "== migration 005 =="
psql "$URL" -v ON_ERROR_STOP=1 -f "$REPO_ROOT/migrations/005_gemini_embeddings.sql"

echo "== re-seed knowledge_base =="
psql "$URL" -v ON_ERROR_STOP=1 -f "$REPO_ROOT/seeds/knowledge_base.sql" | tail -3

echo "== after (expect: 46 | 768) =="
psql "$URL" -c "SELECT count(*) AS rows, vector_dims(embedding) AS dims FROM knowledge_base GROUP BY 2;"
echo "done."
