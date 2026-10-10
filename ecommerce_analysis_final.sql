/* E-commerce customer behavior analysis | MySQL 9.7.0
   Run numbered sections in order in MySQL Workbench.
   Input: ecommerce_project.user_behavior (see docs/sql-guide.md).
   Derived tables are rebuilt; the source table is retained.
   Unit: shopper-category pair. All transitions use strictly later timestamps.
   Original submitted SQL is preserved in archive/ecommerce_analysis_final.sql.
*/

-- 01. Normalize behavior codes
CREATE DATABASE IF NOT EXISTS ecommerce_project;
USE ecommerce_project;
DROP TABLE IF EXISTS behavior;
CREATE TABLE behavior AS
SELECT event_id, user_id, item_id, item_category, behavior_timestamp,
CASE
    WHEN behavior_type = 1 THEN 'click'
    WHEN behavior_type = 2 THEN 'save'
    WHEN behavior_type = 3 THEN 'add to cart'
    WHEN behavior_type = 4 THEN 'buy'
    ELSE NULL
END AS behavior_type
FROM user_behavior;

-- Speeds up the repeated pair/type/time lookups; retains duplicate input events.
CREATE INDEX idx_behavior_pair_type_time
    ON behavior (user_id, item_category, behavior_type, behavior_timestamp);

-- 02. Dataset overview and purchase baseline | Slides 2 and 4
SELECT
    COUNT(*) AS behavior_events,
    COUNT(DISTINCT user_id) AS unique_users,
    COUNT(DISTINCT item_id) AS unique_items,
    COUNT(DISTINCT item_category) AS unique_categories,
    MIN(behavior_timestamp) AS first_event,
    MAX(behavior_timestamp) AS last_event
FROM behavior;

WITH purchase_pairs AS (
    SELECT
        user_id,
        item_category,
        COUNT(*) AS buy_events
    FROM behavior
    WHERE behavior_type = 'buy'
    GROUP BY user_id, item_category
)
SELECT
    COUNT(DISTINCT user_id) AS unique_buyers,
    COUNT(*) AS category_buyer_records,
    SUM(buy_events) AS purchase_events,
    ROUND(
        SUM(buy_events) / NULLIF(COUNT(DISTINCT user_id), 0),
        2
    ) AS events_per_unique_buyer,
    ROUND(
        SUM(buy_events) / NULLIF(COUNT(*), 0),
        2
    ) AS events_per_category_buyer_record
FROM purchase_pairs;

-- 03. Shared sequential funnel and category eligibility | Slides 4 and 5
-- Compute click/engage/buy once, including pairs with no subsequent event.
DROP TABLE IF EXISTS funnel_pairs;
CREATE TABLE funnel_pairs AS
WITH first_clicks AS (
    SELECT user_id, item_category, MIN(behavior_timestamp) AS first_click
    FROM behavior
    WHERE behavior_type = 'click'
    GROUP BY user_id, item_category
), engagements AS (
    SELECT c.user_id, c.item_category, c.first_click,
           MIN(b.behavior_timestamp) AS first_engage
    FROM first_clicks c
    LEFT JOIN behavior b
        ON b.user_id = c.user_id
       AND b.item_category = c.item_category
       AND b.behavior_type IN ('save', 'add to cart')
       AND b.behavior_timestamp > c.first_click
    GROUP BY c.user_id, c.item_category, c.first_click
)
SELECT e.user_id, e.item_category, e.first_click, e.first_engage,
       MIN(b.behavior_timestamp) AS first_buy
FROM engagements e
LEFT JOIN behavior b
    ON b.user_id = e.user_id
   AND b.item_category = e.item_category
   AND b.behavior_type = 'buy'
   AND b.behavior_timestamp > e.first_engage
GROUP BY e.user_id, e.item_category, e.first_click, e.first_engage;

DROP TABLE IF EXISTS funnel_category_summary;
CREATE TABLE funnel_category_summary AS
SELECT item_category,
       COUNT(*) AS click_users,
       COUNT(first_engage) AS engage_users,
       COUNT(first_buy) AS buy_users
FROM funnel_pairs
GROUP BY item_category;

DROP TABLE IF EXISTS funnel_eligible_categories;
CREATE TABLE funnel_eligible_categories AS
SELECT item_category
FROM funnel_category_summary
WHERE click_users >= 30 AND engage_users >= 30;

DROP TABLE IF EXISTS funnel_engaged_pairs;
CREATE TABLE funnel_engaged_pairs AS
SELECT p.user_id, p.item_category, p.first_engage
FROM funnel_pairs p
JOIN funnel_eligible_categories e ON p.item_category = e.item_category
WHERE p.first_engage IS NOT NULL;

SELECT COUNT(*) AS eligible_categories,
       SUM(c.click_users) AS click_pairs,
       SUM(c.engage_users) AS engage_pairs,
       SUM(c.buy_users) AS buy_pairs,
       ROUND(100.0 * SUM(c.engage_users) / NULLIF(SUM(c.click_users), 0), 2)
           AS click_to_engage_rate,
       ROUND(100.0 * SUM(c.buy_users) / NULLIF(SUM(c.engage_users), 0), 2)
           AS engage_to_buy_rate,
       ROUND(100.0 * SUM(c.buy_users) / NULLIF(SUM(c.click_users), 0), 2)
           AS click_to_buy_rate
FROM funnel_category_summary c
JOIN funnel_eligible_categories e ON c.item_category = e.item_category;

-- 04. Conversion benchmarks and priority categories | Slides 6 and 7
-- Category-average conversion is distinct from pooled funnel conversion.
SELECT ROUND(AVG(100.0 * c.buy_users / NULLIF(c.engage_users, 0)), 2)
           AS avg_category_conversion,
       ROUND(AVG(1.0 * c.engage_users), 2) AS avg_engage_users
FROM funnel_category_summary c
JOIN funnel_eligible_categories e ON c.item_category = e.item_category;

-- Preserve the presentation's reported thresholds: 19.21% and 153.06.
SELECT c.item_category, c.engage_users,
       ROUND(100.0 * c.buy_users / NULLIF(c.engage_users, 0), 2)
           AS engage_to_buy_rate
FROM funnel_category_summary c
JOIN funnel_eligible_categories e ON c.item_category = e.item_category
WHERE 100.0 * c.buy_users / NULLIF(c.engage_users, 0) < 19.21
  AND c.engage_users > 153.06
ORDER BY c.engage_users DESC, c.item_category
LIMIT 10;

-- 05. Repeat purchase summary and category segments | Slides 8 and 9
-- Count all purchases after engagement, not just the first purchase.
DROP TABLE IF EXISTS funnel_purchase_pairs;
CREATE TABLE funnel_purchase_pairs AS
SELECT b.user_id, b.item_category,
       COUNT(*) AS buy_events,
       COUNT(DISTINCT DATE(b.behavior_timestamp)) AS purchase_days
FROM behavior b
JOIN funnel_engaged_pairs s
    ON b.user_id = s.user_id
   AND b.item_category = s.item_category
   AND b.behavior_timestamp > s.first_engage
WHERE b.behavior_type = 'buy'
GROUP BY b.user_id, b.item_category;

-- Event contribution includes first purchases by repeat-purchasing pairs.
SELECT COUNT(*) AS purchasing_pairs,
       SUM(CASE WHEN purchase_days >= 2 THEN 1 ELSE 0 END) AS repeat_purchasing_pairs,
       ROUND(100.0 * SUM(CASE WHEN purchase_days >= 2 THEN 1 ELSE 0 END)
           / NULLIF(COUNT(*), 0), 2) AS repeat_purchase_rate,
       SUM(buy_events) AS funnel_purchase_events,
       SUM(CASE WHEN purchase_days >= 2 THEN buy_events ELSE 0 END)
           AS repeat_pair_purchase_events,
       ROUND(100.0 * SUM(CASE WHEN purchase_days >= 2 THEN buy_events ELSE 0 END)
           / NULLIF(SUM(buy_events), 0), 2) AS repeat_event_contribution_pct
FROM funnel_purchase_pairs;

WITH purchase_group AS (
    SELECT item_category, COUNT(*) AS purchasing_pairs,
           ROUND(100.0 * SUM(CASE WHEN purchase_days >= 2 THEN 1 ELSE 0 END)
               / COUNT(*), 2) AS repeat_purchase_rate,
           CASE WHEN 100.0 * SUM(CASE WHEN purchase_days >= 2 THEN 1 ELSE 0 END)
                     / COUNT(*) >= 12.70
                THEN 'Higher repeat' ELSE 'Lower repeat' END AS repeat_segment
    FROM funnel_purchase_pairs
    GROUP BY item_category
    HAVING COUNT(*) >= 30
), ranked AS (
    SELECT *, ROW_NUMBER() OVER (
        PARTITION BY repeat_segment ORDER BY purchasing_pairs DESC, item_category
    ) AS rn
    FROM purchase_group
)
SELECT repeat_segment, item_category, purchasing_pairs, repeat_purchase_rate
FROM ranked
WHERE rn <= 10
ORDER BY repeat_segment, rn;

-- 06. Cart follow-up: compute shared classification once | Slides 10 and 12
-- Nearest-rank P80 uses >=5 observed purchasing pairs per category.
-- No purchase + follow-up >= P80 identifies candidates, not proven abandonment.
DROP TABLE IF EXISTS cart_followup;
CREATE TABLE cart_followup AS
WITH first_clicks AS (
    SELECT
        b.user_id,
        b.item_category,
        MIN(b.behavior_timestamp) AS first_click
    FROM behavior b
    JOIN funnel_eligible_categories e
        ON b.item_category = e.item_category
    WHERE b.behavior_type = 'click'
    GROUP BY b.user_id, b.item_category
),
stage_1 AS (
    SELECT
        c.user_id,
        c.item_category,
        MIN(b.behavior_timestamp) AS addcart_time
    FROM first_clicks c
    JOIN behavior b
        ON b.user_id = c.user_id
       AND b.item_category = c.item_category
       AND b.behavior_timestamp > c.first_click
    WHERE b.behavior_type = 'add to cart'
    GROUP BY c.user_id, c.item_category
),
stage_2 AS (
    SELECT
        s.user_id,
        s.item_category,
        MIN(b.behavior_timestamp) AS first_buy
    FROM stage_1 s
    LEFT JOIN behavior b
        ON b.user_id = s.user_id
       AND b.item_category = s.item_category
       AND b.behavior_type = 'buy'
       AND b.behavior_timestamp > s.addcart_time
    GROUP BY s.user_id, s.item_category
),
observation_end AS (
    SELECT MAX(behavior_timestamp) AS end_time
    FROM behavior
),
cart_diff AS (
    SELECT
        s1.user_id,
        s1.item_category,
        TIMESTAMPDIFF(
            SECOND,
            s1.addcart_time,
            s2.first_buy
        ) AS cart_seconds
    FROM stage_1 s1
    JOIN stage_2 s2
        ON s1.user_id = s2.user_id
       AND s1.item_category = s2.item_category
    WHERE s2.first_buy IS NOT NULL
),
ranked AS (
    SELECT
        user_id,
        item_category,
        cart_seconds,
        COUNT(*) OVER (
            PARTITION BY item_category
        ) AS purchase_count,
        ROW_NUMBER() OVER (
            PARTITION BY item_category
            ORDER BY cart_seconds, user_id
        ) AS rn
    FROM cart_diff
),
benchmark AS (
    SELECT
        item_category,
        cart_seconds AS benchmark_seconds
    FROM ranked
    WHERE purchase_count >= 5
      AND rn = CEIL(0.8 * purchase_count)
),
classified AS (
    SELECT
        s1.user_id,
        s1.item_category,
        CASE
            WHEN b.benchmark_seconds IS NULL
                THEN 'no category benchmark'

            WHEN s2.first_buy IS NOT NULL
                 AND d.cart_seconds <= b.benchmark_seconds
                THEN 'purchased within benchmark'

            WHEN s2.first_buy IS NOT NULL
                 AND d.cart_seconds > b.benchmark_seconds
                THEN 'purchased after benchmark'

            WHEN TIMESTAMPDIFF(
                    SECOND,
                    s1.addcart_time,
                    o.end_time
                 ) >= b.benchmark_seconds
                THEN 'no purchase observed'

            ELSE 'insufficient follow-up'
        END AS abandon_status
    FROM stage_1 s1
    LEFT JOIN stage_2 s2
        ON s1.user_id = s2.user_id
       AND s1.item_category = s2.item_category
    LEFT JOIN cart_diff d
        ON s1.user_id = d.user_id
       AND s1.item_category = d.item_category
    LEFT JOIN benchmark b
        ON s1.item_category = b.item_category
    CROSS JOIN observation_end o
)
SELECT user_id, item_category, abandon_status
FROM classified;

SELECT abandon_status, COUNT(*) AS cart_pair_count,
       ROUND(100.0 * COUNT(*) / NULLIF(SUM(COUNT(*)) OVER (), 0), 2)
           AS cart_pair_share_pct
FROM cart_followup
GROUP BY abandon_status
ORDER BY cart_pair_count DESC;

-- 07. Top cart-reminder categories and coverage | Slide 11
WITH category_counts AS (
    SELECT item_category, COUNT(*) AS unpurchased_cart_pairs
    FROM cart_followup
    WHERE abandon_status = 'no purchase observed'
    GROUP BY item_category
), ranked AS (
    SELECT *, ROW_NUMBER() OVER (
        ORDER BY unpurchased_cart_pairs DESC, item_category
    ) AS rn,
    SUM(unpurchased_cart_pairs) OVER () AS total_candidates
    FROM category_counts
)
SELECT item_category, unpurchased_cart_pairs,
       SUM(unpurchased_cart_pairs) OVER () AS top_10_candidates,
       ROUND(100.0 * SUM(unpurchased_cart_pairs) OVER ()
           / NULLIF(total_candidates, 0), 2) AS top_10_candidate_share_pct
FROM ranked
WHERE rn <= 10
ORDER BY rn;

-- 08. Supporting purchase-scope reconciliation | README / metric definitions
-- Retained although not separately charted in the current 14-slide deck.
-- Selected-category purchases need not follow click -> engage -> buy.
WITH all_purchase_pairs AS (
    SELECT user_id, item_category, COUNT(*) AS buy_events
    FROM behavior
    WHERE behavior_type = 'buy'
    GROUP BY user_id, item_category
)
SELECT 'All categories' AS purchase_scope,
       COUNT(*) AS category_buyer_records, SUM(buy_events) AS purchase_events
FROM all_purchase_pairs
UNION ALL
SELECT '680 selected categories', COUNT(*), SUM(p.buy_events)
FROM all_purchase_pairs p
JOIN funnel_eligible_categories e ON p.item_category = e.item_category
UNION ALL
SELECT 'Full funnel in selected categories', COUNT(*), SUM(buy_events)
FROM funnel_purchase_pairs;

-- Expected on the original input: 37,162 / 90,949 = 40.86%.
SELECT SUM(p.buy_events) AS selected_category_purchase_events,
       (SELECT SUM(buy_events) FROM funnel_purchase_pairs) AS funnel_purchase_events,
       ROUND(100.0 * (SELECT SUM(buy_events) FROM funnel_purchase_pairs)
           / NULLIF(SUM(p.buy_events), 0), 2) AS funnel_coverage_pct
FROM (
    SELECT b.item_category, COUNT(*) AS buy_events
    FROM behavior b
    JOIN funnel_eligible_categories e ON b.item_category = e.item_category
    WHERE b.behavior_type = 'buy'
    GROUP BY b.item_category
) p;
