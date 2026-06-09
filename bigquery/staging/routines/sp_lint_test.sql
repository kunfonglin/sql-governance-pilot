-- ⚠️ 故意違規：硬寫了正式機 project id（tapirus-test-384312），
--    用來演練 project-id lint 會在 PR 擋下。測完請刪這支。
CREATE OR REPLACE PROCEDURE staging.sp_lint_test()
BEGIN
  SELECT * FROM `tapirus-test-384312.staging.user_orders_staging` LIMIT 0;
END;
