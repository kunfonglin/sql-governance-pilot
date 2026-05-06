-- bigquery/fact/routines/sp_update_user_ltv.sql
-- routine_type: PROCEDURE
-- Pattern: UPDATE with subquery + MERGE-style upsert
-- 對 fact_user_ltv 做累積更新（lifetime value snapshot）
--
-- 預期 lineage:
--   reads:  fact.fact_daily_orders, dim.dim_users, fact.fact_user_ltv (self-read)
--   writes: fact.fact_user_ltv

CREATE OR REPLACE PROCEDURE `fact.sp_update_user_ltv`()
BEGIN
  -- Step 1: 對既有 user 做 UPDATE
  UPDATE `fact.fact_user_ltv` T
  SET
    total_orders   = agg.total_orders,
    total_amount   = agg.total_amount,
    last_order_at  = agg.last_order_at,
    updated_at     = CURRENT_TIMESTAMP()
  FROM (
    SELECT
      u.user_id,
      COUNT(*)                AS total_orders,
      SUM(f.amount)           AS total_amount,
      MAX(f.order_date)       AS last_order_at
    FROM `fact.fact_daily_orders` f
    JOIN `dim.dim_users` u
      ON f.user_sk = u.user_sk AND u.is_current = TRUE
    WHERE f.status = 'completed'
    GROUP BY u.user_id
  ) agg
  WHERE T.user_id = agg.user_id;

  -- Step 2: 對新 user 做 INSERT（沒在 T 裡的）
  INSERT INTO `fact.fact_user_ltv`
    (user_id, total_orders, total_amount, first_order_at, last_order_at)
  SELECT
    u.user_id,
    COUNT(*),
    SUM(f.amount),
    MIN(f.order_date),
    MAX(f.order_date)
  FROM `fact.fact_daily_orders` f
  JOIN `dim.dim_users` u
    ON f.user_sk = u.user_sk AND u.is_current = TRUE
  WHERE f.status = 'completed'
    AND u.user_id NOT IN (SELECT user_id FROM `fact.fact_user_ltv`)
  GROUP BY u.user_id;
END;
