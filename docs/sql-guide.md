# Running the SQL analysis

Use [ecommerce_analysis_final.sql](../sql/ecommerce_analysis_final.sql), the project owner’s final script. Environment: MySQL 9.7.0 and MySQL Workbench.

## Input

The script expects `ecommerce_project.user_behavior` to exist with `event_id`, `user_id`, `item_id`, `item_category`, `behavior_timestamp`, and numeric `behavior_type`. Codes 1, 2, 3, and 4 represent click, save, add to cart, and buy. `behavior_timestamp` should be a parsed date/time field.

The supplied cleaned CSV has `time`, `date`, and `hour` fields instead of `event_id` and `behavior_timestamp`. The original import and preprocessing steps are not included; prepare the source table before running this script. The full CSV remains local.

## Execution

Open the main script in Workbench and run numbered sections in order:

1. Normalize behavior codes and add a pair/type/time lookup index.
2. Return dataset overview and all-category purchase baseline.
3. Build shared funnel pairs, category summaries, eligible categories and engaged pairs; return pooled funnel metrics.
4. Return category averages and ten conversion priorities.
5. Build funnel purchasing pairs; return repeat summary and category segments.
6. Build cart follow-up classifications; return counts and shares.
7. Return ten cart-reminder categories and their combined coverage.
8. Reconcile purchase scopes and funnel coverage for supporting documentation.

The script rebuilds seven derived tables: `behavior`, `funnel_pairs`, `funnel_category_summary`, `funnel_eligible_categories`, `funnel_engaged_pairs`, `funnel_purchase_pairs`, and `cart_followup`. It does not drop `user_behavior`. Run all steps from the beginning after source changes; later steps depend on earlier tables. Do not run the archive as a second step.

The owner confirmed 37,162 selected-category funnel purchase events in MySQL. The organized and submitted scripts were compared on a synthetic fixture using SQLite compatibility substitutions; their shared baseline, funnel, repeat, and cart outputs matched. This is a logic check, not native MySQL validation. The organized script has not yet been executed end to end against the full MySQL dataset.

## Supporting calculations

The organized script returns 37,162 / 90,949 = 40.86% coverage and 10,825 / 37,162 = 29.13% repeat-event contribution directly, along with cart shares and top-ten coverage. These expectations refer to the original dataset; they are not hardcoded query results. See [metric definitions](metric-definitions.md).
