-- Top merchants last 30d
SELECT m.merchant_name,COUNT(*) AS tx_count,SUM(t.amount) AS total_amount
FROM transactions t JOIN merchants m ON t.merchant_id=m.merchant_id
WHERE t.tx_ts >= NOW() - INTERVAL 30 DAY
GROUP BY m.merchant_name ORDER BY total_amount DESC LIMIT 10;

-- Fraud rate by brand
SELECT c.brand,COUNT(f.alert_id) AS alerts_count,COUNT(DISTINCT t.tx_id) AS tx_count,
       ROUND(COUNT(f.alert_id)/NULLIF(COUNT(t.tx_id),0),4) AS alerts_per_tx
FROM transactions t JOIN cards c ON t.card_id=c.card_id
LEFT JOIN fraud_alerts f ON f.tx_id=t.tx_id
GROUP BY c.brand ORDER BY alerts_per_tx DESC;

-- Latency trend 7d
SELECT DATE(tx_ts) AS dt,AVG(decision_latency_ms) AS avg_latency,COUNT(*) AS tx_count
FROM transactions
WHERE tx_ts >= NOW()-INTERVAL 7 DAY
GROUP BY DATE(tx_ts) ORDER BY dt;

-- Find top 10 merchants with the highest total transaction value
SELECT merchant_id, SUM(amount) AS total_volume
FROM transactions
GROUP BY merchant_id
ORDER BY total_volume DESC
LIMIT 10;

-- Average fraud score by merchant
SELECT t.merchant_id, AVG(ms.score) AS avg_risk_score
FROM transactions t
JOIN model_scores ms ON t.tx_id = ms.tx_id
GROUP BY t.merchant_id
ORDER BY avg_risk_score DESC;

-- Top 5 countries with the most fraudulent scores (score > 0.8)
SELECT t.geo_country, COUNT(*) AS fraud_like_tx
FROM transactions t
JOIN model_scores ms ON t.tx_id = ms.tx_id
WHERE ms.score > 0.8
GROUP BY t.geo_country
ORDER BY fraud_like_tx DESC
LIMIT 5;

-- Find top 10 risky cards by average model score
SELECT t.card_id, AVG(ms.score) AS avg_score
FROM transactions t
JOIN model_scores ms ON t.tx_id = ms.tx_id
GROUP BY t.card_id
ORDER BY avg_score DESC
LIMIT 10;

-- Top 5 devices with most failed authorizations
SELECT device_fingerprint, COUNT(*) AS failed_attempts
FROM transactions
GROUP BY device_fingerprint
ORDER BY failed_attempts DESC
LIMIT 5;

-- Most recent model version per model_name
SELECT model_name, MAX(version) AS latest_version
FROM model_scores
GROUP BY model_name;

-- % of high-risk scores (>0.9) by channel
SELECT channel,
       SUM(CASE WHEN ms.score > 0.9 THEN 1 ELSE 0 END) / COUNT(*) * 100 AS high_risk_pct
FROM transactions t
JOIN model_scores ms ON t.tx_id = ms.tx_id
GROUP BY channel;

--  Fraud score distribution (bucketed)
SELECT CASE
         WHEN score < 0.2 THEN 'Very Low'
         WHEN score < 0.5 THEN 'Low'
         WHEN score < 0.8 THEN 'Medium'
         ELSE 'High'
       END AS score_band,
       COUNT(*) AS tx_count
FROM model_scores
GROUP BY score_band;

-- Top 5 cards by number of transactions above $5,000
SELECT card_id, COUNT(*) AS high_value_tx
FROM transactions
WHERE amount > 5000
GROUP BY card_id
ORDER BY high_value_tx DESC
LIMIT 5;

-- Merchant with most unique cards used
SELECT merchant_id, COUNT(DISTINCT card_id) AS unique_customers
FROM transactions
GROUP BY merchant_id
ORDER BY unique_customers DESC
LIMIT 5;

-- Rolling fraud detection KPI: 30-day average fraud score per card
SELECT card_id, tx_ts,
       AVG(ms.score) OVER (PARTITION BY card_id 
       ORDER BY tx_ts RANGE BETWEEN INTERVAL 30 
       DAY PRECEDING AND CURRENT ROW) AS rolling_fraud_score
FROM transactions t
JOIN model_scores ms ON t.tx_id = ms.tx_id;

-- Weighted fraud score by transaction amount

SELECT card_id,
       SUM(score * amount) / SUM(amount) AS weighted_fraud_score
FROM transactions t
JOIN model_scores ms ON t.tx_id = ms.tx_id
GROUP BY card_id
ORDER BY weighted_fraud_score DESC
LIMIT 10;

-- “Card cloning suspicion” – same card used in >2 different countries within a single day
SELECT card_id, DATE(tx_ts) AS tx_date, COUNT(DISTINCT geo_country) AS countries_used
FROM transactions
GROUP BY card_id, DATE(tx_ts)
HAVING countries_used > 2;

-- Top 10 risky “merchant + channel” combos
SELECT merchant_id, channel,
       AVG(ms.score) AS avg_risk_score,
       COUNT(*) AS tx_count
FROM transactions t
JOIN model_scores ms ON t.tx_id = ms.tx_id
GROUP BY merchant_id, channel
ORDER BY avg_risk_score DESC
LIMIT 10;

-- Fraud score time-series trend per card
SELECT card_id, DATE(tx_ts) AS tx_date, AVG(ms.score) AS daily_avg_score
FROM transactions t
JOIN model_scores ms ON t.tx_id = ms.tx_id
GROUP BY card_id, tx_date
ORDER BY tx_date DESC;
