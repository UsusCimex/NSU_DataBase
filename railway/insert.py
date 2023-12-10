import psycopg2
from faker import Faker
import getpass
import random
from datetime import timedelta

faker = Faker()

password = getpass.getpass("Введите пароль: ")
db_config = {
    "dbname": "railway",
    "user": "postgres",
    "password": password,
    "host": "localhost"
}

conn = psycopg2.connect(**db_config)
conn.set_client_encoding('UTF8')
cur = conn.cursor()

# Генерация данных для станций
city_names = [faker.city() for _ in range(111)]
for city in city_names:
    cur.execute(
        "INSERT INTO stations (station_name) VALUES (%s)",
        (city,)
    )

conn.commit()
print("Stations generation complete.")

# Генерация поезда для каждого маршрута
for i in range(1000):
    category = random.choice(['Regular', 'Express', 'Luxury'])
    cur.execute(
        "INSERT INTO trains (category) VALUES (%s)",
        (category,)
    )
conn.commit()
print("Trains generation complete.")

# Генерация данных для маршрутов и поездов!
for i in range(5000):
    departure_station, destination_station = random.sample(range(1, 111+1), 2)
    cur.execute(
        "INSERT INTO routes (departure_station, destination_station) VALUES (%s, %s) RETURNING route_id",
        (departure_station, destination_station)
    )
    route_id = cur.fetchone()[0]

conn.commit()
print("Routes generation complete.")

# Генерация данных для составов поездов
for train_id in range(1, 1001):
    general_tickets = random.randint(50, 200)
    platzkart_tickets = random.randint(50, 200)
    coupe_tickets = random.randint(10, 50)
    sv_tickets = random.randint(2, 10)
    cur.execute(
        "INSERT INTO train_compositions (train_id, general_tickets, platzkart_tickets, coupe_tickets, sv_tickets) VALUES (%s, %s, %s, %s, %s)",
        (train_id, general_tickets, platzkart_tickets, coupe_tickets, sv_tickets)
    )

conn.commit()
print("Train compositions generation complete.")

# Генерация данных для расписаний
for i in range(20000):
    train_id = random.randint(1, 1000)
    route_id = random.randint(1, 5000)
    departure_date_time = faker.date_time_between(start_date='-2y', end_date='now')
    cur.execute(
        "INSERT INTO schedules (train_id, route_id, departure_date_time) VALUES (%s, %s, %s) RETURNING schedule_id",
        (train_id, route_id, departure_date_time)
    )
    schedule_id = cur.fetchone()[0]

    # Генерация случайного количества промежуточных станций
    num_stations = random.randint(2, 10)  # Например, от 2 до 10 станций
    last_arrival_time = departure_date_time
    for order_number in range(num_stations):
        station_id = random.randint(1, 111)
        if order_number == 0:
            # Для первой станции время прибытия равно времени отправления
            cur.execute(
                "INSERT INTO intermediate_schedules (schedule_id, station_id, order_number, arrival_date_time, parking_time) VALUES (%s, %s, %s, %s, %s)",
                (schedule_id, station_id, order_number, last_arrival_time, 0)
            )
        else:
            # Время в пути до следующей станции
            travel_time = timedelta(minutes=random.randint(10, 120))
            # Время прибытия на следующую станцию
            next_arrival_time = last_arrival_time + travel_time
            # Время стоянки на станции
            parking_time = random.randint(5, 30)
            cur.execute(
                "INSERT INTO intermediate_schedules (schedule_id, station_id, order_number, arrival_date_time, parking_time) VALUES (%s, %s, %s, %s, %s)",
                (schedule_id, station_id, order_number, next_arrival_time, parking_time)
            )
            # Обновление времени последнего прибытия для следующей станции
            last_arrival_time = next_arrival_time + timedelta(minutes=parking_time)

conn.commit()
print("Schedules generation complete.")

# Генерация данных для пассажиров
for _ in range(75000):
    full_name = faker.name()
    passport_details = faker.ssn()
    cur.execute(
        "INSERT INTO passengers (full_name, passport_details) VALUES (%s, %s)",
        (full_name, passport_details)
    )

conn.commit()
print("Passengers generation complete.")

# Закрытие соединения
cur.close()
conn.close()

print("Data generation complete!")
