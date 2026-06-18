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
)

FAILURES=0

run_test() {
    local file="$1"
    echo "==> Testing $(basename "$file")"
    if ! psql "${PSQL_OPTS[@]}" -f "$file" > /dev/null; then
        echo "FAILED: $(basename "$file")"
        FAILURES=$((FAILURES + 1))
    fi
}

for test_file in tests/*.sql; do
    run_test "$test_file"
done

if [[ "$FAILURES" -gt 0 ]]; then
    echo "Validation failed with $FAILURES error(s)."
    exit 1
fi

echo "All validation tests passed."
