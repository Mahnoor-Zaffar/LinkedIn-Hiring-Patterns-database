CREATE TABLE schema_migrations (
    version     VARCHAR(100) PRIMARY KEY,
    description TEXT NOT NULL,
    applied_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE schema_migrations IS 'Tracks applied DDL migration versions for auditability.';

INSERT INTO schema_migrations (version, description) VALUES
    ('V001', 'Initial schema: companies, candidates, recruiters, job_postings, applications, pipeline_stages.');
