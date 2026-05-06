-- bigquery/analytics/routines/fn_user_segment.sql
-- routine_type: FUNCTION
-- 依國家碼回傳使用者區段
-- 給 sp_merge_dim_users 用

CREATE OR REPLACE FUNCTION `analytics.fn_user_segment`(country STRING)
RETURNS STRING
AS (
  CASE country
    WHEN 'TW' THEN 'TW-Domestic'
    WHEN 'US' THEN 'NA'
    WHEN 'JP' THEN 'APAC-JP'
    WHEN 'UK' THEN 'EMEA'
    ELSE 'Other'
  END
);
