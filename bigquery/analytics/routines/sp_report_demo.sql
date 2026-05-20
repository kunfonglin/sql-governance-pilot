-- bigquery/analytics/routines/sp_report_demo.sql
  -- routine_type: PROCEDURE
  -- 用途：團隊報告 demo 用，走完新增→修改→刪除完整流程

  CREATE OR REPLACE PROCEDURE `analytics.sp_report_demo`(IN p_label STRING)
  BEGIN
    SELECT
      'V1: initial creation'      AS version,
      p_label                     AS label,
      CURRENT_TIMESTAMP()         AS run_at;
  END;