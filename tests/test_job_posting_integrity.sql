DO $$
BEGIN
    BEGIN
        INSERT INTO job_postings (
            recruiter_id, company_id, title, department, min_salary, max_salary
        ) VALUES (1, 2, 'Invalid Company Mapping', 'QA', 100000, 120000);
        RAISE EXCEPTION 'job_postings company integrity trigger did not fire';
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLERRM NOT LIKE '%must match recruiter company_id%' THEN
                RAISE;
            END IF;
    END;
END $$;
