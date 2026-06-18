#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if [[ -f .env ]]; then
    # shellcheck disable=SC1091
    source .env
fi

DB_HOST="${POSTGRES_HOST:-localhost}"
DB_PORT="${POSTGRES_PORT:-5432}"
DB_NAME="${POSTGRES_DB:-linkedin_hiring}"
DB_USER="${POSTGRES_USER:-postgres}"
DB_PASSWORD="${POSTGRES_PASSWORD:-postgres}"

export PGPASSWORD="$DB_PASSWORD"

bash scripts/wait-for-db.sh

PSQL_OPTS=(
    -h "$DB_HOST"
    -p "$DB_PORT"
    -U "$DB_USER"
    -d "$DB_NAME"
    -v ON_ERROR_STOP=1
)

run_sql() {
    local file="$1"
    echo "==> Applying $(basename "$file")"
    psql "${PSQL_OPTS[@]}" -f "$file"
}

echo "Applying pending migrations only (non-destructive)..."

for migration_file in sql/migrations/*.sql; do
    version="$(basename "$migration_file" | sed -E 's/^([V0-9]+)__.*/\1/')"
    already_applied="$(psql "${PSQL_OPTS[@]}" -tAc \
        "SELECT 1 FROM schema_migrations WHERE version = '${version}' LIMIT 1" 2>/dev/null || true)"

    if [[ "$already_applied" == "1" ]]; then
        echo "==> Skipping ${version} (already applied)"
        continue
    fi

    run_sql "$migration_file"

    if [[ "$version" == "V002" ]]; then
        run_sql "sql/schema/12_application_triggers.sql"
        run_sql "sql/schema/11_views.sql"
    fi
done

echo "Migration run complete."
