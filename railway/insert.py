import psycopg2
from faker import Faker
import getpass
import random
from datetime import datetime, timedelta

class PassengerTrip:
    def __init__(self, passenger_id, ticket_type, departure_schedule_id):
        self.passenger_id = passenger_id
        self.ticket_type = ticket_type
        self.departure_schedule_id = departure_schedule_id
        self.destination_schedule_id = None

    def set_destination(self, destination_schedule_id):
        self.destination_schedule_id = destination_schedule_id

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
city_names = set()
while (len(city_names) != 111):
    city_names.add(faker.city())
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
    general_tickets = random.randint(10, 50)
    platzkart_tickets = random.randint(10, 50)
    coupe_tickets = random.randint(5, 10)
    sv_tickets = random.randint(1, 5)

    cur.execute(
        "INSERT INTO tickets (general_tickets, platzkart_tickets, coupe_tickets, sv_tickets) VALUES (%s, %s, %s, %s) RETURNING tickets_id",
        (general_tickets, platzkart_tickets, coupe_tickets, sv_tickets)
    )
    tickets_id = cur.fetchone()[0]

    # Train generation
    category = random.choice(['Regular', 'Express', 'Luxury'])
    cur.execute(
        "INSERT INTO trains (category, tickets_id) VALUES (%s, %s)",
        (category, tickets_id)
    )
conn.commit()
print("Trains generation complete.")

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

# Routes data generation
for i in range(10000):
    departure_station, destination_station = random.sample(range(1, 111+1), 2)
    cur.execute(
        "INSERT INTO routes (route_id) VALUES (%s) RETURNING route_id",
        (i + 1, )
    )
    route_id = cur.fetchone()[0]

    num_intermediate_stations = random.randint(2, 10)  # Количество промежуточных станций
    generated_stations = set()
    generated_stations.add(departure_station)
    generated_stations.add(destination_station)

    train_id = random.randint(1, 1000)
    arrival_date_time = faker.date_time_between(start_date='-2y', end_date='+1y')

    # Occupied tickets generation
    cur.execute(
        "SELECT tickets_id FROM trains WHERE train_id = %s",
        (train_id,)
    )
    tickets_id_id = cur.fetchone()[0]

    cur.execute(
        "SELECT general_tickets, platzkart_tickets, coupe_tickets, sv_tickets FROM tickets WHERE tickets_id = %s",
        (tickets_id_id,)
    )
    tickets_id_info = cur.fetchone()

    occupied_general = random.randint(0, tickets_id_info[0])
    occupied_platzkart = random.randint(0, tickets_id_info[1])
    occupied_coupe = random.randint(0, tickets_id_info[2])
    occupied_sv = random.randint(0, tickets_id_info[3])

    # Добавление начальной станции
    cur.execute(
        "INSERT INTO intermediate_routes (route_id, station_id, order_number) VALUES (%s, %s, %s) RETURNING intermediate_routes_id",
        (route_id, departure_station, 1)
    )

    intermediate_routes_id = cur.fetchone()[0]

    cur.execute(
        "INSERT INTO schedules (train_id, intermediate_routes_id, arrival_date_time, train_delay, parking_time) VALUES (%s, %s, %s, %s, %s) RETURNING schedule_id",
        (train_id, intermediate_routes_id, arrival_date_time, 0, 0,)
    )

    schedule_id = cur.fetchone()[0]

    passenger_trips = []
    unique_passenger = set()

    for og in range(occupied_general) :
        passenger_id = random.randint(1, 75000)
        while (unique_passenger.__contains__(passenger_id)) :
            passenger_id = random.randint(1, 75000)
        unique_passenger.add(passenger_id)
        
        trip = PassengerTrip(passenger_id, 'general', schedule_id)
        passenger_trips.append(trip)
    for op in range(occupied_platzkart) :
        passenger_id = random.randint(1, 75000)
        while (unique_passenger.__contains__(passenger_id)) :
            passenger_id = random.randint(1, 75000)
        unique_passenger.add(passenger_id)
        
        trip = PassengerTrip(passenger_id, 'platzkart', schedule_id)
        passenger_trips.append(trip)
    for oc in range(occupied_coupe) :
        passenger_id = random.randint(1, 75000)
        while (unique_passenger.__contains__(passenger_id)) :
            passenger_id = random.randint(1, 75000)
        unique_passenger.add(passenger_id)
        
        trip = PassengerTrip(passenger_id, 'coupe', schedule_id)
        passenger_trips.append(trip)
    for os in range(occupied_sv) :
        passenger_id = random.randint(1, 75000)
        while (unique_passenger.__contains__(passenger_id)) :
            passenger_id = random.randint(1, 75000)
        unique_passenger.add(passenger_id)
        
        trip = PassengerTrip(passenger_id, 'sv', schedule_id)
        passenger_trips.append(trip)

    # Генерация промежуточных станций
    last_arrival_time = arrival_date_time
    for order in range(2, num_intermediate_stations):
        parking_time = random.randint(5, 60)  # in minutes
        train_delay = random.randint(0, 5) # in minutes
        travel_time = timedelta(minutes=random.randint(10, 120))
        next_arrival_time = last_arrival_time + travel_time + timedelta(minutes=parking_time) + timedelta(minutes=train_delay)
        last_arrival_time = next_arrival_time
        station_id = random.choice([s for s in range(1, 111+1) if s not in generated_stations])
        generated_stations.add(station_id)
        cur.execute(
            "INSERT INTO intermediate_routes (route_id, station_id, order_number) VALUES (%s, %s, %s) RETURNING intermediate_routes_id",
            (route_id, station_id, order)
        )
        intermediate_routes_id = cur.fetchone()[0]
        old_occupied_general = occupied_general
        old_occupied_platzkart = occupied_platzkart
        old_occupied_coupe = occupied_coupe
        old_occupied_sv = occupied_sv

        occupied_general = random.randint(0, tickets_id_info[0])
        occupied_platzkart = random.randint(0, tickets_id_info[1])
        occupied_coupe = random.randint(0, tickets_id_info[2])
        occupied_sv = random.randint(0, tickets_id_info[3])

        diff_general = occupied_general - old_occupied_general
        diff_platzkart = occupied_platzkart - old_occupied_platzkart
        diff_coupe = occupied_coupe - old_occupied_coupe
        diff_sv = occupied_sv - old_occupied_sv

        cur.execute(
            "INSERT INTO schedules (train_id, intermediate_routes_id, arrival_date_time, train_delay, parking_time) VALUES (%s, %s, %s, %s, %s) RETURNING schedule_id",
            (train_id, intermediate_routes_id, next_arrival_time, train_delay, parking_time)
        )

        schedule_id = cur.fetchone()[0]

        for og in range(abs(diff_general)) :
            if (diff_general > 0):
                passenger_id = random.randint(1, 75000)
                while (unique_passenger.__contains__(passenger_id)) :
                    passenger_id = random.randint(1, 75000)
                unique_passenger.add(passenger_id)
                
                trip = PassengerTrip(passenger_id, 'general', schedule_id)
                passenger_trips.append(trip)
            else :
                for trip in passenger_trips:
                    if trip.destination_schedule_id is None and trip.ticket_type == "general":
                        trip.set_destination(schedule_id)
                        break
        for op in range(abs(diff_platzkart)) :
            if (diff_platzkart > 0):
                passenger_id = random.randint(1, 75000)
                while (unique_passenger.__contains__(passenger_id)) :
                    passenger_id = random.randint(1, 75000)
                unique_passenger.add(passenger_id)
                
                trip = PassengerTrip(passenger_id, 'platzkart', schedule_id)
                passenger_trips.append(trip)
            else :
                for trip in passenger_trips:
                    if trip.destination_schedule_id is None and trip.ticket_type == "platzkart":
                        trip.set_destination(schedule_id)
                        break
        for og in range(abs(diff_coupe)) :
            if (diff_coupe > 0):
                passenger_id = random.randint(1, 75000)
                while (unique_passenger.__contains__(passenger_id)) :
                    passenger_id = random.randint(1, 75000)
                unique_passenger.add(passenger_id)
                
                trip = PassengerTrip(passenger_id, 'coupe', schedule_id)
                passenger_trips.append(trip)
            else :
                for trip in passenger_trips:
                    if trip.destination_schedule_id is None and trip.ticket_type == "coupe":
                        trip.set_destination(schedule_id)
                        break
        for og in range(abs(diff_sv)) :
            if (diff_sv > 0):
                passenger_id = random.randint(1, 75000)
                while (unique_passenger.__contains__(passenger_id)) :
                    passenger_id = random.randint(1, 75000)
                unique_passenger.add(passenger_id)
                
                trip = PassengerTrip(passenger_id, 'sv', schedule_id)
                passenger_trips.append(trip)
            else :
                for trip in passenger_trips:
                    if trip.destination_schedule_id is None and trip.ticket_type == "sv":
                        trip.set_destination(schedule_id)
                        break

    # Добавление конечной станции
    cur.execute(
        "INSERT INTO intermediate_routes (route_id, station_id, order_number) VALUES (%s, %s, %s) RETURNING intermediate_routes_id",
        (route_id, destination_station, num_intermediate_stations)
    )
    intermediate_routes_id = cur.fetchone()[0]
    parking_time = random.randint(5, 60)  # in minutes
    train_delay = random.randint(0, 5) # in minutes

    old_occupied_general = occupied_general
    old_occupied_platzkart = occupied_platzkart
    old_occupied_coupe = occupied_coupe
    old_occupied_sv = occupied_sv

    occupied_general = random.randint(0, tickets_id_info[0])
    occupied_platzkart = random.randint(0, tickets_id_info[1])
    occupied_coupe = random.randint(0, tickets_id_info[2])
    occupied_sv = random.randint(0, tickets_id_info[3])

    diff_general = occupied_general - old_occupied_general
    diff_platzkart = occupied_platzkart - old_occupied_platzkart
    diff_coupe = occupied_coupe - old_occupied_coupe
    diff_sv = occupied_sv - old_occupied_sv

    for og in range(abs(diff_general)) :
            if (diff_general > 0):
                passenger_id = random.randint(1, 75000)
                while (unique_passenger.__contains__(passenger_id)) :
                    passenger_id = random.randint(1, 75000)
                unique_passenger.add(passenger_id)
                
                trip = PassengerTrip(passenger_id, 'general', schedule_id)
                passenger_trips.append(trip)
            else :
                for trip in passenger_trips:
                    if trip.destination_schedule_id is None and trip.ticket_type == "general":
                        trip.set_destination(schedule_id)
                        break
    for op in range(abs(diff_platzkart)) :
        if (diff_platzkart > 0):
            passenger_id = random.randint(1, 75000)
            while (unique_passenger.__contains__(passenger_id)) :
                passenger_id = random.randint(1, 75000)
            unique_passenger.add(passenger_id)
            
            trip = PassengerTrip(passenger_id, 'platzkart', schedule_id)
            passenger_trips.append(trip)
        else :
            for trip in passenger_trips:
                if trip.destination_schedule_id is None and trip.ticket_type == "platzkart":
                    trip.set_destination(schedule_id)
                    break
    for og in range(abs(diff_coupe)) :
        if (diff_coupe > 0):
            passenger_id = random.randint(1, 75000)
            while (unique_passenger.__contains__(passenger_id)) :
                passenger_id = random.randint(1, 75000)
            unique_passenger.add(passenger_id)
            
            trip = PassengerTrip(passenger_id, 'coupe', schedule_id)
            passenger_trips.append(trip)
        else :
            for trip in passenger_trips:
                if trip.destination_schedule_id is None and trip.ticket_type == "coupe":
                    trip.set_destination(schedule_id)
                    break
    for og in range(abs(diff_sv)) :
        if (diff_sv > 0):
            passenger_id = random.randint(1, 75000)
            while (unique_passenger.__contains__(passenger_id)) :
                passenger_id = random.randint(1, 75000)
            unique_passenger.add(passenger_id)
            
            trip = PassengerTrip(passenger_id, 'sv', schedule_id)
            passenger_trips.append(trip)
        else :
            for trip in passenger_trips:
                if trip.destination_schedule_id is None and trip.ticket_type == "sv":
                    trip.set_destination(schedule_id)
                    break

    parking_time = random.randint(5, 60)  # in minutes
    travel_time = timedelta(minutes=random.randint(10, 120))
    next_arrival_time = last_arrival_time + travel_time + timedelta(minutes=parking_time)
    cur.execute(
        "INSERT INTO schedules (train_id, intermediate_routes_id, arrival_date_time, train_delay, parking_time) VALUES (%s, %s, %s, %s, %s) RETURNING schedule_id",
        (train_id, intermediate_routes_id, next_arrival_time, train_delay, parking_time)
    )
    schedule_id = cur.fetchone()[0]

    for trip in passenger_trips:
        if trip.destination_schedule_id is None:
            trip.set_destination(schedule_id)
        cur.execute(
            "INSERT INTO passenger_trips (passenger_id, ticket_type, departure_station_schedule, destination_station_schedule) VALUES (%s, %s, %s, %s)",
            (trip.passenger_id, trip.ticket_type, trip.departure_schedule_id, trip.destination_schedule_id)
        )

conn.commit()
print("Routes and schedules generation complete.")

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
