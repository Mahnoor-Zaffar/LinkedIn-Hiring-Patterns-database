-- Assert core tables exist with expected row counts after seeding.

DO $$
DECLARE
    company_count     INT;
    candidate_count   INT;
    recruiter_count   INT;
    job_count         INT;
    application_count INT;
BEGIN
    SELECT COUNT(*) INTO company_count FROM companies;
    SELECT COUNT(*) INTO candidate_count FROM candidates;
    SELECT COUNT(*) INTO recruiter_count FROM recruiters;
    SELECT COUNT(*) INTO job_count FROM job_postings;
    SELECT COUNT(*) INTO application_count FROM applications;

    ASSERT company_count = 5,     format('Expected 5 companies, got %s', company_count);
    ASSERT candidate_count = 8,   format('Expected 8 candidates, got %s', candidate_count);
    ASSERT recruiter_count = 7,   format('Expected 7 recruiters, got %s', recruiter_count);
    ASSERT job_count = 8,         format('Expected 8 job postings, got %s', job_count);
    ASSERT application_count = 20, format('Expected 20 applications, got %s', application_count);
END $$;
