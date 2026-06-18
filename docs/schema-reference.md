# Schema Reference

## Tables

### `companies`

Corporate hiring accounts.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | `INT GENERATED ALWAYS AS IDENTITY` | PK | Surrogate key |
| `name` | `VARCHAR(255)` | NOT NULL, UNIQUE | Legal or brand name |
| `industry` | `VARCHAR(100)` | NOT NULL | Industry vertical |
| `employee_count` | `INT` | NOT NULL, > 0 | Headcount for segmentation |
| `headquarters` | `VARCHAR(150)` | | Primary office location |
| `founded_year` | `INT` | 1800–current year | Year founded |
| `created_at` | `TIMESTAMPTZ` | NOT NULL, DEFAULT NOW() | Record creation timestamp |

---

### `candidates`

Platform user profiles.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | `SERIAL` | PK | Surrogate key |
| `name` | `VARCHAR(255)` | NOT NULL | Full name |
| `headline` | `VARCHAR(500)` | | LinkedIn-style professional headline |
| `years_experience` | `INT` | NOT NULL, ≥ 0 | Total years of experience |
| `email` | `VARCHAR(255)` | NOT NULL, UNIQUE | Contact email |
| `location` | `VARCHAR(150)` | | Geographic location |
| `created_at` | `TIMESTAMPTZ` | NOT NULL, DEFAULT NOW() | Profile creation timestamp |

---

### `recruiters`

Talent acquisition staff tied to a parent company.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | `SERIAL` | PK | Surrogate key |
| `company_id` | `INT` | NOT NULL, FK → `companies(id)` CASCADE | Parent company |
| `name` | `VARCHAR(255)` | NOT NULL | Recruiter name |
| `email` | `VARCHAR(255)` | NOT NULL, UNIQUE | Work email |
| `title` | `VARCHAR(150)` | | Job title |
| `hired_at` | `DATE` | | Date joined company |
| `created_at` | `TIMESTAMPTZ` | NOT NULL, DEFAULT NOW() | Record creation timestamp |

**Index:** `idx_recruiters_company_id`

---

### `job_postings`

Open roles with numeric salary bands.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | `SERIAL` | PK | Surrogate key |
| `recruiter_id` | `INT` | NOT NULL, FK → `recruiters(id)` CASCADE | Posting owner |
| `company_id` | `INT` | NOT NULL, FK → `companies(id)` CASCADE | Hiring company (must match recruiter's company; enforced by trigger) |
| `title` | `VARCHAR(255)` | NOT NULL | Role title |
| `department` | `VARCHAR(100)` | NOT NULL | Internal department |
| `employment_type` | `VARCHAR(50)` | NOT NULL, CHECK enum | `full_time`, `part_time`, `contract`, `internship` |
| `min_salary` | `INT` | NOT NULL, ≥ 0 | Compensation lower bound |
| `max_salary` | `INT` | NOT NULL, ≥ `min_salary` | Compensation upper bound |
| `location` | `VARCHAR(150)` | | Job location |
| `is_remote` | `BOOLEAN` | NOT NULL, DEFAULT FALSE | Remote eligibility |
| `posted_at` | `TIMESTAMPTZ` | NOT NULL, DEFAULT NOW() | Publication timestamp |
| `closed_at` | `TIMESTAMPTZ` | ≥ `posted_at` if set | Closing timestamp |

**Indexes:** `idx_job_postings_recruiter_id`, `idx_job_postings_company_id`, `idx_job_postings_salary_range`, `idx_job_postings_posted_at`

---

### `pipeline_stages`

Reference dimension for application pipeline tracking.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `stage_code` | `SMALLINT` | PK | Numeric stage identifier (1–8) |
| `stage_name` | `VARCHAR(50)` | NOT NULL, UNIQUE | Machine-readable stage name |
| `description` | `TEXT` | NOT NULL | Human-readable stage description |
| `is_terminal` | `BOOLEAN` | NOT NULL, DEFAULT FALSE | Whether stage ends the pipeline |

---

### `applications`

Junction table for candidate-to-job application events.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | `SERIAL` | PK | Surrogate key |
| `job_id` | `INT` | NOT NULL, FK → `job_postings(id)` CASCADE | Target job posting |
| `candidate_id` | `INT` | NOT NULL, FK → `candidates(id)` CASCADE | Applying candidate |
| `pipeline_stage` | `SMALLINT` | NOT NULL, FK → `pipeline_stages(stage_code)` | Current pipeline depth |
| `applied_at` | `TIMESTAMPTZ` | NOT NULL, DEFAULT NOW() | Submission timestamp |
| `updated_at` | `TIMESTAMPTZ` | NOT NULL, DEFAULT NOW() | Last status change (auto-trigger) |
| `days_in_pipeline` | `INT` | NOT NULL, ≥ 0 | Days since application (V002 migration) |

**Unique:** `(job_id, candidate_id)` — one application per candidate per job

**Indexes:** `idx_applications_job_id`, `idx_applications_candidate_id`, `idx_applications_pipeline_stage`, `idx_applications_applied_at`

**Trigger:** `trg_applications_set_timestamps` — maintains `days_in_pipeline` and `updated_at`

**Trigger:** `trg_job_postings_validate_company` — enforces `job_postings.company_id = recruiters.company_id`

**Index:** `idx_job_postings_open_roles` — partial index on open roles (`closed_at IS NULL`)

---

### `schema_migrations`

DDL version audit log.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `version` | `VARCHAR(100)` | PK | Migration version identifier |
| `description` | `TEXT` | NOT NULL | Human-readable change summary |
| `applied_at` | `TIMESTAMPTZ` | NOT NULL, DEFAULT NOW() | Application timestamp |

## Migration History

| Version | Description |
|---------|-------------|
| V001 | Initial schema with all core tables, views, and triggers |
| V002 | Add `days_in_pipeline` metric with non-negative CHECK constraint |
