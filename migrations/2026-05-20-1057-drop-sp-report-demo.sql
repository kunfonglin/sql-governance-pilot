-- migrations/2026-05-20-1057-drop-sp-report-demo.sql
  -- 對應 git 變更: bigquery/analytics/routines/sp_report_demo.sql 被刪除
  -- 操作: DROP PROCEDURE
  -- 備註: demo 結束、清除測試 SP

  DROP PROCEDURE IF EXISTS `analytics.sp_report_demo`;