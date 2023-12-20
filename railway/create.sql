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
    station_name VARCHAR(255) UNIQUE NOT NULL
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
    passport_details VARCHAR(255) NOT NULL
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
