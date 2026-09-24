CREATE TABLE students_one_1(
    id      INTEGER PRIMARY KEY,
    name    VARCHAR(100) NOT NULL,
    email   VARCHAR(150) UNIQUE NOT NULL,
    faculty VARCHAR(100)
);

INSERT INTO students_one_1 (id, name, email, faculty) VALUES
    (1, 'Aidana Nurlanovna', 'aidana@example.com', 'Computer Science'),
    (2, 'Bekzat Amanov', 'bekzat@example.com', 'Economics'),
    (3, 'Cholpon Sultanova', 'cholpon@example.com', 'Law');

SELECT name, email FROM students_one_1 WHERE faculty = 'Law';

SELECT * FROM students_one_1;
SELECT name FROM students_one_1 ORDER BY name;
SELECT * FROM students LIMIT 2;
