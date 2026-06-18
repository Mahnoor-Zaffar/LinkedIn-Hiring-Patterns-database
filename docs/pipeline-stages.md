# Pipeline Stages

Applications track hiring progress via a numeric `pipeline_stage` column referencing the `pipeline_stages` lookup table. This replaces free-text status strings with a normalized, index-friendly metric.

## Stage Codes

| Code | Name | Terminal | Description |
|------|------|----------|-------------|
| 1 | `submitted` | No | Application received, awaiting recruiter review |
| 2 | `screening` | No | Initial ATS or recruiter qualification |
| 3 | `phone` | No | Phone or video screen stage |
| 4 | `technical` | No | Technical assessment or coding interview |
| 5 | `onsite` | No | Onsite or panel interview loop |
| 6 | `offer` | Yes | Offer extended to candidate |
| 7 | `rejected` | Yes | Candidate declined by hiring team |
| 8 | `withdrawn` | Yes | Candidate withdrew from process |

## Design Rationale

- **Numeric codes** enable `BETWEEN` range queries (e.g., all candidates past phone screen)
- **Reference table** allows stage metadata changes without altering application rows
- **`is_terminal` flag** supports funnel analytics (active vs. closed applications)
- **Table column** (`applications.days_in_pipeline`): maintained by `trg_applications_set_timestamps` on insert/update; batch-refreshed via `fn_refresh_days_in_pipeline()`
- **View column** (`v_application_pipeline.days_in_pipeline`): reads from the table column (single source of truth)

## Example Queries

```sql
-- All active (non-terminal) applications
SELECT * FROM v_application_pipeline WHERE is_terminal = FALSE;

-- Applications at or past technical stage
SELECT * FROM applications WHERE pipeline_stage >= 4;

-- Average days in pipeline by stage
SELECT ps.stage_name, ROUND(AVG(a.days_in_pipeline), 1) AS avg_days
FROM applications a
JOIN pipeline_stages ps ON ps.stage_code = a.pipeline_stage
GROUP BY ps.stage_name, ps.stage_code
ORDER BY ps.stage_code;
```

## Schema Evolution (V002)

The V002 migration added `days_in_pipeline` as a dedicated tracking metric:

```sql
ALTER TABLE applications ADD COLUMN days_in_pipeline INT NOT NULL DEFAULT 0;
ALTER TABLE applications ADD CONSTRAINT chk_applications_days_in_pipeline
    CHECK (days_in_pipeline >= 0);
```

This supports time-to-hire analytics without overloading the stage code dimension.
