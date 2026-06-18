-- =============================================================================
-- LinkedIn Hiring Patterns Database
-- Monolithic bootstrap (keep in sync with sql/ — modular path is canonical)
-- =============================================================================

-- Part 1: DATABASE INITIALIZATION & CLEANUP

DROP VIEW IF EXISTS v_company_hiring_metrics CASCADE;
DROP VIEW IF EXISTS v_job_posting_summary CASCADE;
DROP VIEW IF EXISTS v_application_pipeline CASCADE;

DROP TABLE IF EXISTS application_stage_history CASCADE;
DROP TABLE IF EXISTS applications CASCADE;
DROP TABLE IF EXISTS job_postings CASCADE;
DROP TABLE IF EXISTS recruiters CASCADE;
DROP TABLE IF EXISTS candidates CASCADE;
DROP TABLE IF EXISTS companies CASCADE;
DROP TABLE IF EXISTS pipeline_stages CASCADE;
DROP TABLE IF EXISTS schema_migrations CASCADE;

DROP FUNCTION IF EXISTS fn_log_application_stage_change() CASCADE;
DROP FUNCTION IF EXISTS fn_refresh_days_in_pipeline() CASCADE;
DROP FUNCTION IF EXISTS fn_validate_job_posting_company() CASCADE;
DROP FUNCTION IF EXISTS fn_applications_set_timestamps() CASCADE;
DROP FUNCTION IF EXISTS fn_calc_days_in_pipeline(TIMESTAMPTZ) CASCADE;
DROP FUNCTION IF EXISTS fn_set_updated_at() CASCADE;

-- Part 2: DDL SCHEMA CREATION

CREATE TABLE companies (
    id              INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name            VARCHAR(255) NOT NULL UNIQUE,
    industry        VARCHAR(100) NOT NULL,
    employee_count  INT NOT NULL CHECK (employee_count > 0),
    headquarters    VARCHAR(150),
    founded_year    INT CHECK (
        founded_year >= 1800
        AND founded_year <= EXTRACT(YEAR FROM CURRENT_DATE)
    ),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE candidates (
    id                  INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name                VARCHAR(255) NOT NULL,
    headline            VARCHAR(500),
    years_experience    INT NOT NULL DEFAULT 0 CHECK (years_experience >= 0),
    email               VARCHAR(255) NOT NULL UNIQUE,
    location            VARCHAR(150),
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE recruiters (
    id              INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    company_id      INT NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    name            VARCHAR(255) NOT NULL,
    email           VARCHAR(255) NOT NULL UNIQUE,
    title           VARCHAR(150),
    hired_at        DATE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE job_postings (
    id              INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
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

CREATE TABLE pipeline_stages (
    stage_code      SMALLINT PRIMARY KEY,
    stage_name      VARCHAR(50) NOT NULL UNIQUE,
    description     TEXT NOT NULL,
    is_terminal     BOOLEAN NOT NULL DEFAULT FALSE
);

INSERT INTO pipeline_stages (stage_code, stage_name, description, is_terminal) VALUES
    (1, 'submitted',  'Application received and awaiting recruiter review.',       FALSE),
    (2, 'screening',  'Recruiter or ATS initial qualification in progress.',       FALSE),
    (3, 'phone',      'Phone or video screen scheduled or completed.',             FALSE),
    (4, 'technical',  'Technical assessment or coding interview stage.',           FALSE),
    (5, 'onsite',     'Onsite or panel interview loop in progress.',               FALSE),
    (6, 'offer',      'Offer extended to candidate.',                              TRUE),
    (7, 'rejected',   'Candidate declined by hiring team.',                        TRUE),
    (8, 'withdrawn',  'Candidate withdrew from the process.',                      TRUE);

CREATE TABLE applications (
    id              INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    job_id          INT NOT NULL REFERENCES job_postings(id) ON DELETE CASCADE,
    candidate_id    INT NOT NULL REFERENCES candidates(id) ON DELETE CASCADE,
    pipeline_stage  SMALLINT NOT NULL DEFAULT 1 REFERENCES pipeline_stages(stage_code),
    applied_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (job_id, candidate_id)
);

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

CREATE INDEX idx_recruiters_company_id       ON recruiters(company_id);
CREATE INDEX idx_job_postings_recruiter_id   ON job_postings(recruiter_id);
CREATE INDEX idx_job_postings_company_id     ON job_postings(company_id);
CREATE INDEX idx_job_postings_salary_range   ON job_postings(min_salary, max_salary);
CREATE INDEX idx_job_postings_posted_at      ON job_postings(posted_at DESC);
CREATE INDEX idx_job_postings_open_roles     ON job_postings(posted_at DESC) WHERE closed_at IS NULL;
CREATE INDEX idx_applications_job_id         ON applications(job_id);
CREATE INDEX idx_applications_candidate_id   ON applications(candidate_id);
CREATE INDEX idx_applications_pipeline_stage ON applications(pipeline_stage);
CREATE INDEX idx_applications_applied_at     ON applications(applied_at DESC);

CREATE OR REPLACE FUNCTION fn_calc_days_in_pipeline(applied_ts TIMESTAMPTZ)
RETURNS INT
LANGUAGE sql
STABLE
AS $$
    SELECT GREATEST(0, (CURRENT_DATE - applied_ts::DATE));
$$;

CREATE OR REPLACE FUNCTION fn_validate_job_posting_company()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    recruiter_company_id INT;
BEGIN
    SELECT company_id INTO recruiter_company_id
    FROM recruiters
    WHERE id = NEW.recruiter_id;

    IF recruiter_company_id IS NULL THEN
        RAISE EXCEPTION 'recruiter_id % does not exist', NEW.recruiter_id;
    END IF;

    IF NEW.company_id IS DISTINCT FROM recruiter_company_id THEN
        RAISE EXCEPTION
            'company_id % must match recruiter company_id % for recruiter_id %',
            NEW.company_id, recruiter_company_id, NEW.recruiter_id;
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_job_postings_validate_company
    BEFORE INSERT OR UPDATE OF recruiter_id, company_id ON job_postings
    FOR EACH ROW
    EXECUTE PROCEDURE fn_validate_job_posting_company();

CREATE TABLE schema_migrations (
    version     VARCHAR(100) PRIMARY KEY,
    description TEXT NOT NULL,
    applied_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

INSERT INTO schema_migrations (version, description) VALUES
    ('V001', 'Initial schema: companies, candidates, recruiters, job_postings, applications, pipeline_stages.');

-- Part 3: MOCK DATA SEEDING

INSERT INTO companies (name, industry, employee_count, headquarters, founded_year) VALUES
    ('Stripe',           'Financial Technology',  8000,  'San Francisco, CA', 2010),
    ('Databricks',       'Data & Analytics',      6000,  'San Francisco, CA', 2013),
    ('Shopify',          'E-Commerce',            11000, 'Ottawa, Canada',    2006),
    ('Cloudflare',       'Cybersecurity',         3500,  'San Francisco, CA', 2009),
    ('Figma',            'Design Software',       1200,  'San Francisco, CA', 2012);

INSERT INTO candidates (name, headline, years_experience, email, location) VALUES
    ('Priya Sharma',      'Senior Backend Engineer | Distributed Systems',       9,  'priya.sharma@email.com',      'Seattle, WA'),
    ('Marcus Chen',       'Full-Stack Developer | React & Node.js',              5,  'marcus.chen@email.com',       'Austin, TX'),
    ('Elena Rodriguez',   'Data Engineer | Spark, Airflow, dbt',                 7,  'elena.rodriguez@email.com',   'Denver, CO'),
    ('James Okafor',      'Staff Software Engineer | Platform Infrastructure',  12,  'james.okafor@email.com',      'New York, NY'),
    ('Sofia Nakamura',    'ML Engineer | NLP & Recommendation Systems',          4,  'sofia.nakamura@email.com',    'San Jose, CA'),
    ('David Kim',         'DevOps Engineer | Kubernetes, Terraform, CI/CD',        6,  'david.kim@email.com',         'Portland, OR'),
    ('Amara Diallo',      'Product Manager | B2B SaaS Growth',                   8,  'amara.diallo@email.com',      'Chicago, IL'),
    ('Liam O''Brien',     'Frontend Engineer | Design Systems & Accessibility',  3,  'liam.obrien@email.com',       'Boston, MA');

INSERT INTO recruiters (company_id, name, email, title, hired_at) VALUES
    (1, 'Rachel Whitmore',  'rachel.whitmore@stripe.com',      'Senior Technical Recruiter',   '2019-03-15'),
    (1, 'Tom Bradley',      'tom.bradley@stripe.com',          'Talent Acquisition Lead',      '2017-06-01'),
    (2, 'Nina Patel',       'nina.patel@databricks.com',       'Engineering Recruiter',        '2020-01-20'),
    (2, 'Chris Holloway',   'chris.holloway@databricks.com',   'Director of Talent',           '2016-09-10'),
    (3, 'Jessica Morales',  'jessica.morales@shopify.com',     'Senior Recruiter',             '2018-11-05'),
    (4, 'Kevin Zhang',      'kevin.zhang@cloudflare.com',      'Technical Recruiter',          '2021-04-12'),
    (5, 'Anna Kowalski',    'anna.kowalski@figma.com',         'Recruiting Partner',           '2019-08-22');

INSERT INTO job_postings (recruiter_id, company_id, title, department, employment_type, min_salary, max_salary, location, is_remote, posted_at) VALUES
    (1, 1, 'Senior Backend Engineer',           'Payments',        'full_time', 180000, 240000, 'San Francisco, CA', FALSE, '2025-11-01 09:00:00+00'),
    (2, 1, 'Staff Infrastructure Engineer',     'Platform',        'full_time', 220000, 300000, 'Remote',            TRUE,  '2025-11-10 14:30:00+00'),
    (3, 2, 'Data Engineer II',                  'Data Platform',   'full_time', 160000, 210000, 'San Francisco, CA', FALSE, '2025-10-15 10:00:00+00'),
    (4, 2, 'Senior Machine Learning Engineer',  'AI Research',     'full_time', 200000, 275000, 'Seattle, WA',       FALSE, '2025-10-22 11:45:00+00'),
    (5, 3, 'Senior Full-Stack Developer',       'Merchant Tools',  'full_time', 150000, 195000, 'Toronto, Canada',   FALSE, '2025-11-05 08:15:00+00'),
    (6, 4, 'Site Reliability Engineer',         'Infrastructure',  'full_time', 170000, 225000, 'Austin, TX',        TRUE,  '2025-11-18 16:00:00+00'),
    (7, 5, 'Frontend Engineer',                 'Product',         'full_time', 140000, 185000, 'San Francisco, CA', FALSE, '2025-11-20 09:30:00+00'),
    (3, 2, 'Analytics Engineer',                'Data Platform',   'full_time', 145000, 190000, 'Remote',            TRUE,  '2025-12-01 12:00:00+00');

INSERT INTO job_postings (recruiter_id, company_id, title, department, employment_type, min_salary, max_salary, location, is_remote, posted_at, closed_at) VALUES
    (1, 1, 'Payments API Engineer',             'Payments',        'full_time', 160000, 200000, 'San Francisco, CA', FALSE, '2025-09-15 10:00:00+00', '2025-11-15 18:00:00+00'),
    (5, 3, 'Junior Merchant Developer',         'Merchant Tools',  'full_time',  90000, 120000, 'Toronto, Canada',   FALSE, '2025-08-01 09:00:00+00', '2025-10-01 17:00:00+00');

INSERT INTO applications (job_id, candidate_id, pipeline_stage, applied_at) VALUES
    (1, 1, 5, '2025-11-02 10:15:00+00'),
    (1, 2, 3, '2025-11-03 14:20:00+00'),
    (1, 4, 6, '2025-11-04 09:00:00+00'),
    (1, 6, 7, '2025-11-05 16:45:00+00'),
    (2, 1, 4, '2025-11-11 11:00:00+00'),
    (2, 4, 1, '2025-11-12 08:30:00+00'),
    (2, 6, 3, '2025-11-13 13:10:00+00'),
    (3, 3, 5, '2025-10-16 10:00:00+00'),
    (3, 5, 1, '2025-10-17 15:30:00+00'),
    (3, 7, 8, '2025-10-18 09:45:00+00'),
    (4, 1, 3, '2025-10-23 12:00:00+00'),
    (4, 5, 4, '2025-10-24 17:00:00+00'),
    (5, 2, 5, '2025-11-06 10:30:00+00'),
    (5, 8, 1, '2025-11-07 14:00:00+00'),
    (6, 6, 6, '2025-11-19 09:15:00+00'),
    (6, 4, 7, '2025-11-20 11:30:00+00'),
    (7, 8, 3, '2025-11-21 10:00:00+00'),
    (7, 2, 1, '2025-11-22 08:45:00+00'),
    (8, 3, 1, '2025-12-02 09:00:00+00'),
    (8, 5, 3, '2025-12-03 13:20:00+00');

-- Part 4: SCHEMA EVOLUTION MIGRATION

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

INSERT INTO schema_migrations (version, description) VALUES
    ('V003', 'Add application_stage_history audit table and stage transition trigger.')
ON CONFLICT (version) DO NOTHING;

CREATE OR REPLACE FUNCTION fn_applications_set_timestamps()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.days_in_pipeline := fn_calc_days_in_pipeline(NEW.applied_at);

    IF TG_OP = 'UPDATE' THEN
        NEW.updated_at := NOW();
    END IF;

    RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION fn_log_application_stage_change()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO application_stage_history (application_id, from_stage, to_stage, changed_at)
        VALUES (NEW.id, NULL, NEW.pipeline_stage, NEW.applied_at);
    ELSIF TG_OP = 'UPDATE' AND OLD.pipeline_stage IS DISTINCT FROM NEW.pipeline_stage THEN
        INSERT INTO application_stage_history (application_id, from_stage, to_stage, changed_at)
        VALUES (NEW.id, OLD.pipeline_stage, NEW.pipeline_stage, NOW());
    END IF;

    RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION fn_refresh_days_in_pipeline()
RETURNS VOID
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE applications
    SET days_in_pipeline = fn_calc_days_in_pipeline(applied_at);
END;
$$;

CREATE TRIGGER trg_applications_set_timestamps
    BEFORE INSERT OR UPDATE OF applied_at, pipeline_stage ON applications
    FOR EACH ROW
    EXECUTE PROCEDURE fn_applications_set_timestamps();

CREATE TRIGGER trg_applications_log_stage_change
    AFTER INSERT OR UPDATE OF pipeline_stage ON applications
    FOR EACH ROW
    EXECUTE PROCEDURE fn_log_application_stage_change();

INSERT INTO application_stage_history (application_id, from_stage, to_stage, changed_at)
SELECT a.id, NULL, a.pipeline_stage, a.applied_at
FROM applications a
WHERE NOT EXISTS (
    SELECT 1 FROM application_stage_history h WHERE h.application_id = a.id
);

SELECT fn_refresh_days_in_pipeline();

CREATE OR REPLACE VIEW v_application_pipeline AS
SELECT
    a.id AS application_id,
    c.name AS candidate_name,
    c.email AS candidate_email,
    jp.title AS job_title,
    co.name AS company_name,
    ps.stage_name AS pipeline_stage,
    ps.is_terminal,
    a.applied_at,
    a.updated_at,
    a.days_in_pipeline
FROM applications a
JOIN candidates c ON c.id = a.candidate_id
JOIN job_postings jp ON jp.id = a.job_id
JOIN companies co ON co.id = jp.company_id
JOIN pipeline_stages ps ON ps.stage_code = a.pipeline_stage;

CREATE OR REPLACE VIEW v_job_posting_summary AS
SELECT
    jp.id AS job_id,
    jp.title,
    co.name AS company_name,
    co.industry,
    r.name AS recruiter_name,
    jp.department,
    jp.min_salary,
    jp.max_salary,
    ROUND((jp.min_salary + jp.max_salary) / 2.0, 2) AS midpoint_salary,
    jp.is_remote,
    jp.posted_at,
    COUNT(a.id) AS total_applications,
    COUNT(a.id) FILTER (WHERE ps.is_terminal = FALSE) AS active_applications,
    COUNT(a.id) FILTER (WHERE ps.stage_name = 'offer') AS offers_extended
FROM job_postings jp
JOIN companies co ON co.id = jp.company_id
JOIN recruiters r ON r.id = jp.recruiter_id
LEFT JOIN applications a ON a.job_id = jp.id
LEFT JOIN pipeline_stages ps ON ps.stage_code = a.pipeline_stage
GROUP BY
    jp.id, jp.title, co.name, co.industry, r.name,
    jp.department, jp.min_salary, jp.max_salary,
    jp.is_remote, jp.posted_at;

CREATE OR REPLACE VIEW v_company_hiring_metrics AS
WITH company_application_stats AS (
    SELECT
        jp.company_id,
        COUNT(a.id) AS total_applications,
        COUNT(a.id) FILTER (WHERE ps.stage_name = 'offer') AS offers_extended
    FROM job_postings jp
    LEFT JOIN applications a ON a.job_id = jp.id
    LEFT JOIN pipeline_stages ps ON ps.stage_code = a.pipeline_stage
    GROUP BY jp.company_id
),
company_salary_stats AS (
    SELECT
        jp.company_id,
        ROUND(AVG(jp.min_salary), 2) AS avg_min_salary,
        ROUND(AVG(jp.max_salary), 2) AS avg_max_salary
    FROM job_postings jp
    GROUP BY jp.company_id
)
SELECT
    co.id AS company_id,
    co.name AS company_name,
    co.industry,
    COUNT(DISTINCT r.id) AS recruiter_count,
    COUNT(DISTINCT jp.id) FILTER (WHERE jp.closed_at IS NULL) AS open_roles,
    COALESCE(cas.total_applications, 0) AS total_applications,
    css.avg_min_salary,
    css.avg_max_salary,
    COALESCE(cas.offers_extended, 0) AS offers_extended
FROM companies co
LEFT JOIN recruiters r ON r.company_id = co.id
LEFT JOIN job_postings jp ON jp.company_id = co.id
LEFT JOIN company_application_stats cas ON cas.company_id = co.id
LEFT JOIN company_salary_stats css ON css.company_id = co.id
GROUP BY
    co.id, co.name, co.industry,
    cas.total_applications, cas.offers_extended,
    css.avg_min_salary, css.avg_max_salary;
