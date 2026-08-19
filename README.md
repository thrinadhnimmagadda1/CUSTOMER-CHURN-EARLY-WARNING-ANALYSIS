# Customer Churn Early-Warning Analysis

## Project summary

This project builds a customer churn early-warning system for a telecom subscription business. Instead of only reporting churn after customers leave, the analysis creates a 0-100 risk score that flags customers who are likely to churn before the churn event happens.

The project uses SQL-based feature engineering and scoring, validates the score against historical churn outcomes, and produces Power BI-ready datasets for a business dashboard. The final output is designed for retention teams: it does not only show who is at risk, it also explains the top reason each customer was flagged.

## Business problem

Subscription companies lose revenue when customers cancel service. Many companies only discover churn after it has already happened, which means the business has missed the chance to intervene with onboarding help, billing support, service improvements, or contract offers.

The goal of this project is to answer three practical business questions:

1. Which customers are most likely to churn?
2. Why are those customers at risk?
3. How well does the risk score perform when tested against real churn outcomes?

## Tools used

- SQL / SQLite for database modeling, feature engineering, risk scoring, and validation
- Python for the reproducible build script and CSV exports
- Power BI for dashboard design and business reporting
- CSV outputs for BI-ready reporting tables
- Public IBM Telco Customer Churn dataset

## Dataset

The project uses the public IBM Telco Customer Churn sample dataset with 7,043 customers. The dataset includes customer demographics, subscription attributes, billing fields, product add-ons, contract type, tenure, monthly charges, total charges, and churn status.

Important fields include:

- `customerID`
- `gender`
- `SeniorCitizen`
- `Partner`
- `Dependents`
- `tenure`
- `PhoneService`
- `InternetService`
- `OnlineSecurity`
- `TechSupport`
- `Contract`
- `PaperlessBilling`
- `PaymentMethod`
- `MonthlyCharges`
- `TotalCharges`
- `Churn`

Data source: IBM customer churn prediction project: https://github.com/IBM/customer-churn-prediction

## Project structure

```text
data/raw/telco_customer_churn.csv        Source customer churn dataset
sql/01_schema.sql                        Raw table schema
sql/02_model.sql                         Feature engineering, scoring, and validation logic
scripts/build.py                         One-command project build script
outputs/customer_risk_scores.csv         Customer-level Power BI output
outputs/validation_by_tier.csv           Risk-tier validation output
outputs/signal_weights.csv               Learned churn signal weights
outputs/risk_reason_summary.csv          Churn by risk reason and tier
outputs/customer_churn_early_warning_20_page_report.pdf
                                          Detailed project report
powerbi/dashboard_spec.md                Power BI dashboard build guide
powerbi/measures.dax                     DAX measures for the dashboard
docs/findings.md                         Business findings and recommendations
```

## How to run the project

Run the build script from the project folder:

```bash
python3 scripts/build.py
```

The script creates a local SQLite database and exports Power BI-ready CSV files into the `outputs/` folder.

Generated outputs:

- `customer_risk_scores.csv`
- `validation_by_tier.csv`
- `signal_weights.csv`
- `risk_reason_summary.csv`

## Methodology

The project follows a realistic analytics workflow:

1. Load the raw churn dataset into SQLite.
2. Clean and standardize customer fields.
3. Create customer-level churn risk signals.
4. Split customers into training and test samples.
5. Learn signal weights from the training sample.
6. Score every customer from 0 to 100.
7. Assign risk tiers: Low, Medium, and High.
8. Identify the top risk reason for each customer.
9. Validate the score on the untouched test sample.
10. Export results for Power BI.

## Risk scoring approach

This project intentionally uses interpretable SQL logic instead of a black-box machine learning model. The goal is to create a score that a business stakeholder can understand and trust.

Eight churn risk signals are evaluated for each customer:

- Short tenure
- Month-to-month contract
- Electronic check payment method
- Fiber optic internet service
- No online security
- No tech support
- Paperless billing
- High monthly charges

For each signal, the SQL model calculates how strongly that signal is associated with churn in the training sample.

The signal weight is calculated as:

```text
max(0, signal churn rate / baseline churn rate - 1)
```

This means a signal receives more weight when customers with that signal churn more often than the average customer. If a signal does not increase churn risk, it does not receive a positive weight.

The active signal weights are then combined and scaled into a 0-100 score.

Risk tiers:

- Low: score below 40
- Medium: score from 40 to 69.9
- High: score of 70 or above

## Why the validation matters

Many portfolio projects create a score but do not prove whether the score works. This project separates the data into a training sample and a test sample. The training sample is used to learn signal weights. The test sample is held out and used only for validation.

That makes the result more credible because the model is judged on customers it did not use to create the score.

## Validation results

The held-out test sample contains 1,409 customers. The overall churn rate in the test sample is 26.1%.

| Risk tier | Customers | Actual churners | Churn rate |
|---|---:|---:|---:|
| High | 284 | 185 | 65.1% |
| Medium | 442 | 134 | 30.3% |
| Low | 683 | 49 | 7.2% |

Key result:

The High-risk tier has a 65.1% actual churn rate compared with a 26.1% baseline churn rate. That is a 2.49x lift over the average customer.

The High-risk tier also captures 50.3% of all churners in the test sample while representing only 20.2% of test customers. This makes it a practical retention outreach queue.

## Key findings

The strongest churn signals in the training sample were:

| Signal | Training churn rate | Lift |
|---|---:|---:|
| Tenure of 12 months or less | 47.8% | 1.79x |
| Electronic check payment method | 46.1% | 1.73x |
| Month-to-month contract | 42.9% | 1.61x |

The most important business insight is that early-tenure customers are a major churn risk. This suggests that a retention strategy should focus on onboarding quality, early customer support, and first-year engagement before offering broad discounts.

## Power BI dashboard

The Power BI dashboard is designed around four pages.

### Page 1: Executive Overview

Purpose: give leaders a fast summary of customer churn risk.

Recommended visuals:

- Total Customers card
- Actual Churn Rate card
- High Risk Customers card
- High Risk Precision card
- Customers by Risk Tier donut chart
- Churn Rate by Risk Tier column chart
- Customers by Top Risk Reason bar chart

Recommended slicers:

- Contract type
- Tenure band
- Internet service
- Senior citizen flag

### Page 2: Retention Action List

Purpose: give the retention team a list of customers to prioritize.

Recommended columns:

- Customer ID
- Risk Score
- Risk Tier
- Top Risk Reason
- Tenure
- Contract
- Monthly Charges
- Payment Method

Recommended filter:

- Show only High and Medium risk customers

This page should not focus on the historical churn label. In a real business dashboard, the purpose is to decide who needs outreach now.

### Page 3: Driver and Validation Analysis

Purpose: explain why the score works and which factors drive churn.

Recommended visuals:

- Signal Weight bar chart
- Customer count and churn rate by risk tier
- Top risk reason by risk tier matrix
- Validation note explaining that weights were learned on training data and performance was measured on test data

### Page 4: Segment Drilldown

Purpose: allow deeper analysis by customer segment.

Recommended visuals:

- Risk tier by contract type
- Risk score by tenure band
- Churn rate by payment method
- High-risk customers by internet service
- Top risk reason by customer segment

## DAX measures

The main DAX measures are included in `powerbi/measures.dax`.

Core measures:

```DAX
Total Customers = DISTINCTCOUNT(customer_risk_scores[customer_id])

Actual Churners = CALCULATE([Total Customers], customer_risk_scores[churned] = 1)

Actual Churn Rate = DIVIDE([Actual Churners], [Total Customers])

High Risk Customers = CALCULATE([Total Customers], customer_risk_scores[risk_tier] = "High")

High Risk Precision =
DIVIDE(
    CALCULATE([Actual Churners], customer_risk_scores[risk_tier] = "High", customer_risk_scores[sample] = "test"),
    CALCULATE([Total Customers], customer_risk_scores[risk_tier] = "High", customer_risk_scores[sample] = "test")
)

Average Risk Score = AVERAGE(customer_risk_scores[risk_score])
```

## Business recommendations

Based on the results, the business should:

1. Prioritize High-risk customers for retention outreach.
2. Focus first on short-tenure customers because they show the strongest churn signal.
3. Create an onboarding improvement program for customers in their first 12 months.
4. Test payment method interventions for electronic-check customers.
5. Offer contract migration incentives to selected month-to-month customers.
6. Use A/B testing before claiming financial impact from retention campaigns.

## Limitations

This dataset is a single customer snapshot. It does not include event-level usage data, support ticket history, call-center interactions, payment failures, marketing touchpoints, or timestamps.

Because of that, this project should not claim to measure recent usage decline, support tickets in the last 30 days, or real-time customer behavior. A production version should add those data sources and validate the score prospectively.

## Production improvement ideas

In a real company, this project could be improved by adding:

- Monthly usage trends
- Support ticket frequency
- Failed payment events
- Product engagement metrics
- Customer complaint categories
- Retention outreach history
- Customer lifetime value
- A/B test results
- Model monitoring by month
- Fairness checks across customer groups

## Resume bullet

Built a customer churn early-warning system using SQL and Power BI, creating an interpretable 0-100 risk score from customer behavior and contract signals. Validated the score against a held-out test sample, where the High-risk tier achieved a 65.1% actual churn rate and 2.49x lift over baseline, enabling prioritized retention outreach.

## Interview explanation

I built a churn early-warning analysis to help a subscription business identify customers who were likely to cancel. I used SQL to clean the data, engineer churn risk signals, calculate data-driven signal weights, and create a 0-100 customer risk score. I then validated the score on a held-out test sample instead of only reporting the formula. The strongest result was that the High-risk tier had a 65.1% churn rate compared with a 26.1% baseline, giving a 2.49x lift. I also exported Power BI-ready files so the business could view risk tiers, top churn reasons, and an actionable customer list for retention outreach.

## Main takeaway

The project shows how SQL can be used not only for reporting, but also for decision support. The final output helps the business move from reactive churn reporting to proactive retention targeting.
