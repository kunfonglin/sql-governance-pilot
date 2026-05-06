-- bigquery/staging/routines/sp_load_orders.sql
-- routine_type: PROCEDURE
-- Pattern: TRUNCATE + INSERT（每日重灌指定日期 partition 到 staging）
--
-- 預期 lineage:
--   reads:  raw_data.user_orders_raw
--   writes: staging.user_orders_staging

CREATE OR REPLACE PROCEDURE `staging.sp_load_orders`(IN p_date DATE)
BEGIN
  -- Step 1: 清掉今天的 staging（partition 級 DELETE）
  DELETE FROM `staging.user_orders_staging`
  WHERE order_date = p_date;

  -- Step 2: 從 raw 載入清洗後資料（過濾掉 NULL amount / 非合理 status）
  INSERT INTO `staging.user_orders_staging`
    (order_id, user_id, product_id, amount, order_date, status)
  SELECT
    order_id,
    user_id,
    product_id,
    amount,
    order_date,
    status
  FROM `raw_data.user_orders_raw`
  WHERE order_date = p_date
    AND amount IS NOT NULL
    AND status IN ('completed', 'pending', 'refunded', 'cancelled');
END;
