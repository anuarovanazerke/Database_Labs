--Part 2
--2.1
CREATE INDEX emp_salary_idx ON employees(salary);
SELECT indexname, indexdef 
FROM pg_indexes 
WHERE tablename = 'employees';
--Two:Primary key(emp_id) and emp_salary_idx

--2.2
CREATE INDEX emp_dept_idx ON employees(dept_id);
SELECT * FROM employees WHERE dept_id=101;
--Speeds up JOIN operations,improves performance of queries that filter by the foreign key,Helps maintain referential integrity efficiently

--2.3
SELECT tablename, indexname, indexdef
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename, indexname;
--index on columns with UNIQUE constraints and PRIMARY KEY

--Part 3
--3.1
CREATE INDEX emp_dept_salary_idx ON employees(dept_id, salary);
SELECT emp_name,salary
FROM employees
WHERE dept_id=101 AND salary>52000;
--A multicolumn index only works from left to right.Since the index starts with dept_id, a query filtering only by salary cannot use it effectively.

--3.2
CREATE INDEX emp_salary_dept_idx ON employees(salary, dept_id);

SELECT *FROM employees WHERE dept_id=102 AND salary>50000;
SELECT *FROM employees WHERE salary>50000 AND dept_id=102;
--Yes,PostgreSQL can only use the index starting from the first column in the index definition.The leftmost column determines when the index can be applied.

--Part 4
--4.1
ALTER TABLE employees ADD COLUMN email VARCHAR(100);

UPDATE employees SET email = 'john.smith@company.com' WHERE emp_id = 1;
UPDATE employees SET email = 'jane.doe@company.com' WHERE emp_id = 2;
UPDATE employees SET email = 'mike.johnson@company.com' WHERE emp_id = 3;
UPDATE employees SET email = 'sarah.williams@company.com' WHERE emp_id = 4;
UPDATE employees SET email = 'tom.brown@company.com' WHERE emp_id = 5;

CREATE UNIQUE INDEX emp_email_unique_idx ON employees(email);

INSERT INTO employees (emp_id, emp_name, dept_id, salary, email)
VALUES (6, 'New Employee', 101, 55000, 'john.smith@company.com');
--ERROR: duplicate key value violates unique constraint

--4.2
ALTER TABLE employees ADD COLUMN phone VARCHAR(20) UNIQUE;

SELECT indexname,indexdef
FROM pg_indexes
WHERE tablename='employees' AND indexname LIKE '%phone%';

--PostgreSQL automatically created a B-tree index for the column with the UNIQUE constraint (phone).

--Part 5
--5.1
CREATE INDEX emp_salary_desc_idx ON employees(salary DESC);

SELECT emp_name,salary
FROM employees
ORDER BY salary DESC;
--PostgreSQL can return rows directly in sorted order without performing an additional sort operation.

--5.2
CREATE INDEX proj_budget_nulls_first_idx ON projects(budget NULLS FIRST);

SELECT proj_name,budget
FROM projects
ORDER BY budget NULLS FIRST;

--Part 6
--6.1
CREATE INDEX emp_name_lower_idx ON employees(LOWER(emp_name));

SELECT *FROM employees WHERE LOWER(emp_name)='john smith';
--Without the LOWER(emp_name) index, PostgreSQL would perform a sequential scan, applying the LOWER() function to every row, resulting in slow performance.

--6.2
ALTER TABLE employees ADD COLUMN hire_date DATE;
UPDATE employees SET hire_date = '2020-01-15' WHERE emp_id = 1;
UPDATE employees SET hire_date = '2019-06-20' WHERE emp_id = 2;
UPDATE employees SET hire_date = '2021-03-10' WHERE emp_id = 3;
UPDATE employees SET hire_date = '2020-11-05' WHERE emp_id = 4;
UPDATE employees SET hire_date = '2018-08-25' WHERE emp_id = 5;
CREATE INDEX emp_hire_year_idx ON employees(EXTRACT(YEAR FROM hire_date));

SELECT emp_name, hire_date
FROM employees
WHERE EXTRACT(YEAR FROM hire_date) = 2020;

--Part 7
--7.1
ALTER INDEX emp_salary_idx RENAME TO employees_salary_index;

SELECT indexname FROM pg_indexes WHERE tablename = 'employees';

--7.2
DROP INDEX emp_salary_dept_idx;
--It slows down INSERT/UPDATE/DELETE operations.It consumes disk space.It is redundant or not used by the query planner

--7.3
REINDEX INDEX employees_salary_index;

--Part 8
--8.1
SELECT e.emp_name, e.salary, d.dept_name
FROM employees e
JOIN departments d ON e.dept_id = d.dept_id
WHERE e.salary > 50000
ORDER BY e.salary DESC;

CREATE INDEX emp_salary_filter_idx ON employees(salary) WHERE salary > 50000;

--8.2
CREATE INDEX proj_high_budget_idx ON projects(budget)
WHERE budget > 80000;

SELECT proj_name, budget
FROM projects
WHERE budget > 80000;
--They are smaller, so they take less disk space
--They are faster
--They apply only to the relevant subset of data
--They reduce index maintenance overhead

--8.3
EXPLAIN SELECT * FROM employees WHERE salary > 52000;
--the index is being used.
--PostgreSQL scans the entire table; the index is not useful for that query.

--Part 9
--9.1
CREATE INDEX dept_name_hash_idx ON departments USING HASH (dept_name);

SELECT * FROM departments WHERE dept_name = 'IT';
--Use a Hash index only for equality comparisons (=).Hash indexes do not support range queries, inequalities, or sorting.

--9.2
CREATE INDEX proj_name_btree_idx ON projects(proj_name);
CREATE INDEX proj_name_hash_idx ON projects USING HASH (proj_name);

SELECT * FROM projects WHERE proj_name = 'Website Redesign';
SELECT * FROM projects WHERE proj_name > 'Database';

--Part 10
--10.1
SELECT
schemaname,
tablename,
indexname,
pg_size_pretty(pg_relation_size(indexname::regclass)) as index_size
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename, indexname;

--10.2
DROP INDEX IF EXISTS proj_name_hash_idx;

CREATE VIEW index_documentation AS
SELECT
tablename,
indexname,
indexdef,
'Improves salary-based queries' as purpose
FROM pg_indexes
WHERE schemaname = 'public'
AND indexname LIKE '%salary%';
SELECT * FROM index_documentation;

--Summary q
--1.B-tree
--2.Frequent WHERE filtering
--JOIN operations
--ORDER BY operations
--3.ery small tables.Columns that are rarely queried or frequently updated
--4.Indexes must be updated, making write operations slower.
--5.EXPLAIN SELECT ...