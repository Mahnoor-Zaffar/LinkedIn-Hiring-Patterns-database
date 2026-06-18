-- Realistic seed data validating 1:N and N:M relational patterns.

INSERT INTO companies (name, industry, employee_count, headquarters, founded_year) VALUES
    ('Stripe',           'Financial Technology',  8000,  'San Francisco, CA', 2010),
    ('Databricks',       'Data & Analytics',      6000,  'San Francisco, CA', 2013),
    ('Shopify',          'E-Commerce',            11000, 'Ottawa, Canada',    2006),
    ('Cloudflare',       'Cybersecurity',         3500,  'San Francisco, CA', 2009),
    ('Figma',            'Design Software',       1200,  'San Francisco, CA', 2012);

INSERT INTO candidates (name, headline, years_experience, email, location) VALUES
    ('Priya Sharma',      'Senior Backend Engineer | Distributed Systems',       9,  'priya.sharma@email.com',      'Seattle, WA'),
    ('Marcus Chen',       'Full-Stack Developer | React & Node.js',              5,  'marcus.chen@email.com',       'Austin, TX'),
    ('Elena Rodriguez',   'Data Engineer | Spark, Airflow, dbt',                 7,  'elena.rodriguez@email.com',   'Denver, CO'),
    ('James Okafor',      'Staff Software Engineer | Platform Infrastructure',  12,  'james.okafor@email.com',      'New York, NY'),
    ('Sofia Nakamura',    'ML Engineer | NLP & Recommendation Systems',          4,  'sofia.nakamura@email.com',    'San Jose, CA'),
    ('David Kim',         'DevOps Engineer | Kubernetes, Terraform, CI/CD',        6,  'david.kim@email.com',         'Portland, OR'),
    ('Amara Diallo',      'Product Manager | B2B SaaS Growth',                   8,  'amara.diallo@email.com',      'Chicago, IL'),
    ('Liam O''Brien',     'Frontend Engineer | Design Systems & Accessibility',  3,  'liam.obrien@email.com',       'Boston, MA');

INSERT INTO recruiters (company_id, name, email, title, hired_at) VALUES
    (1, 'Rachel Whitmore',  'rachel.whitmore@stripe.com',      'Senior Technical Recruiter',   '2019-03-15'),
    (1, 'Tom Bradley',      'tom.bradley@stripe.com',          'Talent Acquisition Lead',      '2017-06-01'),
    (2, 'Nina Patel',       'nina.patel@databricks.com',       'Engineering Recruiter',        '2020-01-20'),
    (2, 'Chris Holloway',   'chris.holloway@databricks.com',   'Director of Talent',           '2016-09-10'),
    (3, 'Jessica Morales',  'jessica.morales@shopify.com',     'Senior Recruiter',             '2018-11-05'),
    (4, 'Kevin Zhang',      'kevin.zhang@cloudflare.com',      'Technical Recruiter',          '2021-04-12'),
    (5, 'Anna Kowalski',    'anna.kowalski@figma.com',         'Recruiting Partner',           '2019-08-22');

-- Open roles
INSERT INTO job_postings (recruiter_id, company_id, title, department, employment_type, min_salary, max_salary, location, is_remote, posted_at) VALUES
    (1, 1, 'Senior Backend Engineer',           'Payments',        'full_time', 180000, 240000, 'San Francisco, CA', FALSE, '2025-11-01 09:00:00+00'),
    (2, 1, 'Staff Infrastructure Engineer',     'Platform',        'full_time', 220000, 300000, 'Remote',            TRUE,  '2025-11-10 14:30:00+00'),
    (3, 2, 'Data Engineer II',                  'Data Platform',   'full_time', 160000, 210000, 'San Francisco, CA', FALSE, '2025-10-15 10:00:00+00'),
    (4, 2, 'Senior Machine Learning Engineer',  'AI Research',     'full_time', 200000, 275000, 'Seattle, WA',       FALSE, '2025-10-22 11:45:00+00'),
    (5, 3, 'Senior Full-Stack Developer',       'Merchant Tools',  'full_time', 150000, 195000, 'Toronto, Canada',   FALSE, '2025-11-05 08:15:00+00'),
    (6, 4, 'Site Reliability Engineer',         'Infrastructure',  'full_time', 170000, 225000, 'Austin, TX',        TRUE,  '2025-11-18 16:00:00+00'),
    (7, 5, 'Frontend Engineer',                 'Product',         'full_time', 140000, 185000, 'San Francisco, CA', FALSE, '2025-11-20 09:30:00+00'),
    (3, 2, 'Analytics Engineer',                'Data Platform',   'full_time', 145000, 190000, 'Remote',            TRUE,  '2025-12-01 12:00:00+00');

-- Closed roles (exercises partial index on open postings)
INSERT INTO job_postings (recruiter_id, company_id, title, department, employment_type, min_salary, max_salary, location, is_remote, posted_at, closed_at) VALUES
    (1, 1, 'Payments API Engineer',             'Payments',        'full_time', 160000, 200000, 'San Francisco, CA', FALSE, '2025-09-15 10:00:00+00', '2025-11-15 18:00:00+00'),
    (5, 3, 'Junior Merchant Developer',         'Merchant Tools',  'full_time',  90000, 120000, 'Toronto, Canada',   FALSE, '2025-08-01 09:00:00+00', '2025-10-01 17:00:00+00');

-- N:M validation:
--   * Job #1 collects four distinct applicants
--   * Priya (candidate #1) applies to jobs #1, #2, and #4
--   * Elena (candidate #3) applies to both Databricks data roles
INSERT INTO applications (job_id, candidate_id, pipeline_stage, applied_at) VALUES
    (1, 1, 5, '2025-11-02 10:15:00+00'),
    (1, 2, 3, '2025-11-03 14:20:00+00'),
    (1, 4, 6, '2025-11-04 09:00:00+00'),
    (1, 6, 7, '2025-11-05 16:45:00+00'),
    (2, 1, 4, '2025-11-11 11:00:00+00'),
    (2, 4, 1, '2025-11-12 08:30:00+00'),
    (2, 6, 3, '2025-11-13 13:10:00+00'),
    (3, 3, 5, '2025-10-16 10:00:00+00'),
    (3, 5, 1, '2025-10-17 15:30:00+00'),
    (3, 7, 8, '2025-10-18 09:45:00+00'),
    (4, 1, 3, '2025-10-23 12:00:00+00'),
    (4, 5, 4, '2025-10-24 17:00:00+00'),
    (5, 2, 5, '2025-11-06 10:30:00+00'),
    (5, 8, 1, '2025-11-07 14:00:00+00'),
    (6, 6, 6, '2025-11-19 09:15:00+00'),
    (6, 4, 7, '2025-11-20 11:30:00+00'),
    (7, 8, 3, '2025-11-21 10:00:00+00'),
    (7, 2, 1, '2025-11-22 08:45:00+00'),
    (8, 3, 1, '2025-12-02 09:00:00+00'),
    (8, 5, 3, '2025-12-03 13:20:00+00');
