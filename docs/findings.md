# Findings and business narrative

## Executive result

The held-out test sample contains 1,409 customers and an overall churn rate of
26.1%. The score concentrates churn strongly:

| Risk tier | Customers | Actual churners | Churn rate |
|---|---:|---:|---:|
| High | 284 | 185 | 65.1% |
| Medium | 442 | 134 | 30.3% |
| Low | 683 | 49 | 7.2% |

The High tier has **2.49x** the test-sample churn rate and captures **50.3%** of
all test-sample churners while containing 20.2% of test customers. This makes it
a practical first outreach queue. “Precision” here means the observed churn rate
among flagged customers; it is 65.1% for the High tier.

## Strongest observed signals

Weights were learned only from the 80% training sample. The strongest individual
signal was tenure of 12 months or less: its training churn rate was 47.8%, or
1.79x the training baseline. Electronic-check payment followed at 46.1% (1.73x),
then month-to-month contracts at 42.9% (1.61x).

Within the test sample, 207 High-risk customers had short tenure as their dominant
reason and 70.5% churned. This is the clearest priority segment: a targeted early-
life retention program, onboarding check-in, or contract migration offer is more
defensible than a blanket discount to all customers.

## Recommended actions

1. Contact High-risk, short-tenure customers first with onboarding/service-quality outreach.
2. Test autopay or card-payment incentives for electronic-check customers; measure incremental retention.
3. Offer contract migration selectively to High/Medium month-to-month customers.
4. Route “no tech support” and “no online security” customers to education or bundle trials.
5. Run an A/B test before claiming financial impact; compare retained customers and margin against a control group.

## Guardrails

The analysis establishes association, not causation. Sensitive or proxy attributes
should not drive retention eligibility. Monitor tier performance over time, evaluate
outcomes across customer groups, and retrain weights when behavior or pricing changes.

