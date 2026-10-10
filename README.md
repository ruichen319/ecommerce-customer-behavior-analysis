# E-commerce Customer Behavior Analysis | MySQL

Analyzed **12.3m behavioral events** to identify conversion gaps, repeat-purchase patterns, and audiences for cart-reminder experiments.

[SQL analysis](sql/ecommerce_analysis_final.sql) · [Presentation PDF](presentation/ecommerce-customer-behavior-analysis.pdf) · [Google Slides](https://docs.google.com/presentation/d/1gZy5WcbtXoEBcxhPdkYcK3yrrE5zaTVYPZoAbkv-bmo/edit) · [Query guide](docs/query-guide.md)

---

## Business Context

**Where should an e-commerce business focus experiments to generate additional purchase events?**

The analysis follows browsing, engagement, and purchase to prioritize conversion improvements, post-purchase offers, and cart reminders. The objective is additional purchase events across all categories; the available fields do not measure revenue or profit.

## Technical Approach

MySQL queries build eligible-category and engaged shopper-category tables from user behavior.

1. Map numeric behavior codes to click, save, add to cart, and buy; calculate dataset and purchase baselines.
2. Build a sequential funnel using the first click, first subsequent engagement, and first subsequent purchase within each shopper-category combination.
3. Select categories with at least 30 click users and 30 engaged users, then compare audience size and conversion.
4. Segment categories by repeat purchasing on at least two distinct dates after engagement.
5. Use category-specific P80 cart-to-purchase times to separate reminder candidates from records with insufficient follow-up.

SQL techniques include **CTEs, self-joins, LEFT JOINs, conditional aggregation, date functions, and window functions**. `ROW_NUMBER()` supports category rankings and nearest-rank P80 calculations.

## Dataset & Scope

| Attribute | Scope |
| --- | --- |
| Dataset source | — |
| Observation period | November 18–December 18, 2014 |
| Behavioral events | 12.3m |
| Unique users | 10k |
| Unique items | 2.9m |
| Product categories | 8.9k |
| Categories selected for funnel analysis | 680 |
| Timestamp resolution | Hour |

Counts use **k = thousand** and **m = million** and are rounded for readability. Percentages use full-precision counts.

The analytical unit is a **shopper-category combination**: one shopper can appear in several categories, and each combination can generate multiple purchase events. The cleaned CSV remains local. See the [data dictionary](docs/data-dictionary.md) for fields and SQL input requirements.

## Tools

| Tool | Purpose |
| --- | --- |
| MySQL 9.7.0 | Funnel analysis, category segmentation, and purchase-timing calculations |
| MySQL Workbench | SQL development, execution, and result inspection |
| Google Slides | Presentation of findings and proposed business actions |

## Key Findings

### 1. Conversion: engagement does not consistently lead to purchase

The selected-category funnel contains **588k clicked → 104k engaged → 21k purchasing combinations**, with **20.43% engage-to-buy** and **3.61% end-to-end conversion**. Ten categories combine above-average engaged audiences with below-average category conversion. Selection uses **153.06 engaged shoppers** and **19.21% category-average conversion**; the latter is distinct from the pooled 20.43% rate.

### 2. Repeat purchase: 12.70% of purchasing combinations contribute 29.13% of events

**2.7k combinations** purchased on at least two different dates in the same category after engagement. They generated **10.8k of the 37k selected-category funnel purchase events**, including first purchases. The overall **12.70%** repeat rate is used to group categories for post-purchase tests; it does not assign each shopper to one exclusive segment.

### 3. Cart follow-up: 37.6k records qualify for reminder testing

Of **73k shopper-category cart records**, **37.6k (51.40%)** had no subsequent purchase observed despite follow-up reaching category P80. The ten largest category audiences contain **5.7k candidates (15.24%)**. These are potential experiment participants, not confirmed abandoned carts or recoverable purchases.

## Business Recommendations / Experiments

- **Investigate conversion barriers:** survey engaged non-buyers in priority categories about purchase intent, availability, pricing, shipping, and product information, then test improvements supported by the findings.
- **Tailor post-purchase offers:** test subscriptions where replenishment needs are confirmed, or repeat-purchase discounts, in higher-repeat categories; test relevant complementary-product recommendations in lower-repeat categories.
- **Test cart reminders:** at category P80, recheck purchase status and randomly assign eligible users to reminder and no-reminder groups.

Measure **purchase events per randomized user across all categories** over equal follow-up periods. Deduplicate shoppers and use separate pilots or mutually exclusive groups. These are proposed experiments; no conversion uplift, revenue impact, or treatment effect has been established.

## Project Structure

```text
ecommerce-customer-behavior-analysis/
├── README.md
├── sql/
│   └── ecommerce_analysis_final.sql   # Organized main analysis
├── presentation/
│   └── ecommerce-customer-behavior-analysis.pdf  # 14-slide business presentation
├── archive/
│   ├── README.md
│   └── ecommerce_analysis_final.sql   # Original submitted SQL
└── docs/
    ├── query-guide.md                # Business questions mapped to SQL
    ├── sql-guide.md                  # Input requirements and execution order
    ├── data-dictionary.md            # Field definitions and source status
    ├── metric-definitions.md         # Exact denominators and calculation rules
    ├── portfolio-next-steps.md       # Result exports and publication checklist
    └── career-materials.md           # Resume bullets and interview summary
```

## How to Run Locally

1. Clone this repository:
   ```bash
   git clone https://github.com/ruichen319/ecommerce-customer-behavior-analysis.git
   cd ecommerce-customer-behavior-analysis
   ```
2. Prepare `ecommerce_project.user_behavior` with the fields described in the [SQL guide](docs/sql-guide.md). The source dataset and original import/preprocessing steps are not bundled, so the repository is not yet a self-contained reproduction package.
3. Open `sql/ecommerce_analysis_final.sql` in MySQL Workbench and run its sections in order. The script rebuilds derived tables; retain the source table.
4. Review results using the [query guide](docs/query-guide.md) and [metric definitions](docs/metric-definitions.md).

The original selected-category funnel count was confirmed in MySQL. The organized script passed synthetic equivalence checks; full-dataset MySQL execution remains to be confirmed.

## Limitations

- Purchase events are not confirmed orders, revenue, or profit; shopper-category counts are not distinct-user totals.
- The one-month window creates unequal follow-up, while hour-level timestamps exclude same-hour transitions from the strict sequential funnel.
- The funnel covers **40.86%** of purchase events in selected categories. P80 uses observed purchasers and may rely on as few as five observations per category.
- Findings are descriptive. Category IDs and repeat rates alone do not establish product compatibility, subscription suitability, or causal impact.
