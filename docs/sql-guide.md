# Running the analysis

Environment reported by the project owner: MySQL 9.7.0 with MySQL Workbench.

## Execution order

1. Run `sql/00_setup.sql` to create the dedicated `ecommerce_portfolio` schema, an empty CSV input table, and the normalized behavior view. This does not modify the original `ecommerce_project` database.
2. Import `cleaned_data.csv` into `ecommerce_portfolio.cleaned_data` using the Workbench Table Data Import Wizard. Match all seven column names. Import once into an empty table; importing again duplicates events. The CSV has 12,256,906 data rows. The supplied SQL did not include the original CSV import or cleaning process.
3. Run `sql/01_data_checks.sql` and compare with `docs/data-profile.json`. Stop and investigate if counts, timestamps, or behavior codes differ.
4. Run `sql/02_funnel.sql` to create shared funnel views and calculate conversion results and priority categories.
5. Run `sql/03_repeat_purchase.sql` to create the purchase-pair view and calculate repeat-purchase segments.
6. Run `sql/04_cart_followup.sql` for P80 classifications and the ten largest reminder audiences.
7. Run `sql/05_purchase_reconciliation.sql` to compare purchase scope across all categories, eligible categories, and the eligible funnel.

Open and execute each file in Workbench in this order. The scripts use persistent views so analysis stages can be run in separate query tabs. Re-running a view definition replaces that analysis view. The setup does not erase or reload input rows.

These views prioritize readable definitions; repeated scans and timestamp parsing may be slow on the 12.3-million-row input. Runtime and query plans have not been benchmarked on MySQL. Materializing typed, indexed staging tables is a possible later optimization.

## Changes from the original script

The unchanged original is retained in `archive/ecommerce_analysis_original.sql` for reference only. Do not run it as part of the numbered workflow: it contains mixed historical definitions, a `DROP TABLE`, and queries with expired CTE references.

- Consolidated repeated funnel calculations into shared views.
- Retained sequential first qualifying events: engagement strictly after first click, then purchase strictly after engagement.
- Retained the latest eligible-category cart analysis with strict `>` sequencing, rather than the older unrestricted `>=` version.
- Fixed three funnel percentages that shared the same `engage_to_buy_rate` alias.
- Applied the eligible-category restriction to funnel purchase-event reconciliation. One historical query defined eligibility but did not use it.
- Replaced references to `stage_2` outside its CTE statement with explicit shared-view dependencies.
- Retained distinct purchase dates for repeat behavior, rather than the older multiple-event definition.
- Made the published conversion audience threshold (`engage_users > 153.06`) explicit, alongside conversion below 19.21%.
- Retained the published 12.70% repeat-segmentation threshold and deterministic category tie-breaking.
- Replaced the catch-all `ELSE 'buy'` with an explicit code 4 mapping; unknown codes are exposed by the checks.
- Added CSV setup separately because the original depended on a pre-existing `user_behavior` table with an `event_id` and parsed timestamp absent from the supplied CSV.

## Cart percentile details

P80 uses the nearest observed rank `CEIL(0.8 * purchase_count)` with at least five observed purchasers per category. Purchases exactly at P80 are classified within the benchmark. Unpurchased records with follow-up exactly at P80 have sufficient follow-up. Missing benchmarks take precedence over other classifications.

## Verification

`scripts/validate_analysis.py` independently computes the central analytical definitions from the cleaned CSV using Python, pandas, and NumPy:

```bash
python -m pip install -r requirements.txt
python scripts/validate_analysis.py /path/to/cleaned_data.csv
```

The script writes `docs/analysis-validation.json` and exits with a nonzero status if the central funnel, repeat, or cart counts differ from the presentation. This is independent analytical reconciliation; it does not execute or certify the MySQL scripts. The numbered scripts still need a run in the owner's MySQL environment to confirm engine execution and import behavior.

The owner has confirmed the corrected eligible-funnel count of 37,162 in MySQL using the updated source query. This does not imply the refactored numbered workflow has been executed end to end.
