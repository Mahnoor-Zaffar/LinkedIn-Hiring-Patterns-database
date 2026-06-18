# Entity-Relationship Diagram

## Overview

The LinkedIn Hiring Patterns Database models the recruitment lifecycle from corporate accounts through application conversion.

```mermaid
erDiagram
    companies ||--o{ recruiters : employs
    companies ||--o{ job_postings : publishes
    recruiters ||--o{ job_postings : manages
    candidates ||--o{ applications : submits
    job_postings ||--o{ applications : receives
    pipeline_stages ||--o{ applications : tracks

    companies {
        serial id PK
        varchar name
        varchar industry
        int employee_count
        varchar headquarters
        int founded_year
        timestamptz created_at
    }

    candidates {
        serial id PK
        varchar name
        varchar headline
        int years_experience
        varchar email UK
        varchar location
        timestamptz created_at
    }

    recruiters {
        serial id PK
        int company_id FK
        varchar name
        varchar email UK
        varchar title
        date hired_at
        timestamptz created_at
    }

    job_postings {
        serial id PK
        int recruiter_id FK
        int company_id FK
        varchar title
        varchar department
        varchar employment_type
        int min_salary
        int max_salary
        varchar location
        boolean is_remote
        timestamptz posted_at
        timestamptz closed_at
    }

    pipeline_stages {
        smallint stage_code PK
        varchar stage_name UK
        text description
        boolean is_terminal
    }

    applications {
        serial id PK
        int job_id FK
        int candidate_id FK
        smallint pipeline_stage FK
        timestamptz applied_at
        timestamptz updated_at
        int days_in_pipeline
    }
```

## Cardinality Summary

| From | To | Cardinality | Description |
|------|----|-------------|-------------|
| `companies` | `recruiters` | 1:N | One company employs many recruiters |
| `companies` | `job_postings` | 1:N | One company publishes many roles |
| `recruiters` | `job_postings` | 1:N | One recruiter manages many listings |
| `candidates` | `applications` | 1:N | One candidate submits many applications |
| `job_postings` | `applications` | 1:N | One job receives many applications |
| `candidates` ↔ `job_postings` | via `applications` | N:M | Junction resolves many-to-many |

## Views

| View | Purpose |
|------|---------|
| `v_application_pipeline` | Denormalized application lifecycle for dashboards |
| `v_job_posting_summary` | Per-role funnel metrics and salary midpoint |
| `v_company_hiring_metrics` | Company-level hiring volume and benchmarks |

## Seed Data Patterns

The seed dataset intentionally validates:

1. **Job 1 → 4 applicants** — one posting, many candidates (1:N from job side)
2. **Priya → 3 applications** — one candidate, many jobs (1:N from candidate side)
3. **Elena → 2 Databricks roles** — cross-listing within the same company
