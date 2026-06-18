-- Compensation benchmarks by industry and role.

SELECT
    co.industry,
    jp.title,
    COUNT(jp.id) AS role_count,
    MIN(jp.min_salary) AS floor_min_salary,
    ROUND(AVG(jp.min_salary), 2) AS avg_min_salary,
    ROUND(AVG(jp.max_salary), 2) AS avg_max_salary,
    MAX(jp.max_salary) AS ceiling_max_salary,
    ROUND(AVG((jp.min_salary + jp.max_salary) / 2.0), 2) AS avg_midpoint_salary
FROM job_postings jp
JOIN companies co ON co.id = jp.company_id
GROUP BY co.industry, jp.title
ORDER BY avg_midpoint_salary DESC;
