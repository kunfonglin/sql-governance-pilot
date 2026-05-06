-- bigquery/archive/routines/sp_archive_old_orders.sql
-- routine_type: PROCEDURE
-- Pattern: INSERT 到 archive + DELETE 來源（資料搬移）
--
-- 預期 lineage:
--   reads:  staging.user_orders_staging
--   writes: archive.user_orders_archive
--           staging.user_orders_staging  (DELETE 也算 write)

CREATE OR REPLACE PROCEDURE `archive.sp_archive_old_orders`(IN p_cutoff_date DATE)
BEGIN
  -- Step 1: 把 cutoff 之前的 staging 訂單複製到 archive
  INSERT INTO `archive.user_orders_archive`
    (order_id, user_id, product_id, amount, order_date, status)
  SELECT
    order_id, user_id, product_id, amount, order_date, status
  FROM `staging.user_orders_staging`
  WHERE order_date < p_cutoff_date;

  -- Step 2: 從 staging 移除已搬走的
  DELETE FROM `staging.user_orders_staging`
  WHERE order_date < p_cutoff_date;
END;
