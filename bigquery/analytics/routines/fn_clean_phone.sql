-- bigquery/analytics/routines/fn_clean_phone.sql
-- routine_type: FUNCTION
-- 清理電話號碼（去空白、保留數字與 + 號）
-- 給 sp_merge_dim_users 等 SP 內部呼叫

CREATE OR REPLACE FUNCTION `analytics.fn_clean_phone`(raw_phone STRING)
RETURNS STRING
AS (
  REGEXP_REPLACE(IFNULL(TRIM(raw_phone), ''), r'[^0-9+]', '')
);
