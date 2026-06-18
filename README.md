# LinkedIn Hiring Patterns Database

A production-grade PostgreSQL database modeling LinkedIn's corporate hiring ecosystem — companies, recruiters, job postings, candidates, and multi-stage application pipelines.

[![CI](https://github.com/Mahnoor-Zaffar/LinkedIn-Hiring-Patterns-database/actions/workflows/ci.yml/badge.svg)](https://github.com/Mahnoor-Zaffar/LinkedIn-Hiring-Patterns-database/actions/workflows/ci.yml)

## Features

- **Relational hiring pipeline** — 1:N and N:M patterns with explicit foreign keys and `ON DELETE CASCADE`
- **Analytics-ready salary fields** — `min_salary` / `max_salary` as `INT` for range queries and indexing
- **Normalized pipeline tracking** — `pipeline_stages` reference table with numeric `pipeline_stage` metric
- **Operational views** — pre-built views for recruiter dashboards and company metrics
- **Schema migrations** — versioned DDL with `schema_migrations` audit table
- **Dockerized local dev** — one-command PostgreSQL bootstrap
- **CI validation** — automated constraint, relationship, and view tests

## Quick Start

### Prerequisites

- [Docker](https://www.docker.com/) and Docker Compose
- `make` and `psql` (optional; Docker provides PostgreSQL)

### 1. Clone and configure

```bash
git clone https://github.com/Mahnoor-Zaffar/LinkedIn-Hiring-Patterns-database.git
cd LinkedIn-Hiring-Patterns-database
cp .env.example .env
```

### 2. Bootstrap everything

```bash
make bootstrap-all
```

This starts PostgreSQL, loads schema + seed data + migrations, and runs the validation suite.

### 3. Explore the data

```bash
make shell
```

```sql
SELECT * FROM v_application_pipeline LIMIT 10;
SELECT * FROM v_company_hiring_metrics;
```

## Project Structure

```
.
├── linkedin_hiring_schema.sql   # All-in-one bootstrap script (4-part PRD flow)
├── PRD.md                       # Product requirements document
├── docker-compose.yml           # Local PostgreSQL (+ optional pgAdmin)
├── Makefile                     # Developer commands
├── scripts/
│   ├── setup.sh                 # Destructive full bootstrap (drops all objects)
│   ├── migrate.sh               # Apply pending migrations only
│   ├── test-migration-path.sh   # Validate V001 -> V002 upgrade path
│   ├── validate.sh              # Transactional SQL test suite
│   └── run-analytics.sh         # Execute analytics queries
├── sql/
│   ├── 00_drop.sql
│   ├── schema/                  # Ordered DDL (tables, indexes, views, triggers)
│   ├── seeds/                   # Realistic mock data
│   ├── migrations/              # Versioned schema evolution
│   └── analytics/               # Sample analytical queries
├── tests/                       # pgTAP-style SQL assertions
└── docs/                        # ERD, schema reference, pipeline stages
```

## Make Commands

| Command | Description |
|---------|-------------|
| `make up` | Start PostgreSQL container |
| `make setup` | Destructive bootstrap (drop + schema + seeds + migrations) |
| `make reset` | Alias for `make setup` |
| `make migrate` | Apply pending migrations only (non-destructive) |
| `make validate` | Run SQL test suite (transactional, non-mutating) |
| `make test-migration-path` | Validate incremental V001 → V002 upgrade |
| `make analytics` | Run hiring funnel query |
| `make shell` | Open `psql` session |
| `make bootstrap-all` | `up` + `setup` + `validate` |
| `make clean` | Stop containers and remove volumes |

## Schema Overview

| Table | Relationship | Purpose |
|-------|-------------|---------|
| `companies` | Root | Corporate hiring accounts |
| `candidates` | Root | Applicant profiles |
| `recruiters` | N → 1 `companies` | Talent acquisition staff |
| `job_postings` | N → 1 `recruiters`, `companies` | Open roles with salary bands |
| `pipeline_stages` | Reference | Normalized hiring stage codes |
| `applications` | N:M junction | Candidate ↔ job application events |

See [docs/erd.md](docs/erd.md) and [docs/schema-reference.md](docs/schema-reference.md) for full detail.

## Analytics Queries

Pre-built queries in `sql/analytics/`:

- `hiring_funnel.sql` — stage distribution and conversion percentages
- `salary_benchmarks.sql` — compensation by industry and role
- `candidate_activity.sql` — multi-application candidate patterns
- `recruiter_performance.sql` — recruiter workload and offer rates

```bash
bash scripts/run-analytics.sh sql/analytics/salary_benchmarks.sql
```

## Monolithic vs Modular Bootstrap

| Approach | When to use |
|----------|-------------|
| `scripts/setup.sh` | **Canonical path** — day-to-day development and migration testing |
| `linkedin_hiring_schema.sql` | Quick one-file execution, demos, CI smoke test |

Both paths must produce the same final schema state. When changing schema, update `sql/` first, then sync `linkedin_hiring_schema.sql`.

> **Security:** Default credentials in `.env.example` are for local development only. Never use them in staging or production.

> **Note:** `make setup` is destructive — it drops all tables before rebuilding. Use `make migrate` for incremental upgrades on an existing database.

## Optional: pgAdmin

```bash
docker compose --profile admin up -d
```

Open [http://localhost:5050](http://localhost:5050) (default: `admin@local.dev` / `admin`).

## Documentation

- [PRD.md](PRD.md) — product requirements
- [docs/erd.md](docs/erd.md) — entity-relationship diagram
- [docs/schema-reference.md](docs/schema-reference.md) — table and column reference
- [docs/pipeline-stages.md](docs/pipeline-stages.md) — pipeline stage codes

## License

MIT — see [LICENSE](LICENSE).
