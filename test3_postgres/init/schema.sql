CREATE TABLE users (
    id         SERIAL      PRIMARY KEY,
    email      TEXT        NOT NULL,
    full_name  TEXT        NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE addresses (
    id         SERIAL      PRIMARY KEY,
    user_id    INT         NOT NULL REFERENCES users(id),
    street     TEXT        NOT NULL,
    city       TEXT        NOT NULL,
    country    TEXT        NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_addresses_user_id_created_at ON addresses (user_id, created_at DESC);