-- test_setup/cleanup.sql
-- 砍掉測試資料流（DROP 全部 dataset，連帶所有 table / routine）
-- ⚠ 請確認你不需要這些資料再執行

DROP SCHEMA IF EXISTS `raw_data`  CASCADE;
DROP SCHEMA IF EXISTS `staging`   CASCADE;
DROP SCHEMA IF EXISTS `dim`       CASCADE;
DROP SCHEMA IF EXISTS `fact`      CASCADE;
DROP SCHEMA IF EXISTS `analytics` CASCADE;
DROP SCHEMA IF EXISTS `archive`   CASCADE;
