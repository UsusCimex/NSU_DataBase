--- DROP DATABASE ---
-- DROP DATABASE computer_company;

--- CREATE DATABASE ---
-- CREATE DATABASE computer_company;

--- DROP TABLES ---
SELECT 'DROP TABLE "' || tablename || '" CASCADE;' 
FROM pg_tables
WHERE schemaname = 'public';

--- CREATE TABLES ---
CREATE TYPE neccessity_type AS ENUM('Necessarily', 'Not necessarily');

CREATE TABLE category (
    id SERIAL PRIMARY KEY,
    name VARCHAR(20) NOT NULL,
    necessity neccessity_type NOT NULL
);

CREATE TABLE components (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    category_id INT NOT NULL,
    price DECIMAL(10, 2) NOT NULL,
    guarantee_period INT,
    FOREIGN KEY (category_id) REFERENCES category(id) ON DELETE CASCADE
);

CREATE TABLE vendor (
    id SERIAL PRIMARY KEY,
    company_name VARCHAR(20) NOT NULL
);

CREATE TABLE computer (
    serial_number INT PRIMARY KEY,
    vendor_id INT,
    FOREIGN KEY (vendor_id) REFERENCES vendor(id) ON DELETE CASCADE
);

CREATE TABLE computer_components (
    id SERIAL PRIMARY KEY,
    computer_serial INT,
    component_id INT,
    date_sell_component DATE,
    price_sell_computer DECIMAL(10, 2),
    FOREIGN KEY (computer_serial) REFERENCES computer(serial_number) ON DELETE CASCADE,
    FOREIGN KEY (component_id) REFERENCES components(id) ON DELETE CASCADE
);