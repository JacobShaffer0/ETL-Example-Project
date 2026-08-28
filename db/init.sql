-- 1. Create Schemas
CREATE SCHEMA IF NOT EXISTS raw;
CREATE SCHEMA IF NOT EXISTS ref;

CREATE TABLE IF NOT EXISTS ref.mcc_categories (
    mcc TEXT PRIMARY KEY,
    description TEXT,
    category TEXT
);

CREATE TABLE IF NOT EXISTS raw.transactions (
    load_run_id TEXT,
    loaded_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    line_number INT,
    txn_id TEXT,
    mbr_num TEXT,
    acct_num TEXT,
    post_dt TEXT,
    txn_amt TEXT,
    dr_cr_cd TEXT,
    mcc TEXT,
    merch_nm TEXT,
    txn_desc TEXT,
    txn_seq_num TEXT,
    proc_dt TEXT,
    batch_id TEXT
);

DROP TABLE IF EXISTS staging.rejections;
CREATE TABLE staging.rejections (
    id SERIAL PRIMARY KEY,
    line_number INT,
    load_run_id VARCHAR(64),
    transaction_id VARCHAR(128),
    rejection_reason TEXT,
    rejected_at TIMESTAMPTZ DEFAULT NOW()
);

-- Re-create staging.transactions table
DROP TABLE IF EXISTS staging.transactions;
CREATE TABLE staging.transactions (
    transaction_id VARCHAR(64) PRIMARY KEY,
    member_id VARCHAR(64),
    account_id VARCHAR(64),
    posted_date DATE,
    amount NUMERIC(12, 2),
    type VARCHAR(20),
    category VARCHAR(64),
    merchant VARCHAR(255),
    description TEXT,
    load_run_id VARCHAR(64),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.transactions (
    transaction_id VARCHAR(64) PRIMARY KEY,
    member_id VARCHAR(64),
    account_id VARCHAR(64),
    posted_date DATE,
    amount NUMERIC(12, 2),
    type VARCHAR(20),
    category VARCHAR(64),
    merchant VARCHAR(255),
    description TEXT,
    load_run_id VARCHAR(64),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);