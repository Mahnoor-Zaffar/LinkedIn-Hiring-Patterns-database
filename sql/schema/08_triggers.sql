CREATE OR REPLACE FUNCTION fn_set_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_applications_set_updated_at
    BEFORE UPDATE ON applications
    FOR EACH ROW
    EXECUTE PROCEDURE fn_set_updated_at();
