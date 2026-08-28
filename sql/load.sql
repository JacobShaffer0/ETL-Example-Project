-- Step 1: Ensure target production table exists
CREATE TABLE IF NOT EXISTS public.transactions (
    transaction_id VARCHAR(64) PRIMARY KEY,
    member_id VARCHAR(64) NOT NULL,
    account_id VARCHAR(64) NOT NULL,
    posted_date DATE NOT NULL,
    amount NUMERIC(12, 2) NOT NULL,
    type VARCHAR(20) NOT NULL,
    category VARCHAR(64),
    merchant VARCHAR(255),
    description TEXT,
    load_run_id VARCHAR(64),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_transactions_member_id ON public.transactions(member_id);
CREATE INDEX IF NOT EXISTS idx_transactions_posted_date ON public.transactions(posted_date);

-- Step 2: Idempotent Upsert from staging into production
INSERT INTO public.transactions (
    transaction_id,
    member_id,
    account_id,
    posted_date,
    amount,
    type,
    category,
    merchant,
    description,
    created_at,
    updated_at
)
SELECT 
    transaction_id,
    member_id,
    account_id,
    posted_date,
    amount,
    type,
    category,
    merchant,
    description,
    NOW() AS created_at,
    NOW() AS updated_at
FROM staging.transactions
ON CONFLICT (transaction_id) 
DO UPDATE SET
    member_id    = EXCLUDED.member_id,
    account_id   = EXCLUDED.account_id,
    posted_date  = EXCLUDED.posted_date,
    amount       = EXCLUDED.amount,
    type         = EXCLUDED.type,
    category     = EXCLUDED.category,
    merchant     = EXCLUDED.merchant,
    description  = EXCLUDED.description,
    updated_at   = NOW();

    select count(*) from public.transactions;
    