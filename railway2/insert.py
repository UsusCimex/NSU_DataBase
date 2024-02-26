import psycopg2
from psycopg2 import extras
import random
from faker import Faker
import datetime
import getpass

faker = Faker()

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

def generate_marshruts(n=5):
    return [{"marshrut_id": i} for i in range(1, n + 1)]

def generate_tmashruts(stations, marshruts):
    tmashruts = []
    used_combinations = set()
    for marshrut in marshruts:
        while True:
            station_ids = random.sample([station["station_id"] for station in stations], random.randint(3, 7))
            station_ids_tuple = tuple(station_ids)
            if station_ids_tuple not in used_combinations:
                used_combinations.add(station_ids_tuple)
                break
        for order_num, station_id in enumerate(station_ids, start=1):
            tmashruts.append({
                "tmashrut_id": len(tmashruts) + 1, 
                "marshrut_id": marshrut["marshrut_id"], 
                "station_id": station_id, 
                "order_num": order_num})
    return tmashruts

def generate_trains(stations, marshruts, n=10):
    return [{
        "train_id": i, 
        "category": faker.random_element(elements=('Regular', 'Express', 'Luxury')), 
        "quantity": random.randint(5, 15), 
        "head_station_id": random.choice(stations)["station_id"], 
        "marshrut_id": random.choice(marshruts)["marshrut_id"]
    } for i in range(1, n + 1)]

def generate_timetable(trains, stations, n=100):
    timetable = []
    for _ in range(n):
        train = random.choice(trains)
        station = random.choice(stations)
        arrival_time = faker.date_time_this_year(before_now=True, after_now=False)
        departure_time = arrival_time + datetime.timedelta(minutes=random.randint(5, 60))
        timetable.append({
            "id": len(timetable) + 1,
            "train_id": train["train_id"],
            "station_id": station["station_id"],
            "arrival_time": arrival_time,
            "departure_time": departure_time,
            "napr": faker.boolean(),
            "tickets": random.randint(0, 200)
        })
    return timetable
    
def generate_empl(stations, n=20):
    empl = []
    positions = ['Машинист', 'Кондуктор', 'Инженер', 'Охранник']
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

def generate_waitings(trains, n=5000):
    waitings = []
    for _ in range(n):
        train = random.choice(trains)
        waitings.append({
            "waiting_id": len(waitings) + 1,
            "train_id": train["train_id"],
            "date": faker.date_time_this_year(before_now=True, after_now=False),
            "napr": faker.random_element(elements=('Север', 'Юг', 'Восток', 'Запад')),
            "value": random.randint(0, 120)
        })
    return waitings

def insert_data(conn, table_name, data):
    if not data:
        print(f"No data provided for table {table_name}")
        return
    
    columns = data[0].keys()
    column_names = ", ".join(columns)
    
    query = f"INSERT INTO {table_name} ({column_names}) VALUES %s"
    values = [tuple(item[column] for column in columns) for item in data]
    
    cur = conn.cursor()
    try:
        print(f"\"{table_name}\" successfully loaded into the database")
        extras.execute_values(cur, query, values, template=None, page_size=100)
        conn.commit()
    except Exception as e:
        print(f"An error occurred: {e}")
        conn.rollback()
    finally:
        cur.close()

def main():
    # Подключение к базе данных
    conn = connect()
    
    stations = generate_stations(6000)
    insert_data(conn, "stations", stations)

    marshruts = generate_marshruts(5000)
    insert_data(conn, "marshrut", marshruts)

    tmashruts = generate_tmashruts(stations, marshruts)
    insert_data(conn, "tmashrut", tmashruts)

    trains = generate_trains(stations, marshruts, 1000)
    insert_data(conn, "trains", trains)

    timetable = generate_timetable(trains, stations, 20000)
    insert_data(conn, "timetable", timetable)

    empl = generate_empl(stations, 10000)
    insert_data(conn, "empl", empl)

    train_empl = generate_train_empl(trains, empl)
    insert_data(conn, "train_empl", train_empl)

    waitings = generate_waitings(trains, 5000)
    insert_data(conn, "waitings", waitings)

    # Закрытие соединения с базой данных
    conn.close()

if __name__ == "__main__":
    main()