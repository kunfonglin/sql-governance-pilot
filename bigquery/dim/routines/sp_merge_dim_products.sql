-- bigquery/dim/routines/sp_merge_dim_products.sql
-- routine_type: PROCEDURE
-- Pattern: MERGE — SCD Type 1 (overwrite, no history)
--
-- 預期 lineage:
--   reads:  raw_data.products_raw, dim.dim_products
--   writes: dim.dim_products

CREATE OR REPLACE PROCEDURE `dim.sp_merge_dim_products`()
BEGIN
  MERGE `dim.dim_products` T
  USING `raw_data.products_raw` S
  ON T.product_id = S.product_id

  WHEN MATCHED AND (
       T.name     != S.name
    OR T.category != S.category
    OR T.price    != S.price
  )
  THEN UPDATE SET
    name = S.name,
    category = S.category,
    price = S.price,
    updated_at = CURRENT_TIMESTAMP()

  WHEN NOT MATCHED THEN INSERT (product_id, name, category, price, updated_at)
  VALUES (S.product_id, S.name, S.category, S.price, CURRENT_TIMESTAMP());
END;
