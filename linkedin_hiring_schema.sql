-- =============================================================================
-- LinkedIn Hiring Patterns Database
-- PostgreSQL Schema, Seed Data, and Evolution Migration
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Part 1: DATABASE INITIALIZATION & CLEANUP
-- -----------------------------------------------------------------------------

DROP TABLE IF EXISTS applications CASCADE;
DROP TABLE IF EXISTS job_postings CASCADE;
DROP TABLE IF EXISTS recruiters CASCADE;
DROP TABLE IF EXISTS candidates CASCADE;
DROP TABLE IF EXISTS companies CASCADE;

-- -----------------------------------------------------------------------------
-- Part 2: DDL SCHEMA CREATION
-- Topological order: root dimensions first, then dependents, then junction.
-- -----------------------------------------------------------------------------

-- Root dimension: corporate hiring accounts
CREATE TABLE companies (
    id              SERIAL PRIMARY KEY,
    name            VARCHAR(255) NOT NULL,
    industry        VARCHAR(100) NOT NULL,
    employee_count  INT NOT NULL CHECK (employee_count > 0),
    headquarters    VARCHAR(150),
    founded_year    INT CHECK (founded_year >= 1800 AND founded_year <= EXTRACT(YEAR FROM CURRENT_DATE)),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Root dimension: platform user profiles
CREATE TABLE candidates (
    id                  SERIAL PRIMARY KEY,
    name                VARCHAR(255) NOT NULL,
    headline            VARCHAR(500),
    years_experience    INT NOT NULL DEFAULT 0 CHECK (years_experience >= 0),
    email               VARCHAR(255) NOT NULL UNIQUE,
    location            VARCHAR(150),
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Dependent: recruiters belong to a parent company (1:N)
CREATE TABLE recruiters (
    id              SERIAL PRIMARY KEY,
    company_id      INT NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    name            VARCHAR(255) NOT NULL,
    email           VARCHAR(255) NOT NULL UNIQUE,
    title           VARCHAR(150),
    hired_at        DATE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Dependent: job postings reference recruiter and company (1:N from each)
CREATE TABLE job_postings (
    id              SERIAL PRIMARY KEY,
    recruiter_id    INT NOT NULL REFERENCES recruiters(id) ON DELETE CASCADE,
    company_id      INT NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    title           VARCHAR(255) NOT NULL,
    department      VARCHAR(100) NOT NULL,
    employment_type VARCHAR(50) NOT NULL DEFAULT 'full_time',
    min_salary      INT NOT NULL CHECK (min_salary >= 0),
    max_salary      INT NOT NULL CHECK (max_salary >= min_salary),
    location        VARCHAR(150),
    is_remote       BOOLEAN NOT NULL DEFAULT FALSE,
    posted_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    closed_at       TIMESTAMPTZ
);

-- Junction: resolves N:M between candidates and job postings
CREATE TABLE applications (
    id              SERIAL PRIMARY KEY,
    job_id          INT NOT NULL REFERENCES job_postings(id) ON DELETE CASCADE,
    candidate_id    INT NOT NULL REFERENCES candidates(id) ON DELETE CASCADE,
    current_status  VARCHAR(100) NOT NULL DEFAULT 'submitted',
    applied_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (job_id, candidate_id)
);

-- Performance indexes for analytical query patterns
CREATE INDEX idx_recruiters_company_id       ON recruiters(company_id);
CREATE INDEX idx_job_postings_recruiter_id   ON job_postings(recruiter_id);
CREATE INDEX idx_job_postings_company_id     ON job_postings(company_id);
CREATE INDEX idx_job_postings_salary_range   ON job_postings(min_salary, max_salary);
CREATE INDEX idx_applications_job_id         ON applications(job_id);
CREATE INDEX idx_applications_candidate_id   ON applications(candidate_id);
CREATE INDEX idx_applications_applied_at     ON applications(applied_at);

-- -----------------------------------------------------------------------------
-- Part 3: MOCK DATA SEEDING
-- Validates 1:N hierarchies and N:M application workflows.
-- -----------------------------------------------------------------------------

INSERT INTO companies (name, industry, employee_count, headquarters, founded_year) VALUES
    ('Stripe',           'Financial Technology',  8000,  'San Francisco, CA', 2010),
    ('Databricks',       'Data & Analytics',      6000,  'San Francisco, CA', 2013),
    ('Shopify',          'E-Commerce',            11000, 'Ottawa, Canada',    2006),
    ('Cloudflare',       'Cybersecurity',         3500,  'San Francisco, CA', 2009),
    ('Figma',            'Design Software',       1200,  'San Francisco, CA', 2012);

INSERT INTO candidates (name, headline, years_experience, email, location) VALUES
    ('Priya Sharma',      'Senior Backend Engineer | Distributed Systems',       9,  'priya.sharma@email.com',      'Seattle, WA'),
    ('Marcus Chen',         'Full-Stack Developer | React & Node.js',              5,  'marcus.chen@email.com',       'Austin, TX'),
    ('Elena Rodriguez',     'Data Engineer | Spark, Airflow, dbt',                 7,  'elena.rodriguez@email.com',   'Denver, CO'),
    ('James Okafor',        'Staff Software Engineer | Platform Infrastructure',  12,  'james.okafor@email.com',      'New York, NY'),
    ('Sofia Nakamura',      'ML Engineer | NLP & Recommendation Systems',          4,  'sofia.nakamura@email.com',    'San Jose, CA'),
    ('David Kim',           'DevOps Engineer | Kubernetes, Terraform, CI/CD',        6,  'david.kim@email.com',         'Portland, OR'),
    ('Amara Diallo',        'Product Manager | B2B SaaS Growth',                   8,  'amara.diallo@email.com',      'Chicago, IL'),
    ('Liam O''Brien',       'Frontend Engineer | Design Systems & Accessibility',  3,  'liam.obrien@email.com',       'Boston, MA');

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

-- N:M validation:
--   * Multiple candidates apply to job #1 (Senior Backend Engineer @ Stripe)
--   * Candidate #1 (Priya) submits applications to jobs #1, #2, and #4
--   * Candidate #3 (Elena) applies to both Data Engineer roles at Databricks
INSERT INTO applications (job_id, candidate_id, current_status, applied_at) VALUES
    -- Job 1: four distinct applicants (1:N from job perspective)
    (1, 1, 'onsite_interview',  '2025-11-02 10:15:00+00'),
    (1, 2, 'phone_screen',      '2025-11-03 14:20:00+00'),
    (1, 4, 'offer_extended',    '2025-11-04 09:00:00+00'),
    (1, 6, 'rejected',          '2025-11-05 16:45:00+00'),

    -- Job 2: three applicants
    (2, 1, 'technical_interview','2025-11-11 11:00:00+00'),
    (2, 4, 'submitted',         '2025-11-12 08:30:00+00'),
    (2, 6, 'phone_screen',      '2025-11-13 13:10:00+00'),

    -- Job 3: three applicants
    (3, 3, 'onsite_interview',  '2025-10-16 10:00:00+00'),
    (3, 5, 'submitted',         '2025-10-17 15:30:00+00'),
    (3, 7, 'withdrawn',         '2025-10-18 09:45:00+00'),

    -- Job 4: Priya's third application (1:N from candidate perspective)
    (4, 1, 'phone_screen',      '2025-10-23 12:00:00+00'),
    (4, 5, 'technical_interview','2025-10-24 17:00:00+00'),

    -- Job 5: two applicants
    (5, 2, 'onsite_interview',  '2025-11-06 10:30:00+00'),
    (5, 8, 'submitted',         '2025-11-07 14:00:00+00'),

    -- Job 6: two applicants
    (6, 6, 'offer_extended',    '2025-11-19 09:15:00+00'),
    (6, 4, 'rejected',          '2025-11-20 11:30:00+00'),

    -- Job 7: two applicants
    (7, 8, 'phone_screen',      '2025-11-21 10:00:00+00'),
    (7, 2, 'submitted',         '2025-11-22 08:45:00+00'),

    -- Job 8: Elena applies to second Databricks role (candidate multi-application)
    (8, 3, 'submitted',         '2025-12-02 09:00:00+00'),
    (8, 5, 'phone_screen',      '2025-12-03 13:20:00+00');

-- -----------------------------------------------------------------------------
-- Part 4: SCHEMA EVOLUTION MIGRATION
-- Product update: retire singular text status; introduce granular pipeline metric.
-- -----------------------------------------------------------------------------

-- Remove legacy free-text status descriptor
ALTER TABLE applications
    DROP COLUMN current_status;

-- Add pipeline depth tracking metric (replaces free-text status granularity)
ALTER TABLE applications
    ADD COLUMN pipeline_stage SMALLINT NOT NULL DEFAULT 1;

-- Backfill stage codes: 1=submitted, 2=screening, 3=phone, 4=technical,
--                       5=onsite, 6=offer, 7=rejected, 8=withdrawn
UPDATE applications SET pipeline_stage = 5 WHERE id IN (1, 9, 15);
UPDATE applications SET pipeline_stage = 3 WHERE id IN (2, 7, 12, 18, 20);
UPDATE applications SET pipeline_stage = 6 WHERE id IN (3, 16);
UPDATE applications SET pipeline_stage = 7 WHERE id IN (4, 17);
UPDATE applications SET pipeline_stage = 4 WHERE id IN (5, 13);
UPDATE applications SET pipeline_stage = 8 WHERE id IN (11);

-- Enforce valid pipeline stage range at the table level
ALTER TABLE applications
    ADD CONSTRAINT chk_applications_pipeline_stage
    CHECK (pipeline_stage BETWEEN 1 AND 8);
