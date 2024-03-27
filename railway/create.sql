DROP TABLE IF EXISTS passengers CASCADE;
DROP TABLE IF EXISTS stations CASCADE;
DROP TABLE IF EXISTS marshruts CASCADE;
DROP TABLE IF EXISTS tmarshruts CASCADE;
DROP TABLE IF EXISTS trains CASCADE;
DROP TABLE IF EXISTS timetable CASCADE;
DROP TABLE IF EXISTS empl CASCADE;
DROP TABLE IF EXISTS train_empl CASCADE;
DROP TABLE IF EXISTS waitings CASCADE;
DROP TABLE IF EXISTS tickets CASCADE;
DROP TABLE IF EXISTS distances CASCADE;

CREATE TABLE IF NOT EXISTS passengers (
    passenger_id INT PRIMARY KEY,
    full_name TEXT NOT NULL                           -- Полное имя пассажира
);

CREATE TABLE IF NOT EXISTS stations (
    station_id INT PRIMARY KEY,
    name TEXT NOT NULL                                  --Название станции
);

CREATE TABLE IF NOT EXISTS distances (
    station1_id INT REFERENCES stations(station_id),
    station2_id INT REFERENCES stations(station_id),
    distance INT REFERENCES stations(station_id)
);

CREATE TABLE IF NOT EXISTS marshruts (
    marshrut_id INT,
    station_id INT REFERENCES stations(station_id),     --Ид станции
    order_num INT,                                      --Порядок маршрута
    PRIMARY KEY (marshrut_id, station_id)
);

CREATE TABLE IF NOT EXISTS tmarshruts (
    tmarshrut_id INT, 
    marshrut_id INT,                                    --Ид маршрута
    station_id INT,                                     --Ид станции
    order_num INT NOT NULL,                             --Порядок маршрута
    PRIMARY KEY(tmarshrut_id, marshrut_id, station_id),
    FOREIGN KEY(marshrut_id, station_id) REFERENCES  marshruts(marshrut_id, station_id)
);

CREATE TABLE IF NOT EXISTS trains (
    train_id INT PRIMARY KEY, 
    category TEXT,                                      --Категория поезда
    quantity INT,                                       --Количество вагонов
    head_station_id INT REFERENCES stations(station_id),--Ид головной станции
    marshrut_id INT                                     --Ид маршрута
);

CREATE TABLE IF NOT EXISTS timetable (
    timetable_id INT PRIMARY KEY,
    train_id INT REFERENCES trains(train_id) ON DELETE CASCADE , --Ид поезда
    station_id INT,                                              --Ид станции
    marshrut_id INT,                                             --Ид маршрута
    arrival_time TIMESTAMP,                                      --Время отправления
    departure_time TIMESTAMP,                                    --Время прибытия
	napr BOOLEAN,                                                --Направление движения
    FOREIGN KEY(marshrut_id, station_id) REFERENCES marshruts(marshrut_id, station_id)
);

CREATE TABLE IF NOT EXISTS tickets (
    ticket_id SERIAL PRIMARY KEY,
    passenger_id INT REFERENCES passengers(passenger_id),        -- ID пассажира
    departure_timetable INT REFERENCES timetable(timetable_id),  -- ID отправки
    arrival_timetable INT REFERENCES timetable(timetable_id),    -- ID приезда
    purchase_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP            -- Дата покупки билета
);

CREATE TABLE IF NOT EXISTS empl (
    employee_id INT PRIMARY KEY, 
    FIO TEXT,                                           --ФИО сотрудника
    place TEXT,                                         --Должность 
    station_id INT REFERENCES stations(station_id)      --Ид станции 
);

CREATE TABLE IF NOT EXISTS train_empl (
    train_id INT REFERENCES trains(train_id) ON DELETE CASCADE, --Номер поезда
    employee_id INT REFERENCES empl(employee_id),               --Ид работника
    PRIMARY KEY(train_id, employee_id)
);

CREATE TABLE IF NOT EXISTS waitings (
    waiting_id INT PRIMARY KEY, 
    train_id INT REFERENCES trains(train_id) ON DELETE CASCADE , --Ид поезда
    date TIMESTAMP,                                              --Время отправки
    napr BOOLEAN,                                                --Направление
    value INT                                                    --Задержка в минутах
);
