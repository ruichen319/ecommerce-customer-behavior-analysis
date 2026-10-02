-- MySQL. Run numbered files in order; see docs/sql-guide.md.
-- Dedicated portfolio schema; leaves ecommerce_project unchanged.
CREATE DATABASE IF NOT EXISTS ecommerce_portfolio;
USE ecommerce_portfolio;
-- Import the supplied CSV into this table once. Retain every input row.
CREATE TABLE IF NOT EXISTS cleaned_data (
    user_id BIGINT NOT NULL,
    item_id BIGINT NOT NULL,
    behavior_type TINYINT NOT NULL,
    item_category INT NOT NULL,
    time VARCHAR(13) NOT NULL,
    date DATE NOT NULL,
    hour TINYINT NOT NULL
);
-- Use Workbench's Table Data Import Wizard with cleaned_data.csv.
-- Do not import again into a populated table: repeated imports duplicate events.
-- Mapping is taken from the original analysis. Unknown codes remain NULL.
CREATE OR REPLACE VIEW behavior AS
SELECT user_id, item_id, item_category,
       STR_TO_DATE(CONCAT(time, ':00:00'), '%Y-%m-%d %H:%i:%s') AS behavior_timestamp,
       CASE behavior_type WHEN 1 THEN 'click' WHEN 2 THEN 'save'
           WHEN 3 THEN 'add to cart' WHEN 4 THEN 'buy' ELSE NULL END AS behavior_type
FROM cleaned_data;
