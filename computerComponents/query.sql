--- 1. Вывод серийного номера компьютера и его стоимость.

SELECT DISTINCT computer_serial AS serial_number, 
       price_sell_computer AS price
FROM computer_components
ORDER BY serial_number;

--- 2. Найти для заданного комплектующего замену.

SELECT name, price, guarantee_period
FROM components
WHERE category_id = ( 
        SELECT id 
        FROM components 
        WHERE name = 'AMD Ryzen 5 3600'
    ) AND name != 'AMD Ryzen 5 3600'
ORDER BY price;

--- 3. Найти самое дешевое комплектующее для каждой категории.

SELECT components.name AS component, 
       category.name AS category, 
       price
FROM components 
     LEFT JOIN category ON category_id = category.id
WHERE (category_id, price) IN (
    SELECT category_id, 
           MIN(price)
    FROM components
    GROUP BY category_id
)
ORDER BY components.name;

SELECT subQuery.name AS component, 
       category.name AS category, 
       min_price
FROM (
       SELECT name,
              category_id,
              price,
              MIN(price) OVER (PARTITION BY category_id) AS min_price
       FROM components
) subQuery
  LEFT JOIN category ON category.id = subQuery.category_id
WHERE price = min_price
ORDER BY component;

--- 4. Вывести комплектующие, которые находятся на первых 3 местах по уровню востребованности (наиболее часто используемые во всех собранных компьютерах). 
--- Примечание: если уровень востребованности у двух комплектующих одинаковый, то обе находят-ся на одном месте.

SELECT components.name AS company_name, 
       category.name AS category_name
FROM components 
     LEFT JOIN category ON components.category_id = category.id
WHERE components.id IN (
    SELECT component_id
    FROM computer_components
    GROUP BY component_id
    HAVING COUNT(id) >= (
        SELECT COUNT(id)
        FROM computer_components
        GROUP BY component_id
        ORDER BY COUNT(id) DESC
        OFFSET 2 LIMIT 1
    )
);

SELECT components.name AS component_name, 
       category.name AS category_name, 
       sell_count
FROM (
    SELECT component_id,
           COUNT(id) AS sell_count,
           RANK() OVER (ORDER BY COUNT(id) DESC) AS rk
    FROM computer_components
    GROUP BY component_id
) subQuery
    LEFT JOIN components ON components.id = subQuery.component_id
    LEFT JOIN category ON components.category_id = category.id
WHERE rk <= 3;

--- 5. Вывести компьютеры с рентабельностью свыше 30% (цена продажи на 30% больше стоимости производства).

SELECT computer_serial, 
       SUM(components.price) AS components_price, 
       ROUND(AVG(price_sell_computer), 2) AS sell_price,
       ROUND(AVG(price_sell_computer) / SUM(components.price), 2) AS profitability
FROM computer_components
     LEFT JOIN components ON component_id = components.id
GROUP BY computer_serial
HAVING AVG(price_sell_computer) / SUM(components.price) > 1.3;