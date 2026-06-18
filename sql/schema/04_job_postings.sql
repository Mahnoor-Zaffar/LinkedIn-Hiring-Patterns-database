CREATE TABLE job_postings (
    id              SERIAL PRIMARY KEY,
    recruiter_id    INT NOT NULL REFERENCES recruiters(id) ON DELETE CASCADE,
    company_id      INT NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    title           VARCHAR(255) NOT NULL,
    department      VARCHAR(100) NOT NULL,
    employment_type VARCHAR(50) NOT NULL DEFAULT 'full_time'
        CHECK (employment_type IN ('full_time', 'part_time', 'contract', 'internship')),
    min_salary      INT NOT NULL CHECK (min_salary >= 0),
    max_salary      INT NOT NULL CHECK (max_salary >= min_salary),
    location        VARCHAR(150),
    is_remote       BOOLEAN NOT NULL DEFAULT FALSE,
    posted_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    closed_at       TIMESTAMPTZ,
    CHECK (closed_at IS NULL OR closed_at >= posted_at)
);

COMMENT ON TABLE job_postings IS 'Open roles published by recruiters on behalf of companies.';
COMMENT ON COLUMN job_postings.min_salary IS 'Lower bound of compensation band (INT for index-friendly range queries).';
COMMENT ON COLUMN job_postings.max_salary IS 'Upper bound of compensation band (INT for index-friendly range queries).';
