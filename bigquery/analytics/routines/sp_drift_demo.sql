CREATE OR REPLACE PROCEDURE `analytics.sp_drift_demo`(IN p_note STRING)
  BEGIN
   -- bigquery/analytics/routines/sp_drift_demo.sql
  -- routine_type: PROCEDURE
  -- 用途：練習 migration 機制 + drift detector 測試用
  -- 生命週期：新增 → 練習編輯 → drift 測試 → 用 migration 刪除
    -- 完全自包含，不依賴任何 table，安全好刪
    SELECT
      'drift demo'                AS source,
      p_note                      AS note,
      CURRENT_TIMESTAMP()         AS run_at,
      @@dataset_project_id        AS deployed_in,
      SESSION_USER()              AS executed_by;
  END;