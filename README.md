# E-commerce Customer Behavior Analysis

SQL-based analysis of customer conversion, repeat purchases, and cart follow-up opportunities across **12.3 million behavioral events**.

This portfolio project translates customer behavior analysis into prioritized experiment proposals. The repository contains cleaned MySQL scripts, the original SQL archive, analytical documentation, an independent Python validation script, and the project presentation. The full cleaned dataset remains local.

## Business question

Where should an e-commerce business focus experiments to increase purchase events?

The analysis examines three opportunities:

- Improve conversion in categories with large engaged audiences.
- Tailor post-purchase recommendations using category-level repeat behavior.
- Identify shoppers eligible for cart reminders using category-specific purchase timing.

## Dataset and scope

| Attribute | Scope |
| --- | --- |
| Observation period | November 18–December 18, 2014 |
| Behavioral events | 12,256,906 |
| Unique users | 10,000 |
| Unique items | 2,876,947 |
| Product categories | 8,916 |
| Categories eligible for funnel analysis | 680 |
| Timestamp resolution | Hour |

Behaviors include clicks, saves, cart additions, and purchases. Eligible categories have at least 30 click users and 30 engaged users. Dataset provenance and redistribution terms must be documented before raw data is published.

## Key findings

### 1. Conversion funnel

The sequential funnel contains **588,488 click**, **104,079 engaged**, and **21,259 purchasing user–category pairs** across eligible categories.

| Metric | Result |
| --- | --- |
| Click-to-engagement conversion | 17.69% |
| Engagement-to-purchase conversion | 20.43% |
| End-to-end conversion | 3.61% |

Ten categories were prioritized by selecting above-average engaged audiences and below-average category conversion, then ranking by engaged audience size. The selection benchmarks are **153.06 engaged users** and **19.21% category-average conversion**. The latter is an unweighted category mean, distinct from the pooled 20.43% conversion rate.

### 2. Repeat-purchase segmentation

**2,700 repeat buyer–category pairs**, representing **12.70%** of funnel buyer–category pairs, accounted for **10,825 purchase events**, or **29.13%** of funnel purchase events.

This supports testing same-category recommendations in higher-repeat categories and complementary-product recommendations where product relevance can be verified. The purchase contribution includes first purchases and does not represent incremental uplift.

### 3. Cart follow-up opportunities

Category-specific 80th-percentile cart-to-purchase times (P80) were used to distinguish records with sufficient follow-up from those observed for too little time.

Of **73,157 user–category cart records**, **37,605 (51.40%)** had no observed subsequent purchase after sufficient follow-up. The ten largest category audiences contained **5,730 candidate records**.

These are reminder-test candidates, not confirmed abandoned carts or distinct users. Purchase status should be checked again before any reminder is sent.

## Analytical approach

1. Define a user–category funnel: first click → later save or cart addition → later purchase within the same category.
2. Apply minimum audience thresholds and calculate pooled and category-level conversion rates.
3. Identify repeat buyers using purchases on at least two distinct dates in the same category after first engagement.
4. Compare elapsed cart follow-up time against category-specific P80 purchase-time benchmarks.
5. Translate the findings into proposed user-level randomized experiments.

The recommended primary experiment outcome is **purchase events per randomized user across all categories**. Audiences should be deduplicated, follow-up windows aligned, and reminder and incentive treatments evaluated separately. No experiments have been reported as implemented in this repository.

## Deliverables

- [Project presentation](https://docs.google.com/presentation/d/1gZy5WcbtXoEBcxhPdkYcK3yrrE5zaTVYPZoAbkv-bmo/edit): 16 slides covering findings, business recommendations, and limitations. Access is controlled by the presentation owner.
- [SQL execution guide](docs/sql-guide.md): six numbered MySQL scripts, dependencies, and documented cleanup decisions.
- [Validation findings](docs/validation-findings.md): the scope discrepancy found during independent CSV reconciliation.
- [Metric definitions and reconciliation](docs/metric-definitions.md): denominators, scope, and interpretation of the reported results.
- [Data dictionary and validation](docs/data-dictionary.md): cleaned CSV structure, verified totals, and outstanding source documentation.

## Tools and skills demonstrated

Database: **MySQL 9.7.0**, as reported by the project owner from `SELECT VERSION();`. SQL client: **MySQL Workbench**.

**SQL analysis · Conversion funnels · Customer segmentation · Percentile-based timing analysis · Data visualization · Experiment planning · Business communication**

The event count, distinct user/item/category counts, and observation period have been independently checked against the supplied cleaned CSV and match the presentation. Independent Python reconciliation confirms funnel stage counts, repeat counts, and cart classifications. It identifies 37,162 purchase events in the eligible funnel, correcting the presentation denominator of 43,765. The project owner also verified the corrected 37,162 purchase-event count in MySQL. The full numbered SQL workflow has not yet been executed end to end in MySQL. Local presentation-build files and earlier visual design drafts are excluded from the published project.

## Limitations

- Purchase events are not confirmed orders, revenue, or profit.
- Category-level records may count the same user in multiple categories.
- Hour-level timestamps cannot order same-hour events; strict sequencing excludes those transitions.
- The short observation window creates unequal follow-up and limits assessment of longer purchase cycles.
- The defined funnel covers **40.86% of purchase events in eligible categories**; other observed paths remain outside it.
- P80 benchmarks reflect observed purchasers and may use as few as five observations.
- Category IDs alone do not establish product relevance for cross-selling.
- Findings are descriptive. Recommendations do not establish causal or financial impact.

## Reproducibility status and next steps

Run the numbered files in `sql/` following the [execution guide](docs/sql-guide.md). The original script is preserved in `archive/` and is not part of the execution sequence. A separate Python validator checks the analysis against the locally supplied cleaned CSV.

Remaining work:

- Document the dataset source, cleaning rules, and permitted access method.
- Execute the cleaned scripts in MySQL and confirm the import and query outputs.
- Confirm presentation sharing settings for portfolio readers.

The original data cleaning process has not been reconstructed from the cleaned CSV.
