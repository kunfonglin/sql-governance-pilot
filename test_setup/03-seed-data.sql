-- test_setup/03-seed-data.sql
-- 種一些測試資料給 SP 跑出有意義的結果
-- 重複跑：先 truncate raw 表再插入（避免重複 key）

-- ============================================================
-- raw_data.users_raw — 10 個使用者
-- ============================================================

TRUNCATE TABLE `raw_data.users_raw`;

INSERT INTO `raw_data.users_raw` (user_id, name, phone, email, signup_date, country) VALUES
  ('U001', 'Alice Wang',     '+886-912-345-678',  'alice@example.com',  DATE '2025-01-15', 'TW'),
  ('U002', 'Bob Chen',       ' 0987-654-321 ',    'bob@example.com',    DATE '2025-02-20', 'TW'),
  ('U003', 'Carol Lee',      '+1-415-555-0100',   'carol@example.com',  DATE '2025-03-05', 'US'),
  ('U004', 'David Wu',       'invalid-phone',     'david@example.com',  DATE '2025-04-10', 'TW'),
  ('U005', 'Eve Lin',        '+44 20 7946 0958',  'eve@example.com',    DATE '2025-05-22', 'UK'),
  ('U006', 'Frank Ho',       '+886-933-111-222',  'frank@example.com',  DATE '2025-06-01', 'TW'),
  ('U007', 'Grace Cheng',    '+886-955-333-444',  'grace@example.com',  DATE '2025-07-12', 'TW'),
  ('U008', 'Henry Tsai',     '+1-650-555-0199',   'henry@example.com',  DATE '2025-08-03', 'US'),
  ('U009', 'Ivy Su',         '+81 3-1234-5678',   'ivy@example.com',    DATE '2025-09-18', 'JP'),
  ('U010', 'Jack Liu',       '+886-922-777-888',  'jack@example.com',   DATE '2025-10-25', 'TW');

-- ============================================================
-- raw_data.products_raw — 5 個產品
-- ============================================================

TRUNCATE TABLE `raw_data.products_raw`;

INSERT INTO `raw_data.products_raw` (product_id, name, category, price) VALUES
  ('P001', 'Wireless Mouse',   'electronics',  29.99),
  ('P002', 'Mechanical Keyboard', 'electronics', 119.99),
  ('P003', 'Coffee Beans 1kg', 'grocery',      24.50),
  ('P004', 'Yoga Mat',         'sports',       45.00),
  ('P005', 'Fiction Novel',    'books',         12.99);

-- ============================================================
-- raw_data.user_orders_raw — 過去 7 天每天 1-3 筆
-- 包含 1 筆故意壞掉的（amount NULL）給 sp_clean_invalid_orders 測試用
-- ============================================================

TRUNCATE TABLE `raw_data.user_orders_raw`;

INSERT INTO `raw_data.user_orders_raw` (order_id, user_id, product_id, amount, order_date, status) VALUES
  ('O0000001', 'U001', 'P001',  29.99, DATE_SUB(CURRENT_DATE(), INTERVAL 6 DAY), 'completed'),
  ('O0000002', 'U002', 'P002', 119.99, DATE_SUB(CURRENT_DATE(), INTERVAL 6 DAY), 'completed'),
  ('O0000003', 'U003', 'P003',  24.50, DATE_SUB(CURRENT_DATE(), INTERVAL 5 DAY), 'completed'),
  ('O0000004', 'U001', 'P004',  45.00, DATE_SUB(CURRENT_DATE(), INTERVAL 5 DAY), 'refunded'),
  ('O0000005', 'U005', 'P005',  12.99, DATE_SUB(CURRENT_DATE(), INTERVAL 4 DAY), 'completed'),
  ('O0000006', 'U006', 'P001',  29.99, DATE_SUB(CURRENT_DATE(), INTERVAL 4 DAY), 'completed'),
  ('O0000007', 'U007', 'P002', 119.99, DATE_SUB(CURRENT_DATE(), INTERVAL 3 DAY), 'completed'),
  ('O0000008', 'U008', 'P003',  24.50, DATE_SUB(CURRENT_DATE(), INTERVAL 3 DAY), 'cancelled'),
  ('O0000009', 'U009', 'P004',  45.00, DATE_SUB(CURRENT_DATE(), INTERVAL 2 DAY), 'completed'),
  ('O0000010', 'U010', 'P005',  12.99, DATE_SUB(CURRENT_DATE(), INTERVAL 2 DAY), 'completed'),
  ('O0000011', 'U001', 'P002', 119.99, DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY), 'completed'),
  ('O0000012', 'U002', 'P001',  29.99, DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY), 'completed'),
  ('O0000013', 'U003', 'P005',  12.99, CURRENT_DATE(), 'pending'),
  ('O0000014', 'U004', 'P004',   NULL, CURRENT_DATE(), 'pending'),    -- 故意壞，測 sp_clean_invalid_orders
  ('O0000015', 'U005', 'P003',  24.50, CURRENT_DATE(), 'completed');
