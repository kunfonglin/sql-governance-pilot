-- bigquery/analytics/routines/sp_run_daily_pipeline.sql
-- routine_type: PROCEDURE
-- Pattern: orchestrator — 純 CALL 鏈（測試 SP→SP 依賴）
-- 不直接讀寫任何表，但會觸發整條 pipeline
--
-- 預期 lineage（如果工具支援 SP→SP edge）:
--   calls:  staging.sp_load_orders, staging.sp_clean_invalid_orders,
--           dim.sp_merge_dim_users, dim.sp_merge_dim_products,
--           fact.sp_build_daily_orders_fact, fact.sp_update_user_ltv,
--           analytics.sp_build_daily_summary
--
-- 目前 lineage-extract.py from-jobs 模式抓不到 SP→SP（只抓 SP→table），
-- 但 sqlglot 模式可加偵測（之後升級）。

-- strict_mode=false: orchestrator 在 CREATE 時不驗證 CALL 的 SP 是否存在
-- 必要設定，因為部署順序 alphabetical，被 CALL 的 SP 可能還沒建好
-- 實際 SP 不存在的錯誤會在 runtime 才報

CREATE OR REPLACE PROCEDURE `analytics.sp_run_daily_pipeline`(IN p_date DATE)
OPTIONS(strict_mode=false)
BEGIN
  -- Layer 1: raw → staging
  CALL `staging.sp_load_orders`(p_date);
  CALL `staging.sp_clean_invalid_orders`();

  -- Layer 2: dimensions
  CALL `dim.sp_merge_dim_users`();
  CALL `dim.sp_merge_dim_products`();

  -- Layer 3: facts
  CALL `fact.sp_build_daily_orders_fact`(p_date);
  CALL `fact.sp_update_user_ltv`();

  -- Layer 4: aggregations
  CALL `analytics.sp_build_daily_summary`(p_date);
END;
