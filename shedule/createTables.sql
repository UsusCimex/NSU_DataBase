--- DROP DATABASE ---
-- DROP DATABASE shedule;

--- CREATE DATABASE ---
-- CREATE DATABASE shedule;

--- DROP TABLES ---
SELECT 'DROP TABLE "' || tablename || '" CASCADE;' 
FROM pg_tables
WHERE schemaname = 'public';

--- CREATE TABLES ---
CREATE TABLE specializations(
    id SERIAL PRIMARY KEY,
    title VARCHAR(20) NOT NULL
);

CREATE TABLE teachers(
    id SERIAL PRIMARY KEY,
    first_name VARCHAR(20) NOT NULL,
    last_name VARCHAR(20) NOT NULL,
    specialization_id INT NOT NULL,
    CONSTRAINT fk_specialization
        FOREIGN KEY (specialization_id)
        REFERENCES specializations(id)
        ON DELETE CASCADE
);

CREATE TABLE subjects(
    id SERIAL PRIMARY KEY,
    title VARCHAR(20) NOT NULL,
    specialization_id INT NOT NULL,
    CONSTRAINT fk_specialization2
        FOREIGN KEY (specialization_id)
        REFERENCES specializations(id)
        ON DELETE CASCADE
);

CREATE TABLE groups(
    id INT PRIMARY KEY,
    leader_id INT DEFAULT NULL
);

CREATE TABLE students(
    id SERIAL PRIMARY KEY,
    first_name VARCHAR(20) NOT NULL,
    last_name VARCHAR(20) NOT NULL,
    group_id INT NOT NULL
);

ALTER TABLE students
ADD CONSTRAINT fk_group
    FOREIGN KEY (group_id)
    REFERENCES groups(id)
    ON DELETE CASCADE;

ALTER TABLE groups
ADD CONSTRAINT fk_leader
    FOREIGN KEY (leader_id)
    REFERENCES students(id)
    ON DELETE SET NULL;


CREATE TYPE activity_types AS ENUM('Lecture', 'Lab', 'Discussion');

CREATE TABLE shedule(
    id SERIAL PRIMARY KEY,
    date_s DATE NOT NULL,
    number_pair INT NOT NULL CHECK (number_pair >= 1 AND number_pair <= 6),
    number_office INT NOT NULL,
    teacher_id INT NOT NULL,
    group_id INT NOT NULL,
    subject_id INT NOT NULL,
    activity_type activity_types NOT NULL,
    FOREIGN KEY (teacher_id) REFERENCES teachers(id) ON DELETE CASCADE,
    FOREIGN KEY (group_id) REFERENCES groups(id) ON DELETE CASCADE,
    FOREIGN KEY (subject_id) REFERENCES subjects(id) ON DELETE CASCADE
);

CREATE TABLE marks(
    id SERIAL PRIMARY KEY,
    mark INT NOT NULL CHECK (mark >= 2 AND mark <= 5),
    shedule_id INT NOT NULL,
    student_id INT NOT NULL,
    FOREIGN KEY (shedule_id) REFERENCES shedule(id) ON DELETE CASCADE,
    FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE
);