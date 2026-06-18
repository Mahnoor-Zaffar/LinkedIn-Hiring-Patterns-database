-- Views are created after migrations so they can reference post-migration columns.

CREATE OR REPLACE VIEW v_application_pipeline AS
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
    a.days_in_pipeline
FROM applications a
JOIN candidates c ON c.id = a.candidate_id
JOIN job_postings jp ON jp.id = a.job_id
JOIN companies co ON co.id = jp.company_id
JOIN pipeline_stages ps ON ps.stage_code = a.pipeline_stage;

CREATE OR REPLACE VIEW v_job_posting_summary AS
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

CREATE OR REPLACE VIEW v_company_hiring_metrics AS
WITH company_application_stats AS (
    SELECT
        jp.company_id,
        COUNT(a.id) AS total_applications,
        COUNT(a.id) FILTER (WHERE ps.stage_name = 'offer') AS offers_extended
    FROM job_postings jp
    LEFT JOIN applications a ON a.job_id = jp.id
    LEFT JOIN pipeline_stages ps ON ps.stage_code = a.pipeline_stage
    GROUP BY jp.company_id
),
company_salary_stats AS (
    SELECT
        jp.company_id,
        ROUND(AVG(jp.min_salary), 2) AS avg_min_salary,
        ROUND(AVG(jp.max_salary), 2) AS avg_max_salary
    FROM job_postings jp
    GROUP BY jp.company_id
)
SELECT
    co.id AS company_id,
    co.name AS company_name,
    co.industry,
    COUNT(DISTINCT r.id) AS recruiter_count,
    COUNT(DISTINCT jp.id) FILTER (WHERE jp.closed_at IS NULL) AS open_roles,
    COALESCE(cas.total_applications, 0) AS total_applications,
    css.avg_min_salary,
    css.avg_max_salary,
    COALESCE(cas.offers_extended, 0) AS offers_extended
FROM companies co
LEFT JOIN recruiters r ON r.company_id = co.id
LEFT JOIN job_postings jp ON jp.company_id = co.id
LEFT JOIN company_application_stats cas ON cas.company_id = co.id
LEFT JOIN company_salary_stats css ON css.company_id = co.id
GROUP BY
    co.id, co.name, co.industry,
    cas.total_applications, cas.offers_extended,
    css.avg_min_salary, css.avg_max_salary;

COMMENT ON VIEW v_application_pipeline IS 'Denormalized application lifecycle for recruiter dashboards.';
COMMENT ON VIEW v_job_posting_summary IS 'Per-role funnel metrics and compensation midpoint.';
COMMENT ON VIEW v_company_hiring_metrics IS 'Company-level hiring volume and salary benchmarks.';
