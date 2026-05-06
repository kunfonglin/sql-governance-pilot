-- test_setup/run-all-routines.sql
-- 執行所有 SP 一次，產生 INFORMATION_SCHEMA.JOBS 紀錄供 lineage 分析
-- 預設執行「今天日期」，可改參數

DECLARE target_date DATE DEFAULT CURRENT_DATE();

-- Layer 1: raw → staging
CALL `staging.sp_load_orders`(target_date);
CALL `staging.sp_clean_invalid_orders`();

-- Layer 2: build dimensions
CALL `dim.sp_merge_dim_users`();
CALL `dim.sp_merge_dim_products`();

-- Layer 3: build facts
CALL `fact.sp_build_daily_orders_fact`(target_date);
CALL `fact.sp_update_user_ltv`();

-- Layer 4: aggregations
CALL `analytics.sp_build_daily_summary`(target_date);

-- Side flows
CALL `analytics.sp_dynamic_repartition`(target_date);
CALL `archive.sp_archive_old_orders`(DATE_SUB(target_date, INTERVAL 5 DAY));

-- Or just run the orchestrator (which does most of the above)
-- CALL `analytics.sp_run_daily_pipeline`(target_date);
