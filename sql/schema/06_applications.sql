CREATE TABLE applications (
    id              SERIAL PRIMARY KEY,
    job_id          INT NOT NULL REFERENCES job_postings(id) ON DELETE CASCADE,
    candidate_id    INT NOT NULL REFERENCES candidates(id) ON DELETE CASCADE,
    pipeline_stage  SMALLINT NOT NULL DEFAULT 1 REFERENCES pipeline_stages(stage_code),
    applied_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (job_id, candidate_id)
);

COMMENT ON TABLE applications IS 'Junction table resolving N:M candidate-to-job application workflows.';
COMMENT ON COLUMN applications.pipeline_stage IS 'Numeric pipeline depth metric referencing pipeline_stages.';
