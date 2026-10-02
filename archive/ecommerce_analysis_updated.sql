/* ================================
   Database Setup
   ================================ */
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

CREATE TABLE funnel_eligible_categories AS
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
    SELECT item_category
    FROM analysis_1
    WHERE click_users >= 30
      AND engage_users >= 30;
    
-- table
CREATE TABLE funnel_engaged_pairs AS
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

-- check

SELECT
    COUNT(*) AS engaged_pairs,
    COUNT(DISTINCT item_category) AS eligible_categories
FROM funnel_engaged_pairs;

SELECT
    COUNT(*) AS eligible_funnel_buy_events
FROM behavior b
WHERE b.behavior_type = 'buy'
  AND EXISTS (
      SELECT 1
      FROM funnel_engaged_pairs s
      WHERE s.user_id = b.user_id
        AND s.item_category = b.item_category
        AND b.behavior_timestamp > s.first_engage
  );
  
-- table
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
SELECT
    COUNT(*) AS category_count,
    SUM(engage_users) AS total_engage,
    AVG(1.0 * engage_users) AS avg_engage
FROM analysis_1
WHERE click_users >= 30
  AND engage_users >= 30;

WITH purchase_pairs AS (
    SELECT
        b.user_id,
        b.item_category,
        COUNT(DISTINCT DATE(b.behavior_timestamp)) AS purchase_days
    FROM behavior b
    JOIN funnel_engaged_pairs s
        ON b.user_id = s.user_id
       AND b.item_category = s.item_category
       AND b.behavior_timestamp > s.first_engage
    WHERE b.behavior_type = 'buy'
    GROUP BY b.user_id, b.item_category
)
SELECT
    COUNT(*) AS purchasing_pairs,
    SUM(CASE WHEN purchase_days >= 2 THEN 1 ELSE 0 END)
        AS repeat_purchasing_pairs,
    ROUND(
        100.0 * SUM(
            CASE WHEN purchase_days >= 2 THEN 1 ELSE 0 END
        ) / NULLIF(COUNT(*), 0), 2
    ) AS repeat_purchase_rate
FROM purchase_pairs;

-- new repeat analysis
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
SELECT
    SUM(click_users) AS click_pairs,
    SUM(engage_users) AS engage_pairs,
    SUM(buy_users) AS buy_pairs,
    ROUND(
        100.0 * SUM(engage_users)
        / NULLIF(SUM(click_users), 0), 2
    ) AS click_to_engage_rate,
    ROUND(
        100.0 * SUM(buy_users)
        / NULLIF(SUM(engage_users), 0), 2
    ) AS engage_to_buy_rate,
    ROUND(
        100.0 * SUM(buy_users)
        / NULLIF(SUM(click_users), 0), 2
    ) AS click_to_buy_rate
FROM analysis_1
WHERE click_users >= 30
  AND engage_users >= 30;

-- repeat purchase event

WITH purchase_pairs AS (
    SELECT
        b.user_id,
        b.item_category,
        count(*) as buy_event,
        COUNT(DISTINCT DATE(b.behavior_timestamp)) AS purchase_days
    FROM behavior b
    JOIN funnel_engaged_pairs s
        ON b.user_id = s.user_id
       AND b.item_category = s.item_category
       AND b.behavior_timestamp > s.first_engage
    WHERE b.behavior_type = 'buy'
    GROUP BY b.user_id, b.item_category
)
select sum(buy_event) as total_repeat_buy_event
from purchase_pairs
where purchase_days >=2;

WITH purchase_pairs AS (
    SELECT
        b.user_id,
        b.item_category,
        count(*) as buy_event,
        COUNT(DISTINCT DATE(b.behavior_timestamp)) AS purchase_days
    FROM behavior b
    JOIN funnel_engaged_pairs s
        ON b.user_id = s.user_id
       AND b.item_category = s.item_category
       AND b.behavior_timestamp > s.first_engage
    WHERE b.behavior_type = 'buy'
    GROUP BY b.user_id, b.item_category
)
SELECT
    item_category,
    COUNT(*) AS purchasing_pairs,
    SUM(CASE WHEN purchase_days >= 2 THEN 1 ELSE 0 END)
        AS repeat_purchasing_pairs,
    ROUND(
        100.0 * SUM(
            CASE WHEN purchase_days >= 2 THEN 1 ELSE 0 END
        ) / NULLIF(COUNT(*), 0), 2
    ) AS repeat_purchase_rate
FROM purchase_pairs
GROUP BY item_category
ORDER BY purchasing_pairs DESC;

WITH purchase_pairs AS (
    SELECT
        b.user_id,
        b.item_category,
        count(*) as buy_event,
        COUNT(DISTINCT DATE(b.behavior_timestamp)) AS purchase_days
    FROM behavior b
    JOIN funnel_engaged_pairs s
        ON b.user_id = s.user_id
       AND b.item_category = s.item_category
       AND b.behavior_timestamp > s.first_engage
    WHERE b.behavior_type = 'buy'
    GROUP BY b.user_id, b.item_category
),
purchase_group as (SELECT
    item_category,
    COUNT(*) AS purchasing_pairs,
    SUM(CASE WHEN purchase_days >= 2 THEN 1 ELSE 0 END)
        AS repeat_purchasing_pairs,
    ROUND(
        100.0 * SUM(
            CASE WHEN purchase_days >= 2 THEN 1 ELSE 0 END
        ) / COUNT(*), 2
    ) AS repeat_purchase_rate,
    CASE
        WHEN 100.0 * SUM(
            CASE WHEN purchase_days >= 2 THEN 1 ELSE 0 END
        ) / COUNT(*) >= 12.70
        THEN 'Higher repeat'
        ELSE 'Lower repeat'
    END AS repeat_segment
FROM purchase_pairs
GROUP BY item_category
HAVING COUNT(*) >= 30),
ranked as (select *, row_number() over (partition by repeat_segment order by purchasing_pairs desc, item_category) as rn
from purchase_group)
select repeat_segment,
    item_category,
    purchasing_pairs,
    repeat_purchase_rate
from ranked
where rn <= 10
order by repeat_segment, rn;

-- new cart recovery

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
SELECT
    abandon_status,
    COUNT(*) AS cart_pair_count
FROM classified
GROUP BY abandon_status
ORDER BY cart_pair_count DESC;

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
SELECT
    item_category,
    COUNT(*) AS unpurchased_cart_pairs
FROM classified
WHERE abandon_status = 'no purchase observed'
GROUP BY item_category
ORDER BY unpurchased_cart_pairs DESC, item_category
LIMIT 10;

-- buy analysis

CREATE TEMPORARY TABLE eligible_categories AS
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
    SELECT item_category
    FROM analysis_1
    WHERE click_users >= 30
      AND engage_users >= 30;

SELECT
    COUNT(*) AS purchasing_pairs,
    SUM(buy_events) AS total_buy_events
FROM (
    SELECT
        user_id,
        item_category,
        COUNT(*) AS buy_events
    FROM behavior
    WHERE behavior_type = 'buy'
      AND item_category IN (
          SELECT item_category
          FROM eligible_categories
      )
    GROUP BY user_id, item_category
) t;

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
), eligible_categories AS (
    SELECT item_category
    FROM stage_2
    GROUP BY item_category
    HAVING COUNT(*) >= 30
       AND COUNT(first_engage) >= 30
)
SELECT COUNT(*) AS funnel_buy_events
FROM stage_2 s
JOIN behavior b
    ON b.user_id = s.user_id
   AND b.item_category = s.item_category
   AND b.behavior_type = 'buy'
   AND b.behavior_timestamp > s.first_engage
JOIN eligible_categories e
    ON s.item_category = e.item_category;

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
SELECT
    item_category,
    engage_users,
    ROUND(
        100.0 * buy_users / NULLIF(engage_users, 0), 2
    ) AS engage_to_buy_rate
FROM analysis_1
WHERE click_users >= 30
  AND engage_users >= 30
  AND 100.0 * buy_users / NULLIF(engage_users, 0) < 19.21
  AND engage_users > 153.06
ORDER BY engage_users DESC
limit 10;


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
SELECT
    ROUND(AVG(
        100.0 * buy_users / NULLIF(engage_users, 0)
    ), 2) AS avg_category_conversion,
    ROUND(AVG(1.0 * engage_users), 2) AS avg_engage_users
FROM analysis_1
WHERE click_users >= 30
  AND engage_users >= 30;
    
-- conversion update

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
SELECT
    avg(ROUND(
        100.0 * engage_users / NULLIF(click_users, 0),
        2
    )) AS click_to_engage_rate,
    avg(ROUND(
        100.0 * buy_users / NULLIF(engage_users, 0),
        2
    )) AS engage_to_buy_rate
FROM analysis_1
WHERE click_users >= 30
AND engage_users >= 30;
  
