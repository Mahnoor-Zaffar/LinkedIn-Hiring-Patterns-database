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

DROP TRIGGER IF EXISTS trg_applications_set_timestamps ON applications;
CREATE TRIGGER trg_applications_set_timestamps
    BEFORE INSERT OR UPDATE OF applied_at, pipeline_stage ON applications
    FOR EACH ROW
    EXECUTE PROCEDURE fn_applications_set_timestamps();

DROP TRIGGER IF EXISTS trg_applications_log_stage_change ON applications;
CREATE TRIGGER trg_applications_log_stage_change
    AFTER INSERT OR UPDATE OF pipeline_stage ON applications
    FOR EACH ROW
    EXECUTE PROCEDURE fn_log_application_stage_change();

-- Backfill initial history for seed rows inserted before triggers were attached.
INSERT INTO application_stage_history (application_id, from_stage, to_stage, changed_at)
SELECT a.id, NULL, a.pipeline_stage, a.applied_at
FROM applications a
WHERE NOT EXISTS (
    SELECT 1 FROM application_stage_history h WHERE h.application_id = a.id
);

SELECT fn_refresh_days_in_pipeline();
