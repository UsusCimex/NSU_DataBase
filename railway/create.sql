--- DROP DATABASE ---
-- DROP DATABASE railway;

--- CREATE DATABASE ---
-- CREATE DATABASE railway;

--- DROP TABLES ---
SELECT 'DROP TABLE "' || tablename || '" CASCADE;' 
FROM pg_tables
WHERE schemaname = 'public';

--- CREATE TABLES ---
CREATE TABLE stations ( -- Станция
    station_id SERIAL PRIMARY KEY,
    station_name VARCHAR(255) UNIQUE NOT NULL,
    header_station INTEGER REFERENCES stations(station_id)
);

CREATE TABLE routes ( -- Маршрут
    route_id SERIAL PRIMARY KEY,
    destination_station INTEGER REFERENCES stations(station_id) NOT NULL,
    departure_station INTEGER REFERENCES stations(station_id) NOT NULL
);

CREATE TABLE tickets ( -- Информация о билетах
    tickets_id SERIAL PRIMARY KEY,
    general_tickets INTEGER,
    platzkart_tickets INTEGER,
    coupe_tickets INTEGER,
    sv_tickets INTEGER
);

CREATE TABLE trains ( -- Поезда
    train_id SERIAL PRIMARY KEY,
    category VARCHAR(255),
    total_tickets INTEGER REFERENCES tickets(tickets_id)
);

CREATE TABLE intermediate_routes ( -- Промежуточные станции
    arrival_id SERIAL PRIMARY KEY,
    route_id INTEGER REFERENCES routes(route_id) NOT NULL,
    station_id INTEGER REFERENCES stations(station_id) NOT NULL,
    order_number INTEGER
);

CREATE TABLE schedules ( -- Расписание
    schedule_id SERIAL PRIMARY KEY,
    train_id INTEGER REFERENCES trains(train_id) NOT NULL,
    arrival_id INTEGER REFERENCES intermediate_routes(arrival_id) NOT NULL,
    occupied_tickets INTEGER REFERENCES tickets(tickets_id), 
    arrival_date_time TIMESTAMP,
    train_delay INTEGER,
    parking_time INTEGER
);

CREATE TABLE passengers ( -- Пассажиры
    passenger_id SERIAL PRIMARY KEY,
    full_name VARCHAR(255) NOT NULL,
    passport_details VARCHAR(255) UNIQUE NOT NULL
);

CREATE TABLE passenger_trips ( -- Поездка пассажира
    trip_id SERIAL PRIMARY KEY,
    passenger_id INTEGER REFERENCES passengers(passenger_id) NOT NULL,
    ticket_type VARCHAR(255) NOT NULL,
    departure_station_schedule INTEGER REFERENCES schedules(schedule_id) NOT NULL,
    destination_station_schedule INTEGER REFERENCES schedules(schedule_id) NOT NULL
);

CREATE TABLE rzd_employees ( -- Сотрудник РЖД
    employee_id SERIAL PRIMARY KEY,
    full_name VARCHAR(255),
    position VARCHAR(255),
    manager_id INTEGER REFERENCES rzd_employees(employee_id)
);

CREATE TABLE train_crews ( -- Поездная бригада
    crew_id SERIAL PRIMARY KEY,
    train_id INTEGER REFERENCES trains(train_id)
);

CREATE TABLE crew_members ( -- Члены поездной бригады
    member_id SERIAL PRIMARY KEY,
    crew_id INTEGER REFERENCES train_crews(crew_id),
    employee_id INTEGER REFERENCES rzd_employees(employee_id)
);

-- Проверки наличия билетов и заполнение
CREATE FUNCTION check_ticket_availability()
RETURNS TRIGGER AS $$
DECLARE
    departure_order_number INTEGER;
    destination_order_number INTEGER;
    max_tickets INTEGER;
    occupied_tickets_on_segment INTEGER;
BEGIN
    -- Получаем порядковые номера для станций отправления и назначения
    SELECT order_number 
        INTO departure_order_number 
        FROM intermediate_routes 
        WHERE arrival_id = NEW.departure_station_schedule;
    SELECT order_number 
        INTO destination_order_number 
        FROM intermediate_routes 
        WHERE arrival_id = NEW.destination_station_schedule;

    -- Проверяем, что маршруты совпадают
    IF departure_order_number IS NULL OR destination_order_number IS NULL OR departure_order_number >= destination_order_number THEN
        RAISE EXCEPTION 'Некорректные станции отправления и назначения.';
    END IF;

    -- Определяем максимальное количество выбранного типа билетов на поезд
    EXECUTE 'SELECT ' || NEW.ticket_type || '_tickets FROM tickets 
        WHERE tickets_id = (SELECT total_tickets FROM trains WHERE train_id = $1)' 
        INTO max_tickets 
        USING NEW.train_id;

    -- Проверяем количество занятых билетов выбранного типа на каждом участке маршрута
    FOR i IN departure_order_number..destination_order_number-1 LOOP
        EXECUTE 'SELECT COUNT(*) 
            FROM passenger_trips 
            JOIN schedules ON passenger_trips.departure_station_schedule = schedules.schedule_id OR passenger_trips.destination_station_schedule = schedules.schedule_id 
            JOIN intermediate_routes ON schedules.arrival_id = intermediate_routes.arrival_id 
            WHERE intermediate_routes.order_number BETWEEN $1 AND $2 AND passenger_trips.ticket_type = $3 AND schedules.train_id = $4' 
            INTO occupied_tickets_on_segment 
            USING i, i+1, NEW.ticket_type, NEW.train_id;

        -- Проверяем, достаточно ли свободных мест на участке
        IF occupied_tickets_on_segment >= max_tickets THEN
            RAISE EXCEPTION 'Недостаточно свободных билетов типа % на участке между станциями с порядковыми номерами % и %.', NEW.ticket_type, i, i+1;
        END IF;
    END LOOP;

    -- Увеличиваем количество занятых мест для выбранного типа билета
    EXECUTE 'UPDATE tickets SET ' || NEW.ticket_type || '_tickets = ' || NEW.ticket_type || '_tickets + 1 
        WHERE tickets_id = 
            (SELECT occupied_tickets 
            FROM schedules 
            WHERE schedule_id = $1)' 
        USING NEW.departure_station_schedule;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ensure_ticket_availability
BEFORE INSERT ON passenger_trips
FOR EACH ROW
EXECUTE FUNCTION check_ticket_availability();


-- Предотвращения дублирования названий станций
CREATE FUNCTION check_station_name_uniqueness()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.station_name IS NOT DISTINCT FROM OLD.station_name THEN
    RETURN NEW;
  END IF;

  IF EXISTS(SELECT 1 FROM stations WHERE station_name = NEW.station_name) THEN
    RAISE EXCEPTION 'Название станции % уже существует.', NEW.station_name;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER unique_station_name
BEFORE UPDATE ON stations
FOR EACH ROW
EXECUTE FUNCTION check_station_name_uniqueness();

-- Предотвращения дублирования бронирования билетов
CREATE OR REPLACE FUNCTION check_duplicate_booking()
RETURNS TRIGGER AS $$
BEGIN
  IF EXISTS(SELECT 1 FROM passenger_trips WHERE passenger_id = NEW.passenger_id AND departure_station_schedule = NEW.departure_station_schedule) THEN
    RAISE EXCEPTION 'Пассажир уже забронировал билет на этот рейс.';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_check_duplicate_booking
BEFORE INSERT ON passenger_trips
FOR EACH ROW
EXECUTE FUNCTION check_duplicate_booking();