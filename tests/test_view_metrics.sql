-- Validate view metric correctness (guards against join inflation bugs).

DO $$
DECLARE
    total_apps_in_view   INT;
    total_apps_in_table  INT;
    stripe_apps          INT;
    stripe_offers        INT;
    sum_job_apps         INT;
BEGIN
    SELECT COALESCE(SUM(total_applications), 0) INTO total_apps_in_view
    FROM v_company_hiring_metrics;

    SELECT COUNT(*) INTO total_apps_in_table FROM applications;

    ASSERT total_apps_in_view = total_apps_in_table,
        format('View total_applications %s != table count %s', total_apps_in_view, total_apps_in_table);

    SELECT total_applications, offers_extended
    INTO stripe_apps, stripe_offers
    FROM v_company_hiring_metrics
    WHERE company_name = 'Stripe';

    ASSERT stripe_apps = 7,
        format('Stripe expected 7 applications, got %s', stripe_apps);
    ASSERT stripe_offers = 1,
        format('Stripe expected 1 offer, got %s', stripe_offers);

    SELECT COALESCE(SUM(total_applications), 0) INTO sum_job_apps
    FROM v_job_posting_summary;

    ASSERT sum_job_apps = total_apps_in_table,
        format('Job summary apps %s != table count %s', sum_job_apps, total_apps_in_table);
END $$;
