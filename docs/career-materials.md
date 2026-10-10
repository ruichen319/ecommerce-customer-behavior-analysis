# Career materials

## Resume entry

**E-commerce Customer Behavior Analysis | MySQL, MySQL Workbench, Google Slides**

- Analyzed 12.3m behavioral events across 10k users using MySQL to identify conversion gaps, repeat-purchase patterns, and cart follow-up opportunities.
- Built a sequential conversion funnel across 680 categories, measured 3.61% end-to-end conversion, and prioritized 10 categories with large engaged audiences and below-average conversion.
- Segmented categories by cross-date repeat purchasing, finding that 12.70% of purchasing shopper-category combinations generated 29.13% of selected-funnel purchase events, informing targeted post-purchase test proposals.
- Applied category-specific P80 cart-to-purchase thresholds to identify 37.6k unpurchased records eligible for reminder testing and proposed user-level experiments to measure additional purchase events.

## Short interview explanation

I used MySQL to analyze 12.3m e-commerce behavior events and identify where the business could test ways to increase purchases. I built a sequential click-to-engage-to-buy funnel, analyzed repeat purchases within categories, and used purchase timing to identify cart-reminder audiences. The main challenge was keeping the unit of analysis and denominators consistent: one shopper can appear in several categories, and purchase events are not orders. I found 3.61% end-to-end conversion and 37.6k cart records eligible for reminder testing. I translated the findings into experiment proposals rather than claiming that the recommendations had already increased sales.

## Questions to prepare

| Question | Answer to develop |
| --- | --- |
| Why use shopper-category combinations? | It keeps the journey within a category; users can appear in multiple categories, so totals are not unique-user counts. |
| Why require strict event ordering? | The funnel asks whether engagement follows click and purchase follows engagement. Hour-level data cannot resolve same-hour ordering. |
| Why is the category conversion mean different from pooled conversion? | The simple mean weights every category equally; the pooled rate weights categories by engaged audience size. |
| Why define repeat purchase across dates? | Multiple buy events do not necessarily indicate distinct orders. At least two dates is a conservative behavioral definition. |
| What was the denominator correction? | 43,765 included the funnel across all categories. Applying the 680-category restriction gives 37,162, which changes repeat event contribution to 29.13%. |
| Why P80, and what are its limits? | It is a proposed category-specific waiting threshold from observed purchasers. Small samples, censoring and natural late purchases limit interpretation. |
| How would you test a recommendation? | Randomize eligible users, deduplicate overlapping audiences, use equal follow-up, and compare purchase events per randomized user across categories. |

## Evidence boundary

The project demonstrates SQL analysis and business recommendations. It does not establish deployed campaigns, completed surveys, A/B test results, revenue uplift, query-performance improvements, or a separately authored data-cleaning pipeline. Add such claims only after the corresponding work and evidence exist.
