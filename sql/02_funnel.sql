-- MySQL. Run numbered files in order; see docs/sql-guide.md.
USE ecommerce_portfolio;

CREATE OR REPLACE VIEW category_funnel AS
WITH stage_1 AS (
    SELECT
        user_id,
        item_category,
        MIN(behavior_timestamp) AS first_click
    FROM behavior
    WHERE behavior_type = 'click'
    GROUP BY user_id, item_category
),
stage_2 AS (
    SELECT
        s.user_id,
        s.item_category,
        s.first_click,
        MIN(b.behavior_timestamp) AS first_engage
    FROM stage_1 s
    LEFT JOIN behavior b
        ON b.user_id = s.user_id
        AND b.item_category = s.item_category
        AND b.behavior_type IN ('save', 'add to cart')
        AND b.behavior_timestamp > s.first_click
    GROUP BY s.user_id, s.item_category, s.first_click
),
stage_3 AS (
    SELECT
        s.user_id,
        s.item_category,
        s.first_engage,
        MIN(b.behavior_timestamp) AS first_buy
    FROM stage_2 s
    LEFT JOIN behavior b
        ON b.user_id = s.user_id
        AND b.item_category = s.item_category
        AND b.behavior_type = 'buy'
        AND b.behavior_timestamp > s.first_engage
    GROUP BY s.user_id, s.item_category, s.first_engage
),
analysis_1 AS (
    SELECT
        item_category,
        COUNT(*) AS click_users,
        COUNT(first_engage) AS engage_users,
        COUNT(first_buy) AS buy_users
    FROM stage_3
    GROUP BY item_category
)
SELECT * FROM analysis_1;

CREATE OR REPLACE VIEW funnel_eligible_categories AS
SELECT item_category FROM category_funnel WHERE click_users >= 30 AND engage_users >= 30;

CREATE OR REPLACE VIEW funnel_engaged_pairs AS
WITH stage_1 AS (
    SELECT
        user_id,
        item_category,
        MIN(behavior_timestamp) AS first_click
    FROM behavior
    WHERE behavior_type = 'click'
    GROUP BY user_id, item_category
),
stage_2 AS (
    SELECT
        s.user_id,
        s.item_category,
        s.first_click,
        MIN(b.behavior_timestamp) AS first_engage
    FROM stage_1 s
    LEFT JOIN behavior b
        ON b.user_id = s.user_id
        AND b.item_category = s.item_category
        AND b.behavior_type IN ('save', 'add to cart')
        AND b.behavior_timestamp > s.first_click
    GROUP BY s.user_id, s.item_category, s.first_click
)
SELECT
    s.user_id,
    s.item_category,
    s.first_engage
FROM stage_2 s
JOIN funnel_eligible_categories e
    ON s.item_category = e.item_category
WHERE s.first_engage IS NOT NULL;


SELECT COUNT(*) AS eligible_categories, SUM(click_users) AS click_pairs,
       SUM(engage_users) AS engage_pairs, SUM(buy_users) AS buy_pairs,
       ROUND(100.0 * SUM(engage_users) / NULLIF(SUM(click_users),0),2) AS click_to_engage_rate,
       ROUND(100.0 * SUM(buy_users) / NULLIF(SUM(engage_users),0),2) AS engage_to_buy_rate,
       ROUND(100.0 * SUM(buy_users) / NULLIF(SUM(click_users),0),2) AS full_funnel_rate,
       ROUND(AVG(100.0 * buy_users / NULLIF(engage_users,0)),2) AS category_mean_conversion,
       ROUND(AVG(engage_users),2) AS category_mean_engaged_users
FROM category_funnel WHERE click_users >= 30 AND engage_users >= 30;
-- Keep published selection thresholds explicit for reproducibility.
SELECT item_category, engage_users,
       ROUND(100.0 * buy_users / NULLIF(engage_users,0),2) AS engage_to_buy_rate
FROM category_funnel
WHERE click_users >= 30 AND engage_users >= 30 AND engage_users > 153.06
  AND 100.0 * buy_users / NULLIF(engage_users,0) < 19.21
ORDER BY engage_users DESC, item_category LIMIT 10;
