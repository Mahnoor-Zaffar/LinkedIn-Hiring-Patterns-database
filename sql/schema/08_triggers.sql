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
