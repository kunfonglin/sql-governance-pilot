-- cross-project: praxis-works-367201.shared.dim_currency
-- 用途：drift 測試專用——驗證「跨專案引用」不會被誤報。測完請移除（git + prod）。
CREATE OR REPLACE PROCEDURE analytics.sp_xproj_demo()
BEGIN
  SELECT code FROM `praxis-works-367201.shared.dim_currency` LIMIT 0;
END;
