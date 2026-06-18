-- Verify views return data and migration tracking is populated.

DO $$
DECLARE
    pipeline_rows INT;
    summary_rows  INT;
    metrics_rows  INT;
    migration_cnt INT;
BEGIN
    SELECT COUNT(*) INTO pipeline_rows FROM v_application_pipeline;
    SELECT COUNT(*) INTO summary_rows FROM v_job_posting_summary;
    SELECT COUNT(*) INTO metrics_rows FROM v_company_hiring_metrics;
    SELECT COUNT(*) INTO migration_cnt FROM schema_migrations;

    ASSERT pipeline_rows = 20, format('v_application_pipeline expected 20 rows, got %s', pipeline_rows);
    ASSERT summary_rows = 8,   format('v_job_posting_summary expected 8 rows, got %s', summary_rows);
    ASSERT metrics_rows = 5,   format('v_company_hiring_metrics expected 5 rows, got %s', metrics_rows);
    ASSERT migration_cnt >= 2, format('Expected >= 2 migrations, got %s', migration_cnt);

    ASSERT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'applications' AND column_name = 'days_in_pipeline'
    ), 'days_in_pipeline column missing after V002 migration';
END $$;
