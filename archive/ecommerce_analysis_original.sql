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
  ELSE 'buy'
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
    ) AS engage_to_buy_rate,
    ROUND(
        100.0 * SUM(buy_users)
        / NULLIF(SUM(engage_users), 0), 2
    ) AS engage_to_buy_rate,
    ROUND(
        100.0 * SUM(buy_users)
        / NULLIF(SUM(click_users), 0), 2
    ) AS engage_to_buy_rate
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

/* ================================
   Data Exploration
   ================================ */
select count(1)
from behavior;
select count(distinct user_id) as user_num, count(distinct item_id) as item_num, count(distinct item_category) as category_num
from behavior;
select datediff(max(behavior_timestamp), min(behavior_timestamp)) as day_span
from behavior
;
SELECT
    COUNT(*) AS behavior_events,
    COUNT(DISTINCT user_id) AS unique_users,
    COUNT(DISTINCT item_id) AS unique_items,
    COUNT(DISTINCT item_category) AS unique_categories
FROM behavior;
-- Full behavior log
SELECT event_id, user_id, item_id, item_category, behavior_timestamp, behavior_type
FROM behavior
limit 100;

-- behavior time analysis
select date_format(behavior_timestamp, '%H') as behavior_hour,count(distinct user_id) as active_user_num
from behavior
group by 1
order by behavior_hour;

with step1 as (select date_format(behavior_timestamp, '%H') as behavior_hour,count(distinct user_id) as active_user_num
from behavior
group by 1
order by behavior_hour)
select round(avg(active_user_num),0) as avg_count
from step1;

-- daily activity trend 

WITH step_1 AS (
    SELECT
        user_id,
        DATE_FORMAT(behavior_timestamp, '%Y-%m-%d') AS behavior_day
    FROM behavior
    WHERE behavior_type = 'buy'
)
SELECT
    behavior_day,
    COUNT(*) AS purchase_events,
    COUNT(DISTINCT user_id) AS purchasing_users
FROM step_1
GROUP BY behavior_day
ORDER BY behavior_day ASC;

WITH step_1 AS (
    SELECT
        user_id,
        DATE_FORMAT(behavior_timestamp, '%H') AS behavior_hour
    FROM behavior
    WHERE behavior_type = 'buy'
)
SELECT
    behavior_hour,
    COUNT(*) AS purchase_events,
    COUNT(DISTINCT user_id) AS purchasing_users
FROM step_1
GROUP BY behavior_hour
ORDER BY behavior_hour ASC;

select date_format(behavior_timestamp, '%Y-%m-%d') as behavior_day, count(distinct user_id) as active_user_num
from behavior
group by 1
order by 1;

with step1 as (select date_format(behavior_timestamp, '%Y-%m-%d') as behavior_day, count(distinct user_id) as active_user_num
from behavior
group by 1
order by 1)
select round(avg(active_user_num),0) as avg_count
from step1;
--
with step_1 as (SELECT user_id, item_category, count(*) as buy_events, count(distinct user_id) as total_buy
FROM behavior
where behavior_type = 'buy'
group by 1,2)
SELECT
    COUNT(DISTINCT user_id) AS unique_buyers,
    COUNT(*) AS purchasing_pairs,
    SUM(buy_events) AS total_buy_events,
    1.0 * SUM(buy_events) / NULLIF(COUNT(*), 0)
        AS buy_events_per_purchasing_pair
FROM step_1;

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
   AND b.behavior_timestamp > s.first_engage;

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
  
-- conversion

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
)
SELECT
    COUNT(*) AS click_count,
    COUNT(first_engage) AS engage_count,
    COUNT(first_buy) AS buy_count
FROM stage_3;

-- repeat purchase share

with purchase_pairs AS (
    SELECT
        b.user_id,
        b.item_category,
        COUNT(DISTINCT DATE(b.behavior_timestamp))
            AS purchase_days
    FROM stage_2 s
    JOIN behavior b
        ON b.user_id = s.user_id
       AND b.item_category = s.item_category
       AND b.behavior_type = 'buy'
       AND b.behavior_timestamp > s.first_engage
    JOIN eligible_categories e
        ON b.item_category = e.item_category
    GROUP BY b.user_id, b.item_category
)
SELECT
    COUNT(*) AS purchasing_pairs,
    SUM(CASE
        WHEN purchase_days >= 2 THEN 1 ELSE 0
    END) AS repeat_purchasing_pairs,
    ROUND(
        100.0 * SUM(CASE
            WHEN purchase_days >= 2 THEN 1 ELSE 0
        END) / NULLIF(COUNT(*), 0),
        2
    ) AS repeat_purchase_rate
FROM purchase_pairs;

-- low repeat purchase rate 

CREATE TEMPORARY TABLE tmp_conversion_rate AS
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
)
    SELECT
        item_category,
       round(100*COUNT(first_buy)/COUNT(first_engage),2) AS engage_to_buy_conversion_rate
    FROM stage_3
    GROUP BY item_category
	HAVING COUNT(*) >= 30
    AND COUNT(first_engage) >= 30;


CREATE TEMPORARY TABLE tmp_repeat AS 
WITH purchase_pairs AS (
    SELECT
        user_id,
        item_category,
        COUNT(DISTINCT DATE(behavior_timestamp)) AS purchase_days
    FROM behavior
    WHERE behavior_type = 'buy'
    GROUP BY user_id, item_category
)
SELECT
	item_category,
    COUNT(*) AS purchasing_pairs,
    SUM(CASE
        WHEN purchase_days >= 2 THEN 1 ELSE 0
    END) AS repeat_purchasing_pairs,
    ROUND(
        100.0 * SUM(CASE
            WHEN purchase_days >= 2 THEN 1 ELSE 0
        END) / NULLIF(COUNT(*), 0),
        2
    ) AS repeat_purchase_rate
FROM purchase_pairs
group by item_category
order by repeat_purchase_rate desc;

SELECT
    r.*,
    c.engage_to_buy_conversion_rate
FROM tmp_repeat r
JOIN tmp_conversion_rate c
    ON r.item_category = c.item_category
WHERE r.purchasing_pairs >= 30
ORDER BY
    repeat_purchase_rate desc
LIMIT 10;

-- check
WITH stage_1 AS (
    SELECT
        user_id,
        item_category,
        MIN(behavior_timestamp) AS first_click,
        COUNT(*) AS click_event_count
    FROM behavior
    WHERE behavior_type = 'click'
    GROUP BY user_id, item_category
),
stage_2 AS (
    SELECT
        s.user_id,
        s.item_category,
        s.click_event_count,
        MIN(b.behavior_timestamp) AS first_engage
    FROM stage_1 s
    LEFT JOIN behavior b
        ON b.user_id = s.user_id
        AND b.item_category = s.item_category
        AND b.behavior_type IN ('save', 'add to cart')
        AND b.behavior_timestamp > s.first_click
    GROUP BY
        s.user_id,
        s.item_category,
        s.click_event_count
),
stage_3 AS (
    SELECT
        s.user_id,
        s.item_category,
        s.click_event_count,
        s.first_engage,
        MIN(b.behavior_timestamp) AS first_buy
    FROM stage_2 s
    LEFT JOIN behavior b
        ON b.user_id = s.user_id
        AND b.item_category = s.item_category
        AND b.behavior_type = 'buy'
        AND b.behavior_timestamp > s.first_engage
    GROUP BY
        s.user_id,
        s.item_category,
        s.click_event_count,
        s.first_engage
),
stage_4 AS (
    SELECT
        item_category,
        COUNT(*) AS click_users,
        COUNT(first_engage) AS engage_users,
        COUNT(first_buy) AS buy_users,
        SUM(click_event_count) AS click_volume,
        100.0 * COUNT(first_buy)
            / NULLIF(COUNT(first_engage), 0) AS conversion_rate
    FROM stage_3
    GROUP BY item_category
)
SELECT
    item_category,
    click_users,
    engage_users,
    buy_users,
    ROUND(
        100.0 * engage_users / NULLIF(click_users, 0),
        2
    ) AS click_to_engage_rate,
    ROUND(
        100.0 * buy_users / NULLIF(engage_users, 0),
        2
    ) AS engage_to_buy_rate
FROM stage_4
WHERE item_category IN (
    13932, 13381, 220, 3898, 4333,
    1370, 1604, 13404, 6697, 6717
)
ORDER BY
    1.0 * buy_users / NULLIF(engage_users, 0) DESC,
    engage_users DESC;
    
-- overall repeat purchase 
with repeat_purchase as (SELECT user_id,item_category, COUNT(*) AS repeat_purchase_count
FROM behavior
WHERE behavior_type = 'buy'
GROUP BY user_id, item_category
HAVING COUNT(*) > 1),
repeat_purchase_1 as (select item_category, sum(repeat_purchase_count) as cnt
from repeat_purchase
group by 1)
select avg(cnt) as avg_cnt
from repeat_purchase_1;

with repeat_purchase as (SELECT user_id,item_category, COUNT(*) AS repeat_purchase_cnt1
FROM behavior
WHERE behavior_type = 'buy'
GROUP BY user_id, item_category
HAVING COUNT(*) > 1),
purchase as (SELECT user_id,item_category, COUNT(*) AS repeat_purchase_cnt2
FROM behavior
WHERE behavior_type = 'buy'
GROUP BY user_id, item_category
HAVING COUNT(*) >= 1),
repeat_rate as (select distinct p.item_category, round(100*sum(repeat_purchase_cnt1) /sum(repeat_purchase_cnt2),2) as repeat_purchase_rate
from purchase p
left join repeat_purchase r
on p.user_id = r.user_id and p.item_category = r.item_category
group by 1)
select round(avg(repeat_purchase_rate),2) as avg_repeat_purchase_rate
from repeat_rate;

-- conversion 3

with stage_1 as (
select distinct user_id, item_category, min(behavior_timestamp) as first_click
from behavior
where behavior_type = 'click'
group by 1,2),
stage_2 as(
select distinct user_id, item_category, min(behavior_timestamp) as first_engage
from behavior
where behavior_type in ('save', 'add to cart')
group by 1,2),
stage_3 as (
select distinct user_id, item_category, min(behavior_timestamp) as first_buy
from behavior
where behavior_type = 'buy'
group by 1,2),
analysis_1 as (select s1.item_category,
count(distinct s1.user_id) as click_user,
COUNT(DISTINCT CASE WHEN s1.first_click < s2.first_engage THEN s2.user_id END) AS engage_users,
COUNT(DISTINCT CASE WHEN s1.first_click < s2.first_engage and 
s2.first_engage < s3.first_buy THEN s3.user_id END) AS buy_users
FROM stage_1 s1
left JOIN stage_2 s2 ON s1.user_id = s2.user_id AND s1.item_category = s2.item_category
left JOIN stage_3 s3 ON s1.user_id = s3.user_id AND s1.item_category = s3.item_category
GROUP BY s1.item_category)
select a.item_category,
round((engage_users / nullif(click_user,0)*100),2) as click_to_engage_rate,
round((buy_users / nullif(engage_users,0)*100),2) as engage_to_buy_rate
from analysis_1 a
where click_user >= 30 and engage_users >= 30
and round((engage_users / nullif(click_user,0)*100),2) > 10.24
and round((buy_users / nullif(engage_users,0)*100),2) > 17.39
order by engage_to_buy_rate desc
limit 10;

-- conversion funnel behavior in order 1

with stage_1 as (
select distinct user_id, item_category, min(behavior_timestamp) as first_click
from behavior
where behavior_type = 'click'
group by 1,2),
stage_2 as(
select distinct user_id, item_category, min(behavior_timestamp) as first_engage
from behavior
where behavior_type in ('save', 'add to cart')
group by 1,2),
stage_3 as (
select distinct user_id, item_category, min(behavior_timestamp) as first_buy
from behavior
where behavior_type = 'buy'
group by 1,2),
analysis_1 as (select s1.item_category,
count(distinct s1.user_id) as click_user,
COUNT(DISTINCT CASE WHEN s1.first_click < s2.first_engage THEN s2.user_id END) AS engage_users,
COUNT(DISTINCT CASE WHEN s1.first_click < s2.first_engage and 
s2.first_engage < s3.first_buy THEN s3.user_id END) AS buy_users
FROM stage_1 s1
left JOIN stage_2 s2 ON s1.user_id = s2.user_id AND s1.item_category = s2.item_category
left JOIN stage_3 s3 ON s1.user_id = s3.user_id AND s1.item_category = s3.item_category
GROUP BY s1.item_category)
select a.item_category,
round((engage_users / nullif(click_user,0)*100),2) as click_to_engage_rate,
round((buy_users / nullif(engage_users,0)*100),2) as engage_to_buy_rate
from analysis_1 a
where click_user >= 30 and engage_users >= 30
order by click_to_engage_rate desc
limit 15;

-- conversion funnel behavior in order 2

with stage_1 as (
select distinct user_id, item_category, min(behavior_timestamp) as first_click
from behavior
where behavior_type = 'click'
group by 1,2),
stage_2 as(
select distinct user_id, item_category, min(behavior_timestamp) as first_engage
from behavior
where behavior_type in ('save', 'add to cart')
group by 1,2),
stage_3 as (
select distinct user_id, item_category, min(behavior_timestamp) as first_buy
from behavior
where behavior_type = 'buy'
group by 1,2),
analysis_1 as (select s1.item_category,
count(distinct s1.user_id) as click_user,
COUNT(DISTINCT CASE WHEN s1.first_click < s2.first_engage THEN s2.user_id END) AS engage_users,
COUNT(DISTINCT CASE WHEN s1.first_click < s2.first_engage and 
s2.first_engage < s3.first_buy THEN s3.user_id END) AS buy_users
FROM stage_1 s1
left JOIN stage_2 s2 ON s1.user_id = s2.user_id AND s1.item_category = s2.item_category
left JOIN stage_3 s3 ON s1.user_id = s3.user_id AND s1.item_category = s3.item_category
GROUP BY s1.item_category)
select a.item_category,
round((engage_users / nullif(click_user,0)*100),2) as click_to_engage_rate,
round((buy_users / nullif(engage_users,0)*100),2) as engage_to_buy_rate
from analysis_1 a
where click_user >= 30 and engage_users >= 30
order by engage_to_buy_rate desc
limit 15;

-- distribution updated

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
        COUNT(*) AS click_user,
        COUNT(first_engage) AS engage_users,
        COUNT(first_buy) AS buy_users
    FROM stage_3
    GROUP BY item_category
),
rates AS (
    SELECT
        item_category,
        100.0 * buy_users / NULLIF(engage_users, 0)
            AS engage_to_buy_rate
    FROM analysis_1
    WHERE click_user >= 30
      AND engage_users >= 30
),
bucketed AS (
    SELECT
        CASE
            WHEN engage_to_buy_rate < 20 THEN '0–<20%'
            WHEN engage_to_buy_rate < 40 THEN '20–<40%'
            WHEN engage_to_buy_rate < 60 THEN '40–<60%'
            WHEN engage_to_buy_rate < 80 THEN '60–<80%'
            ELSE '80–100%'
        END AS conversion_bucket
    FROM rates
)
SELECT
    conversion_bucket,
    COUNT(*) AS num_categories
FROM bucketed
GROUP BY conversion_bucket
;

-- distribution 2 updated

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
        COUNT(*) AS click_user,
        COUNT(first_engage) AS engage_users,
        COUNT(first_buy) AS buy_users
    FROM stage_3
    GROUP BY item_category
),
rates AS (
    SELECT
        item_category,
        100.0 * engage_users / NULLIF(click_user, 0)
            AS click_to_engage_rate
    FROM analysis_1
    WHERE click_user >= 30
      AND engage_users >= 30
),
bucketed AS (
    SELECT
        CASE
            WHEN click_to_engage_rate < 20 THEN '0–<20%'
            WHEN click_to_engage_rate < 40 THEN '20–<40%'
            WHEN click_to_engage_rate < 60 THEN '40–<60%'
            WHEN click_to_engage_rate < 80 THEN '60–<80%'
            ELSE '80–100%'
        END AS conversion_bucket
    FROM rates
)
SELECT
    conversion_bucket,
    COUNT(*) AS num_categories
FROM bucketed
GROUP BY conversion_bucket;

-- avg time between addcart and purchase updated

WITH stage_1 AS (
    SELECT
        user_id,
        item_category,
        MIN(behavior_timestamp) AS addcart_time
    FROM behavior
    WHERE behavior_type = 'add to cart'
    GROUP BY user_id, item_category
),
stage_2 AS (
    SELECT
        s.user_id,
        s.item_category,
        s.addcart_time,
        MIN(b.behavior_timestamp) AS first_buy
    FROM stage_1 s
    LEFT JOIN behavior b
        ON b.user_id = s.user_id
        AND b.item_category = s.item_category
        AND b.behavior_type = 'buy'
        AND b.behavior_timestamp >= s.addcart_time
    GROUP BY s.user_id, s.item_category, s.addcart_time
)
SELECT
    COUNT(*) AS purchased_user_category_count,
    ROUND(
        AVG(
            TIMESTAMPDIFF(SECOND, addcart_time, first_buy)
            / 3600.0
        ),
        2
    ) AS avg_cart_time_hours
FROM stage_2
WHERE first_buy IS NOT NULL;

-- avg time between addcart and purchase for each category

WITH stage_1 AS (
    SELECT
        user_id,
        item_category,
        MIN(behavior_timestamp) AS addcart_time
    FROM behavior
    WHERE behavior_type = 'add to cart'
    GROUP BY user_id, item_category
),
stage_2 AS (
    SELECT
        s.user_id,
        s.item_category,
        s.addcart_time,
        MIN(b.behavior_timestamp) AS first_buy
    FROM stage_1 s
    LEFT JOIN behavior b
        ON b.user_id = s.user_id
        AND b.item_category = s.item_category
        AND b.behavior_type = 'buy'
        AND b.behavior_timestamp >= s.addcart_time
    GROUP BY s.user_id, s.item_category, s.addcart_time
)
SELECT
    item_category,
    COUNT(*) AS purchased_user_category_count,
    ROUND(
        AVG(
            TIMESTAMPDIFF(SECOND, addcart_time, first_buy)
            / 3600.0
        ),
        2
    ) AS avg_cart_time_hours
FROM stage_2
WHERE first_buy IS NOT NULL and item_category IN (
    1863,
    13932,
    13092,
    4583,
    3064,
    3940,
    8877,
    5468,
    5232,
    9899
)
group by 1;

-- cart abandoner analysis 1


--
WITH stage_1 AS (
    SELECT
        user_id,
        item_category,
        MIN(behavior_timestamp) AS addcart_time
    FROM behavior
    WHERE behavior_type = 'add to cart'
    GROUP BY user_id, item_category
)
select count(1)
from stage_1;

-- cart abandoner analysis updated 9/15

WITH stage_1 AS (
    SELECT
        user_id,
        item_category,
        MIN(behavior_timestamp) AS addcart_time
    FROM behavior
    WHERE behavior_type = 'add to cart'
    GROUP BY user_id, item_category
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
        AND b.behavior_timestamp >= s.addcart_time
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

-- cart abandoner analysis

WITH stage_1 AS (
    SELECT
        user_id,
        item_category,
        MIN(behavior_timestamp) AS addcart_time
    FROM behavior
    WHERE behavior_type = 'add to cart'
    GROUP BY user_id, item_category
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
        AND b.behavior_timestamp >= s.addcart_time
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
    COUNT(*) AS no_purchase_pairs,
    ROUND(
        100.0 * COUNT(*) / SUM(COUNT(*)) OVER (),
        2
    ) AS share_of_all_no_purchase_pairs
FROM classified
WHERE abandon_status = 'no purchase observed'
GROUP BY item_category
ORDER BY no_purchase_pairs DESC, item_category
LIMIT 10;