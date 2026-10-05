-- =====================================================================
-- PulsePass - V1: esquema inicial
-- Flyway es responsable de crear y evolucionar el esquema.
-- Hibernate únicamente valida (ddl-auto: validate).
-- =====================================================================

-- ---------------------------------------------------------------------
-- venues
-- ---------------------------------------------------------------------
CREATE TABLE venues (
    id        BIGINT GENERATED ALWAYS AS IDENTITY,
    code      VARCHAR(30)  NOT NULL,
    name      VARCHAR(150) NOT NULL,
    city      VARCHAR(100) NOT NULL,
    capacity  INTEGER      NOT NULL,
    active    BOOLEAN      NOT NULL DEFAULT TRUE,

    CONSTRAINT pk_venues PRIMARY KEY (id),
    CONSTRAINT uk_venues_code UNIQUE (code),
    CONSTRAINT ck_venues_capacity CHECK (capacity > 0)
);

-- ---------------------------------------------------------------------
-- events
-- ---------------------------------------------------------------------
CREATE TABLE events (
    id           BIGINT GENERATED ALWAYS AS IDENTITY,
    event_code   VARCHAR(30)  NOT NULL,
    name         VARCHAR(150) NOT NULL,
    description  TEXT,
    category     VARCHAR(30)  NOT NULL,
    status       VARCHAR(30)  NOT NULL,
    event_date   TIMESTAMP    NOT NULL,
    minimum_age  INTEGER      NOT NULL DEFAULT 0,
    venue_id     BIGINT       NOT NULL,

    CONSTRAINT pk_events PRIMARY KEY (id),
    CONSTRAINT uk_events_event_code UNIQUE (event_code),
    CONSTRAINT fk_events_venue
        FOREIGN KEY (venue_id) REFERENCES venues (id),
    CONSTRAINT ck_events_category CHECK (
        category IN (
            'MUSIC',
            'FESTIVAL',
            'CONFERENCE',
            'UNIVERSITY',
            'SPORTS',
            'CULTURAL'
        )
    ),
    CONSTRAINT ck_events_status CHECK (
        status IN (
            'DRAFT',
            'PUBLISHED',
            'SOLD_OUT',
            'CANCELLED',
            'FINISHED'
        )
    ),
    CONSTRAINT ck_events_minimum_age CHECK (minimum_age >= 0)
);

-- ---------------------------------------------------------------------
-- artists
-- ---------------------------------------------------------------------
CREATE TABLE artists (
    id          BIGINT GENERATED ALWAYS AS IDENTITY,
    stage_name  VARCHAR(150) NOT NULL,
    active      BOOLEAN      NOT NULL DEFAULT TRUE,

    CONSTRAINT pk_artists PRIMARY KEY (id),
    CONSTRAINT uk_artists_stage_name UNIQUE (stage_name)
);

-- ---------------------------------------------------------------------
-- event_artists (tabla asociativa Event N:M Artist)
-- ---------------------------------------------------------------------
CREATE TABLE event_artists (
    event_id   BIGINT NOT NULL,
    artist_id  BIGINT NOT NULL,

    CONSTRAINT pk_event_artists PRIMARY KEY (event_id, artist_id),
    CONSTRAINT fk_event_artists_event
        FOREIGN KEY (event_id) REFERENCES events (id),
    CONSTRAINT fk_event_artists_artist
        FOREIGN KEY (artist_id) REFERENCES artists (id)
);

-- ---------------------------------------------------------------------
-- users
-- ---------------------------------------------------------------------
CREATE TABLE users (
    id        BIGINT GENERATED ALWAYS AS IDENTITY,
    username  VARCHAR(50)  NOT NULL,
    email     VARCHAR(150) NOT NULL,
    active    BOOLEAN      NOT NULL DEFAULT TRUE,

    CONSTRAINT pk_users PRIMARY KEY (id),
    CONSTRAINT uk_users_username UNIQUE (username)
);

-- El email debe ser único ignorando mayúsculas/minúsculas.
CREATE UNIQUE INDEX uk_users_email_lower ON users (LOWER(email));

-- ---------------------------------------------------------------------
-- user_profiles (User 1:1 UserProfile)
-- ---------------------------------------------------------------------
CREATE TABLE user_profiles (
    id          BIGINT GENERATED ALWAYS AS IDENTITY,
    user_id     BIGINT       NOT NULL,
    first_name  VARCHAR(100) NOT NULL,
    last_name   VARCHAR(100) NOT NULL,
    phone       VARCHAR(30),
    city        VARCHAR(100),
    birth_date  DATE         NOT NULL,

    CONSTRAINT pk_user_profiles PRIMARY KEY (id),
    CONSTRAINT uk_user_profiles_user UNIQUE (user_id),
    CONSTRAINT fk_user_profiles_user
        FOREIGN KEY (user_id) REFERENCES users (id)
);

-- ---------------------------------------------------------------------
-- tickets
-- ---------------------------------------------------------------------
CREATE TABLE tickets (
    id             BIGINT GENERATED ALWAYS AS IDENTITY,
    ticket_code    VARCHAR(40)    NOT NULL,
    type           VARCHAR(30)    NOT NULL,
    price          NUMERIC(12, 2) NOT NULL,
    status         VARCHAR(30)    NOT NULL,
    purchase_date  TIMESTAMP      NOT NULL,
    user_id        BIGINT         NOT NULL,
    event_id       BIGINT         NOT NULL,

    CONSTRAINT pk_tickets PRIMARY KEY (id),
    CONSTRAINT uk_tickets_ticket_code UNIQUE (ticket_code),
    CONSTRAINT fk_tickets_user
        FOREIGN KEY (user_id) REFERENCES users (id),
    CONSTRAINT fk_tickets_event
        FOREIGN KEY (event_id) REFERENCES events (id),
    CONSTRAINT ck_tickets_type CHECK (
        type IN (
            'GENERAL',
            'STUDENT',
            'VIP',
            'BACKSTAGE'
        )
    ),
    CONSTRAINT ck_tickets_status CHECK (
        status IN (
            'RESERVED',
            'PAID',
            'USED',
            'CANCELLED'
        )
    ),
    CONSTRAINT ck_tickets_price CHECK (price >= 0)
);

-- ---------------------------------------------------------------------
-- Índices
-- ---------------------------------------------------------------------
CREATE INDEX idx_events_venue_id   ON events (venue_id);
CREATE INDEX idx_events_status     ON events (status);
CREATE INDEX idx_events_event_date ON events (event_date);

CREATE INDEX idx_tickets_user_id   ON tickets (user_id);
CREATE INDEX idx_tickets_event_id  ON tickets (event_id);
CREATE INDEX idx_tickets_status    ON tickets (status);
