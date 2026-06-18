CREATE TABLE pipeline_stages (
    stage_code      SMALLINT PRIMARY KEY,
    stage_name      VARCHAR(50) NOT NULL UNIQUE,
    description     TEXT NOT NULL,
    is_terminal     BOOLEAN NOT NULL DEFAULT FALSE
);

COMMENT ON TABLE pipeline_stages IS 'Reference dimension for normalized application pipeline tracking.';

INSERT INTO pipeline_stages (stage_code, stage_name, description, is_terminal) VALUES
    (1, 'submitted',  'Application received and awaiting recruiter review.',       FALSE),
    (2, 'screening',  'Recruiter or ATS initial qualification in progress.',       FALSE),
    (3, 'phone',      'Phone or video screen scheduled or completed.',             FALSE),
    (4, 'technical',  'Technical assessment or coding interview stage.',           FALSE),
    (5, 'onsite',     'Onsite or panel interview loop in progress.',               FALSE),
    (6, 'offer',      'Offer extended to candidate.',                              TRUE),
    (7, 'rejected',   'Candidate declined by hiring team.',                        TRUE),
    (8, 'withdrawn',  'Candidate withdrew from the process.',                      TRUE);
