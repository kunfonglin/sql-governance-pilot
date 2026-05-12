-- migrations/2026-05-07-1400-drop-sp-hello-world.sql
-- 對應 git 變更: bigquery/analytics/routines/sp_hello_world.sql 被刪除
-- 操作: DROP SP（test + prod 都會跑）
-- 備註: 情境 C 第一個 migration，驗證 Phase 1 v1.1 migration 機制
--       sp_hello_world 是測試用 SP，已不需要

DROP PROCEDURE IF EXISTS `analytics.sp_hello_world`;
