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

INSERT INTO components (name, categoryid, price, guaranteeperiod) 
VALUES
    ('ASUS Prime B450M-A/CSM', 1, 7500, 1),
    ('AMD Ryzen 5 3600', 2, 24000, 1),
    ('AMD Ryzen 7 5700X', 2, 33000, 2)
    ('Corsair Vengeance LPX 16GB', 3, 8500, '2023-06-30'),
    ('Seagate Barracuda 2TB', 4, 6000, '2022-12-01'),
    ('MSI GeForce RTX 3060', 5, 45000, '2025-02-10'),
    ('EVGA 600 W1', 6, 4000, '2024-09-05'),
    ('Cooler Master Hyper 212 RGB', 7, 5500, '2023-11-25'),
    ('NZXT H510', 8, 9000, '2024-07-18'),
    ('Logitech G213 Prodigy', 9, 3500, '2023-03-12'),
    ('Razer Deathadder Elite', 10, 5000, '2022-10-20');

INSERT INTO vendor (companyname) 
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
    ('Razer');

INSERT INTO computer (serialnumber, vendorid) 
VALUES
    (10001, 1),
    (10002, 2),
    (10003, 3),
    (10004, 4),
    (10005, 5),
    (10006, 6),
    (10007, 7),
    (10008, 8),
    (10009, 9),
    (10010, 10);

INSERT INTO computercomponents (computerid, componentid, datesellcomponent, pricesellcomputer) 
VALUES
    (10001, 1, '2021-11-01', 40900),
    (10001, 2, '2021-11-01', 40900),
    (10001, 3, '2021-11-01', 40900),
    (10001, 4, '2021-11-01', 40900),
    (10001, 5, '2021-11-01', 40900),
    (10001, 6, '2021-11-01', 40900),
    (10001, 7, '2021-11-01', 40900),
    (10001, 8, '2021-11-01', 40900),
    (10001, 9, '2021-11-01', 40900),
    (10001, 10, '2021-11-01', 40900);