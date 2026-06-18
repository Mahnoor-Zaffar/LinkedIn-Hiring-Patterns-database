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

PSQL_OPTS=(
    -h "$DB_HOST"
    -p "$DB_PORT"
    -U "$DB_USER"
    -d "$DB_NAME"
    -v ON_ERROR_STOP=1
    --single-transaction
)

run_sql() {
    local file="$1"
    echo "==> Running $(basename "$file")"
    psql "${PSQL_OPTS[@]}" -f "$file"
}

echo "Bootstrapping LinkedIn Hiring Patterns Database..."

run_sql "sql/00_drop.sql"

for schema_file in sql/schema/*.sql; do
    run_sql "$schema_file"
done

run_sql "sql/seeds/seed_data.sql"

for migration_file in sql/migrations/*.sql; do
    run_sql "$migration_file"
done

echo "Bootstrap complete."
