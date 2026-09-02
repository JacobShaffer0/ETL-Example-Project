CREATE SCHEMA IF NOT EXISTS analytics;

CREATE OR REPLACE VIEW analytics.member_monthly_spending AS
WITH monthly_category_aggregates AS (
    SELECT 
        member_id,
        EXTRACT(YEAR FROM posted_date)::INT AS spend_year,
        EXTRACT(MONTH FROM posted_date)::INT AS spend_month,
        category,
        -- Total spend: sum of debits (using ABS to ensure positive spending metrics)
        SUM(ABS(amount)) AS total_spend,
        COUNT(transaction_id) AS transaction_count
    FROM public.transactions
    WHERE type = 'debit'
    GROUP BY 
        member_id,
        EXTRACT(YEAR FROM posted_date),
        EXTRACT(MONTH FROM posted_date),
        category
)
SELECT 
    member_id,
    spend_year,
    spend_month,
    category,
    total_spend,
    transaction_count,
    
    -- Month-over-Month spend delta
    total_spend - LAG(total_spend, 1, 0) OVER (
        PARTITION BY member_id, category 
        ORDER BY spend_year, spend_month
    ) AS mom_spend_delta,
    
    -- Running Year-To-Date debit total
    SUM(total_spend) OVER (
        PARTITION BY member_id, spend_year, category 
        ORDER BY spend_month
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS ytd_total_spend

FROM monthly_category_aggregates
ORDER BY member_id, category, spend_year, spend_month;
select * from analytics.member_monthly_spending;
