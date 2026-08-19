# Power BI build specification

Import `outputs/customer_risk_scores.csv`, `outputs/signal_weights.csv`, and
`outputs/validation_by_tier.csv`. Add the measures from `measures.dax`.

## Page 1 — Executive overview

- Cards: Total Customers, Actual Churn Rate, High Risk Customers, High Risk Precision
- Donut: customers by risk tier (sort High, Medium, Low)
- Column chart: churn rate by risk tier, filtered to `sample = test`
- Bar chart: customers by top risk reason
- Slicers: contract, tenure band, internet service, senior citizen

## Page 2 — Retention action list

- Table: customer ID, risk score, tier, top reason, tenure, contract, monthly charges, payment method
- Apply red/amber/green conditional formatting to risk score
- Default filter: risk tier is High or Medium; actual churn is intentionally not shown to users

## Page 3 — Driver and validation analysis

- Bar chart from `signal_weights`: signal vs weight
- Combo chart from `validation_by_tier`: customers and actual churn rate
- Matrix: top risk reason by risk tier, showing customer count and churn rate
- Add a text note: weights use the training sample; performance uses the untouched test sample

