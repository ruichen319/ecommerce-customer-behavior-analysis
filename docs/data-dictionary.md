# Data dictionary

The project uses a cleaned e-commerce behavior dataset covering November 18–December 18, 2014. The full CSV remains local.

Dataset source: —

Access terms: —

The original cleaning procedure has not yet been documented.

## Cleaned CSV fields

| Column | Interpretation |
| --- | --- |
| `user_id` | User identifier |
| `item_id` | Item identifier |
| `behavior_type` | 1 = click, 2 = save, 3 = add to cart, 4 = buy |
| `item_category` | Product category identifier |
| `time` | Event timestamp in `YYYY-MM-DD HH` format |
| `date` | Date component |
| `hour` | Hour component |

## SQL input table

The final script reads `user_behavior`, which contains `event_id`, `user_id`, `item_id`, `item_category`, `behavior_timestamp`, and numeric `behavior_type`. It creates a `behavior` table with descriptive behavior labels. CSV import, event ID creation, and timestamp conversion are prerequisites, not included preprocessing code.

## Reported scope

The project reports 12,256,906 events, 10,000 users, 2,876,947 items, and 8,916 categories. The selected funnel includes 680 categories. README counts are abbreviated for readability; metric documentation retains full precision.

See the [SQL guide](sql-guide.md) and [metric definitions](metric-definitions.md) for execution and counting rules.
