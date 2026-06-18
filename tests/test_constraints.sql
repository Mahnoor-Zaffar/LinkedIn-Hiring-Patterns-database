-- Validate CHECK constraints and FK integrity.

DO $$
BEGIN
    -- Salary range constraint
    BEGIN
        INSERT INTO job_postings (
            recruiter_id, company_id, title, department,
            min_salary, max_salary
        ) VALUES (1, 1, 'Invalid Salary Test', 'QA', 200000, 100000);
        RAISE EXCEPTION 'Salary CHECK constraint did not fire';
    EXCEPTION WHEN check_violation THEN
        NULL;
    END;

    -- Duplicate application constraint
    BEGIN
        INSERT INTO applications (job_id, candidate_id, pipeline_stage)
        VALUES (1, 1, 1);
        RAISE EXCEPTION 'UNIQUE(job_id, candidate_id) did not fire';
    EXCEPTION WHEN unique_violation THEN
        NULL;
    END;

    -- Invalid pipeline stage FK
    BEGIN
        INSERT INTO applications (job_id, candidate_id, pipeline_stage)
        VALUES (2, 2, 99);
        RAISE EXCEPTION 'pipeline_stage FK did not fire';
    EXCEPTION WHEN foreign_key_violation THEN
        NULL;
    END;

    -- Cascade delete: removing a job removes its applications
    INSERT INTO job_postings (
        recruiter_id, company_id, title, department, min_salary, max_salary
    ) VALUES (1, 1, 'Temp Role', 'Temp', 100000, 120000);

    INSERT INTO applications (job_id, candidate_id, pipeline_stage)
    SELECT id, 2, 1 FROM job_postings WHERE title = 'Temp Role';

    DELETE FROM job_postings WHERE title = 'Temp Role';

    ASSERT NOT EXISTS (
        SELECT 1 FROM applications a
        JOIN job_postings jp ON jp.id = a.job_id
        WHERE jp.title = 'Temp Role'
    ), 'ON DELETE CASCADE failed for applications';
END $$;
