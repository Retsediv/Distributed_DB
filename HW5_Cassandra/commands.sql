-- 0. Create Keyspace
CREATE KEYSPACE IF NOT EXISTS shop
WITH REPLICATION = {
  'class' : 'SimpleStrategy',
  'replication_factor' : 1
};
USE shop;

-- 0.1 Model the table
CREATE TABLE IF NOT EXISTS items (
  category text,
  price decimal,
  id uuid,
  name text,
  manufacturer text,
  properties map<text, text>,
  PRIMARY KEY (category, price, id)
) WITH CLUSTERING ORDER BY (price ASC);

-- 0.2 Create an index to search in the properties map
CREATE INDEX IF NOT EXISTS idx_properties ON items(properties);

-- 0.3 Add data
BEGIN BATCH
  INSERT INTO items (category, price, id, name, manufacturer, properties)
  VALUES (
    'electronics',
    299.99,
    uuid(),
    'Smartphone X',
    'BrandY',
    {'color': 'black', 'memory': '128GB', 'battery': '3000mAh'}
  );

  INSERT INTO items (category, price, id, name, manufacturer, properties)
  VALUES (
    'electronics',
    999.99,
    uuid(),
    'Laptop Pro',
    'BrandZ',
    {'processor': 'i7', 'RAM': '16GB', 'storage': '512GB', 'screen': '15 inch'}
  );

  INSERT INTO items (category, price, id, name, manufacturer, properties)
  VALUES (
    'clothing',
    49.99,
    uuid(),
    'T-shirt',
    'FashionCo',
    {'color': 'blue', 'size': 'M', 'material': 'cotton'}
  );

  INSERT INTO items (category, price, id, name, manufacturer, properties)
  VALUES (
    'electronics',
    149.99,
    uuid(),
    'Wireless Headphones',
    'SoundMaster',
    {'color': 'white', 'battery_life': '20h', 'connectivity': 'Bluetooth'}
  );
APPLY BATCH;


-- 1. Напишіть запит, який показує структуру створеної таблиці (команда DESCRIBE)
DESCRIBE TABLE items;

-- 2. Напишіть запит, який виводить усі товари в певній категорії відсортовані за ціною
SELECT * FROM items where category = 'electronics' ORDER BY price;

-- 3. Напишіть запити, які вибирають товари за різними критеріями в межах певної категорії (тут де треба замість індексу використайте Matirialized view):
-- 3.a назва
CREATE MATERIALIZED VIEW IF NOT EXISTS items_by_name AS
  SELECT category, id, name, price, manufacturer, properties
  FROM items
  WHERE category IS NOT NULL AND name IS NOT NULL AND price IS NOT NULL AND id IS NOT NULL
  PRIMARY KEY (category, name, price, id)
  WITH CLUSTERING ORDER BY (name ASC, price ASC, id ASC);

SELECT * FROM items_by_name
  WHERE category = 'electronics' AND name = 'Smartphone X';

-- 3.b ціна (в проміжку)
DROP MATERIALIZED VIEW IF EXISTS items_by_price;
CREATE MATERIALIZED VIEW IF NOT EXISTS items_by_price AS
  SELECT category, id, name, price, manufacturer, properties
  FROM items
  WHERE category IS NOT NULL AND price IS NOT NULL AND id IS NOT NULL
  PRIMARY KEY (category, price, id)
  WITH CLUSTERING ORDER BY (price ASC, id ASC);

SELECT * FROM items_by_price
  WHERE category = 'electronics' AND price >= 50.00 AND price <= 1800.00;

-- 3.c ціна та виробник
CREATE MATERIALIZED VIEW IF NOT EXISTS items_by_manufacturer_and_price AS
  SELECT category, id, name, price, manufacturer, properties
  FROM items
  WHERE category IS NOT NULL AND manufacturer IS NOT NULL AND price IS NOT NULL AND id IS NOT NULL
  PRIMARY KEY (category, manufacturer, price, id)
  WITH CLUSTERING ORDER BY (manufacturer ASC, price ASC, id ASC);

SELECT * FROM items_by_manufacturer_and_price
  WHERE category = 'electronics' AND manufacturer = 'BrandY'
    AND price >= 200.00 AND price <= 800.00;

-- 4. Напишіть запити, які вибирають товари за:
CREATE INDEX IF NOT EXISTS idx_properties_keys ON items (KEYS(properties));
CREATE INDEX IF NOT EXISTS idx_properties_values ON items (VALUES(properties));

-- 4.a наявність певних характеристик
SELECT * FROM items
  WHERE properties CONTAINS KEY 'color';

-- 4.b певна характеристика та її значення
SELECT * FROM items
  WHERE properties CONTAINS KEY 'color' AND properties['color'] = 'black';

-- 5. Оновити опис товару:

-- 5.a змінить існуючі значення певної характеристики
UPDATE items
  SET properties['color'] = 'blue'
WHERE category = 'electronics' AND price = 149.99
  AND id = 69279da1-4824-4074-a04c-ac0be406711b;

-- 5.b додайте нові властивості (характеристики) товару
UPDATE items
  SET properties = properties + {'warranty': '2 years'}
WHERE category = 'electronics' AND price = 149.99
  AND id = 69279da1-4824-4074-a04c-ac0be406711b;

-- 5.c видалить характеристику товару
UPDATE items
  SET properties = properties - {'battery'}
WHERE category = 'electronics' AND price = 299.99
  AND id = 295deb6e-b7e0-4204-898b-101c95520f27;

-- 5.d Показати всі
SELECT * FROM items;


-- Створіть таблицю orders в якій міститься ім'я замовника і інформація про замовлення: перелік id-товарів у замовленні, вартість замовлення, дата замовлення, .... Для кожного замовника повинна бути можливість швидко шукати його замовлення і виконувати по них запити.

CREATE TABLE orders (
  customer_name text,
  order_date timestamp,
  order_id uuid,
  product_ids list<uuid>,
  order_cost decimal,
  PRIMARY KEY (customer_name, order_date, order_id)
) WITH CLUSTERING ORDER BY (order_date DESC, order_id ASC);


-- 1) Напишіть запит, який показує структуру створеної таблиці (команда DESCRIBE)

DESCRIBE TABLE orders;

BEGIN BATCH
  INSERT INTO orders (customer_name, order_date, order_id, product_ids, order_cost)
  VALUES (
    'John Doe',
    '2023-10-01 12:00:00',
    uuid(),
    [69279da1-4824-4074-a04c-ac0be406711b, 295deb6e-b7e0-4204-898b-101c95520f27],
    399.98
  );

  INSERT INTO orders (customer_name, order_date, order_id, product_ids, order_cost)
  VALUES (
    'John Doe',
    '2023-10-02 14:30:00',
    uuid(),
    [78a6f224-4240-4772-aaaf-b2fe4796a484],
    999.99
  );

  INSERT INTO orders (customer_name, order_date, order_id, product_ids, order_cost)
  VALUES (
    'Jane Smith',
    '2023-10-03 09:15:00',
    uuid(),
    [2c78c130-d64e-4f7d-ab24-54485a204417, 78a6f224-4240-4772-aaaf-b2fe4796a484, 295deb6e-b7e0-4204-898b-101c95520f27],
    1349.97
  );

  INSERT INTO orders (customer_name, order_date, order_id, product_ids, order_cost)
  VALUES (
    'Jane Smith',
    '2023-10-04 16:45:00',
    uuid(),
    [2c78c130-d64e-4f7d-ab24-54485a204417],
    49.99
  );
APPLY BATCH;

-- 2) Для замовника виведіть всі його замовлення відсортовані за часом коли вони були зроблені
SELECT * FROM orders
WHERE customer_name = 'John Doe'
ORDER BY order_date ASC;

-- 3) Для замовника знайдіть замовлення з певним товаром
CREATE INDEX IF NOT EXISTS idx_order_product_ids ON orders (VALUES(product_ids));

SELECT * FROM orders
WHERE customer_name = 'John Doe' AND product_ids CONTAINS 69279da1-4824-4074-a04c-ac0be406711b;

-- 4) Для замовника знайдіть замовлення за певний період часу і їх кількість
SELECT COUNT(*) FROM orders
WHERE customer_name = 'John Doe'
  AND order_date >= '2023-01-01'
  AND order_date <= '2023-12-31';

-- 5) Для кожного замовників визначте суму на яку були зроблені усі його замовлення
CREATE OR REPLACE FUNCTION sumCost(state decimal, order_cost decimal)
  CALLED ON NULL INPUT
  RETURNS decimal
  LANGUAGE java AS 'return state.add(order_cost);';

CREATE OR REPLACE AGGREGATE sumOrderCost(decimal)
  SFUNC sumCost
  STYPE decimal
  INITCOND 0;

SELECT sumOrderCost(order_cost) AS total_cost
FROM orders
WHERE customer_name = 'John Doe';


-- 6) Для кожного замовників визначте замовлення з максимальною вартістю
CREATE MATERIALIZED VIEW IF NOT EXISTS orders_by_cost AS
  SELECT customer_name, order_cost, order_date, order_id, product_ids
  FROM orders
  WHERE customer_name IS NOT NULL
    AND order_cost IS NOT NULL
    AND order_date IS NOT NULL
    AND order_id IS NOT NULL
  PRIMARY KEY (customer_name, order_cost, order_date, order_id)
  WITH CLUSTERING ORDER BY (order_cost DESC, order_date DESC, order_id ASC);

SELECT * FROM orders_by_cost
WHERE customer_name = 'John Doe'
LIMIT 1;

-- 7) Модифікуйте певне замовлення додавши / видаливши один або кілька товарів при цьому також змінюючи вартість замовлення
UPDATE orders
    SET product_ids = product_ids + [78a6f224-4240-4772-aaaf-b2fe4796a484], order_cost = 1500.00
WHERE customer_name = 'John Doe'
  AND order_date = '2023-10-01 12:00:00'
  AND order_id = fcc19611-1857-49b8-a51c-3a90fa28f7de;


-- 8) Для кожного замовлення виведіть час коли його ціна були занесена в базу (SELECT WRITETIME)
SELECT order_cost, WRITETIME(order_cost) AS order_cost_writetime
FROM orders
WHERE customer_name = 'John Doe';

-- 9) Створіть замовлення з певним часом життя (TTL), після якого воно видалиться
INSERT INTO orders (customer_name, order_date, order_id, product_ids, order_cost)
VALUES (
  'Andrii A', toTimestamp(now()), uuid(),
  [78a6f224-4240-4772-aaaf-b2fe4796a484],
  199.99
) USING TTL 86400;

-- 10) Поверніть замовлення у форматі JSON
SELECT JSON * FROM orders
WHERE customer_name = 'John Doe';


-- 11) Додайте замовлення у форматі JSON
INSERT INTO orders JSON '{
  "customer_name": "Bob B",
  "order_date": "2023-10-01T12:00:00Z",
  "order_id": "123e4567-e89b-1111-aaaa-426614174001",
  "product_ids": ["78a6f224-4240-4772-aaaf-b2fe4796a484"],
  "order_cost": 299.99
}';

