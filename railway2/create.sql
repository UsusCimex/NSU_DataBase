DROP TABLE IF EXISTS stations CASCADE;
DROP TABLE IF EXISTS marshrut CASCADE;
DROP TABLE IF EXISTS tmashrut CASCADE;
DROP TABLE IF EXISTS trains CASCADE;
DROP TABLE IF EXISTS timetable CASCADE;
DROP TABLE IF EXISTS empl CASCADE;
DROP TABLE IF EXISTS train_empl CASCADE;
DROP TABLE IF EXISTS waitings CASCADE;

CREATE TABLE IF NOT EXISTS stations (
    station_id INT PRIMARY KEY,
    name TEXT NOT NULL                                  --Название станции
);

CREATE TABLE IF NOT EXISTS marshrut (
    marshrut_id INT PRIMARY KEY
);

CREATE TABLE IF NOT EXISTS tmashrut (
    tmashrut_id INT PRIMARY KEY, 
    marshrut_id INT REFERENCES marshrut(marshrut_id),   --Ид маршрута
    station_id INT REFERENCES stations(station_id),     --Ид станции
    order_num INT NOT NULL                              --Порядок маршрута
);

CREATE TABLE IF NOT EXISTS trains (
    train_id INT PRIMARY KEY, 
    category TEXT,                                      --Категория поезда
    quantity INT,                                       --Количество вагонов
    head_station_id INT REFERENCES stations(station_id),--Ид головной станции
    marshrut_id INT REFERENCES marshrut(marshrut_id)    --Ид маршрута
);

CREATE TABLE IF NOT EXISTS timetable (
    id INT PRIMARY KEY,
    train_id INT REFERENCES trains(train_id),           --Ид поезда
    station_id INT REFERENCES stations(station_id),     --Ид станции
    arrival_time TIMESTAMP,                             --Время отправления
    departure_time TIMESTAMP,                           --Время прибытия
	napr BOOLEAN,                                       --Направление движения
    tickets INT                                         --Количество билетов
);

CREATE TABLE IF NOT EXISTS empl (
    employee_id INT PRIMARY KEY, 
    FIO TEXT,                                           --ФИО сотрудника
    place TEXT,                                         --Должность 
    station_id INT REFERENCES stations(station_id)      --Ид станции 
);

CREATE TABLE IF NOT EXISTS train_empl (
    train_id INT REFERENCES trains(train_id),           --Номер поезда
    employee_id INT REFERENCES empl(employee_id),       --Ид работника
    PRIMARY KEY(train_id, employee_id)
);

CREATE TABLE IF NOT EXISTS waitings (
    waiting_id INT PRIMARY KEY, 
    train_id INT REFERENCES trains(train_id),           --Ид поезда
    date TIMESTAMP,                                     --Время отправки
    napr TEXT,                                          --Направление
    value INT                                           --Задержка в минутах
);
