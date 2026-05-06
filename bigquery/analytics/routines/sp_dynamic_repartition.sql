-- bigquery/analytics/routines/sp_dynamic_repartition.sql
-- routine_type: PROCEDURE
-- Pattern: EXECUTE IMMEDIATE — dynamic SQL，sqlglot 抓不到（測試 lineage 工具的盲點）
-- 在 runtime 由 audit log / INFORMATION_SCHEMA.JOBS 才能看到完整依賴
--
-- 預期 lineage:
--   reads (sqlglot 看不到):  fact.fact_daily_orders   ← 動態組
--   writes (sqlglot 看不到): analytics.daily_partition_metrics  ← 動態組
--
--   執行時 jobs 會顯示真實依賴，所以 from-jobs 模式可以補回

CREATE OR REPLACE PROCEDURE `analytics.sp_dynamic_repartition`(IN p_date DATE)
BEGIN
  DECLARE source_table STRING;
  DECLARE target_table STRING;
  DECLARE sql_text     STRING;

  SET source_table = 'fact.fact_daily_orders';
  SET target_table = 'analytics.daily_partition_metrics';

  -- 動態組 SQL：算指定日期 partition 的 row count，寫進 metrics 表
  SET sql_text = FORMAT("""
    DELETE FROM `%s` WHERE partition_date = DATE('%s');

    INSERT INTO `%s` (partition_date, table_name, row_count)
    SELECT
      DATE('%s') AS partition_date,
      '%s'       AS table_name,
      COUNT(*)   AS row_count
    FROM `%s`
    WHERE order_date = DATE('%s');
  """,
    target_table,                 -- DELETE FROM target
    FORMAT_DATE('%Y-%m-%d', p_date),
    target_table,                 -- INSERT INTO target
    FORMAT_DATE('%Y-%m-%d', p_date),
    source_table,
    source_table,                 -- FROM source
    FORMAT_DATE('%Y-%m-%d', p_date)
  );

  EXECUTE IMMEDIATE sql_text;
END;
