| `TXN_ID` | `transaction_id` | `text` | Renamed. Used as unique constraint for upserts. |
| `MBR_NUM` | `member_id` | `text` | Renamed. Links transaction to member. |
| `ACCT_NUM` | `account_id` | `text` | Renamed. Links transaction to account. |
| `POST_DT` | `posted_date` | `date` | Parsed from `YYYYMMDD` string using `TO_DATE(POST_DT, 'YYYYMMDD')`. |
| `TXN_AMT` + `DR_CR_CD` | `amount` | `numeric(12,2)` | Numeric conversion. Debits (`DR_CR_CD = 'D'`) are negated (`-TXN_AMT`); credits (`'C'`) remain positive. |
| `DR_CR_CD` | `type` | `text` | Decoded via `CASE`: `'D'` → `'debit'`, `'C'` to `'credit'`. |
| `MCC` | `category` | `text` | Joined to `ref.mcc_categories` on `MCC`. Defaults via `COALESCE(ref.category, 'other')`. |
| `MERCH_NM` | `merchant` | `text` | Direct map. Trimmed for spaces. |
| `TXN_DESC` | `description` | `text` | Direct map. |
| *(System)* | `created_at` | `timestamptz` | Set to `CURRENT_TIMESTAMP` on original row insertion. |
| *(System)* | `updated_at` | `timestamptz` | Set to `CURRENT_TIMESTAMP` on initial insertion and updated on every upsert conflict. |