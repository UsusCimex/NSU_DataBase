--- INSERT VALUES INTO TABLES ---
INSERT INTO category (name, necessity) 
VALUES 
    ('Motherboard', 'Necessarily'), 
    ('CPU', 'Necessarily'),
    ('RAM', 'Necessarily'),
    ('Hard drive', 'Necessarily'),
    ('Graphics card', 'Necessarily'),
    ('Power supply', 'Necessarily'),
    ('Cooling system', 'Necessarily'),
    ('Case', 'Necessarily'),
    ('Keyboard', 'Not necessarily'),
    ('Mouse', 'Not necessarily');

INSERT INTO components (name, category_id, price, guarantee_period) 
VALUES
    ('ASUS Prime B450M-A/CSM', 1, 7500, 12),
    ('AMD Ryzen 5 3600', 2, 24000, 12),
    ('AMD Ryzen 7 5700X', 2, 33000, 24),
    ('Corsair Vengeance LPX 16GB', 3, 8500, 6),
    ('Seagate Barracuda 2TB', 4, 6000, 6),
    ('MSI GeForce RTX 3060', 5, 45000, 6),
    ('EVGA 600 W1', 6, 4000, 1),
    ('Cooler Master Hyper 212 RGB', 7, 5500, 12),
    ('NZXT H510', 8, 9000, 1),
    ('Logitech G213 Prodigy', 9, 3500, 12),
    ('Razer Deathadder Elite', 10, 5000, 6),
    ('ASUS Prime B211', 1, 5500, 12),
    ('Viva Vivaldi 14', 1, 7890, 12),
    ('Intel Core I7 12500ULTRA', 2, 35500, 12),
    ('Intel Core I5 5555sd', 2, 22100, 24),
    ('G.Skill Trident Z5 Neo RGB DDR5-6000', 3, 28500, 6),
    ('Western Digital Blue Desktop 1TB', 4, 5000, 6),
    ('NVIDIA RTX 4090', 5, 99999, 6),
    ('Radeon RX 6800', 5, 44900, 12);


INSERT INTO vendor (company_name) 
VALUES
    ('ASUS'),
    ('AMD'),
    ('Corsair'),
    ('Seagate'),
    ('MSI'),
    ('EVGA'),
    ('Cooler Master'),
    ('NZXT'),
    ('Logitech'),
    ('Razer'),
    ('Intel');

INSERT INTO computer (serial_number, vendor_id) 
VALUES
    (10001, 1),
    (10002, 2),
    (10003, 2),
    (10004, 1),
    (10005, 5),
    (10006, 5),
    (10007, 1),
    (10008, 2),
    (10009, 5),
    (10010, 1);

INSERT INTO computer_components (computer_serial, component_id, date_sell_component, price_sell_computer) 
VALUES
    (10001, 1, '2021-11-01', 40900),
    (10001, 2, '2022-10-05', 40900),
    (10001, 5, '2021-11-01', 40900),
    (10002, 2, '2023-01-01', 54100),
    (10003, 3, '2021-11-01', 99899),
    (10003, 5, '2021-05-03', 99899),
    (10003, 6, '2021-10-12', 99899),
    (10003, 7, '2022-01-02', 99899),
    (10003, 8, '2021-09-05', 99899),
    (10004, 4, '2021-10-10', 101000),
    (10004, 5, '2021-10-10', 101000),
    (10004, 7, '2021-10-10', 101000),
    (10004, 10, '2021-10-10', 101000),
    (10005, 5, '2021-11-01', 35000),
    (10005, 8, '2022-11-11', 35000),
    (10005, 9, '2022-11-11', 35000),
    (10006, 6, '2021-11-01', 42900),
    (10006, 11, '2021-11-01', 42900),
    (10007, 7, '2020-11-01', 29999),
    (10008, 7, '2021-11-01', 35000),
    (10008, 8, '2021-02-05', 35000),
    (10008, 9, '2021-01-01', 35000),
    (10009, 9, '2021-11-01', 54100),
    (10010, 1, '2022-11-18', 75599),
    (10010, 10, '2023-05-17', 75599);