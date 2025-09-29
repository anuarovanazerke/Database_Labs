--A-1
CREATE TABLE employees (
    emp_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    department VARCHAR(50),
    salary INTEGER,
    hire_date DATE,
    status VARCHAR(20) DEFAULT 'Active'
);

CREATE TABLE departments (
    dept_id SERIAL PRIMARY KEY,
    dept_name VARCHAR(50),
    budget INTEGER,
    manager_id INTEGER
);

CREATE TABLE projects (
    project_id SERIAL PRIMARY KEY,
    project_name VARCHAR(100),
    dept_id INTEGER,
    start_date DATE,
    end_date DATE,
    budget INTEGER
);

--2 insert with col. spec.
INSERT INTO employees (emp_id, first_name, last_name, department)
VALUES (1, 'John', 'Doe', 'IT');

--3 insert with default
INSERT INTO employees (first_name, last_name, department)
VALUES ('Jane', 'Smith', 'HR');

--4 insert mult. row
INSERT INTO departments (dept_name, budget, manager_id)
VALUES ('IT', 100000, 1),
       ('HR', 50000, 2),
       ('Sales', 80000, 3);
 

--5 insert with expres.
INSERT INTO employees (first_name, last_name, department, hire_date, salary)
VALUES ('Alice', 'Brown', 'Finance', CURRENT_DATE, 50000 * 1.1);

--6 insert from select
CREATE TEMP TABLE temp_employees AS
SELECT * FROM employees WHERE department = 'IT';

--С 
--7 update with arith.
UPDATE employees SET salary = salary * 1.1;

--8 update with where
UPDATE employees
SET status = 'Senior'
WHERE salary > 60000 AND hire_date < '2020-01-01';


--9 update using case
UPDATE employees
SET department = CASE
    WHEN salary > 80000 THEN 'Management'
    WHEN salary BETWEEN 50000 AND 80000 THEN 'Senior'
    ELSE 'Junior'
END;


--10 update with default
UPDATE employees
SET department = DEFAULT
WHERE status = 'Inactive';


--11 update with subquery
UPDATE departments d
SET budget = (
    SELECT AVG(salary) * 1.2
    FROM employees e
    WHERE e.department = d.dept_id
);

--12 update multiple columns
UPDATE employees
SET salary = salary * 1.15,
    status = 'Promoted'
WHERE department = 'Sales';


--D
--13 delete with sam. where
DELETE FROM employees WHERE status = 'Terminated';

--14 delete with comp. where
DELETE FROM employees
WHERE salary < 40000
  AND hire_date > '2023-01-01'
  AND department IS NULL;

--15 delete with subquery
DELETE FROM departments
WHERE dept_id NOT IN (
    SELECT DISTINCT department
    FROM employees
    WHERE department IS NOT NULL
);

--16 delete with returning
DELETE FROM projects
WHERE end_date < '2023-01-01'
RETURNING *;


--E 
--17 insert with null
INSERT INTO employees (first_name, last_name, salary, department)
VALUES ('NullTest', 'Employee', NULL, NULL);

--18 update null 
UPDATE employees
SET department = 'Unassigned'
WHERE department IS NULL;

--19 delete with null
DELETE FROM employees
WHERE salary IS NULL OR department IS NULL;


--F
--20 insert with returning
INSERT INTO employees (first_name, last_name, department, salary)
VALUES ('Mike', 'Jordan', 'IT', 70000)
RETURNING emp_id, first_name || ' ' || last_name AS full_name;

--21 update with returning
UPDATE employees
SET salary = salary + 5000
WHERE department = 'IT'
RETURNING emp_id, salary - 5000 AS old_salary, salary AS new_salary;

--22 delete with returning
DELETE FROM employees
WHERE hire_date < '2020-01-01'
RETURNING *;



--G
--23 conditional insert
INSERT INTO employees (first_name, last_name, department, salary)
SELECT 'John', 'Doe', 'Finance', 60000
WHERE NOT EXISTS (
    SELECT 1 FROM employees WHERE first_name = 'John' AND last_name = 'Doe'
);

--24 update with join
UPDATE employees e
SET salary = salary * (
    CASE
        WHEN (SELECT budget FROM departments d WHERE d.dept_id = e.department) > 100000 THEN 1.10
        ELSE 1.05
    END
);

--25 bulk operations
INSERT INTO employees (first_name, last_name, department, salary)
VALUES ('A', 'One', 'IT', 50000),
       ('B', 'Two', 'HR', 45000),
       ('C', 'Three', 'Sales', 55000),
       ('D', 'Four', 'Finance', 60000),
       ('E', 'Five', 'IT', 70000);

UPDATE employees
SET salary = salary * 1.1
WHERE first_name IN ('A','B','C','D','E');

--26 data migration
CREATE TABLE employee_archive AS TABLE employees WITH NO DATA;

INSERT INTO employee_archive
SELECT * FROM employees WHERE status = 'Inactive';

DELETE FROM employees WHERE status = 'Inactive';

--27 complex business logic
UPDATE projects p
SET end_date = end_date + INTERVAL '30 days'
WHERE budget > 50000
  AND (SELECT COUNT(*) FROM employees e WHERE e.department = p.dept_id) > 3;
