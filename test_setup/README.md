# Pilot 測試資料流

> 一套涵蓋常見 BQ SP 模式的測試資料，給 `lineage-extract.py` 跑出有意義的結果用。

---

## 整體架構

```
raw_data/                 ← 原始落地資料
  user_orders_raw
  users_raw
  products_raw

   ↓ sp_load_orders + sp_clean_invalid_orders

staging/                  ← 清洗後
  user_orders_staging
  invalid_orders_log

   ↓ sp_merge_dim_users + sp_merge_dim_products

dim/                      ← 維度表
  dim_users               (SCD Type 2)
  dim_products            (SCD Type 1)

   ↓ sp_build_daily_orders_fact + sp_update_user_ltv

fact/                     ← 事實表
  fact_daily_orders       (partitioned)
  fact_user_ltv           (accumulating snapshot)

   ↓ sp_build_daily_summary

analytics/                ← 聚合
  daily_summary
  daily_partition_metrics

archive/                  ← 冷儲存
  user_orders_archive
```

---

## 一次性 Setup

在 sandbox project（`tapirus-test-384312`）依序執行：

```bash
# 認證（用你慣用方式：JSON key 或 ADC）
gcloud config set project tapirus-test-384312

# 1. 建 dataset
bq query --project_id=tapirus-test-384312 --use_legacy_sql=false \
  < D:/Claude/BQ_Governance/phase1/pilot/test_setup/01-create-datasets.sql

# 2. 建 table
bq query --project_id=tapirus-test-384312 --use_legacy_sql=false \
  < D:/Claude/BQ_Governance/phase1/pilot/test_setup/02-create-tables.sql

# 3. 種測試資料
bq query --project_id=tapirus-test-384312 --use_legacy_sql=false \
  < D:/Claude/BQ_Governance/phase1/pilot/test_setup/03-seed-data.sql
```

或一次跑完：

```bash
for f in D:/Claude/BQ_Governance/phase1/pilot/test_setup/0*.sql; do
  echo "==> $f"
  bq query --project_id=tapirus-test-384312 --use_legacy_sql=false < "$f"
done
```

---

## 部署所有 SP / UDF

```bash
# 用 platform 的 apply-routines.sh（或手動跑每個 .sql）
bash D:/Claude/BQ_Governance/phase1/platform/scripts/apply-routines.sh \
  --project tapirus-test-384312 \
  --root D:/Claude/BQ_Governance/phase1/pilot/bigquery
```

或一隻一隻跑（驗證單檔）：

```bash
for f in D:/Claude/BQ_Governance/phase1/pilot/bigquery/*/routines/*.sql; do
  echo "==> $f"
  bq query --project_id=tapirus-test-384312 --use_legacy_sql=false < "$f"
done
```

---

## 跑一遍產生 INFORMATION_SCHEMA.JOBS 資料

```bash
bq query --project_id=tapirus-test-384312 --use_legacy_sql=false \
  < D:/Claude/BQ_Governance/phase1/pilot/test_setup/run-all-routines.sql
```

跑完後，`region-us.INFORMATION_SCHEMA.JOBS_BY_PROJECT` 應該會有約 10+ 筆 SP CALL 紀錄，可供 lineage-extract 抽。

---

## 跑 lineage 工具驗證

```bash
cd D:/Claude/BQ_Governance/phase1/platform

# 從 jobs 抽
poetry run python scripts/lineage-extract.py from-jobs \
  --project tapirus-test-384312 --region US --days 1 --db ./lineage.db

# 從 git 靜態解析
poetry run python scripts/lineage-extract.py from-repo \
  --git-root ../pilot/bigquery --db ./lineage.db

# 看摘要
poetry run python scripts/lineage-extract.py merge --db ./lineage.db

# 看單支 SP 報告
poetry run python scripts/lineage-extract.py report \
  --routine staging.sp_load_orders --db ./lineage.db
```

---

## 各 SP 的「期望 lineage」對照表

驗證工具正確性用。每筆都列「sqlglot 應該抓到」+「runtime jobs 應該抓到」。

| SP | 場景 | reads (應該抓到) | writes (應該抓到) | 工具盲點 |
|---|---|---|---|---|
| `staging.sp_load_orders` | TRUNCATE + INSERT | `raw_data.user_orders_raw` | `staging.user_orders_staging` (DELETE+INSERT) | — |
| `staging.sp_clean_invalid_orders` | 多 write target | `raw_data.user_orders_raw` | `staging.invalid_orders_log` (INSERT)<br>`raw_data.user_orders_raw` (DELETE) | — |
| `dim.sp_merge_dim_users` | MERGE SCD-2 + UDF call | `raw_data.users_raw`, `dim.dim_users` | `dim.dim_users` | UDF call (`fn_clean_phone`, `fn_user_segment`) sqlglot 抓不到 |
| `dim.sp_merge_dim_products` | MERGE SCD-1 | `raw_data.products_raw`, `dim.dim_products` | `dim.dim_products` | — |
| `fact.sp_build_daily_orders_fact` | TEMP TABLE + 跨多 dataset | `staging.user_orders_staging`, `dim.dim_users`, `dim.dim_products` | `fact.fact_daily_orders` | TEMP TABLE 中介可能讓某些工具誤判 |
| `fact.sp_update_user_ltv` | UPDATE + INSERT (self-read) | `fact.fact_daily_orders`, `dim.dim_users`, `fact.fact_user_ltv` | `fact.fact_user_ltv` | self-read/write 對某些工具難 |
| `analytics.sp_build_daily_summary` | 多 CTE + DELETE+INSERT | `fact.fact_daily_orders`, `dim.dim_products` | `analytics.daily_summary` | — |
| `analytics.sp_dynamic_repartition` | EXECUTE IMMEDIATE | (sqlglot: 看不到)<br>(jobs: `fact.fact_daily_orders`) | (sqlglot: 看不到)<br>(jobs: `analytics.daily_partition_metrics`) | **最關鍵測試**：sqlglot 一定抓不到，jobs 才能補 |
| `archive.sp_archive_old_orders` | INSERT 到 archive + DELETE source | `staging.user_orders_staging` | `archive.user_orders_archive` (INSERT)<br>`staging.user_orders_staging` (DELETE) | — |
| `analytics.sp_run_daily_pipeline` | orchestrator (CALL chain) | (無 table 直接讀) | (無 table 直接寫) | **SP→SP edge** 目前工具不抓，是已知限制 |

UDF：

| UDF | 用途 | 被誰 call |
|---|---|---|
| `analytics.fn_clean_phone` | 清電話 | `dim.sp_merge_dim_users` |
| `analytics.fn_user_segment` | 分國家段 | `dim.sp_merge_dim_users` |

---

## 重置 / 砍掉重練

```bash
bq query --project_id=tapirus-test-384312 --use_legacy_sql=false \
  < D:/Claude/BQ_Governance/phase1/pilot/test_setup/cleanup.sql
```

⚠ 會 DROP 全部 6 個 dataset（含所有 table 與 routine）。

---

## 注意

- 這些 SP / UDF / table 是**測試資料流**，不是真正的 governance 對象。但因為它們確實放在 `bigquery/{schema}/routines/` 下，所以 governance CI/CD（之後 Phase 1 完整跑時）會把它們當正式 routine 部署。如果想隔離，可以在 `governance.yaml` 的 `exclude.routines` 加進去；或者就把它們當 demo flow 一起治理也 OK。
- 種子資料只有 15 筆訂單，跑出來的 `daily_summary` 數字小，但 lineage edges 數量是真實的。
- 跨專案 ref 沒測 — 這需要你另外的 GCP project 給來源。Phase 1 暫不放。
