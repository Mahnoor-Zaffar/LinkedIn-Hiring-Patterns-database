-- Validate application_stage_history audit trail behavior.

DO $$
DECLARE
    target_app_id   INT;
    history_before  INT;
    history_after   INT;
BEGIN
    SELECT id INTO target_app_id
    FROM applications
    WHERE job_id = 1 AND candidate_id = 1;

    SELECT COUNT(*) INTO history_before
    FROM application_stage_history
    WHERE application_id = target_app_id;

    ASSERT history_before >= 1,
        format('Expected initial history row for application %s', target_app_id);

    UPDATE applications
    SET pipeline_stage = 6
    WHERE id = target_app_id AND pipeline_stage = 5;

    SELECT COUNT(*) INTO history_after
    FROM application_stage_history
    WHERE application_id = target_app_id;

    ASSERT history_after = history_before + 1,
        format('Stage update should append history (%s -> %s)', history_before, history_after);
END $$;
