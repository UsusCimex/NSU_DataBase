-- SQL-запрос для формирования кумулятивного отчёта по датам
WITH ordered_tickets AS (
SELECT t.marshrut_id,
       m1.order_num AS order_from,
       m2.order_num AS order_to
FROM tickets t
    JOIN marshrut m1
        ON m1.marshrut_id = t.marshrut_id AND m1.station_id = t.departure_station_id
    JOIN marshrut m2
        ON m2.marshrut_id = t.marshrut_id AND m2.station_id = t.arrival_station_id
)
SELECT t.arrival_time::date AS data,
       COUNT(distinct t.marshrut_id || '-' || t.train_id) AS trip_count,
       COUNT(1) AS count_passangers,
       COUNT(1)::numeric / SUM(dst.distance) AS passanger_dist
FROM timetable t
    JOIN marshrut m1 ON m1.marshrut_id = t.marshrut_id AND m1.station_id = t.station_id
    JOIN marshrut m2 ON m2.marshrut_id = t.marshrut_id AND m2.order_num = m1.order_num + 1
    JOIN distances dst ON dst.station1_id = m1.station_id AND dst.station2_id = m2.station_id
    RIGHT JOIN ordered_tickets ot ON t.marshrut_id = ot.marshrut_id AND m1.order_num BETWEEN ot.order_from AND ot.order_to
GROUP BY data
ORDER BY data;


-- Запрос на заполнение данных с выводом при помощи PL/SQL
DO
$$
    DECLARE
        r RECORD;
    BEGIN
        FOR r IN SELECT * FROM timetable LIMIT 100
            LOOP
                RAISE NOTICE 'Train ID: %, Station ID: %, Arrival: %, Departure: %',
                    r.train_id, r.station_id, r.arrival_time, r.departure_time;
            END LOOP;
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'Error: %', SQLERRM;
    END
$$;

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

-- Триггер для проверки соответствия поезда и станции маршрута
CREATE OR REPLACE FUNCTION check_train_station_route()
    RETURNS TRIGGER AS
$$
BEGIN
    IF NOT EXISTS (SELECT 1
                   FROM marshrut m
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
    FROM tmarshrut
    WHERE station_id = NEW.station_id
      AND marshrut_id = (SELECT marshrut_id FROM trains WHERE train_id = NEW.train_id);

    IF cur_station_order_num > 0 THEN
        -- Получаем order_num предыдущей станции
        SELECT tms.station_id, tms.order_num
        INTO prev_station_id, prev_station_order_num
        FROM tmarshrut tms
        WHERE tms.marshrut_id = (SELECT marshrut_id FROM trains WHERE train_id = NEW.train_id)
          AND tms.order_num < prev_station_order_num
        ORDER BY tms.order_num DESC
        LIMIT 1;

        -- Ищем время отправления с предыдущей станции (Не работает если таблица заполнена в будущем)
        SELECT departure_time
        INTO prev_departure_time
        FROM timetable
        WHERE train_id = NEW.train_id
          AND station_id = prev_station_id
        ORDER BY departure_time DESC
        LIMIT 1;

        -- Пытаемся найти средний интервал между аналогичными станциями для других поездов
        SELECT AVG(t2.arrival_time - t1.departure_time)
        INTO interval_between_stations
        FROM timetable t1
                 JOIN timetable t2 ON t1.train_id = t2.train_id AND t1.station_id = prev_station_id AND
                                      t2.station_id = NEW.station_id
        WHERE t1.departure_time < t2.arrival_time;

        -- Корректируем время прибытия и отправления, если текущее время меньше времени предыдущего
        IF NEW.arrival_time <= prev_departure_time THEN
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
    SELECT COALESCE(MAX(marshrut_id), 0) + 1
    INTO next_marshrut_id
    FROM (SELECT marshrut_id
          FROM marshrut
          UNION
          SELECT marshrut_id
          FROM tmarshrut) AS combined;

    IF NEW.marshrut_id IS NULL THEN
        NEW.marshrut_id := next_marshrut_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER auto_assign_marshrut_id_before_insert
    BEFORE INSERT
    ON marshrut
    FOR EACH ROW
EXECUTE FUNCTION auto_assign_marshrut_id();

-- Триггер для логирования удаления поездов
--создание таблицы
CREATE TABLE IF NOT EXISTS train_deletions_audit
(
    train_id        INT,
    deleted_tickets INT,
    deletion_time   TIMESTAMP DEFAULT NOW()
);

--триггер
CREATE OR REPLACE FUNCTION log_train_deletion()
    RETURNS TRIGGER AS
$$
DECLARE
    tickets_sold INT;
BEGIN
    SELECT COUNT(1) INTO tickets_sold
    FROM tickets
    WHERE train_id = OLD.train_id;

    IF tickets_sold > 300 THEN
        INSERT INTO train_deletions_audit (train_id, deleted_tickets)
        VALUES (OLD.train_id, tickets_sold);
    END IF;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER log_train_deletion_before_delete
    BEFORE DELETE
    ON trains
    FOR EACH ROW
EXECUTE FUNCTION log_train_deletion();