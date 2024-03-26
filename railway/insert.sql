CREATE OR REPLACE FUNCTION generate_stations(n INTEGER DEFAULT 10) RETURNS VOID AS
$$
DECLARE
    i INTEGER;
BEGIN
    FOR i IN 1..n
        LOOP
            INSERT INTO stations (station_id, name)
            VALUES (i, 'Station ' || i);
        END LOOP;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION generate_station_distances(min_distance INTEGER, max_distance INTEGER) RETURNS VOID AS
$$
DECLARE
    station1 RECORD;
    station2 RECORD;
BEGIN
    FOR station1 IN SELECT station_id FROM stations
        LOOP
            FOR station2 IN SELECT station_id FROM stations WHERE station_id > station1.station_id
                LOOP
                    INSERT INTO distances (station1_id, station2_id, distance)
                    VALUES (station1.station_id, station2.station_id,
                            (RANDOM() * (max_distance - min_distance) + min_distance)::INTEGER);
                END LOOP;
        END LOOP;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION generate_marshruts(n INTEGER DEFAULT 50000) RETURNS VOID AS
$$
DECLARE
    marshrut_id  INTEGER := 1;
    num_stations INTEGER;
    station      RECORD;
    order_num    INTEGER;
BEGIN
    WHILE marshrut_id <= n
        LOOP
            order_num := 1;
            SELECT INTO num_stations TRUNC(RANDOM() * 3 + 2)::INTEGER; -- Случайное число от 2 до 5
            FOR station IN SELECT station_id FROM stations ORDER BY RANDOM() LIMIT num_stations
                LOOP
                    INSERT INTO marshruts (marshrut_id, station_id, order_num)
                    VALUES (marshrut_id, station.station_id, order_num);
                    order_num := order_num + 1;
                END LOOP;
            marshrut_id := marshrut_id + 1;
        END LOOP;
END;
$$ LANGUAGE plpgsql;


-- CREATE OR REPLACE FUNCTION generate_tmarshruts() RETURNS VOID AS
DO
$$
DECLARE
    m1                   RECORD;
    m2                   RECORD;
    s1                   RECORD;
    s2                   RECORD;
    tmarshrut_id_counter INTEGER := 1;
    var_order_num            INTEGER;
BEGIN
    FOR m1 IN SELECT * FROM marshruts m WHERE m.order_num > 1
        LOOP
            FOR m2 IN SELECT * FROM marshruts m WHERE m.marshrut_id > m1.marshrut_id AND
                                                    m.station_id = m1.station_id AND
                                                    m.order_num < (SELECT MAX(mt.order_num) from marshruts mt where mt.marshrut_id = m.marshrut_id)
                LOOP
                    var_order_num := 1;
                    FOR s1 IN SELECT * FROM marshruts m WHERE m.marshrut_id = m1.marshrut_id AND m.order_num <= m1.order_num
                        LOOP
                            INSERT INTO tmarshruts (tmarshrut_id, marshrut_id, station_id, order_num)
                            VALUES (tmarshrut_id_counter, s1.marshrut_id, s1.station_id, var_order_num);
                            var_order_num := var_order_num + 1;
                        END LOOP;
                    FOR s2 IN SELECT * FROM marshruts m WHERE m.marshrut_id = m2.marshrut_id AND m.order_num >= m2.order_num
                        LOOP
                            INSERT INTO tmarshruts (tmarshrut_id, marshrut_id, station_id, order_num)
                            VALUES (tmarshrut_id_counter, s2.marshrut_id, s2.station_id, var_order_num - 1);
                            var_order_num := var_order_num + 1;
                        END LOOP;
                    tmarshrut_id_counter := tmarshrut_id_counter + 1;
                END LOOP;
        END LOOP;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM tmarshruts LIMIT 10;

CREATE OR REPLACE FUNCTION generate_timetable(n INTEGER DEFAULT 10) RETURNS VOID AS
$$
DECLARE
    train            RECORD;
    marshrut         RECORD;
    station_sequence RECORD;
    station_count    INTEGER;
    arrival_time     TIMESTAMP;
    departure_time   TIMESTAMP;
    i                INTEGER;
BEGIN
    FOR train IN SELECT * FROM trains
        LOOP
            FOR marshrut IN SELECT * FROM marshruts WHERE marshrut_id = train.marshrut_id ORDER BY order_num
                LOOP
                    station_count := (SELECT COUNT(*) FROM marshruts WHERE marshrut_id = train.marshrut_id);
                    i := 1;
                    FOR station_sequence IN SELECT *
                                            FROM marshruts
                                            WHERE marshrut_id = train.marshrut_id
                                            ORDER BY order_num
                        LOOP
                            IF i = 1 THEN
                                arrival_time := NOW(); -- Тут надо задать рандомное время прибытия
                                departure_time := arrival_time + (RANDOM() * 60)::INTEGER *
                                                                 INTERVAL '1 minute';
                            ELSIF i = station_count THEN
                                departure_time := arrival_time;
                            ELSE
                                arrival_time := departure_time + (RANDOM() * 60)::INTEGER *
                                                                 INTERVAL '1 minute';
                                departure_time := arrival_time + (RANDOM() * 60)::INTEGER *
                                                                 INTERVAL '1 minute';
                            END IF;

                            INSERT INTO timetable (train_id, station_id, marshrut_id, arrival_time, departure_time, napr)
                            VALUES (train.train_id, station_sequence.station_id, marshrut.marshrut_id, arrival_time,
                                    departure_time, TRUE);

                            i := i + 1;
                        END LOOP;
                END LOOP;
        END LOOP;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION generate_empl(n INTEGER DEFAULT 20) RETURNS VOID AS
$$
DECLARE
    i          INTEGER;
    position   TEXT;
    station_id INTEGER;
BEGIN
    FOR i IN 1..n
        LOOP
            -- Случайное определение должности сотрудника
            WITH positions AS (SELECT unnest(ARRAY ['Driver', 'Conductor', 'Engineer', 'Security Guard']) AS position)
            SELECT position
            INTO position
            FROM positions
            ORDER BY RANDOM()
            LIMIT 1;

            -- Случайный выбор станции
            SELECT station_id INTO station_id FROM stations ORDER BY RANDOM() LIMIT 1;

            -- Вставка данных о сотруднике
            INSERT INTO empl (employee_id, FIO, place, station_id)
            VALUES (i, 'Employee ' || i, position, station_id);
        END LOOP;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION generate_train_empl() RETURNS VOID AS
$$
DECLARE
    train         RECORD;
    employee_id   INTEGER;
    num_employees INTEGER;
BEGIN
    FOR train IN SELECT train_id FROM trains
        LOOP
            SELECT TRUNC(RANDOM() * 2 + 1)::INTEGER INTO num_employees; -- от 1 до 3 сотрудников

            WHILE num_employees > 0
                LOOP
                    SELECT employee_id INTO employee_id FROM empl ORDER BY RANDOM() LIMIT 1;

                    INSERT INTO train_empl (train_id, employee_id)
                    VALUES (train.train_id, employee_id);

                    num_employees := num_employees - 1;
                END LOOP;
        END LOOP;
END;
$$ LANGUAGE plpgsql;