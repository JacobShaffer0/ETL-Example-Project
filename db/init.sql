-- 1. Create Schemas
CREATE SCHEMA IF NOT EXISTS raw;
CREATE SCHEMA IF NOT EXISTS staging;
CREATE SCHEMA IF NOT EXISTS ref;
CREATE SCHEMA IF NOT EXISTS public;
CREATE SCHEMA IF NOT EXISTS analytics;

-- 2. Layer 0: Reference Data Table
CREATE TABLE IF NOT EXISTS ref.mcc_categories (
    mcc TEXT PRIMARY KEY,
    description TEXT,
    category TEXT
);

-- 3. Layer 1: Raw Ingestion Table (All columns text)
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

-- 4. Layer 2: Staging & Rejections Tables
CREATE TABLE IF NOT EXISTS staging.transactions (
    transaction_id TEXT,
    member_id TEXT,
    account_id TEXT,
    posted_date DATE,
    amount NUMERIC(12,2),
    type TEXT,
    category TEXT,
    merchant TEXT,
    description TEXT,
    load_run_id TEXT
);

CREATE TABLE IF NOT EXISTS staging.rejections (
    load_run_id TEXT,
    line_number INT,
    txn_id TEXT,
    rejection_reason TEXT,
    rejected_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 5. Layer 3: Production Analytics Target Table
CREATE TABLE IF NOT EXISTS public.transactions (
    transaction_id TEXT PRIMARY KEY, -- Conflict target for upserts
    member_id TEXT NOT NULL,
    account_id TEXT NOT NULL,
    posted_date DATE NOT NULL,
    amount NUMERIC(12,2) NOT NULL,
    type TEXT NOT NULL,
    category TEXT NOT NULL,
    merchant TEXT,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 6. Optimization Index for Analytical Queries
CREATE INDEX IF NOT EXISTS idx_transactions_member_date 
ON public.transactions (member_id, posted_date);