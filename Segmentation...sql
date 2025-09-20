# Segmentation & Insights 

--  High-Spend Digital First Enterprises ---

WITH customer_stats AS (
    SELECT 
        customer_id,
        SUM(amount) AS total_spend,
        AVG(digital_login_frequency) AS avg_digital_use,
        COUNT(transaction_id) AS total_transactions,
        AVG(amount) AS avg_transaction
    FROM amex_business
    GROUP BY customer_id
)

SELECT
    customer_id,
    total_spend,
    avg_digital_use,
    total_transactions,
    avg_transaction
FROM customer_stats
WHERE total_spend > 20000
  AND avg_digital_use > 20
ORDER BY total_spend DESC;

--  Traditional Large Accounts (low digital adoption)  --
# IF total_spend > 20000       -- High total spend threshold (adjust as needed)
# IF avg_digital_use <= 20     -- Low digital adoption threshold (adjust as needed)

WITH customer_stats AS (
    SELECT 
        customer_id,
        SUM(amount) AS total_spend,
        COUNT(transaction_id) AS total_transactions,
        AVG(amount) AS avg_transaction,
        AVG(digital_login_frequency) AS avg_digital_use
    FROM amex_business
    GROUP BY customer_id
)

SELECT
    customer_id,
    total_spend,
    total_transactions,
    avg_transaction,
    avg_digital_use
FROM customer_stats
ORDER BY total_spend DESC;

--   Mid-Market Growth Firms ---
# IF total_spend BETWEEN 10000 AND 20000 → filters for medium spend
# IF total_transactions BETWEEN 50 AND 200 → filters for medium transaction activity

WITH customer_stats AS (
    SELECT 
        customer_id,
        SUM(amount) AS total_spend,
        COUNT(transaction_id) AS total_transactions,
        ROUND(AVG(amount),2) AS avg_transaction,
        ROUND(STDDEV(amount),2) AS spend_volatility,
        ROUND(AVG(digital_login_frequency),1) AS avg_digital_use
    FROM amex_business
    GROUP BY customer_id
)

SELECT
    customer_id,
    total_spend,
    total_transactions,
    avg_transaction,
    spend_volatility,
    avg_digital_use
FROM customer_stats
ORDER BY total_spend DESC;

--   Transaction-Heavy, Low Margin Firms  ---
# IF total_transactions > 200          -- threshold for "heavy" transactions
# IF avg_transaction < 50              -- threshold for "low margin"

WITH customer_stats AS (
    SELECT 
        customer_id,
        COUNT(transaction_id) AS total_transactions,
        ROUND(AVG(amount),2) AS avg_transaction,
        SUM(amount) AS total_spend
    FROM amex_business
    GROUP BY customer_id
)

SELECT
    customer_id,
    total_transactions,
    avg_transaction,
    total_spend
FROM customer_stats 
ORDER BY total_transactions DESC, avg_transaction ASC;

--   Emerging Businesses with Volatile Spend   ---
# IF spend_volatility > 1000  -- adjust threshold as needed

WITH customer_volatility AS (
    SELECT 
        customer_id,
        SUM(amount) AS total_spend,
        COUNT(transaction_id) AS total_transactions,
        ROUND(AVG(amount),2) AS avg_transaction,
        ROUND(STDDEV(amount),2) AS spend_volatility,
        ROUND(AVG(digital_login_frequency),2) AS avg_digital_use
    FROM amex_business
    GROUP BY customer_id
)

SELECT
    customer_id,
    total_spend,
    total_transactions,
    avg_transaction,
    spend_volatility,
    avg_digital_use
FROM customer_volatility
ORDER BY spend_volatility DESC;

SELECT * FROM customer_segments WHERE segment_name = 'Traditional Large Accounts';






