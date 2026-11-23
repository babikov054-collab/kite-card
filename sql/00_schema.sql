-- Kite Card: credit-card acquisition funnel
-- Creates the 5 tables and loads them from data/*.csv
-- Run once:  duckdb card_funnel.duckdb < sql/00_schema.sql

CREATE OR REPLACE TABLE customers (
    customer_id         INTEGER PRIMARY KEY,
    birth_year          INTEGER,
    city                VARCHAR,
    employment_status   VARCHAR,       -- employed / self_employed / student / unemployed / retired
    monthly_income_eur  DOUBLE,
    created_at          TIMESTAMP
);

CREATE OR REPLACE TABLE applications (
    application_id        INTEGER PRIMARY KEY,
    customer_id           INTEGER,
    applied_at            TIMESTAMP,
    channel               VARCHAR,     -- instagram / google_ads / referral / organic / tiktok / affiliate
    device                VARCHAR,     -- ios / android / web
    acquisition_cost_eur  DOUBLE,      -- marketing cost paid for this lead
    kyc_status            VARCHAR,     -- completed / abandoned
    kyc_completed_at      TIMESTAMP    -- NULL if abandoned
);

CREATE OR REPLACE TABLE credit_decisions (
    decision_id       INTEGER PRIMARY KEY,
    application_id    INTEGER,
    decided_at        TIMESTAMP,
    decision          VARCHAR,         -- approved / declined
    decision_type     VARCHAR,         -- automated / manual_review
    score_version     VARCHAR,         -- v1 (until 2025-03-14) / v2 (from 2025-03-15)
    decline_reason    VARCHAR,         -- NULL if approved
    credit_limit_eur  DOUBLE           -- NULL if declined
);

CREATE OR REPLACE TABLE cards (
    card_id         INTEGER PRIMARY KEY,
    application_id  INTEGER,
    customer_id     INTEGER,
    shipped_at      TIMESTAMP,
    courier         VARCHAR,           -- RapidEnvio / EuroParcel
    delivered_at    TIMESTAMP,         -- NULL if lost in transit
    activated_at    TIMESTAMP,         -- NULL if never activated
    status          VARCHAR            -- active / delivered_inactive / lost_in_transit
);

CREATE OR REPLACE TABLE transactions (
    transaction_id     INTEGER PRIMARY KEY,
    card_id            INTEGER,
    txn_at             TIMESTAMP,
    amount_eur         DOUBLE,
    merchant_category  VARCHAR
);

COPY customers        FROM 'data/customers.csv'        (HEADER, NULLSTR '');
COPY applications     FROM 'data/applications.csv'     (HEADER, NULLSTR '');
COPY credit_decisions FROM 'data/credit_decisions.csv' (HEADER, NULLSTR '');
COPY cards            FROM 'data/cards.csv'            (HEADER, NULLSTR '');
COPY transactions     FROM 'data/transactions.csv'     (HEADER, NULLSTR '');
