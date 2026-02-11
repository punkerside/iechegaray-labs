CREATE TABLE users (
    id         BIGSERIAL,
    email      TEXT        NOT NULL,
    full_name  TEXT        NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE addresses (
    id         BIGSERIAL,
    user_id    BIGINT      NOT NULL,
    street     TEXT        NOT NULL,
    city       TEXT        NOT NULL,
    country    TEXT        NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);