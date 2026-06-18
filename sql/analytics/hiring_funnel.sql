-- Hiring funnel conversion rates by pipeline stage.

SELECT
    ps.stage_name,
    ps.stage_code,
    COUNT(a.id) AS application_count,
    ROUND(
        100.0 * COUNT(a.id) / NULLIF(SUM(COUNT(a.id)) OVER (), 0),
        2
    ) AS pct_of_total
FROM pipeline_stages ps
LEFT JOIN applications a ON a.pipeline_stage = ps.stage_code
GROUP BY ps.stage_code, ps.stage_name
ORDER BY ps.stage_code;
