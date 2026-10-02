-- MySQL. Run numbered files in order; see docs/sql-guide.md.
USE ecommerce_portfolio;

CREATE OR REPLACE VIEW purchase_pairs AS
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
    GROUP BY b.user_id, b.item_category;
SELECT COUNT(*) AS purchasing_pairs, SUM(buy_event) AS funnel_purchase_events,
       SUM(purchase_days >= 2) AS repeat_purchasing_pairs,
       SUM(CASE WHEN purchase_days >= 2 THEN buy_event ELSE 0 END) AS repeat_buyer_purchase_events,
       ROUND(100.0 * SUM(purchase_days >= 2) / NULLIF(COUNT(*),0),2) AS repeat_purchase_rate
FROM purchase_pairs;
WITH purchase_group AS (SELECT
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
