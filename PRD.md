# Product Requirements Document (PRD)

## 1. Project Overview
A relational database tracking recruitment pipelines, talent acquisition activity, and application conversions modeled after LinkedIn's hiring ecosystem. This system tracks companies, internal recruiters, job postings, candidates, and multi-stage job applications.

## 2. Project Objectives
* **Ecosystem Modeling:** Map corporate structures, job descriptions, applicant profiles, and hiring statuses into a relational model.
* **Structural Analytics Protection:** Enforce strict data types (such as separating salary bands into numeric fields) to enable high-performance data querying and market trend analysis.
* **Application Conversion Lifecycle:** Implement an operational junction structure linking candidates to job listings through distinct submission events.
* **Schema Migration Execution:** Validate database extensibility by executing schema updates via Data Definition Language (DDL) migration actions.

## 3. Core Workflow Steps
[Companies & Candidates] ➔ [Recruiters & Job Postings] ➔ [Applications Junction Tracking] ➔ [Schema Iteration Migration]

### Part 1: Research & Relational Mapping
* **Companies (1:N with Recruiters):** Entities that host hiring accounts.
* **Recruiters (1:N with JobPostings):** Individual accounts posting listings on behalf of a parent company.
* **JobPostings (1:N with Applications):** Distinct open roles tracking departments, titles, and salary parameters.
* **Candidates (1:N with Applications):** Platform user profiles submitting applications.
* **Applications (N:M Junction Table):** Bridges Candidates and JobPostings to resolve the multi-application lifecycle.
* **PipelineStages (Reference Table):** Normalized lookup for application stage tracking via numeric `pipeline_stage` codes.

### Part 2: Schema Implementation Rules
* **Order of Execution:** Construct root dimension tables (`companies`, `candidates`) prior to dependent relational entities (`recruiters`, `job_postings`, `applications`).
* **Data Optimization Rule:** Store numerical ranges (like target compensation bands) as individual `INT` attributes (`min_salary`, `max_salary`) rather than a single string text block to facilitate math calculations and indexing.

### Part 3: Data Seeding
* Populate data records ensuring clear verification of relation behaviors. Multiple candidates must apply to the same job post, and singular candidates must hold several distinct application workflows to validate the relational constraints.

### Part 4: Schema Evolution Migration
* Execute schema updates via `ALTER TABLE` commands to replicate a product specification change — adding a `days_in_pipeline` tracking metric with an explicit `CHECK` constraint for time-based funnel analytics.

---

## 4. Logical Table Structural Blueprint

| Table | Primary Key | Foreign Keys | Key Attributes |
| :--- | :--- | :--- | :--- |
| **companies** | `id` | None | `name`, `industry`, `employee_count` |
| **recruiters** | `id` | `company_id` | `name`, `email` |
| **job_postings** | `id` | `recruiter_id`, `company_id` | `title`, `min_salary`, `max_salary` |
| **candidates** | `id` | None | `name`, `headline`, `years_experience` |
| **pipeline_stages** | `stage_code` | None | `stage_name`, `is_terminal` |
| **applications** | `id` | `job_id`, `candidate_id`, `pipeline_stage` | `pipeline_stage`, `applied_at`, `days_in_pipeline` |

## 5. Deliverables

| Artifact | Location | Purpose |
| :--- | :--- | :--- |
| Monolithic bootstrap script | `linkedin_hiring_schema.sql` | One-file DDL + seed + migration |
| Modular schema | `sql/schema/` | Production-ordered DDL files |
| Seed data | `sql/seeds/seed_data.sql` | Realistic mock records |
| Migrations | `sql/migrations/` | Versioned schema evolution |
| Analytics queries | `sql/analytics/` | Sample hiring funnel reports |
| Validation tests | `tests/` | Constraint and relationship assertions |
| Documentation | `docs/` | ERD, schema reference, pipeline stages |
