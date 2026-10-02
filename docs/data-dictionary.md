# Cleaned dataset

The project owner supplied `cleaned_data.csv`, a 661,333,669-byte CSV containing 12,256,906 records. This is a cleaned analysis input; the original source and cleaning procedure have not yet been supplied. The full CSV remains local and is excluded from Git.

## Fields

Descriptions below follow the observed column names and values. Behavior meanings below are confirmed by the original SQL mapping; the external dataset documentation is still needed.

| Column | Observed representation | Interpretation |
| --- | --- | --- |
| `user_id` | Integer-like identifier | User identifier; preserve as an identifier |
| `item_id` | Integer-like identifier | Item identifier |
| `behavior_type` | Codes 1, 2, 3, 4 | 1 = click, 2 = save, 3 = add to cart, 4 = buy |
| `item_category` | Integer-like identifier | Product category identifier |
| `time` | `YYYY-MM-DD HH` | Event timestamp at hour resolution; timezone unspecified |
| `date` | `YYYY-MM-DD` | Date component of `time` |
| `hour` | Integer-like hour | Hour component of `time` |

## Verified profile

A complete chunked scan of the CSV returned:

| Measure | Result |
| --- | --- |
| Records | 12,256,906 |
| Distinct users | 10,000 |
| Distinct items | 2,876,947 |
| Distinct categories | 8,916 |
| Earliest timestamp | 2014-11-18 00 |
| Latest timestamp | 2014-12-18 23 |
| Missing values detected by the CSV reader | 0 across all seven columns |
| Date/hour inconsistencies with timestamp components | 0 |

All four population counts and the date range match the latest presentation.

| Behavior code | Records |
| --- | --- |
| 1 | 11,550,581 |
| 2 | 242,556 |
| 3 | 343,564 |
| 4 | 120,205 |

The original SQL confirms code 4 represents purchases. Its 120,205 events match the reported all-category purchase-event total.

Machine-readable results are saved in [data-profile.json](data-profile.json).

## Scope of validation

The scan checked row count, distinct identifiers, behavior frequencies, missing values, timestamp range, and consistency of date/hour components. It did not establish duplicate-event policy, verify the original cleaning process, or establish the original preprocessing steps. Separate analytical reconciliation is documented in [validation findings](validation-findings.md).

## Local data setup

Once the source and access terms are documented, place the cleaned analysis input at `data/processed/cleaned_data.csv` in a local checkout. That directory is ignored by Git. Database import and query execution instructions are in [the SQL guide](sql-guide.md).

Database: MySQL 9.7.0, reported by the project owner from `SELECT VERSION();`. SQL client: MySQL Workbench.

Still needed: dataset source/download link and cleaning script or explanation.
