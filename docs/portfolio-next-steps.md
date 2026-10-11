# Portfolio preparation

The README, organized SQL, query guide, and presentation PDF are included in this repository. The main analysis reorganizes the owner's SQL; no additional analysis tools or experimental results are represented as completed work.

## 1. Complete dataset provenance

Provide the original dataset name, publisher, download URL, and access or redistribution terms. Document the actual steps used to create `user_behavior`, including timestamp parsing, event IDs, missing values, and duplicate handling. Do not infer or recreate historical cleaning steps from the final CSV.

## 2. Export query results from MySQL Workbench

Save the actual result grids as CSV files in a future `results/` folder. The following are proposed filenames, not files already generated:

| Proposed output | Contents |
| --- | --- |
| `dataset_overview.csv` | Population counts and observation dates |
| `purchase_baseline.csv` | All-category buyers, purchasing pairs and events |
| `purchase_coverage.csv` | Selected-category and selected-funnel counts with clearly labeled scope |
| `conversion_funnel.csv` | Click, engage and buy counts and pooled conversion rates |
| `conversion_priorities.csv` | Ten selected categories, audience sizes and conversion rates |
| `repeat_summary.csv` | Purchasing pairs, repeat pairs, purchase events and contribution calculations |
| `repeat_category_segments.csv` | Higher/lower repeat groups and their top ten categories |
| `cart_status.csv` | Five mutually exclusive statuses and their counts |
| `cart_priority_categories.csv` | Ten largest reminder audiences |

Use the query guide to locate the SQL. Preserve actual exported counts. If combining outputs or adding ratios for presentation, label the derived calculations and retain their source counts. These aggregate results are sufficient for evidence without uploading individual behavior records.

## 3. Add presentation evidence

The current 14-slide Google Slides presentation has been exported and visually checked: [presentation PDF](../presentation/ecommerce-customer-behavior-analysis.pdf). It is included in `presentation/` and linked from the README alongside the online deck.

Optional next addition: three readable slide images in `assets/` covering conversion, repeat-purchase audiences, and cart follow-up. Confirm that external readers can access the online presentation. Re-export the PDF whenever the online deck changes.

## 4. Publication status and final checks

The repository now includes the organized main SQL, original submitted SQL in `archive/`, current documentation, and the 14-slide presentation PDF. Superseded SQL scripts, assistant-generated validation artifacts, and Python dependencies have been removed from the current branch; earlier versions remain in Git history.

The full cleaned CSV, local backups, temporary checks, and session history remain excluded. Executed end to end in MySQL 9.7.0 by the project owner, with all outputs verified against the documented expected results. Remaining work: export the actual result grids, document dataset provenance, and confirm presentation sharing for external readers.

Suggested repository description:

> MySQL analysis of 12.3m e-commerce behavior events to identify conversion gaps, repeat-purchase patterns, and cart-reminder test audiences.

Suggested topics: `sql`, `mysql`, `data-analysis`, `ecommerce`, `customer-behavior`, `conversion-funnel`, `portfolio`.

## 5. Prepare the interview narrative

Use [career materials](career-materials.md) for resume bullets and a short project explanation. Be ready to explain the unit of analysis, why 19.21% differs from 20.43%, the correction from all-category to selected-category purchase events, and why reminder candidates do not establish recoverable sales.
