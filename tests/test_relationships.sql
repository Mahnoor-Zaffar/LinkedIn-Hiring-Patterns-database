-- Validate 1:N and N:M relationship patterns from seed data.

DO $$
DECLARE
    job1_applicants   INT;
    priya_apps        INT;
    elena_databricks  INT;
BEGIN
    -- Job #1 (Stripe Senior Backend) should have 4 applicants
    SELECT COUNT(*) INTO job1_applicants
    FROM applications WHERE job_id = 1;
    ASSERT job1_applicants = 4,
        format('Job 1 expected 4 applicants, got %s', job1_applicants);

    -- Priya (candidate #1) should have 3 applications
    SELECT COUNT(*) INTO priya_apps
    FROM applications WHERE candidate_id = 1;
    ASSERT priya_apps = 3,
        format('Priya expected 3 applications, got %s', priya_apps);

    -- Elena (candidate #3) should have 2 Databricks applications
    SELECT COUNT(*) INTO elena_databricks
    FROM applications a
    JOIN job_postings jp ON jp.id = a.job_id
    WHERE a.candidate_id = 3 AND jp.company_id = 2;
    ASSERT elena_databricks = 2,
        format('Elena expected 2 Databricks apps, got %s', elena_databricks);
END $$;
