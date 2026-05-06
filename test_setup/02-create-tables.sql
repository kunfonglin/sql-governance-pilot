-- test_setup/02-create-tables.sql
-- 一次性執行：建立測試資料流的所有 base table
-- 全部用 CREATE TABLE IF NOT EXISTS（重複跑安全）

-- ============================================================
-- raw_data layer — 原始落地資料
-- ============================================================

CREATE TABLE IF NOT EXISTS `raw_data.user_orders_raw` (
  order_id      STRING        NOT NULL,
  user_id       STRING        NOT NULL,
  product_id    STRING        NOT NULL,
  amount        NUMERIC(18,2),
  order_date    DATE          NOT NULL,
  status        STRING,
  raw_loaded_at TIMESTAMP     DEFAULT CURRENT_TIMESTAMP()
)
PARTITION BY order_date
OPTIONS (description = 'Raw daily orders from upstream');

CREATE TABLE IF NOT EXISTS `raw_data.users_raw` (
  user_id       STRING        NOT NULL,
  name          STRING,
  phone         STRING,
  email         STRING,
  signup_date   DATE,
  country       STRING,
  raw_loaded_at TIMESTAMP     DEFAULT CURRENT_TIMESTAMP()
)
OPTIONS (description = 'Raw user master');

CREATE TABLE IF NOT EXISTS `raw_data.products_raw` (
  product_id    STRING        NOT NULL,
  name          STRING,
  category      STRING,
  price         NUMERIC(18,2),
  raw_loaded_at TIMESTAMP     DEFAULT CURRENT_TIMESTAMP()
)
OPTIONS (description = 'Raw product catalog');

-- ============================================================
-- staging layer — 清洗後資料
-- ============================================================

CREATE TABLE IF NOT EXISTS `staging.user_orders_staging` (
  order_id      STRING        NOT NULL,
  user_id       STRING        NOT NULL,
  product_id    STRING        NOT NULL,
  amount        NUMERIC(18,2) NOT NULL,
  order_date    DATE          NOT NULL,
  status        STRING        NOT NULL,
  cleaned_at    TIMESTAMP     DEFAULT CURRENT_TIMESTAMP()
)
PARTITION BY order_date
CLUSTER BY user_id
OPTIONS (description = 'Cleansed daily orders ready for fact build');

CREATE TABLE IF NOT EXISTS `staging.invalid_orders_log` (
  order_id     STRING       NOT NULL,
  reason       STRING       NOT NULL,
  raw_payload  STRING,
  logged_at    TIMESTAMP    DEFAULT CURRENT_TIMESTAMP()
)
PARTITION BY DATE(logged_at)
OPTIONS (description = 'Orders that failed validation, kept for ops triage');

-- ============================================================
-- dim layer — 維度表
-- ============================================================

CREATE TABLE IF NOT EXISTS `dim.dim_users` (
  user_sk        INT64       NOT NULL,    -- surrogate key
  user_id        STRING      NOT NULL,
  name           STRING,
  phone_clean    STRING,
  email          STRING,
  country        STRING,
  segment        STRING,
  valid_from     TIMESTAMP   NOT NULL,
  valid_to       TIMESTAMP,
  is_current     BOOL        NOT NULL
)
CLUSTER BY user_id
OPTIONS (description = 'SCD-Type-2 dimension of users');

CREATE TABLE IF NOT EXISTS `dim.dim_products` (
  product_id   STRING       NOT NULL,
  name         STRING,
  category     STRING,
  price        NUMERIC(18,2),
  updated_at   TIMESTAMP    DEFAULT CURRENT_TIMESTAMP()
)
OPTIONS (description = 'SCD-Type-1 product dimension');

-- ============================================================
-- fact layer — 事實表
-- ============================================================

CREATE TABLE IF NOT EXISTS `fact.fact_daily_orders` (
  order_date     DATE          NOT NULL,
  order_id       STRING        NOT NULL,
  user_sk        INT64,
  product_id     STRING,
  category       STRING,
  amount         NUMERIC(18,2),
  status         STRING,
  built_at       TIMESTAMP     DEFAULT CURRENT_TIMESTAMP()
)
PARTITION BY order_date
CLUSTER BY user_sk
OPTIONS (description = 'Daily orders fact, partitioned by date');

CREATE TABLE IF NOT EXISTS `fact.fact_user_ltv` (
  user_id        STRING        NOT NULL,
  total_orders   INT64,
  total_amount   NUMERIC(18,2),
  first_order_at DATE,
  last_order_at  DATE,
  updated_at     TIMESTAMP     DEFAULT CURRENT_TIMESTAMP()
)
CLUSTER BY user_id
OPTIONS (description = 'Per-user lifetime value, accumulating snapshot');

-- ============================================================
-- analytics layer — 聚合
-- ============================================================

CREATE TABLE IF NOT EXISTS `analytics.daily_summary` (
  summary_date     DATE        NOT NULL,
  total_orders     INT64,
  total_amount     NUMERIC(18,2),
  unique_users     INT64,
  top_category     STRING,
  built_at         TIMESTAMP   DEFAULT CURRENT_TIMESTAMP()
)
PARTITION BY summary_date
OPTIONS (description = 'Daily KPI summary');

CREATE TABLE IF NOT EXISTS `analytics.daily_partition_metrics` (
  partition_date  DATE        NOT NULL,
  table_name      STRING      NOT NULL,
  row_count       INT64,
  computed_at     TIMESTAMP   DEFAULT CURRENT_TIMESTAMP()
)
PARTITION BY partition_date
OPTIONS (description = 'Per-partition rowcount metrics, written by sp_dynamic_repartition');

-- ============================================================
-- archive layer — 冷儲存
-- ============================================================

CREATE TABLE IF NOT EXISTS `archive.user_orders_archive` (
  order_id      STRING        NOT NULL,
  user_id       STRING        NOT NULL,
  product_id    STRING        NOT NULL,
  amount        NUMERIC(18,2),
  order_date    DATE          NOT NULL,
  status        STRING,
  archived_at   TIMESTAMP     DEFAULT CURRENT_TIMESTAMP()
)
PARTITION BY order_date
OPTIONS (description = 'Archived old orders');
