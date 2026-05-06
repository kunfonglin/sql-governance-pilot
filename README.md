# sql-governance-pilot

BigQuery SQL governance repo for **pilot**（個人 sandbox 環境，驗證 Phase 1 機制用）。

> Phase 1 範圍：Stored Procedure / Function only. Tables / Views / Migrations 為未來擴充。

---

## SQL 撰寫規範（4 條）

完整版見 [platform docs/sql-rules.md](https://github.com/kunfonglin/sql-governance-platform/blob/v1.0/docs/sql-rules.md)。

| # | 規則 | 範例 |
|---|------|------|
| 1 | 檔案路徑 `bigquery/{dataset}/routines/{name}.sql` | — |
| 2 | 用 `CREATE OR REPLACE PROCEDURE` / `FUNCTION`（冪等） | ✅ |
| 3 | 不寫 project id;跨專案保留完整路徑 + `-- cross-project:` header | `dataset.table` 不是 `project.dataset.table` |
| 4 | 全部使用 Standard SQL | — |

---

## 開發流程

```
1. BQ Studio (sandbox-test) → Repositories → 開個人 workspace（branch = feature/xxx）
2. 編輯 bigquery/{dataset}/routines/sp_xxx.sql
3. 在 BQ Studio 點「執行」直接驗證
4. Commit & Push
5. 開 PR feature → development
6. CI 跑 pr-validate;reviewer approve
7. Merge → 自動 deploy 到 sandbox-test
8. 開 PR development → main → reviewer approve
9. Merge → environment approval gate → approver approve → deploy 到 sandbox-prod
```

---

## 目錄結構

```
bigquery/{dataset}/routines/*.sql     ← SP / FN 程式碼
config/.governance.yaml               ← 環境設定 + exclude 名單
audit/                                ← drift 報告 + 部署 manifest
.github/workflows/                    ← 4 個 thin wrapper（呼叫 platform）
```

---

## 引用的 Platform 版本

`config/.governance.yaml` 內的 `platform.ref`（目前：v1.0）。
升級流程見 [platform docs/onboarding-new-project.md](https://github.com/kunfonglin/sql-governance-platform/blob/v1.0/docs/onboarding-new-project.md).

---

## 監控

- 每日 03:00 UTC 自動跑 drift detector，異常推 TG
- 每次 deploy 寫 `audit/deploys/YYYY-MM-DD-{run}-manifest.json`

## Owner

- Project owner: @kunfonglin
- Platform: kunfonglin/sql-governance-platform
