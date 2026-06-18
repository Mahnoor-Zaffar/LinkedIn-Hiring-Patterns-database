CREATE VIEW v_application_pipeline AS
SELECT
    a.id AS application_id,
    c.name AS candidate_name,
    c.email AS candidate_email,
    jp.title AS job_title,
    co.name AS company_name,
    ps.stage_name AS pipeline_stage,
    ps.is_terminal,
    a.applied_at,
    a.updated_at,
    (CURRENT_DATE - a.applied_at::DATE) AS days_in_pipeline
FROM applications a
JOIN candidates c ON c.id = a.candidate_id
JOIN job_postings jp ON jp.id = a.job_id
JOIN companies co ON co.id = jp.company_id
JOIN pipeline_stages ps ON ps.stage_code = a.pipeline_stage;

CREATE VIEW v_job_posting_summary AS
SELECT
    jp.id AS job_id,
    jp.title,
    co.name AS company_name,
    co.industry,
    r.name AS recruiter_name,
    jp.department,
    jp.min_salary,
    jp.max_salary,
    ROUND((jp.min_salary + jp.max_salary) / 2.0, 2) AS midpoint_salary,
    jp.is_remote,
    jp.posted_at,
    COUNT(a.id) AS total_applications,
    COUNT(a.id) FILTER (WHERE ps.is_terminal = FALSE) AS active_applications,
    COUNT(a.id) FILTER (WHERE ps.stage_name = 'offer') AS offers_extended
FROM job_postings jp
JOIN companies co ON co.id = jp.company_id
JOIN recruiters r ON r.id = jp.recruiter_id
LEFT JOIN applications a ON a.job_id = jp.id
LEFT JOIN pipeline_stages ps ON ps.stage_code = a.pipeline_stage
GROUP BY
    jp.id, jp.title, co.name, co.industry, r.name,
    jp.department, jp.min_salary, jp.max_salary,
    jp.is_remote, jp.posted_at;

CREATE VIEW v_company_hiring_metrics AS
SELECT
    co.id AS company_id,
    co.name AS company_name,
    co.industry,
    COUNT(DISTINCT r.id) AS recruiter_count,
    COUNT(DISTINCT jp.id) AS open_roles,
    COUNT(a.id) AS total_applications,
    ROUND(AVG(jp.min_salary), 2) AS avg_min_salary,
    ROUND(AVG(jp.max_salary), 2) AS avg_max_salary,
    COUNT(a.id) FILTER (WHERE ps.stage_name = 'offer') AS offers_extended
FROM companies co
LEFT JOIN recruiters r ON r.company_id = co.id
LEFT JOIN job_postings jp ON jp.company_id = co.id
LEFT JOIN applications a ON a.job_id = jp.id
LEFT JOIN pipeline_stages ps ON ps.stage_code = a.pipeline_stage
GROUP BY co.id, co.name, co.industry;

COMMENT ON VIEW v_application_pipeline IS 'Denormalized application lifecycle for recruiter dashboards.';
COMMENT ON VIEW v_job_posting_summary IS 'Per-role funnel metrics and compensation midpoint.';
COMMENT ON VIEW v_company_hiring_metrics IS 'Company-level hiring volume and salary benchmarks.';
