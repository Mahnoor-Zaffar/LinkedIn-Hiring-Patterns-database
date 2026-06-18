-- V002: Add days_in_pipeline tracking metric with non-negative constraint.

ALTER TABLE applications
    ADD COLUMN IF NOT EXISTS days_in_pipeline INT NOT NULL DEFAULT 0;

ALTER TABLE applications
    DROP CONSTRAINT IF EXISTS chk_applications_days_in_pipeline;

ALTER TABLE applications
    ADD CONSTRAINT chk_applications_days_in_pipeline
    CHECK (days_in_pipeline >= 0);

INSERT INTO schema_migrations (version, description) VALUES
    ('V002', 'Add days_in_pipeline tracking metric with non-negative constraint.')
ON CONFLICT (version) DO NOTHING;
