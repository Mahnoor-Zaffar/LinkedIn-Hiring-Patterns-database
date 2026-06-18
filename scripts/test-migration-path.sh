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

PSQL_DB_OPTS=(
    -h "$DB_HOST"
    -p "$DB_PORT"
    -U "$DB_USER"
    -d "$DB_NAME"
    -v ON_ERROR_STOP=1
)

run_sql() {
    local file="$1"
    psql "${PSQL_DB_OPTS[@]}" -f "$file" > /dev/null
}

echo "Testing incremental migration path (V001 base -> V002 upgrade)..."

psql "${PSQL_DB_OPTS[@]}" -f sql/00_drop.sql

for schema_file in sql/schema/0*.sql sql/schema/10_*.sql; do
    [[ -f "$schema_file" ]] || continue
    base_name="$(basename "$schema_file")"
    if [[ "$base_name" == "11_views.sql" || "$base_name" == "12_application_triggers.sql" ]]; then
        continue
    fi
    run_sql "$schema_file"
done

run_sql "sql/seeds/seed_data.sql"

if psql "${PSQL_DB_OPTS[@]}" -tAc \
    "SELECT 1 FROM information_schema.columns WHERE table_name = 'applications' AND column_name = 'days_in_pipeline'" \
    | grep -q 1; then
    echo "Migration path test failed: days_in_pipeline exists before V002."
    exit 1
fi

bash scripts/migrate.sh
bash scripts/validate.sh

echo "Incremental migration path validated."
