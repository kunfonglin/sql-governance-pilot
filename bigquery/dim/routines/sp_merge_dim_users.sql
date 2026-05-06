-- bigquery/dim/routines/sp_merge_dim_users.sql
-- routine_type: PROCEDURE
-- Pattern: MERGE — SCD Type 2（insert new + close old + insert new version）
-- 額外用了 UDF：fn_clean_phone, fn_user_segment
--
-- 預期 lineage:
--   reads:  raw_data.users_raw, dim.dim_users  (MERGE source = raw, target = dim)
--   writes: dim.dim_users
--   uses:   analytics.fn_clean_phone, analytics.fn_user_segment  (UDF call — 進階偵測)

CREATE OR REPLACE PROCEDURE `dim.sp_merge_dim_users`()
BEGIN
  DECLARE max_sk INT64;

  -- 取目前最大的 surrogate key，新 row 從這號開始往下發
  SET max_sk = (SELECT IFNULL(MAX(user_sk), 0) FROM `dim.dim_users`);

  MERGE `dim.dim_users` T
  USING (
    SELECT
      -- 在子查詢內預先算好新 SK，MERGE 內 INSERT VALUES 不能放 window function
      max_sk + ROW_NUMBER() OVER (ORDER BY user_id) AS new_user_sk,
      user_id,
      name,
      `analytics.fn_clean_phone`(phone) AS phone_clean,
      email,
      country,
      `analytics.fn_user_segment`(country) AS segment
    FROM `raw_data.users_raw`
  ) S
  ON T.user_id = S.user_id AND T.is_current = TRUE

  -- 如果有變更 → 把舊版收尾、之後 INSERT 新版
  WHEN MATCHED AND (
       T.name        != S.name
    OR T.phone_clean != S.phone_clean
    OR T.email       != S.email
    OR T.country     != S.country
    OR T.segment     != S.segment
  )
  THEN UPDATE SET valid_to = CURRENT_TIMESTAMP(), is_current = FALSE

  -- 全新 user → 直接插入（用子查詢預算好的 new_user_sk）
  WHEN NOT MATCHED THEN INSERT
    (user_sk, user_id, name, phone_clean, email, country, segment, valid_from, valid_to, is_current)
  VALUES (
    S.new_user_sk,
    S.user_id, S.name, S.phone_clean, S.email, S.country, S.segment,
    CURRENT_TIMESTAMP(), CAST(NULL AS TIMESTAMP), TRUE
  );

  -- 第二段：對「剛被 closed 的」user 補插新版本
  -- (BQ MERGE 不支援同一 statement 內既 close 又 insert 新 row，所以分兩步)
  INSERT INTO `dim.dim_users`
    (user_sk, user_id, name, phone_clean, email, country, segment, valid_from, valid_to, is_current)
  SELECT
    max_sk + 1000 + ROW_NUMBER() OVER (ORDER BY r.user_id) AS user_sk,
    r.user_id,
    r.name,
    `analytics.fn_clean_phone`(r.phone) AS phone_clean,
    r.email,
    r.country,
    `analytics.fn_user_segment`(r.country) AS segment,
    CURRENT_TIMESTAMP() AS valid_from,
    CAST(NULL AS TIMESTAMP) AS valid_to,
    TRUE AS is_current
  FROM `raw_data.users_raw` r
  WHERE r.user_id IN (
    SELECT user_id FROM `dim.dim_users`
    WHERE is_current = FALSE AND valid_to >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 1 MINUTE)
  );
END;
