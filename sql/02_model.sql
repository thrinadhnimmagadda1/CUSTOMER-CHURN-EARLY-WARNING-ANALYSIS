DROP VIEW IF EXISTS customer_features;
CREATE VIEW customer_features AS
SELECT
  *,
  CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END AS churned,
  CASE WHEN (ROW_NUMBER() OVER (ORDER BY customer_id) - 1) % 5 = 0 THEN 'test' ELSE 'train' END AS sample,
  CASE WHEN tenure <= 6 THEN '0-6 months'
       WHEN tenure <= 12 THEN '7-12 months'
       WHEN tenure <= 24 THEN '13-24 months'
       WHEN tenure <= 48 THEN '25-48 months'
       ELSE '49+ months' END AS tenure_band,
  CASE WHEN monthly_charges < 35 THEN 'Low (<$35)'
       WHEN monthly_charges < 70 THEN 'Medium ($35-$69.99)'
       ELSE 'High ($70+)' END AS charge_band,
  CASE WHEN contract = 'Month-to-month' THEN 1 ELSE 0 END AS s_monthly_contract,
  CASE WHEN tenure <= 12 THEN 1 ELSE 0 END AS s_short_tenure,
  CASE WHEN internet_service = 'Fiber optic' THEN 1 ELSE 0 END AS s_fiber,
  CASE WHEN online_security = 'No' THEN 1 ELSE 0 END AS s_no_security,
  CASE WHEN tech_support = 'No' THEN 1 ELSE 0 END AS s_no_support,
  CASE WHEN payment_method = 'Electronic check' THEN 1 ELSE 0 END AS s_echeck,
  CASE WHEN paperless_billing = 'Yes' THEN 1 ELSE 0 END AS s_paperless,
  CASE WHEN monthly_charges >= 70 THEN 1 ELSE 0 END AS s_high_charge
FROM raw_customers;

DROP TABLE IF EXISTS signal_weights;
CREATE TABLE signal_weights AS
WITH signals AS (
  SELECT churned, 'Month-to-month contract' signal, s_monthly_contract active FROM customer_features WHERE sample='train'
  UNION ALL SELECT churned, 'Tenure of 12 months or less', s_short_tenure FROM customer_features WHERE sample='train'
  UNION ALL SELECT churned, 'Fiber optic service', s_fiber FROM customer_features WHERE sample='train'
  UNION ALL SELECT churned, 'No online security', s_no_security FROM customer_features WHERE sample='train'
  UNION ALL SELECT churned, 'No tech support', s_no_support FROM customer_features WHERE sample='train'
  UNION ALL SELECT churned, 'Electronic check payment', s_echeck FROM customer_features WHERE sample='train'
  UNION ALL SELECT churned, 'Paperless billing', s_paperless FROM customer_features WHERE sample='train'
  UNION ALL SELECT churned, 'High monthly charge', s_high_charge FROM customer_features WHERE sample='train'
), baseline AS (
  SELECT AVG(churned * 1.0) base_rate FROM customer_features WHERE sample='train'
)
SELECT signal,
       COUNT(*) FILTER (WHERE active=1) AS active_customers,
       ROUND(AVG(churned * 1.0) FILTER (WHERE active=1), 6) AS signal_churn_rate,
       ROUND(base_rate, 6) AS baseline_churn_rate,
       ROUND(MAX(0.0, AVG(churned * 1.0) FILTER (WHERE active=1) / base_rate - 1.0), 6) AS weight
FROM signals CROSS JOIN baseline
GROUP BY signal;

DROP VIEW IF EXISTS customer_signal_long;
CREATE VIEW customer_signal_long AS
SELECT customer_id, churned, sample, 'Month-to-month contract' signal, s_monthly_contract active FROM customer_features
UNION ALL SELECT customer_id, churned, sample, 'Tenure of 12 months or less', s_short_tenure FROM customer_features
UNION ALL SELECT customer_id, churned, sample, 'Fiber optic service', s_fiber FROM customer_features
UNION ALL SELECT customer_id, churned, sample, 'No online security', s_no_security FROM customer_features
UNION ALL SELECT customer_id, churned, sample, 'No tech support', s_no_support FROM customer_features
UNION ALL SELECT customer_id, churned, sample, 'Electronic check payment', s_echeck FROM customer_features
UNION ALL SELECT customer_id, churned, sample, 'Paperless billing', s_paperless FROM customer_features
UNION ALL SELECT customer_id, churned, sample, 'High monthly charge', s_high_charge FROM customer_features;

DROP TABLE IF EXISTS customer_scores;
CREATE TABLE customer_scores AS
WITH contributions AS (
  SELECT s.customer_id, s.churned, s.sample, s.signal, s.active * w.weight contribution
  FROM customer_signal_long s JOIN signal_weights w USING(signal)
), totals AS (
  SELECT customer_id, churned, sample, SUM(contribution) raw_score
  FROM contributions GROUP BY customer_id, churned, sample
), bounds AS (
  SELECT MIN(raw_score) lo, MAX(raw_score) hi FROM totals WHERE sample='train'
), ranked_reasons AS (
  SELECT customer_id, signal,
         ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY contribution DESC, signal) rn
  FROM contributions WHERE contribution > 0
)
SELECT t.customer_id, t.churned, t.sample,
       ROUND(100.0 * (t.raw_score - b.lo) / NULLIF(b.hi-b.lo,0), 1) risk_score,
       CASE WHEN 100.0*(t.raw_score-b.lo)/NULLIF(b.hi-b.lo,0) >= 70 THEN 'High'
            WHEN 100.0*(t.raw_score-b.lo)/NULLIF(b.hi-b.lo,0) >= 40 THEN 'Medium'
            ELSE 'Low' END risk_tier,
       COALESCE(r.signal, 'No elevated signal') top_risk_reason
FROM totals t CROSS JOIN bounds b
LEFT JOIN ranked_reasons r ON t.customer_id=r.customer_id AND r.rn=1;

DROP VIEW IF EXISTS customer_risk_export;
CREATE VIEW customer_risk_export AS
SELECT f.customer_id, f.gender, f.senior_citizen, f.partner, f.dependents,
       f.tenure, f.tenure_band, f.contract, f.internet_service, f.tech_support,
       f.online_security, f.payment_method, f.paperless_billing,
       f.monthly_charges, f.total_charges, s.risk_score, s.risk_tier,
       s.top_risk_reason, s.churned, s.sample
FROM customer_features f JOIN customer_scores s USING(customer_id);

DROP VIEW IF EXISTS validation_by_tier;
CREATE VIEW validation_by_tier AS
SELECT risk_tier, COUNT(*) customers, SUM(churned) actual_churners,
       ROUND(100.0*AVG(churned),1) actual_churn_rate_pct,
       ROUND(AVG(risk_score),1) avg_risk_score
FROM customer_scores WHERE sample='test'
GROUP BY risk_tier
ORDER BY CASE risk_tier WHEN 'High' THEN 1 WHEN 'Medium' THEN 2 ELSE 3 END;

