--- a. Выбрать всех студентов с фамилией, начинающейся с буквы, задаваемой в запросе.
SELECT first_name, last_name, group_id
FROM students
WHERE last_name LIKE 'A%';

--- b. Найти всех студентов-однофамильцев.
SELECT first_name, last_name, group_id
FROM students
WHERE last_name IN (
    SELECT last_name
    FROM students
    GROUP BY last_name
    HAVING COUNT(id) > 1
);
--- OR ---
SELECT last_name
FROM students
GROUP BY last_name
HAVING COUNT(*) > 1;
--- OR ---
SELECT s1.first_name, s1.last_name, s1.group_id
FROM students s1
     JOIN students s2 ON s1.last_name = s2.last_name AND s1.id < s2.id;

--- c. Список всех студентов у преподавателя.
SELECT teachers.first_name AS "Teacher first_name", 
       teachers.last_name AS "Teacher last_name", 
       students.first_name, 
       students.last_name, 
       students.group_id
FROM students
     LEFT JOIN schedule ON schedule.group_id = students.group_id
     LEFT JOIN teachers ON teachers.id = schedule.teacher_id
LIMIT 10;

--- d. Найти группы, в которых нет старосты.
SELECT id
FROM groups
WHERE leader_id IS NULL;

--- e. Вывести все группы и среднюю успеваемость в них.
SELECT students.group_id,
       ROUND(AVG(marks.mark),2) AS "Average_mark"
FROM students
     LEFT JOIN marks ON marks.student_id = students.id 
GROUP BY students.group_id;

--- f. Вывести N лучших студентов по ср. баллу (N – параметр запроса).
SELECT first_name,
       last_name,
       group_id,
       ROUND(AVG(marks.mark),2) AS "Average_mark"
FROM students 
     LEFT JOIN marks ON marks.student_id = students.id 
GROUP BY students.id
ORDER BY "Average_mark" DESC
LIMIT 15;

--- g. Выбрать группу с самой высокой успеваемостью.
SELECT students.group_id,
       ROUND(AVG(marks.mark), 2) AS "Average_mark"
FROM students
     LEFT JOIN marks ON marks.student_id = students.id 
GROUP BY students.group_id
ORDER BY "Average_mark" DESC
LIMIT 1;

--- h. Посчитать количество студентов у каждого преподавателя.
SELECT teachers.first_name,
       teachers.last_name,
       COUNT(DISTINCT students.id) AS "Count"
FROM teachers
     LEFT JOIN schedule ON schedule.teacher_id = teachers.id
     LEFT JOIN students ON students.group_id = schedule.group_id
GROUP BY teachers.id
ORDER BY "Count" DESC;

--- i. Выбрать преподавателей, у которого студентов-отличников больше 10.
--- ChangedTask: Выбрать преподавателей, у которых студентов с средним баллом 4.5 и выше больше 5
SELECT teachers.first_name,
       teachers.last_name
FROM students
     LEFT JOIN schedule ON schedule.group_id = students.group_id
     LEFT JOIN teachers ON teachers.id = schedule.teacher_id
WHERE students.id IN (
     SELECT s.id
     FROM students s
          INNER JOIN marks ON marks.student_id = s.id
     GROUP BY s.id
     HAVING AVG(marks.mark) >= 4.5
)
GROUP BY teachers.id
HAVING COUNT(DISTINCT students.id) > 5;
