-- Recruiter workload and conversion performance.

SELECT
    r.name AS recruiter_name,
    co.name AS company_name,
    COUNT(DISTINCT jp.id) AS roles_managed,
    COUNT(a.id) AS total_applications,
    COUNT(a.id) FILTER (WHERE ps.stage_name = 'offer') AS offers_extended,
    ROUND(
        100.0 * COUNT(a.id) FILTER (WHERE ps.stage_name = 'offer')
        / NULLIF(COUNT(a.id), 0),
        2
    ) AS offer_rate_pct
FROM recruiters r
JOIN companies co ON co.id = r.company_id
LEFT JOIN job_postings jp ON jp.recruiter_id = r.id
LEFT JOIN applications a ON a.job_id = jp.id
LEFT JOIN pipeline_stages ps ON ps.stage_code = a.pipeline_stage
GROUP BY r.id, r.name, co.name
ORDER BY total_applications DESC;
