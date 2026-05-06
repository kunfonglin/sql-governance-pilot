-- bigquery/analytics/routines/sp_hello_world.sql
-- routine_type: PROCEDURE
-- 第一個樣板 SP — 用來走 PR → dev → prod approval → deploy 端到端流程
-- 部署成功後可改成有實際業務的 SP

CREATE OR REPLACE PROCEDURE `analytics.sp_hello_world`()
BEGIN
  SELECT
    'hello from sql-governance-pilot' AS message,
    CURRENT_TIMESTAMP() AS run_at;
END;
