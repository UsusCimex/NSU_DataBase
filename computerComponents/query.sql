--- 1. Вывод серийного номера компьютера и его стоимость.

SELECT DISTINCT computer_serial AS serial_number, price_sell_computer AS price
FROM computer_components
ORDER BY serial_number;

--- 2. Найти для заданного комплектующего замену.

SELECT name, price, guarantee_period
FROM components
WHERE category_id = ( SELECT id FROM components WHERE name = 'AMD Ryzen 5 3600' )
      AND name != 'AMD Ryzen 5 3600'
ORDER BY price;

--- 3. Найти самое дешевое комплектующее для каждой категории.

--- 4. Вывести комплектующие, которые находятся на первых 3 местах по уровню востребованности (наиболее часто используемые во всех собранных компьютерах). Примечание: если уровень востребованности у двух комплектующих одинаковый, то обе находят-ся на одном месте.

--- 5. Вывести компьютеры с рентабельностью свыше 30% (цена продажи на 30% больше стоимости производства).