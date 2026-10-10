# SQL query guide

The main script reorganizes the owner’s submitted SQL into eight dependent sections. The unchanged submission is retained in `archive/`; run only the main script. Slide numbers refer to the current 14-slide presentation.

| Section | Presentation coverage | Output |
| --- | --- | --- |
| [Step 2](../sql/ecommerce_analysis_final.sql#L28) | Slides 2, 4 | Dataset overview and all-category purchase baseline |
| [Step 3](../sql/ecommerce_analysis_final.sql#L61) | Slides 4–5 | 680 categories; 588,488 click, 104,079 engaged, 21,259 purchasing pairs; funnel rates |
| [Step 4](../sql/ecommerce_analysis_final.sql#L126) | Slides 6–7 | 19.21% and 153.06 category means; ten conversion-priority categories |
| [Step 5](../sql/ecommerce_analysis_final.sql#L145) | Slides 8–9 | 2,700 repeat pairs / 21,259 buyers = 12.70%; top ten categories per repeat segment |
| [Step 6](../sql/ecommerce_analysis_final.sql#L193) | Slides 10, 12 | Five cart statuses, counts and shares; category P80 classification |
| [Step 7](../sql/ecommerce_analysis_final.sql#L322) | Slide 11 | Ten cart-reminder categories; 5,730 candidates and 15.24% coverage |
| [Step 8](../sql/ecommerce_analysis_final.sql#L343) | README / supporting checks | Purchase scopes: 120,205 all-category, 90,949 selected-category, 37,162 funnel events; 40.86% coverage |

[Step 1](../sql/ecommerce_analysis_final.sql#L9) prepares behavior labels and a lookup index. Slides 1, 3 and 14 introduce or summarize the project. Slides 7, 9 and 12 contain proposed actions, while Slide 13 explains limitations; these do not require separate experiment-result queries.

The repeat summary also returns 10,825 events from repeat-purchasing pairs and their 29.13% contribution for the README. These figures and purchase coverage are supporting outputs, not separate charts in the current deck.

## Cleanup decisions

- Reuse one sequential pair table and one category summary instead of repeatedly rebuilding the same click/engage/buy CTEs.
- Remove the purchase-stage calculation from eligibility-only logic; selection depends only on clicks and engagement.
- Replace the duplicate temporary eligible-category table with the shared eligible-category table.
- Merge the standalone repeat count and event-total queries into one summary. Omit the unfiltered repeat-category listing; retain the top ten categories in each presentation segment.
- Compute cart classification once and reuse it for status totals and priority categories.
- Retain purchase reconciliation because the README still cites its results.
- Return cart percentages and top-ten coverage directly in SQL instead of requiring manual division.

## Preserved definitions

Strict timestamp ordering, same-category joins, minimum category sizes, the 12.70% repeat threshold, and nearest-rank P80 with at least five observed purchasers remain unchanged. Conversion selection retains the presentation thresholds of 19.21% and 153.06. Category IDs break ranking ties deterministically. Counts remain shopper-category pairs unless explicitly labeled events or unique users.
