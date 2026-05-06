-- bigquery/fact/routines/sp_build_daily_orders_fact.sql
-- routine_type: PROCEDURE
-- Pattern: TEMP TABLE + CTE + DELETE partition + INSERT
-- 跨多個 dataset (staging / dim / fact) — 測試多 schema lineage
--
-- 預期 lineage:
--   reads:  staging.user_orders_staging, dim.dim_users, dim.dim_products
--   writes: fact.fact_daily_orders

CREATE OR REPLACE PROCEDURE `fact.sp_build_daily_orders_fact`(IN p_date DATE)
BEGIN
  -- Step 1: 建 TEMP TABLE — 把當日訂單 + dim 資訊先 join 好
  CREATE OR REPLACE TEMP TABLE _tmp_enriched_orders AS
  WITH base_orders AS (
    SELECT order_id, user_id, product_id, amount, order_date, status
    FROM `staging.user_orders_staging`
    WHERE order_date = p_date
  ),
  with_user AS (
    SELECT
      o.*,
      u.user_sk
    FROM base_orders o
    LEFT JOIN `dim.dim_users` u
      ON o.user_id = u.user_id AND u.is_current = TRUE
  )
  SELECT
    w.order_date,
    w.order_id,
    w.user_sk,
    w.product_id,
    p.category,
    w.amount,
    w.status
  FROM with_user w
  LEFT JOIN `dim.dim_products` p
    ON w.product_id = p.product_id;

  -- Step 2: 清掉當日 fact partition（idempotent rebuild）
  DELETE FROM `fact.fact_daily_orders`
  WHERE order_date = p_date;

  -- Step 3: 從 TEMP TABLE 灌進 fact
  INSERT INTO `fact.fact_daily_orders`
    (order_date, order_id, user_sk, product_id, category, amount, status)
  SELECT
    order_date, order_id, user_sk, product_id, category, amount, status
  FROM _tmp_enriched_orders;
END;
