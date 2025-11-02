--Part 1
--1.1
CREATE TABLE employees (
emp_id INT PRIMARY KEY,
emp_name VARCHAR(50),
dept_id INT,
salary DECIMAL(10,2)
);

CREATE TABLE departments (
dept_id INT PRIMARY KEY,
dept_name VARCHAR(50),
location VARCHAR(50)
);

CREATE TABLE projects (
project_id INT PRIMARY KEY,
project_name VARCHAR(50),
dept_id INT,
budget DECIMAL(10,2)
);
--1.2
INSERT INTO employees (emp_id, emp_name, dept_id, salary) VALUES
(1, 'John Smith', 101, 50000),
(2, 'Jane Doe', 102, 60000),
(3, 'Mike Johnson', 101, 55000),
(4, 'Sarah Williams', 103, 65000),
(5, 'Tom Brown', NULL, 45000);

INSERT INTO departments (dept_id, dept_name, location) VALUES
(101, 'IT', 'Building A'),
(102, 'HR', 'Building B'),
(103, 'Finance', 'Building C'),
(104, 'Marketing', 'Building D');

INSERT INTO projects (project_id, project_name, dept_id, budget) VALUES
(1, 'Website Redesign', 101, 100000),
(2, 'Employee Training', 102, 50000),
(3, 'Budget Analysis', 103, 75000),
(4, 'Cloud Migration', 101, 150000),
(5, 'AI Research', NULL, 200000);

--Part 2 Cross join
--2.1
SELECT e.emp_name, d.dept_name
FROM employees e
CROSS JOIN departments d;
--N=num.of emp.=5 and M=num.of.dept=4 N*M=20

--2.2
--A
SELECT e.emp_name, d.dept_name
FROM employees e, departments d;
--B
SELECT e.emp_name, d.dept_name
FROM employees e
INNER JOIN departments d ON TRUE;

--2.3
SELECT e.emp_name, p.project_name
FROM employees e
CROSS JOIN projects p;

--Part 3 inner join
--3.1
SELECT e.emp_name, d.dept_name, d.location
FROM employees e
INNER JOIN departments d ON e.dept_id = d.dept_id;
--returns all employees where dept_id is NOT null.Tom Brown excluded due to his dept_id is null

--3.2
SELECT emp_name, dept_name, location
FROM employees
INNER JOIN departments USING (dept_id);
--only one dept_id column appears,in the ON option, if aliases are explicitly specified, you can get both (e.dept_id and d.dept_id).

--3.3
SELECT emp_name, dept_name, location
FROM employees
NATURAL INNER JOIN departments;

--3.4
SELECT e.emp_name, d.dept_name, p.project_name
FROM employees e
INNER JOIN departments d ON e.dept_id = d.dept_id
INNER JOIN projects p ON d.dept_id = p.dept_id;

--Part 4 left join
--4.1
SELECT e.emp_name, e.dept_id AS emp_dept, d.dept_id AS dept_dept, d.dept_name
FROM employees e
LEFT JOIN departments d ON e.dept_id = d.dept_id;
--For Tom Brown emp_id is null,d.dept_name also null

--4.2
SELECT emp_name, dept_id, dept_name
FROM employees
LEFT JOIN departments USING (dept_id);

--4.3
SELECT e.emp_name, e.dept_id
FROM employees e
LEFT JOIN departments d ON e.dept_id = d.dept_id
WHERE d.dept_id IS NULL;

--4.4
SELECT d.dept_name, COUNT(e.emp_id) AS employee_count
FROM departments d
LEFT JOIN employees e ON d.dept_id = e.dept_id
GROUP BY d.dept_id, d.dept_name
ORDER BY employee_count DESC;

--Part 5 right join
--5.1
SELECT e.emp_name, d.dept_name
FROM employees e
RIGHT JOIN departments d ON e.dept_id = d.dept_id;

--5.2
SELECT e.emp_name, d.dept_name
FROM departments d
LEFT JOIN employees e ON e.dept_id = d.dept_id;

--5.3
SELECT d.dept_name, d.location
FROM departments d
LEFT JOIN employees e ON e.dept_id = d.dept_id
WHERE e.emp_id IS NULL;

-Part 6 full join
--6.1
SELECT e.emp_name, e.dept_id AS emp_dept, d.dept_id AS dept_dept, d.dept_name
FROM employees e
FULL JOIN departments d ON e.dept_id = d.dept_id;
--records with emp. without dept is null on the left,records with dept. without emp. is null on the right

--6.2
SELECT d.dept_name, p.project_name, p.budget
FROM departments d
FULL JOIN projects p ON d.dept_id = p.dept_id;
--6.3
SELECT
CASE
WHEN e.emp_id IS NULL THEN 'Department without employees'
WHEN d.dept_id IS NULL THEN 'Employee without department'
ELSE 'Matched'
END AS record_status,
e.emp_name,
d.dept_name
FROM employees e
FULL JOIN departments d ON e.dept_id = d.dept_id
WHERE e.emp_id IS NULL OR d.dept_id IS NULL;

--Part 7 On vs Where
--7.1
SELECT e.emp_name, d.dept_name, e.salary
FROM employees e
LEFT JOIN departments d ON e.dept_id = d.dept_id AND d.location = 'Building A';

--7.2 
SELECT e.emp_name, d.dept_name, e.salary
FROM employees e
LEFT JOIN departments d ON e.dept_id = d.dept_id
WHERE d.location = 'Building A';

--Query 1 (ON clause): Applies the filter BEFORE the join, so all employees are included, but only departments in Building A are matched.Query 2 (WHERE clause): Applies the filter AFTER the join, so employees are excluded if their department is not in Building A.

--7.3
--On
SELECT e.emp_name, d.dept_name, e.salary
FROM employees e
INNER JOIN departments d ON e.dept_id = d.dept_id AND d.location = 'Building A';
--where
SELECT e.emp_name, d.dept_name, e.salary
FROM employees e
INNER JOIN departments d ON e.dept_id = d.dept_id
WHERE d.location = 'Building A';
--For INNER JOIN, the results are the same — the filter in ON or WHERE is equivalent, because INNER JOIN removes non-matching entries before/after the filter in the same way.

--Part 8 complex join
--8.1
SELECT
    d.dept_name,
    e.emp_name,
    e.salary,
    p.project_name,
    p.budget
FROM departments d
LEFT JOIN employees e ON d.dept_id = e.dept_id
LEFT JOIN projects p ON d.dept_id = p.dept_id
ORDER BY d.dept_name, e.emp_name;

--8.2
ALTER TABLE employees ADD COLUMN manager_id INT;

UPDATE employees SET manager_id = 3 WHERE emp_id = 1;
UPDATE employees SET manager_id = 3 WHERE emp_id = 2;
UPDATE employees SET manager_id = NULL WHERE emp_id = 3;
UPDATE employees SET manager_id = 3 WHERE emp_id = 4;
UPDATE employees SET manager_id = 3 WHERE emp_id = 5;

SELECT e.emp_name AS employee, m.emp_name AS manager
FROM employees e
LEFT JOIN employees m ON e.manager_id = m.emp_id;

--8.3
SELECT d.dept_name, AVG(e.salary) AS avg_salary
FROM departments d
INNER JOIN employees e ON d.dept_id = e.dept_id
GROUP BY d.dept_id, d.dept_name
HAVING AVG(e.salary) > 50000;

--1)INNER JOIN returns only matching rows from both tables; LEFT JOIN returns all rows from the left table and matching rows from the right (non—matching right ones are NULL).
--2)To generate all combinations of values (matrices of tests, schedules, all possible configurations).
--3)For external joins, the filter in ON is applied during matching (it can save rows from the left table with NULL in the right), and in WHERE it is applied after joining and can filter rows with NULL, thereby turning the external JOIN into an internal one.
--4)SELECT COUNT(*) FROM table1 CROSS JOIN table2  5*10=50
--5)For all columns with the same name in both tables.
--6)Unexpected connections, if both tables have additional columns with the same name, may lead to erroneous logic.
--7)
SELECT * 
FROM B 
RIGHT JOIN A ON A.id = B.id;
--8)Use a FULL OUTER JOIN when you need to include all records from both tables, showing matched rows together and unmatched rows from either side as NULL.It’s useful for finding all data, including “orphans” (records without matches) from both tables.
