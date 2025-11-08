--Part 2
--2.1
CREATE OR REPLACE VIEW employee_details AS
SELECT e.emp_id,
       e.emp_name,
       e.salary,
       d.dept_name,
       d.location
FROM employees e
JOIN departments d ON e.dept_id = d.dept_id;
--Its returns 4 rows, fnd returns only employees whose matches with table records and not null
--Tom brown doesnt appear because his dep_id is null

--2.2
CREATE OR REPLACE VIEW dept_statistics AS
SELECT d.dept_id,
       d.dept_name,
       COUNT(e.emp_id) AS employee_count,
       AVG(e.salary) AS avg_salary,
       MAX(e.salary) AS max_salary,
       MIN(e.salary) AS min_salary
FROM departments d
LEFT JOIN employees e ON d.dept_id = e.dept_id
GROUP BY d.dept_id, d.dept_name;

--2.3
CREATE OR REPLACE VIEW project_overview AS
SELECT p.project_id,
       p.project_name,
       p.budget,
       d.dept_name,
       d.location,
       (SELECT COUNT(*) FROM employees e WHERE e.dept_id = p.dept_id) AS team_size
FROM projects p
LEFT JOIN departments d ON p.dept_id = d.dept_id;

--2.4
CREATE OR REPLACE VIEW high_earners AS
SELECT emp_id, emp_name, dept_id, salary
FROM employees
WHERE salary > 55000;
--It displays employees earning more than 55,000.Jane Doe,Sarah Williams

--Part 3
--3.1
CREATE OR REPLACE VIEW employee_details AS
SELECT e.emp_id,
       e.emp_name,
       e.salary,
       d.dept_name,
       d.location,
       CASE
           WHEN e.salary > 60000 THEN 'High'
           WHEN e.salary > 50000 THEN 'Medium'
           ELSE 'Standard'
       END AS salary_grade
FROM employees e
JOIN departments d ON e.dept_id = d.dept_id;


--3.2
ALTER VIEW high_earners RENAME TO top_performers;

--3.3
CREATE TEMP VIEW temp_low_salary AS
SELECT * FROM employees WHERE salary < 50000;

SELECT * FROM temp_low_salary;

DROP VIEW IF EXISTS temp_low_salary;


--Part 4
--4.1
CREATE OR REPLACE VIEW employee_salaries AS
SELECT emp_id, emp_name, dept_id, salary
FROM employees;

--4.2
UPDATE employee_salaries
SET salary = 52000
WHERE emp_name = 'John Smith';
--employees table updates as well — John Smith’s salary becomes 52,000.

--4.3
INSERT INTO employee_salaries (emp_id, emp_name, dept_id, salary)
VALUES (6, 'Alice Johnson', 102, 58000);
--New row is added to the base table employees

--4.4
CREATE OR REPLACE VIEW it_employees AS
SELECT emp_id, emp_name, dept_id, salary
FROM employees
WHERE dept_id = 101
WITH LOCAL CHECK OPTION;
 
CREATE OR REPLACE VIEW it_employees AS
SELECT emp_id, emp_name, dept_id, salary
FROM employees
WHERE dept_id = 101
WITH LOCAL CHECK OPTION;
INSERT INTO it_employees (emp_id, emp_name, dept_id, salary)
VALUES (7, 'Bob Wilson', 103, 60000);

--[44000] ERROR: new row violates check option for view "it_employees"
-- Detail: Failing row contains (7, Bob Wilson, 103, 60000.00, null).

--Part 5
--5.1
CREATE MATERIALIZED VIEW dept_summary_mv AS
SELECT d.dept_id,
       d.dept_name,
       COUNT(e.emp_id) AS total_employees,
       SUM(e.salary) AS total_salaries,
       COUNT(p.project_id) AS total_projects,
       SUM(p.budget) AS total_project_budget
FROM departments d
LEFT JOIN employees e ON d.dept_id = e.dept_id
LEFT JOIN projects p ON d.dept_id = p.dept_id
GROUP BY d.dept_id, d.dept_name
WITH DATA;


--5.2
INSERT INTO employees (emp_id, emp_name, dept_id, salary)
VALUES (8, 'Charlie Brown', 101, 54000);

SELECT * FROM dept_summary_mv WHERE dept_id = 101;

REFRESH MATERIALIZED VIEW dept_summary_mv;

SELECT * FROM dept_summary_mv WHERE dept_id = 101;
--After refresh, department 101’s totals include Charlie Brown.

--5.3
CREATE UNIQUE INDEX ON dept_summary_mv(dept_id);
REFRESH MATERIALIZED VIEW CONCURRENTLY dept_summary_mv;
--CONCURRENTLY allows refresh without blocking reads but requires a unique index.

--5.4
CREATE MATERIALIZED VIEW project_stats_mv AS
SELECT p.project_name,
       p.budget,
       d.dept_name,
       COUNT(e.emp_id) AS assigned_employees
FROM projects p
LEFT JOIN departments d ON p.dept_id = d.dept_id
LEFT JOIN employees e ON e.dept_id = p.dept_id
GROUP BY p.project_name, p.budget, d.dept_name
WITH NO DATA;
--[55000] ERROR: materialized view "project_stats_mv" has not been populated
--Use the REFRESH MATERIALIZED VIEW command.

--Part 6
--6.1
CREATE ROLE analyst;
CREATE ROLE data_viewer WITH LOGIN PASSWORD 'viewer123';
CREATE ROLE report_user WITH LOGIN PASSWORD 'report456';

--6.2
CREATE ROLE db_creator WITH LOGIN PASSWORD 'creator789' CREATEDB;
CREATE ROLE user_manager WITH LOGIN PASSWORD 'manager101' CREATEROLE;
CREATE ROLE admin_user WITH LOGIN PASSWORD 'admin999' SUPERUSER;

--6.3
GRANT SELECT ON employees, departments, projects TO analyst;
GRANT ALL PRIVILEGES ON employee_details TO data_viewer;
GRANT SELECT, INSERT ON employees TO report_user;

--6.4
CREATE ROLE hr_team;
CREATE ROLE finance_team;
CREATE ROLE it_team;

CREATE ROLE hr_user1 WITH LOGIN PASSWORD 'hr001';
CREATE ROLE hr_user2 WITH LOGIN PASSWORD 'hr002';
CREATE ROLE finance_user1 WITH LOGIN PASSWORD 'fin001';

GRANT hr_team TO hr_user1;
GRANT hr_team TO hr_user2;
GRANT finance_team TO finance_user1;

GRANT SELECT, UPDATE ON employees TO hr_team;
GRANT SELECT ON dept_statistics TO finance_team;

--6.5
REVOKE UPDATE ON employees FROM hr_team;
REVOKE hr_team FROM hr_user2;
REVOKE ALL PRIVILEGES ON employee_details FROM data_viewer;

--6.6
ALTER ROLE analyst WITH LOGIN PASSWORD 'analyst123';
ALTER ROLE user_manager WITH SUPERUSER;
ALTER ROLE analyst WITH PASSWORD NULL;
ALTER ROLE data_viewer WITH CONNECTION LIMIT 5;

--Part 7
--7.1
CREATE ROLE read_only;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO read_only;

CREATE ROLE junior_analyst WITH LOGIN PASSWORD 'junior123';
CREATE ROLE senior_analyst WITH LOGIN PASSWORD 'senior123';

GRANT read_only TO junior_analyst;
GRANT read_only TO senior_analyst;

GRANT INSERT, UPDATE ON employees TO senior_analyst;

--7.2
CREATE ROLE project_manager WITH LOGIN PASSWORD 'pm123';

ALTER VIEW dept_statistics OWNER TO project_manager;
ALTER TABLE projects OWNER TO project_manager;

--7.3
CREATE ROLE temp_owner WITH LOGIN PASSWORD 'temp123';
CREATE TABLE temp_table (id INT) OWNER TO temp_owner;

REASSIGN OWNED BY temp_owner TO postgres;
DROP OWNED BY temp_owner;
DROP ROLE temp_owner;


--7.4
CREATE OR REPLACE VIEW hr_employee_view AS
SELECT * FROM employees WHERE dept_id = 102;
GRANT SELECT ON hr_employee_view TO hr_team;

CREATE OR REPLACE VIEW finance_employee_view AS
SELECT emp_id, emp_name, salary FROM employees;
GRANT SELECT ON finance_employee_view TO finance_team;


--Part 8
--8.1
CREATE OR REPLACE VIEW dept_dashboard AS
WITH emp AS (
    SELECT dept_id, COUNT(*) AS emp_count, ROUND(AVG(salary),2) AS avg_salary
    FROM employees GROUP BY dept_id
),
proj AS (
    SELECT dept_id, COUNT(*) AS active_projects, SUM(budget) AS total_project_budget
    FROM projects GROUP BY dept_id
)
SELECT d.dept_name,
       d.location,
       COALESCE(e.emp_count, 0) AS employee_count,
       COALESCE(e.avg_salary, 0) AS average_salary,
       COALESCE(p.active_projects, 0) AS number_of_active_projects,
       COALESCE(p.total_project_budget, 0) AS total_project_budget,
       CASE
           WHEN COALESCE(e.emp_count, 0) = 0 THEN 0
           ELSE ROUND(p.total_project_budget / e.emp_count, 2)
       END AS budget_per_employee
FROM departments d
LEFT JOIN emp e ON d.dept_id = e.dept_id
LEFT JOIN proj p ON d.dept_id = p.dept_id;

--8.2
ALTER TABLE projects
ADD COLUMN IF NOT EXISTS created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP;

CREATE OR REPLACE VIEW high_budget_projects AS
SELECT p.project_name,
       p.budget,
       d.dept_name,
       p.created_date,
       CASE
           WHEN p.budget > 150000 THEN 'Critical Review Required'
           WHEN p.budget > 100000 THEN 'Management Approval Needed'
           ELSE 'Standard Process'
       END AS approval_status
FROM projects p
LEFT JOIN departments d ON p.dept_id = d.dept_id
WHERE p.budget > 75000;


--8.3
CREATE ROLE viewer_role;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO viewer_role;

CREATE ROLE entry_role;
GRANT viewer_role TO entry_role;
GRANT INSERT ON employees, projects TO entry_role;

CREATE ROLE analyst_role;
GRANT entry_role TO analyst_role;
GRANT UPDATE ON employees, projects TO analyst_role;

CREATE ROLE manager_role;
GRANT analyst_role TO manager_role;
GRANT DELETE ON employees, projects TO manager_role;

CREATE ROLE alice WITH LOGIN PASSWORD 'alice123';
CREATE ROLE bob WITH LOGIN PASSWORD 'bob123';
CREATE ROLE charlie WITH LOGIN PASSWORD 'charlie123';

GRANT viewer_role TO alice;
GRANT analyst_role TO bob;
GRANT manager_role TO charlie;
