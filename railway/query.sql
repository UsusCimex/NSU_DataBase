-- Список городов
SELECT station_name
FROM stations
ORDER BY station_name
LIMIT 10;
-- Список маршрутов
SELECT r.route_id, 
    s1.station_name AS "destination", 
    s2.station_name AS "departure" 
FROM routes r 
    LEFT JOIN stations s1 ON s1.station_id = r.destination_station 
    LEFT JOIN stations s2 ON s2.station_id = r.departure_station 
LIMIT 10;

-- Отчёт о задержках поездов
SELECT r.route_id,
    st.station_name,
    s.arrival_date_time,
    s.train_delay
FROM schedules s
    JOIN intermediate_routes ir ON s.arrival_id = ir.arrival_id
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
    JOIN intermediate_routes ir ON sch.arrival_id = ir.arrival_id
    JOIN routes r ON ir.route_id = r.route_id
    JOIN stations st ON ir.station_id = st.station_id
WHERE EXISTS(SELECT ir2.order_number FROM intermediate_routes ir2 JOIN stations st2 ON ir2.station_id = st2.station_id
            WHERE r.route_id = ir2.route_id AND
            st2.station_name = 'Amandaton') AND
      EXISTS(SELECT ir2.order_number FROM intermediate_routes ir2 JOIN stations st2 ON ir2.station_id = st2.station_id
            WHERE r.route_id = ir2.route_id AND
            st2.station_name = 'Kellybury')
ORDER BY r.route_id;

-- С учётом пересадок
WITH RECURSIVE route_path AS (
    SELECT 
        r1.route_id, 
        r1.departure_station, 
        r1.destination_station, 
        ARRAY[r1.route_id] AS route_history,
        1 as hop_count
    FROM 
        routes r1
    WHERE 
        r1.departure_station = (SELECT station_id FROM stations WHERE station_name = 'A') -- Начальная станцию

    UNION ALL

    SELECT 
        r2.route_id, 
        rp.departure_station, 
        r2.destination_station, 
        route_history || r2.route_id, 
        rp.hop_count + 1
    FROM 
        routes r2
    JOIN 
        route_path rp ON rp.destination_station = r2.departure_station
    WHERE 
        NOT (r2.route_id = ANY(route_history)) -- предотвращение циклов
        AND hop_count < 5 -- ограничение количества пересадок
)
SELECT * FROM route_path
WHERE destination_station = (SELECT station_id FROM stations WHERE station_name = 'B') -- Конечная станцию
ORDER BY hop_count, route_id;

-- Все станции-пересадки по маршруту
SELECT st.station_name,
    ir.order_number,
    sch.arrival_date_time
FROM schedules sch
    JOIN intermediate_routes ir ON sch.arrival_id = ir.arrival_id
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
    JOIN tickets tck ON t.total_tickets = tck.tickets_id
WHERE t.train_id = 4;

-- Количество занятых билетов на каждой станции
SELECT s.station_name,
    sch.arrival_date_time,
    tck.general_tickets AS "General",
    tck.platzkart_tickets AS "Platzkart",
    tck.coupe_tickets AS "Coupe",
    tck.sv_tickets AS "SV"
FROM schedules sch
     JOIN trains t USING(train_id)
     JOIN intermediate_routes ir USING(arrival_id)
     JOIN stations s USING(station_id)
     JOIN tickets tck ON sch.occupied_tickets = tck.tickets_id
WHERE t.train_id = 4
ORDER BY sch.arrival_date_time DESC;

-- Отчёт о ближайших поездах
SELECT t.train_id,
    st1.station_name AS "Departure",
    st2.station_name AS "Destionation",
    st.station_name AS "Station",
    sch.arrival_date_time AS "Arrival Time",
    sch.arrival_date_time + (sch.parking_time || 'minutes')::interval AS "Departure Time"
FROM trains t
    JOIN schedules sch ON t.train_id = sch.train_id
    JOIN intermediate_routes ir ON sch.arrival_id = ir.arrival_id
    JOIN stations st ON ir.station_id = st.station_id
    JOIN routes r ON ir.route_id = r.route_id
    JOIN stations st1 ON r.departure_station = st1.station_id
    JOIN stations st2 ON r.destination_station = st2.station_id
WHERE st.station_name = 'Dustintown'
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
