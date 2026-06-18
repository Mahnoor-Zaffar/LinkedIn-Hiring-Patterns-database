CREATE TABLE companies (
    id              SERIAL PRIMARY KEY,
    name            VARCHAR(255) NOT NULL,
    industry        VARCHAR(100) NOT NULL,
    employee_count  INT NOT NULL CHECK (employee_count > 0),
    headquarters    VARCHAR(150),
    founded_year    INT CHECK (
        founded_year >= 1800
        AND founded_year <= EXTRACT(YEAR FROM CURRENT_DATE)
    ),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE companies IS 'Corporate hiring accounts that host recruitment activity.';
COMMENT ON COLUMN companies.employee_count IS 'Active headcount used for company-size segmentation.';
