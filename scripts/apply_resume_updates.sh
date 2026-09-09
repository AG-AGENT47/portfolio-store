#!/usr/bin/env bash
# One-shot: apply the resume-driven content updates to the live Neon DB.
#   bash portfolio-store/scripts/apply_resume_updates.sh
#
# Runs (in order): migration 004 (featured projects), migration 006 (project
# metadata fixes + GPU rename), then the content seeds, then the regenerated
# knowledge_base (50 chunks). All are idempotent / upserts — safe to re-run.
# Does NOT run migration 005 (that one drops+recreates the embedding column).
set -euo pipefail

export PATH="/opt/homebrew/opt/libpq/bin:/usr/local/opt/libpq/bin:$PATH"
command -v psql >/dev/null || { echo "ERROR: psql not found. brew install libpq"; exit 1; }

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORKSPACE="$(cd "$REPO_ROOT/.." && pwd)"

URL="${NEON_DATABASE_URL:-}"
if [ -z "$URL" ]; then
  URL="$(grep -E '^NEON_DATABASE_URL=' "$WORKSPACE/rag-chatbot/.env" | cut -d= -f2- | tr -d '"' | tr -d "'")"
fi
[ -n "$URL" ] || { echo "ERROR: set NEON_DATABASE_URL or add it to rag-chatbot/.env"; exit 1; }

echo "== before =="
psql "$URL" -c "SELECT count(*) FILTER (WHERE is_featured) AS featured, count(*) AS total FROM projects;"
psql "$URL" -c "SELECT count(*) AS experience_rows FROM experience;"
psql "$URL" -c "SELECT count(*) AS kb_rows, vector_dims(embedding) AS dims FROM knowledge_base GROUP BY 2;"

echo "== migration 004 (featured projects + RAG chatbot project) =="
psql "$URL" -v ON_ERROR_STOP=1 -f "$REPO_ROOT/migrations/004_update_featured_projects.sql"

echo "== migration 006 (project metadata fixes + GPU rename) =="
psql "$URL" -v ON_ERROR_STOP=1 -f "$REPO_ROOT/migrations/006_project_metadata_fixes.sql"

echo "== migration 007 (project GitHub links + RAG live demo -> #chat) =="
psql "$URL" -v ON_ERROR_STOP=1 -f "$REPO_ROOT/migrations/007_project_links.sql"

for s in personal_info skills experience education projects; do
  echo "== seed: $s =="
  psql "$URL" -v ON_ERROR_STOP=1 -f "$REPO_ROOT/seeds/$s.sql"
done

echo "== seed: knowledge_base (50 chunks, 768-dim) =="
psql "$URL" -v ON_ERROR_STOP=1 -f "$REPO_ROOT/seeds/knowledge_base.sql" | tail -3

echo
echo "== after (expect: featured 5 / total 11, experience 7, kb 50 | 768) =="
psql "$URL" -c "SELECT display_order, title, is_featured FROM projects ORDER BY is_featured DESC, display_order;"
psql "$URL" -c "SELECT display_order, company, role, location, start_date, end_date FROM experience ORDER BY display_order;"
psql "$URL" -c "SELECT count(*) AS kb_rows, vector_dims(embedding) AS dims FROM knowledge_base GROUP BY 2;"
echo "done. Redeploy the website (Vercel) or wait <= 1h for ISR."
