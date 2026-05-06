-- bigquery/analytics/routines/sp_build_daily_summary.sql
-- routine_type: PROCEDURE
-- Pattern: 多 CTE + DELETE partition + INSERT
-- 也展示 「跨多 dataset 讀取」（fact + dim）
--
-- 預期 lineage:
--   reads:  fact.fact_daily_orders, dim.dim_products
--   writes: analytics.daily_summary

CREATE OR REPLACE PROCEDURE `analytics.sp_build_daily_summary`(IN p_date DATE)
BEGIN
  -- Idempotent: 先刪當日
  DELETE FROM `analytics.daily_summary`
  WHERE summary_date = p_date;

  INSERT INTO `analytics.daily_summary`
    (summary_date, total_orders, total_amount, unique_users, top_category)
  WITH base AS (
    SELECT *
    FROM `fact.fact_daily_orders`
    WHERE order_date = p_date
      AND status = 'completed'
  ),
  with_cat AS (
    SELECT
      b.*,
      COALESCE(b.category, p.category, 'unknown') AS final_category
    FROM base b
    LEFT JOIN `dim.dim_products` p USING (product_id)
  ),
  cat_count AS (
    SELECT
      final_category,
      COUNT(*) AS c,
      ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC) AS rn
    FROM with_cat
    GROUP BY final_category
  ),
  agg AS (
    SELECT
      COUNT(*)                            AS total_orders,
      SUM(amount)                         AS total_amount,
      COUNT(DISTINCT user_sk)             AS unique_users
    FROM with_cat
  )
  SELECT
    p_date AS summary_date,
    agg.total_orders,
    agg.total_amount,
    agg.unique_users,
    (SELECT final_category FROM cat_count WHERE rn = 1) AS top_category
  FROM agg;
END;
