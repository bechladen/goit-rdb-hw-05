USE mydb;

-- 1. Вкладений запит в SELECT: order_details + customer_id з orders
SELECT
  od.*,
  (SELECT o.customer_id
   FROM orders o
   WHERE o.id = od.order_id) AS customer_id
FROM order_details od;

-- 2. Вкладений запит в WHERE: order_details тільки там, де у orders shipper_id = 3
-- варіант з WHERE (SELECT o.shipper_id ... ) = 3 працює тільки якщо підзапит гарантовано повертає 1 рядок для кожного order_id. У “нормальній” моделі orders.id — унікальний, тому підзапит повертає 1 рядок і помилки не буде. Але шаблон з = ризиковий, якщо таблиця може містити дублікати/неунікальні ключі або якщо підзапит потенційно може повернути кілька значень.
SELECT *
FROM order_details od
WHERE EXISTS (
  SELECT 1
  FROM orders o
  WHERE o.id = od.order_id
    AND o.shipper_id = 3
);
       
-- 3. Вкладений запит у FROM: quantity>10, далі AVG(quantity) група по order_id
SELECT
  t.order_id,
  AVG(t.quantity) AS avg_quantity
FROM (
  SELECT order_id, quantity
  FROM order_details
  WHERE quantity > 10
) AS t
GROUP BY t.order_id;

-- 4. Те саме через WITH (CTE) temp (MySQL 8+)
WITH temp AS (
  SELECT order_id, quantity
  FROM order_details
  WHERE quantity > 10
)
SELECT
  order_id,
  AVG(quantity) AS avg_quantity
FROM temp
GROUP BY order_id;

-- 5. Функція FLOAT/FLOAT, ділення, і застосувати до quantity
-- Ділення на 0 дасть NULL або помилку залежно від налаштувань, тому краще захиститися.
DELIMITER $$

CREATE FUNCTION divide_f(a FLOAT, b FLOAT)
RETURNS FLOAT
DETERMINISTIC
BEGIN
  IF b = 0 THEN
    RETURN NULL;
  END IF;
  RETURN a / b;
END$$

DELIMITER ;