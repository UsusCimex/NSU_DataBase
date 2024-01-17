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
    SELECT ir.route_id,
        ir.station_id,
        ir.order_number,
        ARRAY[ir.station_id] AS route_history,
        1 as hop_count
    FROM intermediate_routes ir
    WHERE ir.station_id = (SELECT station_id FROM stations WHERE station_name = 'Allenton') -- Начальная станция
    UNION ALL
    SELECT ir2.route_id,
        ir2.station_id,
        ir2.order_number,
        route_history || ir2.station_id, 
        rp.hop_count + 1
    FROM route_path rp
         INNER JOIN intermediate_routes ir2 ON (rp.route_id = ir2.route_id AND
                                                rp.order_number < ir2.order_number AND
                                                rp.station_id != ir2.station_id)
         INNER JOIN intermediate_routes ir3 ON (rp.route_id != ir3.route_id AND 
                                                rp.station_id = ir3.station_id)
    WHERE hop_count <= 3 -- ограничение количества пересадок
)
SELECT * FROM route_path
WHERE station_id = (SELECT station_id FROM stations WHERE station_name = 'Barbaratown') -- Конечная станциz
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

SELECT ir.order_number,
       s.station_name AS "Station",
       COUNT(*) AS "Count passenger"
FROM intermediate_routes ir
     JOIN stations s USING(station_id)
     JOIN (SELECT pt.trip_id,
                ir1.route_id,
                ir1.order_number AS "order_from",
                ir2.order_number AS "order_to"
            FROM passenger_trips pt
                JOIN schedules s1 ON pt.departure_station_schedule = s1.schedule_id
                JOIN intermediate_routes ir1 ON s1.intermediate_routes_id = ir1.intermediate_routes_id
                JOIN schedules s2 ON pt.destination_station_schedule = s2.schedule_id
                JOIN intermediate_routes ir2 ON s2.intermediate_routes_id = ir2.intermediate_routes_id
            WHERE pt.ticket_type LIKE 'coupe') AS trips ON ir.order_number BETWEEN trips.order_from AND trips.order_to AND ir.route_id = trips.route_id
WHERE ir.route_id = 1
GROUP BY ir.order_number, s.station_name;

-- fixed(на два join меньше)
-- Отчёт о ближайших поездах
SELECT t.train_id,
    (SELECT station_name FROM stations s JOIN intermediate_routes ir USING(station_id) WHERE ir.route_id = r.route_id AND ir.order_number = 1) AS "Departure",
    (SELECT station_name FROM stations s JOIN intermediate_routes ir USING(station_id) WHERE ir.route_id = r.route_id AND ir.order_number = (SELECT MAX(order_number) FROM intermediate_routes WHERE route_id = r.route_id)) AS "Destination",
    sch.arrival_date_time AS "Arrival Time",
    sch.arrival_date_time + (sch.parking_time || 'minutes')::interval AS "Departure Time"
FROM trains t
    JOIN schedules sch ON t.train_id = sch.train_id
    JOIN intermediate_routes ir ON sch.intermediate_routes_id = ir.intermediate_routes_id
    JOIN routes r ON ir.route_id = r.route_id
WHERE ir.station_id = (SELECT station_id FROM stations WHERE station_name = 'Allenton')
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
