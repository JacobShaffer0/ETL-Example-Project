-- Step 1: Truncate staging tables so the active load batch stays isolated
TRUNCATE TABLE staging.transactions;
TRUNCATE TABLE staging.rejections;

-- Step 2: Route bad/invalid records from raw into staging.rejections
INSERT INTO staging.rejections (
    line_number,
    load_run_id,
    transaction_id,
    rejection_reason,
    rejected_at
)
SELECT 
    line_number,
    load_run_id,
    txn_id,
    CASE 
        WHEN txn_id IS NULL OR TRIM(txn_id) = '' THEN 'Missing transaction_id'
        WHEN txn_amt IS NULL OR TRIM(txn_amt) = '' THEN 'Missing transaction amount'
        WHEN post_dt IS NULL OR post_dt !~ '^\d{8}$' THEN 'Invalid or unparseable post_dt format (expected YYYYMMDD)'
        ELSE 'Unknown data quality issue'
    END AS rejection_reason,
    NOW() AS rejected_at
FROM raw.transactions
WHERE load_run_id = (SELECT load_run_id FROM raw.transactions ORDER BY loaded_at DESC LIMIT 1)  AND (
      txn_id IS NULL OR TRIM(txn_id) = ''
      OR txn_amt IS NULL OR TRIM(txn_amt) = ''
      OR post_dt IS NULL OR post_dt !~ '^\d{8}$'
  );

-- Step 3: Clean, transform, deduplicate, and load valid records into staging.transactions
WITH valid_raw AS (
    SELECT 
        r.line_number,
        r.load_run_id,
        TRIM(r.txn_id) AS transaction_id,
        TRIM(r.mbr_num) AS member_id,
        TRIM(r.acct_num) AS account_id,
        TO_DATE(r.post_dt, 'YYYYMMDD') AS posted_date,
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
    LEFT JOIN ref.mcc_categories m 
        ON TRIM(r.mcc) = m.mcc
WHERE r.load_run_id = (SELECT load_run_id FROM raw.transactions ORDER BY loaded_at DESC LIMIT 1)      AND r.txn_id IS NOT NULL AND TRIM(r.txn_id) != ''
      AND r.txn_amt IS NOT NULL AND TRIM(r.txn_amt) != ''
      AND r.post_dt ~ '^\d{8}$'
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



