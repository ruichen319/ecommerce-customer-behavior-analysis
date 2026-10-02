-- MySQL. Run numbered files in order; see docs/sql-guide.md.
USE ecommerce_portfolio;

SELECT 'all_categories' AS scope, COUNT(*) AS category_buyer_records, SUM(events) AS purchase_events
FROM (SELECT user_id,item_category,COUNT(*) AS events FROM behavior
      WHERE behavior_type='buy' GROUP BY user_id,item_category) a
UNION ALL
SELECT 'eligible_categories',COUNT(*),SUM(events)
FROM (SELECT b.user_id,b.item_category,COUNT(*) AS events FROM behavior b
      JOIN funnel_eligible_categories e ON b.item_category=e.item_category
      WHERE b.behavior_type='buy' GROUP BY b.user_id,b.item_category) e
UNION ALL
SELECT 'eligible_funnel',COUNT(*),SUM(buy_event) FROM purchase_pairs;
