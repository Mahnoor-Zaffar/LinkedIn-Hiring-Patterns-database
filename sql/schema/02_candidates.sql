CREATE TABLE candidates (
    id                  INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name                VARCHAR(255) NOT NULL,
    headline            VARCHAR(500),
    years_experience    INT NOT NULL DEFAULT 0 CHECK (years_experience >= 0),
    email               VARCHAR(255) NOT NULL UNIQUE,
    location            VARCHAR(150),
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE candidates IS 'Platform user profiles submitting job applications.';
