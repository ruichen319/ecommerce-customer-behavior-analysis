# Analytical validation findings

Independent Python computation on the full supplied cleaned CSV confirms the latest sequential funnel and cart definitions, with one purchase-scope discrepancy in the original presentation.

## Purchase-event denominator correction

| Metric | Original presentation | Recomputed |
| --- | --- | --- |
| Funnel purchase events within 680 eligible categories | 43,765 | 37,162 |
| Eligible-funnel share of 90,949 eligible-category purchase events | 48.12% | 40.86% |
| Repeat-buyer contribution to eligible-funnel purchase events | 24.73% | 29.13% |

The 43,765 count reproduces exactly when the sequential funnel is computed across **all categories**. The original script contains a query that defines `eligible_categories` but never applies it to the final purchase-event join. This explains the scope mismatch: a count from all categories was paired with buyer counts and repeat events restricted to 680 eligible categories.

The corrected denominator is 37,162. The repeat numerator remains 10,825, so its share becomes 29.13%. Purchase events outside the defined funnel account for 59.14% of eligible-category purchases.

The README, metric definitions, and current Google Slides presentation use corrected figures. Slides 5 and 9 have been checked after the correction. The project owner independently confirmed 37,162 in MySQL. A resume bullet using the previous 24.73% contribution should use 29.13% for this scope.

## Confirmed results

- 680 eligible categories.
- 588,488 click pairs, 104,079 engaged pairs, and 21,259 purchasing pairs.
- 2,700 repeat purchasing pairs and 10,825 purchase events from those pairs.
- All five cart status counts, including 37,605 eligible unpurchased records.
- All ten cart-priority categories and their individual counts.
- All-category purchases: 120,205 events and 81,659 buyer–category pairs.
- Eligible-category purchases: 90,949 events and 59,738 buyer–category pairs.

## Verification boundary

Results were independently computed with `scripts/validate_analysis.py` and saved to `analysis-validation.json`. The validator now checks the confirmed 37,162 eligible-funnel baseline. The historical 43,765 all-category count and the reason for the correction remain documented above.

The cleaned MySQL scripts have been reviewed but have not been executed against the owner's MySQL server. CSV import behavior, SQL engine execution, performance, and the original pre-cleaning transformations remain outside this verification. The original SQL archive is byte-for-byte identical to the supplied file.
