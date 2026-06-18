-- Assert core tables exist with expected row counts after seeding.

DO $$
DECLARE
    company_count     INT;
    candidate_count   INT;
    recruiter_count   INT;
    job_count         INT;
    open_job_count    INT;
    closed_job_count  INT;
    application_count INT;
    history_count     INT;
BEGIN
    SELECT COUNT(*) INTO company_count FROM companies;
    SELECT COUNT(*) INTO candidate_count FROM candidates;
    SELECT COUNT(*) INTO recruiter_count FROM recruiters;
    SELECT COUNT(*) INTO job_count FROM job_postings;
    SELECT COUNT(*) INTO open_job_count FROM job_postings WHERE closed_at IS NULL;
    SELECT COUNT(*) INTO closed_job_count FROM job_postings WHERE closed_at IS NOT NULL;
    SELECT COUNT(*) INTO application_count FROM applications;
    SELECT COUNT(*) INTO history_count FROM application_stage_history;

    ASSERT company_count = 5,      format('Expected 5 companies, got %s', company_count);
    ASSERT candidate_count = 8,    format('Expected 8 candidates, got %s', candidate_count);
    ASSERT recruiter_count = 7,    format('Expected 7 recruiters, got %s', recruiter_count);
    ASSERT job_count = 10,         format('Expected 10 job postings, got %s', job_count);
    ASSERT open_job_count = 8,     format('Expected 8 open jobs, got %s', open_job_count);
    ASSERT closed_job_count = 2,   format('Expected 2 closed jobs, got %s', closed_job_count);
    ASSERT application_count = 20, format('Expected 20 applications, got %s', application_count);
    ASSERT history_count = 20,     format('Expected 20 stage history rows, got %s', history_count);
END $$;
