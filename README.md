# sql-governance-pilot

BigQuery SQL governance repo for **pilot**嚗犖 sandbox ?啣?嚗?霅?Phase 1 璈?剁???
> Phase 1 蝭?嚗tored Procedure / Function only. Tables / Views / Migrations ?箸靘??
---

## SQL ?啣神閬?嚗? 璇?

摰?? [platform docs/sql-rules.md](https://github.com/kunfonglin/sql-governance-platform/blob/v1.0/docs/sql-rules.md)??
| # | 閬? | 蝭? |
|---|------|------|
| 1 | 瑼?頝臬? `bigquery/{dataset}/routines/{name}.sql` | ??|
| 2 | ??`CREATE OR REPLACE PROCEDURE` / `FUNCTION`嚗蝑? | ??|
| 3 | 銝神 project id嚗楊撠?靽?摰頝臬? + `-- cross-project:` header | `dataset.table` 銝 `project.dataset.table` |
| 4 | ?券雿輻 Standard SQL | ??|

---

## ?瘚?

```
1. BQ Studio (sandbox-test) ??Repositories ???犖 workspace嚗ranch = feature/xxx嚗?2. 蝺刻摩 bigquery/{dataset}/routines/sp_xxx.sql
3. ??BQ Studio 暺銵?仿?霅?4. Commit & Push
5. ??PR feature ??development
6. CI 頝?pr-validate嚗eviewer approve
7. Merge ???芸? deploy ??sandbox-test
8. ??PR development ??main ??reviewer approve
9. Merge ??environment approval gate ??approver approve ??deploy ??sandbox-prod
```

---

## ?桅?蝯?

```
bigquery/{dataset}/routines/*.sql     ??SP / FN 蝔?蝣?config/.governance.yaml               ???啣?閮剖? + exclude ?
audit/                                ??drift ?勗? + ?函蔡 manifest
.github/workflows/                    ??4 ??thin wrapper嚗??platform嚗?```

---

## 撘??Platform ?

`config/.governance.yaml` ?抒? `platform.ref`嚗??v1.0嚗???瘚?閬?[platform docs/onboarding-new-project.md](https://github.com/kunfonglin/sql-governance-platform/blob/v1.0/docs/onboarding-new-project.md).

---

## ??

- 瘥 03:00 UTC ?芸?頝?drift detector嚗撣豢 TG
- 瘥活 deploy 撖?`audit/deploys/YYYY-MM-DD-{run}-manifest.json`

## Owner

- Project owner: @kunfonglin
- Platform: kunfonglin/sql-governance-platform
