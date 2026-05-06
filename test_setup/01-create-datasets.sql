-- test_setup/01-create-datasets.sql
-- 一次性執行：建立測試資料流的 5 個 dataset
-- 在 sandbox project（tapirus-test-384312）執行
-- region: US

-- 注意：手動執行，不走 governance CI/CD（Phase 1 不管 dataset DDL）

CREATE SCHEMA IF NOT EXISTS `raw_data`
OPTIONS (
  description = 'Test dataflow: raw landed data',
  labels = [('purpose','governance-test'), ('layer','raw')]
);

CREATE SCHEMA IF NOT EXISTS `staging`
OPTIONS (
  description = 'Test dataflow: cleansed staging',
  labels = [('purpose','governance-test'), ('layer','staging')]
);

CREATE SCHEMA IF NOT EXISTS `dim`
OPTIONS (
  description = 'Test dataflow: dimensional tables',
  labels = [('purpose','governance-test'), ('layer','dim')]
);

CREATE SCHEMA IF NOT EXISTS `fact`
OPTIONS (
  description = 'Test dataflow: fact tables',
  labels = [('purpose','governance-test'), ('layer','fact')]
);

CREATE SCHEMA IF NOT EXISTS `analytics`
OPTIONS (
  description = 'Test dataflow: aggregations',
  labels = [('purpose','governance-test'), ('layer','analytics')]
);

CREATE SCHEMA IF NOT EXISTS `archive`
OPTIONS (
  description = 'Test dataflow: cold storage',
  labels = [('purpose','governance-test'), ('layer','archive')]
);
