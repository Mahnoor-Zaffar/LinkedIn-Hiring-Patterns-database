-- Candidate application activity: validates 1:N from candidate perspective.

SELECT
    c.name AS candidate_name,
    c.years_experience,
    COUNT(a.id) AS applications_submitted,
    COUNT(a.id) FILTER (WHERE ps.is_terminal = FALSE) AS active_applications,
    COUNT(a.id) FILTER (WHERE ps.stage_name = 'offer') AS offers_received,
    STRING_AGG(DISTINCT co.name, ', ' ORDER BY co.name) AS companies_applied_to
FROM candidates c
JOIN applications a ON a.candidate_id = c.id
JOIN job_postings jp ON jp.id = a.job_id
JOIN companies co ON co.id = jp.company_id
JOIN pipeline_stages ps ON ps.stage_code = a.pipeline_stage
GROUP BY c.id, c.name, c.years_experience
ORDER BY applications_submitted DESC, c.name;
