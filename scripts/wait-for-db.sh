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

MAX_RETRIES="${DB_WAIT_RETRIES:-30}"
SLEEP_SECONDS="${DB_WAIT_SLEEP:-1}"

echo "Waiting for PostgreSQL at ${DB_HOST}:${DB_PORT}..."
for ((i = 1; i <= MAX_RETRIES; i++)); do
    if pg_isready -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" >/dev/null 2>&1; then
        echo "Database is ready."
        exit 0
    fi
    sleep "$SLEEP_SECONDS"
done

echo "PostgreSQL not ready after ${MAX_RETRIES} attempts."
exit 1
