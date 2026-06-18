-- V002: Add days_in_pipeline computed metric column with non-negative constraint.
-- Simulates a product iteration adding time-based funnel analytics.

ALTER TABLE applications
    ADD COLUMN IF NOT EXISTS days_in_pipeline INT NOT NULL DEFAULT 0;

UPDATE applications
SET days_in_pipeline = GREATEST(0, (CURRENT_DATE - applied_at::DATE));

ALTER TABLE applications
    DROP CONSTRAINT IF EXISTS chk_applications_days_in_pipeline;

ALTER TABLE applications
    ADD CONSTRAINT chk_applications_days_in_pipeline
    CHECK (days_in_pipeline >= 0);

INSERT INTO schema_migrations (version, description) VALUES
    ('V002', 'Add days_in_pipeline tracking metric with non-negative constraint.')
ON CONFLICT (version) DO NOTHING;
