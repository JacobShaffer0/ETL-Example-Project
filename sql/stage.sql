-- Clean up staging tables for current batch execution
TRUNCATE TABLE staging.transactions;
TRUNCATE TABLE staging.rejections;

-- Step 1: Route invalid records from raw into staging.rejections
WITH target_batch AS (
    SELECT load_run_id 
    FROM raw.transactions 
    GROUP BY load_run_id
    ORDER BY MAX(loaded_at) DESC 
    LIMIT 1
)
INSERT INTO staging.rejections (
    line_number,
    load_run_id,
    transaction_id,
    rejection_reason,
    rejected_at
)
SELECT 
    r.line_number,
    r.load_run_id,
    r.txn_id,
    CASE 
        WHEN r.txn_id IS NULL OR TRIM(r.txn_id) = '' THEN 'Missing transaction_id'
        WHEN r.txn_amt IS NULL OR TRIM(r.txn_amt) = '' THEN 'Missing transaction amount'
        WHEN r.post_dt IS NULL OR TRIM(BOTH E' \r\n\t' FROM r.post_dt::text) = '' THEN 'Date is Null'
        ELSE 'Unknown data quality issue'
    END AS rejection_reason,
    NOW() AS rejected_at
FROM raw.transactions r
JOIN target_batch tb ON r.load_run_id = tb.load_run_id
WHERE (
    r.txn_id IS NULL OR TRIM(r.txn_id) = ''
    OR r.txn_amt IS NULL OR TRIM(r.txn_amt) = ''
    OR r.post_dt IS NULL 
    OR TRIM(BOTH E' \r\n\t' FROM r.post_dt::text) = ''
);

-- Step 2: Clean, transform, deduplicate, and load valid records into staging.transactions
WITH target_batch AS (
    SELECT load_run_id 
    FROM raw.transactions 
    GROUP BY load_run_id
    ORDER BY MAX(loaded_at) DESC 
    LIMIT 1
),
valid_raw AS (
    SELECT 
        r.line_number,
        r.load_run_id,
        TRIM(r.txn_id) AS transaction_id,
        TRIM(r.mbr_num) AS member_id,
        TRIM(r.acct_num) AS account_id,
        CASE 
            WHEN TRIM(BOTH E' \r\n\t' FROM r.post_dt::text) ~ '^\d{8}$' 
                THEN TO_DATE(TRIM(BOTH E' \r\n\t' FROM r.post_dt::text), 'YYYYMMDD')
            ELSE TO_DATE(TRIM(BOTH E' \r\n\t' FROM r.post_dt::text), 'YYYY-MM-DD')
        END AS posted_date,
        CASE 
            WHEN UPPER(TRIM(r.dr_cr_cd)) = 'D' THEN -ABS(r.txn_amt::numeric(12,2))
            ELSE ABS(r.txn_amt::numeric(12,2))
        END AS amount,
        CASE 
            WHEN UPPER(TRIM(r.dr_cr_cd)) = 'D' THEN 'debit'
            WHEN UPPER(TRIM(r.dr_cr_cd)) = 'C' THEN 'credit'
            ELSE 'other'
        END AS type,
        COALESCE(m.category, 'other') AS category,
        TRIM(r.merch_nm) AS merchant,
        TRIM(r.txn_desc) AS description,
        r.loaded_at
    FROM raw.transactions r
    JOIN target_batch tb ON r.load_run_id = tb.load_run_id
    LEFT JOIN ref.mcc_categories m 
        ON TRIM(r.mcc) = m.mcc
    WHERE r.txn_id IS NOT NULL AND TRIM(r.txn_id) != ''
      AND r.txn_amt IS NOT NULL AND TRIM(r.txn_amt) != ''
      AND r.post_dt IS NOT NULL
      AND TRIM(BOTH E' \r\n\t' FROM r.post_dt::text) != ''
),
deduplicated AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (
            PARTITION BY transaction_id 
            ORDER BY loaded_at DESC, line_number DESC
        ) AS row_num
    FROM valid_raw
)
INSERT INTO staging.transactions (
    transaction_id,
    member_id,
    account_id,
    posted_date,
    amount,
    type,
    category,
    merchant,
    description,
    load_run_id
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
    load_run_id
FROM deduplicated
WHERE row_num = 1;

