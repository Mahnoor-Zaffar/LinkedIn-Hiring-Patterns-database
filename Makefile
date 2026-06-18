.PHONY: help up down logs reset setup migrate validate test analytics shell clean bootstrap-all test-migration-path

help: ## Show available commands
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

up: ## Start PostgreSQL via Docker Compose
	docker compose up -d postgres
	@bash scripts/wait-for-db.sh

down: ## Stop Docker Compose services
	docker compose down

logs: ## Tail PostgreSQL logs
	docker compose logs -f postgres

setup: ## Destructive bootstrap: drop, schema, seeds, migrations, views
	bash scripts/setup.sh

reset: setup ## Alias for setup (full drop + re-bootstrap)

migrate: ## Apply pending migrations only (non-destructive)
	bash scripts/migrate.sh

validate: ## Run SQL validation test suite (transactional, non-mutating)
	bash scripts/validate.sh

test: validate ## Alias for validate

test-migration-path: ## Validate V001 -> V002 incremental upgrade path
	bash scripts/test-migration-path.sh

analytics: ## Run default hiring funnel analytics query
	bash scripts/run-analytics.sh sql/analytics/hiring_funnel.sql

shell: ## Open psql shell against the database
	@if [ -f .env ]; then set -a; . ./.env; set +a; fi; \
	PGPASSWORD=$${POSTGRES_PASSWORD:-postgres} psql \
		-h $${POSTGRES_HOST:-localhost} \
		-p $${POSTGRES_PORT:-5432} \
		-U $${POSTGRES_USER:-postgres} \
		-d $${POSTGRES_DB:-linkedin_hiring}

bootstrap-all: up setup validate ## Full local bootstrap: start DB, load schema, run tests

clean: ## Stop services and remove volumes
	docker compose down -v
