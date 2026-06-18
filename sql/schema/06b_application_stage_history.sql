CREATE TABLE application_stage_history (
    id              INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    application_id  INT NOT NULL REFERENCES applications(id) ON DELETE CASCADE,
    from_stage      SMALLINT REFERENCES pipeline_stages(stage_code),
    to_stage        SMALLINT NOT NULL REFERENCES pipeline_stages(stage_code),
    changed_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CHECK (from_stage IS DISTINCT FROM to_stage)
);

CREATE INDEX idx_stage_history_application_id ON application_stage_history(application_id);
CREATE INDEX idx_stage_history_changed_at     ON application_stage_history(changed_at DESC);

COMMENT ON TABLE application_stage_history IS 'Immutable audit log of pipeline stage transitions per application.';
COMMENT ON COLUMN application_stage_history.from_stage IS 'Previous stage; NULL indicates initial submission event.';
