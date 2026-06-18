-- Application triggers depend on days_in_pipeline column (added in V002 migration).

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

SELECT fn_refresh_days_in_pipeline();
