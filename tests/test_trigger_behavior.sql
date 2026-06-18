-- Validate application timestamp and days_in_pipeline trigger behavior.

DO $$
DECLARE
    initial_days INT;
    updated_days INT;
    updated_at_before TIMESTAMPTZ;
    updated_at_after TIMESTAMPTZ;
BEGIN
    SELECT days_in_pipeline, updated_at
    INTO initial_days, updated_at_before
    FROM applications
    WHERE id = 1;

    ASSERT initial_days = fn_calc_days_in_pipeline(
        (SELECT applied_at FROM applications WHERE id = 1)
    ), 'days_in_pipeline not synced with applied_at on seed data';

    UPDATE applications
    SET pipeline_stage = 4
    WHERE id = 1
    RETURNING days_in_pipeline, updated_at
    INTO updated_days, updated_at_after;

    ASSERT updated_days = initial_days,
        'days_in_pipeline should remain stable when only pipeline_stage changes';
    ASSERT updated_at_after > updated_at_before,
        'updated_at should advance when application row changes';
END $$;
