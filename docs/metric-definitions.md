# Metric definitions and reconciliation

Source: the latest `ecommerce-consulting.pptx` presentation and the SQL output values documented in its local build source. Stage counts, repeat counts, and cart classifications have also been independently reconciled against the cleaned CSV. The eligible-funnel purchase-event denominator is corrected below; see validation-findings.md.

## Counting units

- **Behavior event:** one recorded action.
- **Unique buyer:** one distinct user with a purchase across all categories.
- **User–category pair / category-buyer record:** one user in one category; the same person can appear in multiple categories.
- **Purchase event:** one recorded buy event, not necessarily one order.
- **Category-cart record:** one user–category record based on the first cart strictly after the first click; not an individual basket.

## Funnel rules

Eligible categories have at least 30 click users and 30 engaged users. Engagement is a save or add-to-cart strictly after the first click. A funnel purchase occurs strictly after engagement in the same category. Hour-level timestamps mean same-hour transitions are excluded.

| Metric | Calculation | Reported result |
| --- | --- | --- |
| Click-to-engage | 104,079 / 588,488 | 17.69% |
| Engage-to-buy | 21,259 / 104,079 | 20.43% |
| Full-funnel conversion | 21,259 / 588,488 | 3.61% |
| Funnel share of eligible purchase events | 37,162 / 90,949 | 40.86% |
| Repeat share of funnel category buyers | 2,700 / 21,259 | 12.70% |
| Purchase contribution of repeat category buyers | 10,825 / 37,162 | 29.13% |
| Cart reminder candidate share | 37,605 / 73,157 | 51.40% |

The 19.21% category-average engagement-to-purchase rate is a simple mean across categories, whereas 20.43% is pooled across user–category pairs.

## Purchase scope reconciliation

| Scope | Category-buyer records | Purchase events |
| --- | --- | --- |
| All categories | 81,659 | 120,205 |
| 680 eligible categories | 59,738 | 90,949 |
| Sequential funnel in eligible categories | 21,259 | 37,162 |

There are 8,886 unique buyers across all categories. This count must not be substituted for category-buyer records in category-level ratios.

## Repeat purchases

A repeat category buyer has purchases on at least two distinct dates in the same category after first engagement. Purchase contribution includes the first purchase. The segmentation benchmark is a 12.70% repeat rate; the presentation ranks categories with at least 30 funnel buyers by buyer count within each segment.

## Cart follow-up classification

P80 is the 80th percentile of observed cart-to-buy times within a category. The presentation reports the following mutually exclusive statuses:

| Status | Records |
| --- | --- |
| No purchase after sufficient follow-up | 37,605 |
| Insufficient follow-up | 15,972 |
| Purchased within P80 | 13,845 |
| Purchased after P80 | 3,176 |
| No category benchmark | 2,559 |
| Total | 73,157 |

The original SQL uses nearest rank CEIL(0.8*n), at least five purchased records per category, purchase time <= P80 for within-benchmark classification, and follow-up >= P80 for unpurchased candidates. Passing the P80 threshold does not prove abandonment.

## Experiment interpretation

Recommendations are proposed tests. Randomize by user, deduplicate overlapping audiences, and compare purchase events across all categories using consistent follow-up windows. The three opportunity groups overlap and should not be summed into a total opportunity estimate.
