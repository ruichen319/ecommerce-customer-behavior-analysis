-- MySQL. Run numbered files in order; see docs/sql-guide.md.
USE ecommerce_portfolio;

SELECT COUNT(*) AS behavior_events, COUNT(DISTINCT user_id) AS unique_users,
       COUNT(DISTINCT item_id) AS unique_items, COUNT(DISTINCT item_category) AS unique_categories,
       MIN(behavior_timestamp) AS first_event, MAX(behavior_timestamp) AS last_event
FROM behavior;
SELECT behavior_type, COUNT(*) AS events FROM behavior GROUP BY behavior_type;
SELECT SUM(behavior_timestamp IS NULL) AS invalid_timestamps,
       SUM(behavior_type IS NULL) AS unknown_behavior_codes FROM behavior;
SELECT COUNT(*) AS inconsistent_time_components FROM cleaned_data
WHERE LEFT(time, 10) <> CAST(date AS CHAR)
   OR CAST(RIGHT(time, 2) AS UNSIGNED) <> hour;
SELECT COUNT(DISTINCT user_id) AS unique_buyers, COUNT(*) AS purchase_events
FROM behavior WHERE behavior_type = 'buy';
