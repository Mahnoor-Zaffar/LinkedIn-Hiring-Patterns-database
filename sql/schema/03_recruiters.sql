CREATE TABLE recruiters (
    id              INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    company_id      INT NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    name            VARCHAR(255) NOT NULL,
    email           VARCHAR(255) NOT NULL UNIQUE,
    title           VARCHAR(150),
    hired_at        DATE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE recruiters IS 'Internal talent acquisition accounts tied to a parent company (1:N).';
