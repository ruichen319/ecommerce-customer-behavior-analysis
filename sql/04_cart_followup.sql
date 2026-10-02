-- MySQL. Run numbered files in order; see docs/sql-guide.md.
USE ecommerce_portfolio;

-- P80 uses nearest rank CEIL(0.8*n), n >= 5; strict later events.
CREATE OR REPLACE VIEW cart_classified AS
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
SELECT * FROM classified;
SELECT abandon_status, COUNT(*) AS cart_pair_count FROM cart_classified
GROUP BY abandon_status ORDER BY cart_pair_count DESC;
SELECT item_category, COUNT(*) AS unpurchased_cart_pairs FROM cart_classified
WHERE abandon_status = 'no purchase observed'
GROUP BY item_category ORDER BY unpurchased_cart_pairs DESC, item_category LIMIT 10;
