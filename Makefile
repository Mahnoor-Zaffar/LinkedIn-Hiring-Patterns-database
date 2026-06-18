.PHONY: help up down logs reset setup validate test analytics shell clean

help: ## Show available commands
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-16s\033[0m %s\n", $$1, $$2}'

up: ## Start PostgreSQL via Docker Compose
	docker compose up -d postgres
	@echo "Waiting for database..."
	@docker compose exec postgres sh -c 'until pg_isready -U $$POSTGRES_USER -d $$POSTGRES_DB; do sleep 1; done'
	@echo "Database ready at localhost:$${POSTGRES_PORT:-5432}"

down: ## Stop Docker Compose services
	docker compose down

logs: ## Tail PostgreSQL logs
	docker compose logs -f postgres

setup: ## Bootstrap schema, seeds, and migrations
	bash scripts/setup.sh

reset: ## Drop and re-bootstrap the database
	bash scripts/reset.sh

validate: ## Run SQL validation test suite
	bash scripts/validate.sh

test: validate ## Alias for validate

analytics: ## Run default hiring funnel analytics query
	bash scripts/run-analytics.sh sql/analytics/hiring_funnel.sql

shell: ## Open psql shell against the database
	@PGPASSWORD=$${POSTGRES_PASSWORD:-postgres} psql \
		-h $${POSTGRES_HOST:-localhost} \
		-p $${POSTGRES_PORT:-5432} \
		-U $${POSTGRES_USER:-postgres} \
		-d $${POSTGRES_DB:-linkedin_hiring}

bootstrap-all: up setup validate ## Full local bootstrap: start DB, load schema, run tests

clean: ## Stop services and remove volumes
	docker compose down -v
