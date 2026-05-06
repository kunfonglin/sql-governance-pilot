-- bigquery/staging/routines/sp_clean_invalid_orders.sql
-- routine_type: PROCEDURE
-- Pattern: 從 raw 找壞資料 → INSERT 到 invalid_orders_log → DELETE raw
-- 兩個 statement 各對一張表寫入，是「多 write edge」測試案例
--
-- 預期 lineage:
--   reads:  raw_data.user_orders_raw
--   writes: staging.invalid_orders_log
--           raw_data.user_orders_raw   (DELETE 也算 write)

CREATE OR REPLACE PROCEDURE `staging.sp_clean_invalid_orders`()
BEGIN
  -- 把不合法的訂單記到 log（amount NULL 或 status 非預期）
  INSERT INTO `staging.invalid_orders_log` (order_id, reason, raw_payload)
  SELECT
    order_id,
    CASE
      WHEN amount IS NULL THEN 'AMOUNT_NULL'
      WHEN status NOT IN ('completed','pending','refunded','cancelled') THEN 'STATUS_INVALID'
      ELSE 'UNKNOWN'
    END AS reason,
    TO_JSON_STRING(STRUCT(order_id, user_id, product_id, amount, order_date, status))
  FROM `raw_data.user_orders_raw`
  WHERE amount IS NULL
     OR status NOT IN ('completed','pending','refunded','cancelled');

  -- 從 raw 移除這些壞資料（避免下次跑 sp_load_orders 又被當合法）
  DELETE FROM `raw_data.user_orders_raw`
  WHERE amount IS NULL
     OR status NOT IN ('completed','pending','refunded','cancelled');
END;
