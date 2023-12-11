import psycopg2
from faker import Faker
import getpass
import random
from datetime import datetime, timedelta

faker = Faker()

# Database connection credentials
password = getpass.getpass("Введите пароль: ")
db_config = {
    "dbname": "railway",
    "user": "postgres",
    "password": password,
    "host": "localhost"
}

# Establishing the database connection
conn = psycopg2.connect(**db_config)
conn.set_client_encoding('UTF8')
cur = conn.cursor()

# Stations data generation
city_names = [faker.city() for _ in range(111)]
for city in city_names:
    cur.execute(
        "INSERT INTO stations (station_name) VALUES (%s)",
        (city,)
    )
conn.commit()
print("Stations generation complete.")

# Trains and Tickets data generation
for i in range(1000):
    # Ticket generation
    general_tickets = random.randint(50, 200)
    platzkart_tickets = random.randint(50, 200)
    coupe_tickets = random.randint(10, 50)
    sv_tickets = random.randint(2, 10)

    cur.execute(
        "INSERT INTO tickets (general_tickets, platzkart_tickets, coupe_tickets, sv_tickets) VALUES (%s, %s, %s, %s) RETURNING tickets_id",
        (general_tickets, platzkart_tickets, coupe_tickets, sv_tickets)
    )
    tickets_id = cur.fetchone()[0]

    # Train generation
    category = random.choice(['Regular', 'Express', 'Luxury'])
    cur.execute(
        "INSERT INTO trains (category, total_tickets) VALUES (%s, %s)",
        (category, tickets_id)
    )
conn.commit()
print("Trains generation complete.")

# Routes data generation
for i in range(5000):
    departure_station, destination_station = random.sample(range(1, 111+1), 2)
    cur.execute(
        "INSERT INTO routes (departure_station, destination_station) VALUES (%s, %s) RETURNING route_id",
        (departure_station, destination_station)
    )
    route_id = cur.fetchone()[0]

    num_intermediate_stations = random.randint(2, 10)  # Количество промежуточных станций
    generated_stations = set()
    generated_stations.add(departure_station)
    generated_stations.add(destination_station)

    train_id = random.randint(1, 1000)
    arrival_date_time = faker.date_time_between(start_date='-2y', end_date='+1m')

    # Occupied tickets generation
    cur.execute(
        "SELECT total_tickets FROM trains WHERE train_id = %s",
        (train_id,)
    )
    total_tickets_id = cur.fetchone()[0]

    cur.execute(
        "SELECT general_tickets, platzkart_tickets, coupe_tickets, sv_tickets FROM tickets WHERE tickets_id = %s",
        (total_tickets_id,)
    )
    total_tickets_info = cur.fetchone()

    occupied_general = random.randint(0, total_tickets_info[0])
    occupied_platzkart = random.randint(0, total_tickets_info[1])
    occupied_coupe = random.randint(0, total_tickets_info[2])
    occupied_sv = random.randint(0, total_tickets_info[3])

    cur.execute(
        "INSERT INTO tickets (general_tickets, platzkart_tickets, coupe_tickets, sv_tickets) VALUES (%s, %s, %s, %s) RETURNING tickets_id",
        (occupied_general, occupied_platzkart, occupied_coupe, occupied_sv)
    )
    occupied_tickets_id = cur.fetchone()[0]

    # Добавление начальной станции
    cur.execute(
        "INSERT INTO intermediate_routes (route_id, station_id, order_number) VALUES (%s, %s, %s) RETURNING arrival_id",
        (route_id, departure_station, 1)
    )

    arrival_id = cur.fetchone()[0]

    cur.execute(
        "INSERT INTO schedules (train_id, arrival_id, occupied_tickets, arrival_date_time, parking_time) VALUES (%s, %s, %s, %s, %s)",
        (train_id, arrival_id, occupied_tickets_id, arrival_date_time, 0)
    )

    # Генерация промежуточных станций
    last_arrival_time = arrival_date_time
    for order in range(2, num_intermediate_stations):
        parking_time = random.randint(5, 60)  # in minutes
        travel_time = timedelta(minutes=random.randint(10, 120))
        next_arrival_time = last_arrival_time + travel_time + timedelta(minutes=parking_time)
        last_arrival_time = next_arrival_time
        station_id = random.choice([s for s in range(1, 111+1) if s not in generated_stations])
        generated_stations.add(station_id)
        cur.execute(
            "INSERT INTO intermediate_routes (route_id, station_id, order_number) VALUES (%s, %s, %s) RETURNING arrival_id",
            (route_id, station_id, order)
        )
        arrival_id = cur.fetchone()[0]
        occupied_general = random.randint(0, total_tickets_info[0])
        occupied_platzkart = random.randint(0, total_tickets_info[1])
        occupied_coupe = random.randint(0, total_tickets_info[2])
        occupied_sv = random.randint(0, total_tickets_info[3])

        cur.execute(
            "INSERT INTO tickets (general_tickets, platzkart_tickets, coupe_tickets, sv_tickets) VALUES (%s, %s, %s, %s) RETURNING tickets_id",
            (occupied_general, occupied_platzkart, occupied_coupe, occupied_sv)
        )
        occupied_tickets_id = cur.fetchone()[0]

        cur.execute(
            "INSERT INTO schedules (train_id, arrival_id, occupied_tickets, arrival_date_time, parking_time) VALUES (%s, %s, %s, %s, %s)",
            (train_id, arrival_id, occupied_tickets_id, next_arrival_time, parking_time)
        )

    # Добавление конечной станции
    cur.execute(
        "INSERT INTO intermediate_routes (route_id, station_id, order_number) VALUES (%s, %s, %s) RETURNING arrival_id",
        (route_id, destination_station, num_intermediate_stations)
    )
    arrival_id = cur.fetchone()[0]
    parking_time = random.randint(5, 60)
    occupied_general = random.randint(0, total_tickets_info[0])
    occupied_platzkart = random.randint(0, total_tickets_info[1])
    occupied_coupe = random.randint(0, total_tickets_info[2])
    occupied_sv = random.randint(0, total_tickets_info[3])

    cur.execute(
        "INSERT INTO tickets (general_tickets, platzkart_tickets, coupe_tickets, sv_tickets) VALUES (%s, %s, %s, %s) RETURNING tickets_id",
        (occupied_general, occupied_platzkart, occupied_coupe, occupied_sv)
    )
    occupied_tickets_id = cur.fetchone()[0]
    parking_time = random.randint(5, 60)  # in minutes
    travel_time = timedelta(minutes=random.randint(10, 120))
    next_arrival_time = last_arrival_time + travel_time + timedelta(minutes=parking_time)
    cur.execute(
        "INSERT INTO schedules (train_id, arrival_id, occupied_tickets, arrival_date_time, parking_time) VALUES (%s, %s, %s, %s, %s)",
        (train_id, arrival_id, occupied_tickets_id, next_arrival_time, parking_time)
    )

conn.commit()
print("Routes and schedules generation complete.")

# Passengers data generation
for _ in range(75000):
    full_name = faker.name()
    passport_details = faker.ssn()
    cur.execute(
        "INSERT INTO passengers (full_name, passport_details) VALUES (%s, %s)",
        (full_name, passport_details)
    )
conn.commit()
print("Passengers generation complete.")

# Passenger Trips data generation
for _ in range(20000):
    passenger_id = random.randint(1, 75000)
    schedule_id = random.randint(1, 20000)
    cur.execute(
        "INSERT INTO passenger_trips (passenger_id, schedule_id) VALUES (%s, %s)",
        (passenger_id, schedule_id)
    )
conn.commit()
print("Passenger trips generation complete.")

positions_hierarchy = {
    1: ['CEO'],
    2: ['HR Director', 'Logistics Director', 'Finance Director', 'IT Director', 'Marketing Director', 'Operations Director', 'Commercial Director', 'Technical Director', 'Legal Director', 'Quality Director'],
    3: ['Sales Manager', 'Service Manager', 'Procurement Manager', 'Production Manager', 'HR Manager', 'Finance Manager', 'IT Manager', 'Marketing Manager', 'Operations Manager', 'Quality Manager'],
    4: ['Engineer', 'Accountant', 'Analyst', 'Technician', 'Programmer', 'Designer', 'Economist', 'Legal Advisor', 'HR Specialist', 'Logistics Coordinator'],
    5: ['Conductor', 'Engineer', 'Worker', 'Technician', 'Clerk', 'Security Guard', 'Cleaner', 'Maintenance Staff', 'Storekeeper', 'Dispatcher']
}

manager_ids = {level: [] for level in positions_hierarchy}
employees_counts = {1: 1, 2: 10, 3: 100, 4: 1000, 5: 10000}

for level in sorted(positions_hierarchy):
    for _ in range(employees_counts[level]):
        full_name = faker.name()
        position = random.choice(positions_hierarchy[level])
        manager_id = None

        if level > 1:
            # Выбор случайного менеджера из предыдущего уровня
            possible_managers = manager_ids[level - 1]
            manager_id = random.choice(possible_managers) if possible_managers else None

        cur.execute(
            "INSERT INTO rzd_employees (full_name, position, manager_id) VALUES (%s, %s, %s) RETURNING employee_id",
            (full_name, position, manager_id)
        )
        new_employee_id = cur.fetchone()[0]
        manager_ids[level].append(new_employee_id)

conn.commit()
print("RZD employees generation complete.")

for i in range(500):
    train_id = random.randint(1, 1000)
    cur.execute(
        "INSERT INTO train_crews (train_id) VALUES (%s)",
        (train_id,)
    )
conn.commit()
print("Train crews generation complete.")

# Crew Members data generation
for i in range(2000):
    crew_id = random.randint(1, 500)
    employee_id = random.randint(1, 1000)
    cur.execute(
        "INSERT INTO crew_members (crew_id, employee_id) VALUES (%s, %s)",
        (crew_id, employee_id)
    )
conn.commit()
print("Crew members generation complete.")

# Close the connection
cur.close()
conn.close()

print("Data generation complete!")
