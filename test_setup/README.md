# Pilot 皜祈岫鞈?瘚?
> 銝憟項?虜閬?BQ SP 璅∪??葫閰西???蝯?`lineage-extract.py` 頝??蝢拍?蝯??具?
---

## ?湧??嗆?

```
raw_data/                 ?????賢鞈?
  user_orders_raw
  users_raw
  products_raw

   ??sp_load_orders + sp_clean_invalid_orders

staging/                  ??皜?敺?  user_orders_staging
  invalid_orders_log

   ??sp_merge_dim_users + sp_merge_dim_products

dim/                      ??蝬剖漲銵?  dim_users               (SCD Type 2)
  dim_products            (SCD Type 1)

   ??sp_build_daily_orders_fact + sp_update_user_ltv

fact/                     ??鈭祕銵?  fact_daily_orders       (partitioned)
  fact_user_ltv           (accumulating snapshot)

   ??sp_build_daily_summary

analytics/                ????
  daily_summary
  daily_partition_metrics

archive/                  ???瑕摮?  user_orders_archive
```

---

## 銝甈⊥?Setup

??sandbox project嚗tapirus-test-384312`嚗?摨銵?

```bash
# 隤?嚗雿?冽撘?JSON key ??ADC嚗?gcloud config set project tapirus-test-384312

# 1. 撱?dataset
bq query --project_id=tapirus-test-384312 --use_legacy_sql=false \
  < D:/Claude/BQ_Governance/phase1/pilot/test_setup/01-create-datasets.sql

# 2. 撱?table
bq query --project_id=tapirus-test-384312 --use_legacy_sql=false \
  < D:/Claude/BQ_Governance/phase1/pilot/test_setup/02-create-tables.sql

# 3. 蝔格葫閰西???bq query --project_id=tapirus-test-384312 --use_legacy_sql=false \
  < D:/Claude/BQ_Governance/phase1/pilot/test_setup/03-seed-data.sql
```

??甈∟?摰?

```bash
for f in D:/Claude/BQ_Governance/phase1/pilot/test_setup/0*.sql; do
  echo "==> $f"
  bq query --project_id=tapirus-test-384312 --use_legacy_sql=false < "$f"
done
```

---

## ?函蔡???SP / UDF

```bash
# ??platform ??apply-routines.sh嚗???頝???.sql嚗?bash D:/Claude/BQ_Governance/phase1/platform/scripts/apply-routines.sh \
  --project tapirus-test-384312 \
  --root D:/Claude/BQ_Governance/phase1/pilot/bigquery
```

???颱??餉?嚗?霅瑼?嚗?
```bash
for f in D:/Claude/BQ_Governance/phase1/pilot/bigquery/*/routines/*.sql; do
  echo "==> $f"
  bq query --project_id=tapirus-test-384312 --use_legacy_sql=false < "$f"
done
```

---

## 頝????INFORMATION_SCHEMA.JOBS 鞈?

```bash
bq query --project_id=tapirus-test-384312 --use_legacy_sql=false \
  < D:/Claude/BQ_Governance/phase1/pilot/test_setup/run-all-routines.sql
```

頝?敺?`region-us.INFORMATION_SCHEMA.JOBS_BY_PROJECT` ?府??蝝?10+ 蝑?SP CALL 蝝???臭? lineage-extract ?賬?
---

## 頝?lineage 撌亙撽?

```bash
cd D:/Claude/BQ_Governance/phase1/platform

# 敺?jobs ??poetry run python scripts/lineage-extract.py from-jobs \
  --project tapirus-test-384312 --region US --days 1 --db ./lineage.db

# 敺?git ??閫??
poetry run python scripts/lineage-extract.py from-repo \
  --git-root ../pilot/bigquery --db ./lineage.db

# ??閬?poetry run python scripts/lineage-extract.py merge --db ./lineage.db

# ???SP ?勗?
poetry run python scripts/lineage-extract.py report \
  --routine staging.sp_load_orders --db ./lineage.db
```

---

## ??SP ????lineage???扯”

撽?撌亙甇?Ⅱ?抒??蝑?qlglot ?府????untime jobs ?府???
| SP | ?湔 | reads (?府?) | writes (?府?) | 撌亙?脤? |
|---|---|---|---|---|
| `staging.sp_load_orders` | TRUNCATE + INSERT | `raw_data.user_orders_raw` | `staging.user_orders_staging` (DELETE+INSERT) | ??|
| `staging.sp_clean_invalid_orders` | 憭?write target | `raw_data.user_orders_raw` | `staging.invalid_orders_log` (INSERT)<br>`raw_data.user_orders_raw` (DELETE) | ??|
| `dim.sp_merge_dim_users` | MERGE SCD-2 + UDF call | `raw_data.users_raw`, `dim.dim_users` | `dim.dim_users` | UDF call (`fn_clean_phone`, `fn_user_segment`) sqlglot ????|
| `dim.sp_merge_dim_products` | MERGE SCD-1 | `raw_data.products_raw`, `dim.dim_products` | `dim.dim_products` | ??|
| `fact.sp_build_daily_orders_fact` | TEMP TABLE + 頝典? dataset | `staging.user_orders_staging`, `dim.dim_users`, `dim.dim_products` | `fact.fact_daily_orders` | TEMP TABLE 銝凋??航霈?鈭極?瑁炊??|
| `fact.sp_update_user_ltv` | UPDATE + INSERT (self-read) | `fact.fact_daily_orders`, `dim.dim_users`, `fact.fact_user_ltv` | `fact.fact_user_ltv` | self-read/write 撠?鈭極?琿 |
| `analytics.sp_build_daily_summary` | 憭?CTE + DELETE+INSERT | `fact.fact_daily_orders`, `dim.dim_products` | `analytics.daily_summary` | ??|
| `analytics.sp_dynamic_repartition` | EXECUTE IMMEDIATE | (sqlglot: ????<br>(jobs: `fact.fact_daily_orders`) | (sqlglot: ????<br>(jobs: `analytics.daily_partition_metrics`) | **??皜祈岫**嚗qlglot 銝摰?銝嚗obs ?鋆?|
| `archive.sp_archive_old_orders` | INSERT ??archive + DELETE source | `staging.user_orders_staging` | `archive.user_orders_archive` (INSERT)<br>`staging.user_orders_staging` (DELETE) | ??|
| `analytics.sp_run_daily_pipeline` | orchestrator (CALL chain) | (??table ?湔霈) | (??table ?湔撖? | **SP?P edge** ?桀?撌亙銝?嚗撌脩? |

UDF嚗?
| UDF | ?券?| 鋡怨狐 call |
|---|---|---|
| `analytics.fn_clean_phone` | 皜閰?| `dim.sp_merge_dim_users` |
| `analytics.fn_user_segment` | ??摰嗆挾 | `dim.sp_merge_dim_users` |

---

## ?蔭 / ???毀

```bash
bq query --project_id=tapirus-test-384312 --use_legacy_sql=false \
  < D:/Claude/BQ_Governance/phase1/pilot/test_setup/cleanup.sql
```

????DROP ?券 6 ??dataset嚗???table ??routine嚗?
---

## 瘜冽?

- ?? SP / UDF / table ??*皜祈岫鞈?瘚?*嚗??舐?甇?? governance 撠情???摰Ⅱ撖行??`bigquery/{schema}/routines/` 銝??隞?governance CI/CD嚗?敺?Phase 1 摰頝?嚗????甇?? routine ?函蔡????嚗隞亙 `governance.yaml` ??`exclude.routines` ?脣嚗??停??? demo flow 銝韏瑟祥?? OK??- 蝔桀?鞈??芣? 15 蝑??殷?頝靘? `daily_summary` ?詨?撠?雿?lineage edges ?賊??舐?撖衣???- 頝典?獢?ref 瘝葫 ????閬??血???GCP project 蝯虫?皞hase 1 ?思??整?