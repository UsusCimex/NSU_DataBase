-- Список городов
SELECT station_name
FROM stations
ORDER BY station_name
LIMIT 10;

-- Отчёт о задержках поездов
SELECT r.route_id,
    st.station_name,
    s.arrival_date_time,
    s.train_delay
FROM schedules s
    JOIN intermediate_routes ir ON s.intermediate_routes_id = ir.intermediate_routes_id
    JOIN routes r ON ir.route_id = r.route_id
    JOIN stations st ON ir.station_id = st.station_id
    JOIN trains t ON s.train_id = t.train_id
WHERE t.train_id = 5
    AND s.arrival_date_time BETWEEN '2023-01-01' AND '2024-01-01';

-- Отчёты о маршрутах и поездах между указанными городами
SELECT r.route_id,
       sch.train_id,
       st.station_name,
       sch.arrival_date_time
FROM schedules sch
    JOIN intermediate_routes ir ON sch.intermediate_routes_id = ir.intermediate_routes_id
    JOIN routes r ON ir.route_id = r.route_id
    JOIN stations st ON ir.station_id = st.station_id
WHERE EXISTS(SELECT ir2.order_number FROM intermediate_routes ir2 JOIN stations st2 ON ir2.station_id = st2.station_id
            WHERE r.route_id = ir2.route_id AND
            st2.station_name = 'Brownton') AND
      EXISTS(SELECT ir2.order_number FROM intermediate_routes ir2 JOIN stations st2 ON ir2.station_id = st2.station_id
            WHERE r.route_id = ir2.route_id AND
            st2.station_name = 'Ashleyland')
ORDER BY r.route_id;

-- fixed(Добавить промежуточные станции)
-- С учётом пересадок
WITH RECURSIVE route_path AS (
    SELECT r1.route_id,
        ARRAY[r1.route_id] AS route_history,
        1 as hop_count
    FROM routes r1
    WHERE r1.departure_station = (SELECT station_id FROM stations WHERE station_name = 'Brownton') -- Начальная станцию
    UNION ALL
    SELECT r2.route_id,
        route_history || r2.route_id, 
        rp.hop_count + 1
    FROM routes r2
        JOIN route_path rp ON rp.destination_station = r2.departure_station
    WHERE NOT (r2.route_id = ANY(route_history)) -- предотвращение циклов
          AND hop_count < 3 -- ограничение количества пересадок
)
SELECT * FROM route_path
WHERE destination_station = (SELECT station_id FROM stations WHERE station_name = 'Ashleyland') -- Конечная станцию
ORDER BY hop_count, route_id;

-- Все станции-пересадки по маршруту
SELECT st.station_name,
    ir.order_number,
    sch.arrival_date_time
FROM schedules sch
    JOIN intermediate_routes ir ON sch.intermediate_routes_id = ir.intermediate_routes_id
    JOIN routes r ON ir.route_id = r.route_id
    JOIN stations st ON ir.station_id = st.station_id
WHERE r.route_id = 13
ORDER BY sch.schedule_id, ir.order_number;

-- Количество билетов на указанный поезд
-- Максимальное количество
SELECT tck.general_tickets AS "General",
    tck.platzkart_tickets AS "Platzkart",
    tck.coupe_tickets AS "Coupe",
    tck.sv_tickets AS "SV"
FROM trains t
    JOIN tickets tck ON t.tickets_id = tck.tickets_id
WHERE t.train_id = 4;

-- fixed (не использовать количество купленных билетов)
-- Количество занятых билетов на каждой станции
SELECT st.station_name,
    COUNT(DISTINCT pt.trip_id) as occupied_tickets
FROM stations st
    JOIN intermediate_routes ir ON st.station_id = ir.station_id
    JOIN schedules s ON ir.intermediate_routes_id = s.intermediate_routes_id
    JOIN passenger_trips pt ON pt.departure_station_schedule <= s.schedule_id AND pt.destination_station_schedule >= s.schedule_id
WHERE ir.route_id = 5 AND EXISTS (
    SELECT 1
    FROM intermediate_routes ir_start
        JOIN intermediate_routes ir_end ON ir_start.route_id = ir_end.route_id
        JOIN schedules s_start ON ir_start.intermediate_routes_id = s_start.intermediate_routes_id
        JOIN schedules s_end ON ir_end.intermediate_routes_id = s_end.intermediate_routes_id
    WHERE 
        s_start.schedule_id = pt.departure_station_schedule AND
        s_end.schedule_id = pt.destination_station_schedule AND
        ir.order_number BETWEEN ir_start.order_number AND ir_end.order_number
    )
GROUP BY st.station_name, ir.order_number
ORDER BY ir.order_number;

-- fixed(на два join меньше)
-- Отчёт о ближайших поездах
SELECT t.train_id,
    (SELECT station_name FROM stations WHERE station_id = r.departure_station) AS "Departure",
    (SELECT station_name FROM stations WHERE station_id = r.destination_station) AS "Destination",
    sch.arrival_date_time AS "Arrival Time",
    sch.arrival_date_time + (sch.parking_time || 'minutes')::interval AS "Departure Time"
FROM trains t
    JOIN schedules sch ON t.train_id = sch.train_id
    JOIN intermediate_routes ir ON sch.intermediate_routes_id = ir.intermediate_routes_id
    JOIN routes r ON ir.route_id = r.route_id
WHERE st.station_name = 'Brookemouth'
    AND sch.arrival_date_time + (sch.parking_time || 'minutes')::interval BETWEEN current_date AND current_date + interval '7 days'
ORDER BY sch.arrival_date_time;

-- Иерархия сотрудников РЖД
WITH RECURSIVE EmployeeHierarchy AS (
    SELECT e.employee_id,
        e.full_name,
        e.position,
        e.manager_id,
        1 AS depth
    FROM rzd_employees e
    WHERE e.manager_id IS NULL
    UNION ALL
    SELECT e.employee_id,
        e.full_name,
        e.position,
        e.manager_id,
        eh.depth + 1 AS depth
    FROM rzd_employees e
        INNER JOIN EmployeeHierarchy eh ON e.manager_id = eh.employee_id
)
SELECT employee_id,
    full_name,
    position,
    manager_id,
    depth
FROM EmployeeHierarchy
ORDER BY depth, manager_id, employee_id;

-- Другая реализация
WITH RECURSIVE EmployeeHierarchy AS (
    SELECT e.employee_id,
        e.full_name,
        e.manager_id,
        1 AS depth,
        CAST(e.full_name AS TEXT) AS hierarchy
    FROM rzd_employees e
    WHERE e.manager_id IS NULL
    UNION ALL
    SELECT e.employee_id,
        e.full_name,
        e.manager_id,
        eh.depth + 1 AS depth,
        eh.hierarchy || ' -> ' || e.full_name AS hierarchy
    FROM rzd_employees e
        INNER JOIN EmployeeHierarchy eh ON e.manager_id = eh.employee_id
)
SELECT hierarchy
FROM EmployeeHierarchy
WHERE depth > 4
ORDER BY depth, manager_id, employee_id;
