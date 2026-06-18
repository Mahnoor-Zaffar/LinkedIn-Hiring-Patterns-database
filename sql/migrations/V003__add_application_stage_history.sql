-- V003: Add application stage history audit table and transition trigger.

CREATE TABLE IF NOT EXISTS application_stage_history (
    id              INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    application_id  INT NOT NULL REFERENCES applications(id) ON DELETE CASCADE,
    from_stage      SMALLINT REFERENCES pipeline_stages(stage_code),
    to_stage        SMALLINT NOT NULL REFERENCES pipeline_stages(stage_code),
    changed_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CHECK (from_stage IS DISTINCT FROM to_stage)
);

CREATE INDEX IF NOT EXISTS idx_stage_history_application_id
    ON application_stage_history(application_id);
CREATE INDEX IF NOT EXISTS idx_stage_history_changed_at
    ON application_stage_history(changed_at DESC);

INSERT INTO schema_migrations (version, description) VALUES
    ('V003', 'Add application_stage_history audit table and stage transition trigger.')
ON CONFLICT (version) DO NOTHING;
