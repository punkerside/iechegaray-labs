BEGIN;

-- Optional: clear existing data and reset sequences
TRUNCATE TABLE addresses, users RESTART IDENTITY;

-- 10,000 users
-- created_at randomized within the last 5 years
INSERT INTO users (email, full_name, created_at)
SELECT
    'user' || i || '@example.com' AS email,
    'User ' || i                   AS full_name,
    now() - (random() * interval '5 years') AS created_at
FROM generate_series(1, 10000) AS s(i);

-- 1,000,000 addresses
-- 100 addresses per user
-- created_at randomized within the last 5 years
INSERT INTO addresses (user_id, street, city, country, created_at)
SELECT
    u.id                                  AS user_id,
    'Street ' || gs.addr_id              AS street,
    'City '   || ((gs.addr_id % 100) + 1) AS city,
    'Country'                             AS country,
    now() - (random() * interval '5 years') AS created_at
FROM users AS u
JOIN LATERAL generate_series(1, 1000) AS gs(addr_id) ON true;

COMMIT;