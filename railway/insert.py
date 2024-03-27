import psycopg2
from psycopg2 import extras
import random
from faker import Faker
import datetime
import time
import getpass

faker = Faker()
random.seed(21212)


def connect():
    password = getpass.getpass("Введите пароль: ")
    return psycopg2.connect(
        dbname="railway2",
        user="postgres",
        password=password,
        host="localhost"
    )


def generate_stations(n=10):
    return [{"station_id": i, "name": faker.unique.city()} for i in range(1, n + 1)]


def generate_station_distances(stations, min_distance=10, max_distance=500):
    distances = []
    for i, station1 in enumerate(stations):
        for station2 in stations[i + 1:]:
            distance = {
                "station1_id": station1["station_id"],
                "station2_id": station2["station_id"],
                "distance": random.randint(min_distance, max_distance)
            }
            distances.append(distance)
    return distances


def generate_marshruts(stations, n=5):
    marshruts = []
    for marshrut_id in range(1, n + 1):
        # Генерируем случайное количество станций для каждого маршрута, например, от 2 до длины списка станций
        num_stations = random.randint(2, min(len(stations),
                                             5))  # Предполагаем, что маршрут не превышает 5 станций для упрощения
        station_ids = random.sample(stations, num_stations)
        for order_num, station_id in enumerate(station_ids, start=1):
            marshruts.append({
                "marshrut_id": marshrut_id,
                "station_id": station_id['station_id'],
                "order_num": order_num
            })
    return marshruts


def generate_tmarshruts(marshruts):
    tmarshruts = []
    tmarshrut_id_counter = 1

    # Сначала создаем маппинг маршрутов по их ID для легкого доступа
    marshrut_mapping = {}
    for marshrut in marshruts:
        if marshrut['marshrut_id'] not in marshrut_mapping:
            marshrut_mapping[marshrut['marshrut_id']] = []
        marshrut_mapping[marshrut['marshrut_id']].append(marshrut)

    # Ищем все возможные комбинации для пересадок
    for marshrut_id, marshrut_data in marshrut_mapping.items():
        for next_marshrut_id, next_marshrut_data in marshrut_mapping.items():
            if marshrut_id == next_marshrut_id:
                continue  # Пропускаем одинаковые маршруты
            # Ищем общую станцию
            common_stations = [data for data in marshrut_data if
                               data['station_id'] in [n_data['station_id'] for n_data in next_marshrut_data]]
            if common_stations:
                # Для каждой общей станции формируем полный пересадочный маршрут
                for common_station in common_stations:
                    combined_marshrut = marshrut_data[:common_station['order_num']] + next_marshrut_data[
                                                                                      next((index for index, d in
                                                                                            enumerate(
                                                                                                next_marshrut_data)
                                                                                            if d.get('station_id') ==
                                                                                            common_station[
                                                                                                'station_id']), 0):]
                    for order, data in enumerate(combined_marshrut, start=1):
                        tmarshruts.append({
                            "tmarshrut_id": tmarshrut_id_counter,
                            "marshrut_id": data['marshrut_id'],
                            "station_id": data['station_id'],
                            "order_num": order
                        })
                    tmarshrut_id_counter += 1

    return tmarshruts


def generate_trains(stations, marshruts, n=10):
    return [{
        "train_id": i,
        "category": faker.random_element(elements=('Regular', 'Express', 'Luxury')),
        "quantity": random.randint(5, 15),
        "head_station_id": random.choice(stations)["station_id"],
        "marshrut_id": random.choice(marshruts)["marshrut_id"]
    } for i in range(1, n + 1)]


def generate_timetable(trains, marshruts, n=10):
    timetable = []
    id_counter = 1
    for train in trains:
        marshrut = next((m for m in marshruts if m['marshrut_id'] == train['marshrut_id']), None)
        if not marshrut:
            continue
        station_sequence = sorted([m for m in marshruts if m['marshrut_id'] == marshrut['marshrut_id']],
                                  key=lambda x: x['order_num'])
        for _ in range(n):
            for i, station in enumerate(station_sequence):
                # Для каждой станции устанавливаем время прибытия и отправления, кроме первой и последней
                arrival_time = faker.date_time_between_dates(datetime_start="-2y", datetime_end="now")
                departure_time = arrival_time + datetime.timedelta(minutes=random.randint(5, 60))
                timetable.append({
                    "timetable_id": id_counter,
                    "train_id": train["train_id"],
                    "station_id": station["station_id"],
                    "marshrut_id": marshrut['marshrut_id'],
                    "arrival_time": arrival_time if i > 0 else departure_time,
                    "departure_time": departure_time if i < len(station_sequence) - 1 else arrival_time,
                    "napr": True
                })
                id_counter += 1
    return timetable


def generate_empl(stations, n=20):
    empl = []
    positions = ['Driver', 'Conductor', 'Engineer', 'Security Guard']
    for i in range(1, n + 1):
        station = random.choice(stations)
        empl.append({
            "employee_id": i,
            "FIO": faker.unique.name(),
            "place": random.choice(positions),
            "station_id": station["station_id"]
        })
    return empl


def generate_train_empl(trains, empl):
    train_empl = []
    used_employees = set()
    for train in trains:
        for _ in range(random.randint(1, 3)):
            while True:
                employee = random.choice(empl)
                if employee["employee_id"] not in used_employees:
                    used_employees.add(employee["employee_id"])
                    break
            train_empl.append({
                "train_id": train["train_id"],
                "employee_id": employee["employee_id"]
            })
    return train_empl


def generate_waitings(timetable, n=50):
    waitings = []
    for el in random.choices(timetable, k=n):
        wait = random.randint(0, 120)
        waitings.append({
            "waiting_id": len(waitings) + 1,
            "train_id": el["train_id"],
            "date": el["arrival_time"] + datetime.timedelta(minutes=wait),
            "napr": True,
            "value": wait
        })
    return waitings


def generate_passengers(n=10):
    return [{"passenger_id": i, "full_name": faker.unique.name()} for i in range(1, n + 1)]


def generate_tickets(passengers, timetable, n=50):
    tickets = []
    for _ in range(n):
        passenger = random.choice(passengers)
        departure_timetable = random.choice(timetable)
        arrival_timetable = random.choice(timetable)
        while departure_timetable == arrival_timetable or departure_timetable["marshrut_id"] != arrival_timetable["marshrut_id"]:
            arrival_timetable = random.choice(timetable)
        purchase_date = faker.date_time_between_dates(datetime_start="-1y", datetime_end="now")
        tickets.append({
            "passenger_id": passenger["passenger_id"],
            "departure_timetable": departure_timetable["timetable_id"],
            "arrival_timetable": arrival_timetable["timetable_id"],
            "purchase_date": purchase_date
        })
    return tickets


def insert_data(conn, table_name, data):
    last_time = time.time()
    if not data:
        print(f"No data provided for table {table_name}")
        return

    columns = data[0].keys()
    column_names = ", ".join(columns)

    query = f"INSERT INTO {table_name} ({column_names}) VALUES %s"
    values = [[item[column] for column in columns] for item in data]

    cur = conn.cursor()
    try:
        extras.execute_values(cur, query, values, template=None, page_size=100)
        conn.commit()
        print(f"\"{table_name}\" successfully loaded into the database")
    except Exception as e:
        print(f"An error occurred: {e}")
        conn.rollback()
    finally:
        cur.close()


def main():
    # Подключение к базе данных
    conn = connect()

    global_time = time.time()

    start_time = time.time()
    stations = generate_stations(1000)
    insert_data(conn, "stations", stations)
    insert_time = time.time()
    print(f"Time taken to generate and insert data: {insert_time - start_time} seconds")

    start_time = time.time()
    distances = generate_station_distances(stations)
    insert_data(conn, "distances", distances)
    insert_time = time.time()
    print(f"Time taken to generate and insert data: {insert_time - start_time} seconds")

    start_time = time.time()
    marshruts = generate_marshruts(stations, 500)
    insert_data(conn, "marshruts", marshruts)
    insert_time = time.time()
    print(f"Time taken to generate and insert data: {insert_time - start_time} seconds")

    start_time = time.time()
    tmarshruts = generate_tmarshruts(random.choices(marshruts, k=100))
    insert_data(conn, "tmarshruts", tmarshruts)
    insert_time = time.time()
    print(f"Time taken to generate and insert data: {insert_time - start_time} seconds")

    start_time = time.time()
    trains = generate_trains(stations, marshruts, 1000)
    insert_data(conn, "trains", trains)
    insert_time = time.time()
    print(f"Time taken to generate and insert data: {insert_time - start_time} seconds")

    start_time = time.time()
    passengers = generate_passengers(100)
    insert_data(conn, "passengers", passengers)
    insert_time = time.time()
    print(f"Time taken to generate and insert data: {insert_time - start_time} seconds")

    start_time = time.time()
    timetable = generate_timetable(trains, marshruts, 10)
    insert_data(conn, "timetable", timetable)
    insert_time = time.time()
    print(f"Time taken to generate and insert data: {insert_time - start_time} seconds")

    start_time = time.time()
    tickets = generate_tickets(passengers, timetable, 10000)
    insert_data(conn, "tickets", tickets)
    insert_time = time.time()
    print(f"Time taken to generate and insert data: {insert_time - start_time} seconds")

    start_time = time.time()
    empl = generate_empl(stations, 10000)
    insert_data(conn, "empl", empl)
    insert_time = time.time()
    print(f"Time taken to generate and insert data: {insert_time - start_time} seconds")

    start_time = time.time()
    train_empl = generate_train_empl(trains, empl)
    insert_data(conn, "train_empl", train_empl)
    insert_time = time.time()
    print(f"Time taken to generate and insert data: {insert_time - start_time} seconds")

    start_time = time.time()
    waitings = generate_waitings(timetable, 2000)
    insert_data(conn, "waitings", waitings)
    insert_time = time.time()
    print(f"Time taken to generate and insert data: {insert_time - start_time} seconds")

    end_global_time = time.time()
    print(f"Time taken to generate and insert all data: {end_global_time - global_time} seconds")
    # Закрытие соединения с базой данных
    conn.close()


if __name__ == "__main__":
    main()
