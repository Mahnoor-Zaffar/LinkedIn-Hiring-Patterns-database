-- Drop all objects in reverse dependency order for repeatable bootstrap cycles.

DROP VIEW IF EXISTS v_company_hiring_metrics CASCADE;
DROP VIEW IF EXISTS v_job_posting_summary CASCADE;
DROP VIEW IF EXISTS v_application_pipeline CASCADE;

DROP TABLE IF EXISTS applications CASCADE;
DROP TABLE IF EXISTS job_postings CASCADE;
DROP TABLE IF EXISTS recruiters CASCADE;
DROP TABLE IF EXISTS candidates CASCADE;
DROP TABLE IF EXISTS companies CASCADE;
DROP TABLE IF EXISTS pipeline_stages CASCADE;
DROP TABLE IF EXISTS schema_migrations CASCADE;

DROP FUNCTION IF EXISTS fn_set_updated_at() CASCADE;
