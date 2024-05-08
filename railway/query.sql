-- SQL-запрос для формирования отчёта по датам
WITH trips_and_passengers AS (
    SELECT
        t.arrival_time::DATE AS date,
        COUNT(DISTINCT ti.passenger_id) AS num_trips,
        COUNT(ti.passenger_id) AS num_passengers
    FROM
        timetable t
        JOIN tickets ti ON t.timetable_id = ti.timetable_id
    GROUP BY t.arrival_time::DATE
), betweens AS (
    SELECT tt.timetable_id,
         tt.station_id,
         LEAD(tt.station_id)
            OVER (PARTITION BY tt.timetable_id ORDER BY tt.arrival_time) AS next_station_id,
         tt.arrival_time
    FROM timetable tt
), count_passengers AS (
    SELECT tt.timetable_id,
           tt.station_id,
           COUNT(t.passenger_id) AS count_p
    FROM tickets t
         RIGHT JOIN timetable tt ON t.timetable_id = tt.timetable_id
    GROUP BY tt.timetable_id, tt.station_id
), distances_sum AS (
    SELECT b.arrival_time::DATE AS date,
           SUM(d.distance * cp.count_p) AS total_distance
    FROM betweens b
        JOIN count_passengers cp ON b.station_id = cp.station_id AND b.timetable_id = cp.timetable_id
        JOIN distances d ON d.station1_id = LEAST(b.station_id, b.next_station_id)
                                     AND d.station2_id = GREATEST(b.station_id, b.next_station_id)
    WHERE next_station_id IS NOT NULL
    GROUP BY b.arrival_time::DATE
)
SELECT
    CASE
        WHEN GROUPING(date_part('year', tp.date)) = 1 AND GROUPING(date_part('quarter', tp.date)) = 1 AND GROUPING(tp.date) = 1 THEN 'ИТОГ'
        WHEN GROUPING(date_part('quarter', tp.date)) = 1 AND GROUPING(tp.date) = 1 THEN date_part('year', tp.date)::text || '(итог)'
        WHEN GROUPING(tp.date) = 1 THEN 'Q' || date_part('quarter', tp.date)::text || ' ' || date_part('year', tp.date)::text
        ELSE tp.date::text
    END AS period,
    COALESCE(SUM(tp.num_trips), 0) AS num_trips,
    COALESCE(SUM(tp.num_passengers), 0) AS num_passengers,
    COALESCE(SUM(ds.total_distance), 0) AS total_distance
FROM
    trips_and_passengers tp
    JOIN distances_sum ds ON tp.date = ds.date
GROUP BY ROLLUP(date_part('year', tp.date), date_part('quarter', tp.date), tp.date)
ORDER BY
    date_part('year', tp.date),
    date_part('quarter', tp.date),
    tp.date;

CREATE INDEX idx_timetable_arrival_time ON timetable USING btree(arrival_time);
CREATE INDEX idx_timetable_id ON timetable(timetable_id);
CREATE INDEX idx_tickets_timetable_id ON tickets(timetable_id);
CREATE INDEX idx_stations_station_id ON stations(station_id);
CREATE INDEX idx_distances_station_ids ON distances(station1_id, station2_id);

DO
$$
DECLARE
    record RECORD;
    prev_quarter INT := 0;
    prev_year INT := 0;

    sum_trips_q INT := 0;
    sum_passenger_q INT := 0;
    sum_km_q INT := 0;

    sum_trips_y INT := 0;
    sum_passenger_y INT := 0;
    sum_km_y INT := 0;
BEGIN
    CREATE TEMP TABLE bertweens ON COMMIT DROP AS
        SELECT tt.timetable_id,
             tt.station_id,
             LEAD(tt.station_id)
                OVER (PARTITION BY tt.timetable_id ORDER BY tt.arrival_time) AS next_station_id,
             tt.arrival_time
        FROM timetable tt;

    FOR record IN (
        SELECT
            tt.arrival_time::DATE as day,
            EXTRACT(QUARTER FROM tt.arrival_time) AS quarter,
            EXTRACT(YEAR FROM tt.arrival_time) AS year,
            COUNT(t.passenger_id) AS num_passengers,
            COUNT(DISTINCT t.passenger_id) AS num_trips,
            SUM(d.distance) AS pass_km
        FROM timetable tt
        JOIN tickets t ON t.timetable_id = tt.timetable_id
        LEFT JOIN bertweens b ON b.timetable_id = tt.timetable_id AND b.arrival_time = tt.arrival_time
        LEFT JOIN distances d ON d.station1_id = LEAST(b.station_id, b.next_station_id)
                                     AND d.station2_id = GREATEST(b.station_id, b.next_station_id)
        GROUP BY day, quarter, year
        ORDER BY day
    ) LOOP
        IF prev_quarter <> 0 AND (prev_quarter <> record.quarter OR prev_year <> record.year) THEN
            RAISE NOTICE 'End of Q% %: Num Trips: %, Num Passengers: %, Total Distance: %', prev_quarter, prev_year, sum_trips_q, sum_passenger_q, sum_km_q;
            sum_passenger_q := 0;
            sum_trips_q := 0;
            sum_km_q := 0;
        END IF;

        IF prev_year <> 0 AND prev_year <> record.year THEN
            RAISE NOTICE 'End of Year %: Num Trips: %, Num Passengers: %, Total Distance: %', prev_year, sum_trips_y, sum_passenger_y, sum_km_y;
            sum_passenger_y := 0;
            sum_trips_y := 0;
            sum_km_y := 0;
        END IF;

        RAISE NOTICE '%: Num Trips: %, Num Passengers: %, Total Distance: %', record.day, record.num_trips, record.num_passengers, record.pass_km;

        sum_trips_q := sum_trips_q + record.num_trips;
        sum_passenger_q := sum_passenger_q + record.num_passengers;
        sum_km_q := sum_km_q + record.pass_km;

        sum_trips_y := sum_trips_y + record.num_trips;
        sum_passenger_y := sum_passenger_y + record.num_passengers;
        sum_km_y := sum_km_y + record.pass_km;

        prev_quarter := record.quarter;
        prev_year := record.year;
    END LOOP;

    -- Вывести последние суммы, если не были выведены из-за окончания цикла
    IF sum_passenger_q <> 0 OR sum_km_q <> 0 THEN
        RAISE NOTICE 'End of Q% %: Num Trips: %, Num Passengers: %, Total Distance: %', prev_quarter, prev_year, sum_trips_q, sum_passenger_q, sum_km_q;
    END IF;
    IF sum_passenger_y <> 0 OR sum_km_y <> 0 THEN
        RAISE NOTICE 'End of Year %: Num Trips: %, Num Passengers: %, Total Distance: %', prev_year, sum_trips_y, sum_passenger_y, sum_km_y;
    END IF;
END;
$$ LANGUAGE PLPGSQL;

SELECT * FROM timetable WHERE arrival_time::DATE = '2023-04-04';

-- Функция для корректировки времени прибытия поездов
CREATE OR REPLACE FUNCTION fix_delays(target_date TIMESTAMP)
    RETURNS VOID AS
$$
DECLARE
    train_record RECORD;
BEGIN
    FOR train_record IN SELECT tm.train_id, w.value AS delay_minutes, tm.arrival_time, tm.departure_time
                        FROM waitings w
                                 JOIN timetable tm ON tm.train_id = w.train_id
                        WHERE w.value > 0
                          AND w.date = target_date
                          AND tm.arrival_time = w.date - INTERVAL '1 minute' * w.value
        LOOP
            UPDATE timetable tm
            SET arrival_time   = tm.arrival_time + INTERVAL '1 minute' * train_record.delay_minutes,
                departure_time = tm.departure_time + INTERVAL '1 minute' * train_record.delay_minutes
            WHERE train_id = train_record.train_id
              AND arrival_time = train_record.arrival_time;

            UPDATE waitings
            SET value = 0
            WHERE train_id = train_record.train_id
              AND date = target_date;
        END LOOP;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;
-- С использованием курсора
CREATE OR REPLACE FUNCTION fix_delays(target_date TIMESTAMP)
    RETURNS VOID AS
$$
DECLARE
    train_cursor CURSOR FOR
        SELECT tm.train_id, w.value AS delay_minutes, tm.arrival_time, tm.departure_time
        FROM waitings w
                 JOIN timetable tm ON tm.train_id = w.train_id
        WHERE w.value > 0
          AND w.date = target_date
          AND tm.arrival_time = w.date - INTERVAL '1 minute' * w.value;
    train_record RECORD;
BEGIN
    OPEN train_cursor;
    LOOP
        FETCH train_cursor INTO train_record;
        EXIT WHEN NOT FOUND;

        UPDATE timetable
        SET arrival_time   = arrival_time + INTERVAL '1 minute' * train_record.delay_minutes,
            departure_time = departure_time + INTERVAL '1 minute' * train_record.delay_minutes
        WHERE train_id = train_record.train_id
          AND arrival_time = train_record.arrival_time;

        UPDATE waitings
        SET value = 0
        WHERE train_id = train_record.train_id
          AND date = target_date;
    END LOOP;
    CLOSE train_cursor;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM timetable WHERE timetable_id = 3751;

SELECT fix_delays('2024-01-03 23:30:59.000000');
SELECT * FROM waitings LIMIT 1;
SELECT * FROM timetable t JOIN waitings w USING(train_id) WHERE t.train_id = 751 AND t.arrival_time = w.date - INTERVAL '1 minute' * w.value;

-- Триггер для проверки соответствия поезда и станции маршрута
CREATE OR REPLACE FUNCTION check_train_station_route()
    RETURNS TRIGGER AS
$$
BEGIN
    IF NOT EXISTS (SELECT 1
                   FROM marshruts m
                            JOIN trains t ON m.marshrut_id = t.marshrut_id
                   WHERE t.train_id = NEW.train_id
                     AND m.station_id = NEW.station_id) THEN
        RAISE EXCEPTION 'Station does not match train route.';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER check_train_station_route_before_insert
    BEFORE INSERT OR UPDATE
    ON timetable
    FOR EACH ROW
EXECUTE FUNCTION check_train_station_route();

--Триггер для проверки и коррекции времени прибытия
CREATE OR REPLACE FUNCTION correct_timetable_timing()
    RETURNS TRIGGER AS
$$
DECLARE
    cur_station_order_num     INT;
    prev_station_id           INT;
    prev_station_order_num    INT;
    prev_departure_time       TIMESTAMP;
    interval_between_stations INTERVAL;
    default_interval          INTERVAL := '10 minute'; -- дефолтный интервал
BEGIN
    -- Проверяем, является ли станция начальной в маршруте
    SELECT order_num
    INTO cur_station_order_num
    FROM marshruts
    WHERE station_id = NEW.station_id
      AND marshrut_id = (SELECT marshrut_id FROM trains WHERE train_id = NEW.train_id);

    IF cur_station_order_num > 1 THEN
        -- Получаем station_id и order_num предыдущей станции
        prev_station_order_num = cur_station_order_num - 1;
        SELECT station_id
        INTO prev_station_id
        FROM tmarshruts tms
        WHERE tms.marshrut_id = (SELECT marshrut_id FROM trains WHERE train_id = NEW.train_id)
          AND tms.order_num = prev_station_order_num;

        -- Ищем время отправления с предыдущей станции
        SELECT departure_time
        INTO prev_departure_time
        FROM timetable
        WHERE timetable_id = NEW.timetable_id
          AND station_id = prev_station_id
        ORDER BY departure_time DESC
        LIMIT 1;

        -- Корректируем время прибытия и отправления, если текущее время меньше времени предыдущего
        IF NEW.arrival_time <= prev_departure_time THEN
            -- Пытаемся найти средний интервал между аналогичными станциями для других поездов
            SELECT AVG(t2.arrival_time - t1.departure_time)
            INTO interval_between_stations
            FROM timetable t1
                     JOIN timetable t2 ON t1.timetable_id = t2.timetable_id AND t1.station_id = prev_station_id AND
                                          t2.station_id = NEW.station_id
            WHERE t1.departure_time < t2.arrival_time;

            IF interval_between_stations IS NOT NULL THEN
                NEW.arrival_time := prev_departure_time + interval_between_stations;
                NEW.departure_time := NEW.arrival_time + interval_between_stations;
            ELSE
                NEW.arrival_time := prev_departure_time + default_interval;
                NEW.departure_time := NEW.arrival_time + default_interval;
            END IF;
        END IF;
    END IF;
    -- Если order_num = 0, никаких действий не требуется

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER correct_timetable_timing_before_insert
    BEFORE INSERT
    ON timetable
    FOR EACH ROW
EXECUTE FUNCTION correct_timetable_timing();

--Триггер для автоматического присвоения номера маршрута
CREATE OR REPLACE FUNCTION auto_assign_marshrut_id()
    RETURNS TRIGGER AS
$$
DECLARE
    next_marshrut_id INT;
BEGIN
    IF NEW.marshrut_id IS NULL THEN
        SELECT MIN(gs.marshrut_id)
        INTO next_marshrut_id
        FROM generate_series(1, (SELECT MAX(marshrut_id) FROM marshruts)) AS gs(marshrut_id)
        WHERE NOT EXISTS (SELECT 1 FROM marshruts WHERE marshrut_id = gs.marshrut_id)
            AND NOT EXISTS (SELECT 1 FROM tmarshruts WHERE marshrut_id = gs.marshrut_id);

        IF next_marshrut_id IS NULL THEN
            next_marshrut_id := 1;
        END IF;

        NEW.marshrut_id := next_marshrut_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
-- Другая реализация
CREATE OR REPLACE FUNCTION auto_assign_marshrut_id()
    RETURNS TRIGGER AS
$$
DECLARE
    max_marshrut_id INT;
    max_tmarshrut_id INT;
BEGIN
    IF NEW.marshrut_id IS NULL THEN
        SELECT MAX(m.marshrut_id)
        INTO max_marshrut_id
        FROM marshruts m;
        SELECT MAX(m.marshrut_id)
        INTO max_tmarshrut_id
        FROM tmarshruts m;

        IF max_tmarshrut_id > max_marshrut_id THEN
            max_marshrut_id := max_tmarshrut_id;
        END IF;

        FOR i IN 0..max_marshrut_id + 1 LOOP
            IF i NOT IN (SELECT marshrut_id FROM marshruts UNION
                         SELECT marshrut_id FROM tmarshruts)
            THEN
                NEW.marshrut_id = i;
                RETURN NEW;
            end if;
        end loop;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER auto_assign_marshrut_id_before_insert
    BEFORE INSERT
    ON marshruts
    FOR EACH ROW
EXECUTE FUNCTION auto_assign_marshrut_id();

-- Триггер для логирования удаления поездов
DROP TABLE IF EXISTS train_deletions_audit CASCADE;
--создание таблицы
CREATE TABLE IF NOT EXISTS train_deletions_audit
(
    train_id        INT,
    deleted_tickets INT,
    user_name       VARCHAR,
    deletion_time   TIMESTAMP DEFAULT NOW()
);

--триггер
CREATE OR REPLACE FUNCTION log_train_deletion()
    RETURNS TRIGGER AS
$$
DECLARE
    tickets_sold INT;
    user_name VARCHAR;
BEGIN
    SELECT COUNT(1)
    INTO tickets_sold
    FROM tickets t LEFT JOIN timetable tt USING (timetable_id)
    WHERE tt.train_id = OLD.train_id;

    SELECT current_user
    INTO user_name;

    IF tickets_sold > 300 THEN
        INSERT INTO train_deletions_audit (train_id, deleted_tickets, user_name)
        VALUES (OLD.train_id, tickets_sold, user_name);
    END IF;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER log_train_deletion_before_delete
    BEFORE DELETE
    ON trains
    FOR EACH ROW
EXECUTE FUNCTION log_train_deletion();

SELECT tt.train_id,
       COUNT(1) as count
FROM tickets t
    LEFT JOIN timetable tt USING (timetable_id)
GROUP BY tt.train_id
ORDER BY count DESC;

DELETE FROM trains WHERE train_id = 562;
SELECT * FROM train_deletions_audit LIMIT 10;
TRUNCATE train_deletions_audit;