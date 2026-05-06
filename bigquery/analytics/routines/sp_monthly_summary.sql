-- bigquery/analytics/routines/sp_monthly_summary.sql
  -- routine_type: PROCEDURE
  -- 月度匯總：從 daily_summary 聚合到月份級

  CREATE OR REPLACE PROCEDURE `analytics.sp_monthly_summary`(IN p_year_month STRING)
  BEGIN
    -- p_year_month 格式：'YYYY-MM' 例如 '2026-05'
    SELECT
      p_year_month                  AS year_month,
      COUNT(DISTINCT summary_date)  AS days_with_data,
      SUM(total_orders)             AS total_orders,
      SUM(total_amount)             AS total_amount,
      AVG(unique_users)             AS avg_daily_unique_users
    FROM `analytics.daily_summary`
    WHERE FORMAT_DATE('%Y-%m', summary_date) = p_year_month;
  END;