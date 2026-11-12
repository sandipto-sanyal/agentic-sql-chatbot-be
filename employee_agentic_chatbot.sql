

-- 2026-06-20 13:45:40
SELECT first_name, last_name, TIMESTAMPDIFF(YEAR, birth_date, CURDATE()) AS age FROM employees ORDER BY birth_date ASC LIMIT 1;

-- 2026-06-20 13:49:24
SELECT d.dept_name, AVG(s.salary) AS average_salary
FROM departments d
JOIN dept_emp de ON d.dept_no = de.dept_no
JOIN salaries s ON de.emp_no = s.emp_no
WHERE s.to_date = '9999-01-01'
GROUP BY d.dept_name;

-- 2026-06-20 13:52:05
SELECT d.dept_name, AVG(s.salary) AS average_salary, COUNT(e.emp_no) AS employee_count
FROM departments d
JOIN dept_emp de ON d.dept_no = de.dept_no
JOIN employees e ON de.emp_no = e.emp_no
JOIN salaries s ON e.emp_no = s.emp_no
GROUP BY d.dept_name
ORDER BY average_salary DESC
LIMIT 1;

-- 2026-06-20 13:55:01
SELECT d.dept_name, e.first_name, e.last_name, s.salary 
FROM salaries s 
JOIN employees e ON s.emp_no = e.emp_no 
JOIN dept_emp de ON e.emp_no = de.emp_no 
JOIN departments d ON de.dept_no = d.dept_no 
WHERE s.salary = (SELECT MAX(salary) 
                  FROM salaries s2 
                  JOIN dept_emp de2 ON s2.emp_no = de2.emp_no 
                  WHERE de2.dept_no = de.dept_no) 
ORDER BY d.dept_name;

-- 2026-06-20 14:04:09
SELECT d.dept_name, e.first_name, e.last_name, s.salary 
FROM departments d 
JOIN dept_emp de ON d.dept_no = de.dept_no 
JOIN salaries s ON de.emp_no = s.emp_no 
JOIN employees e ON de.emp_no = e.emp_no 
WHERE s.salary = (SELECT MAX(salary) 
                  FROM salaries s2 
                  JOIN dept_emp de2 ON s2.emp_no = de2.emp_no 
                  WHERE de2.dept_no = d.dept_no) 
ORDER BY d.dept_name;

-- 2026-06-20 14:13:11
WITH MaxSalaries AS (
    SELECT de2.dept_no, MAX(s2.salary) AS max_salary
    FROM salaries s2
    JOIN dept_emp de2 ON s2.emp_no = de2.emp_no
    GROUP BY de2.dept_no
),
DeptEmployees AS (
    SELECT d.dept_name, e.first_name, e.last_name, s.salary, de.dept_no
    FROM departments d
    JOIN dept_emp de ON d.dept_no = de.dept_no 
    JOIN salaries s ON de.emp_no = s.emp_no 
    JOIN employees e ON de.emp_no = e.emp_no 
)

SELECT de.dept_name, de.first_name, de.last_name, de.salary 
FROM DeptEmployees de
JOIN MaxSalaries ms ON de.dept_no = ms.dept_no AND de.salary = ms.max_salary
ORDER BY de.dept_name;

-- 2026-11-09 13:45:40
SELECT d.dept_name, e.first_name, e.last_name, s.salary
FROM departments d
JOIN dept_emp de ON d.dept_no = de.dept_no
JOIN salaries s ON de.emp_no = s.emp_no
JOIN employees e ON de.emp_no = e.emp_no
WHERE s.salary = (SELECT MAX(salary) FROM salaries s2 JOIN dept_emp de2 ON s2.emp_no = de2.emp_no WHERE de2.dept_no = d.dept_no)
ORDER BY d.dept_name;

-- 2026-11-09 13:46:24
WITH MaxSalaries AS (
    SELECT de2.dept_no, MAX(s.salary) AS max_salary
    FROM salaries s
    JOIN dept_emp de2 ON s.emp_no = de2.emp_no
    GROUP BY de2.dept_no
),
EmployeeSalaries AS (
    SELECT d.dept_name, e.first_name, e.last_name, s.salary
    FROM departments d
    JOIN dept_emp de ON d.dept_no = de.dept_no
    JOIN salaries s ON de.emp_no = s.emp_no
    JOIN employees e ON de.emp_no = e.emp_no
)
SELECT es.dept_name, es.first_name, es.last_name, es.salary
FROM EmployeeSalaries es
JOIN MaxSalaries ms ON es.salary = ms.max_salary
ORDER BY es.dept_name;

-- 2026-11-09 15:22:21
SELECT d.dept_name, e.first_name, e.last_name, s.salary 
FROM departments d 
JOIN dept_emp de ON d.dept_no = de.dept_no 
JOIN salaries s ON de.emp_no = s.emp_no 
JOIN employees e ON de.emp_no = e.emp_no 
WHERE (de.emp_no, s.from_date) IN (
    SELECT emp_no, MAX(from_date) 
    FROM salaries 
    GROUP BY emp_no
) 
GROUP BY d.dept_name 
ORDER BY s.salary DESC;

-- 2026-11-09 15:23:06
WITH LatestSalaries AS (
    SELECT emp_no, MAX(from_date) AS max_from_date
    FROM salaries
    GROUP BY emp_no
),
CurrentSalaries AS (
    SELECT s.emp_no, s.salary
    FROM salaries s
    JOIN LatestSalaries ls ON s.emp_no = ls.emp_no AND s.from_date = ls.max_from_date
)
SELECT d.dept_name, e.first_name, e.last_name, cs.salary 
FROM departments d 
JOIN dept_emp de ON d.dept_no = de.dept_no 
JOIN CurrentSalaries cs ON de.emp_no = cs.emp_no 
JOIN employees e ON de.emp_no = e.emp_no 
ORDER BY cs.salary DESC;

-- 2026-11-09 15:25:12
SELECT d.dept_name, e.first_name, e.last_name, s.salary 
FROM departments d 
JOIN dept_emp de ON d.dept_no = de.dept_no 
JOIN salaries s ON de.emp_no = s.emp_no 
JOIN employees e ON de.emp_no = e.emp_no 
WHERE (de.emp_no, s.from_date) IN (
    SELECT emp_no, MAX(from_date) 
    FROM salaries 
    GROUP BY emp_no
) 
GROUP BY d.dept_name 
ORDER BY s.salary DESC;

-- 2026-11-09 15:30:05
WITH LatestSalaries AS (
    SELECT emp_no, MAX(from_date) AS max_date
    FROM salaries
    GROUP BY emp_no
),
FilteredSalaries AS (
    SELECT s.emp_no, s.salary
    FROM salaries s
    JOIN LatestSalaries ls ON s.emp_no = ls.emp_no AND s.from_date = ls.max_date
),
EmployeeDepartments AS (
    SELECT d.dept_name, e.first_name, e.last_name, fs.salary
    FROM departments d
    JOIN dept_emp de ON d.dept_no = de.dept_no
    JOIN employees e ON de.emp_no = e.emp_no
    JOIN FilteredSalaries fs ON de.emp_no = fs.emp_no
)
SELECT dept_name, first_name, last_name, salary 
FROM EmployeeDepartments
ORDER BY salary DESC;

-- 2026-11-09 15:46:31
WITH MaxSalaries AS (
    SELECT de2.dept_no, MAX(s2.salary) AS max_salary
    FROM salaries s2
    JOIN dept_emp de2 ON s2.emp_no = de2.emp_no
    GROUP BY de2.dept_no
)

SELECT d.dept_name, e.first_name, e.last_name, s.salary
FROM departments d
JOIN dept_emp de ON d.dept_no = de.dept_no
JOIN salaries s ON de.emp_no = s.emp_no
JOIN employees e ON de.emp_no = e.emp_no
JOIN MaxSalaries ms ON d.dept_no = ms.dept_no AND s.salary = ms.max_salary;

-- 2026-11-09 15:48:55
WITH DepartmentSalaries AS (
    SELECT d.dept_name AS department, s.salary
    FROM dept_emp de
    JOIN departments d ON de.dept_no = d.dept_no
    JOIN salaries s ON de.emp_no = s.emp_no
)
SELECT department, AVG(salary) AS average_salary
FROM DepartmentSalaries
GROUP BY department;

-- 2026-11-09 15:52:35
SELECT d.dept_name, AVG(s.salary) as average_salary 
FROM departments d 
JOIN dept_emp de ON d.dept_no = de.dept_no 
JOIN salaries s ON de.emp_no = s.emp_no 
GROUP BY d.dept_name;

-- 2026-11-09 15:56:17
WITH EmployeeSalaries AS (
    SELECT d.dept_name as department, s.salary
    FROM dept_emp de
    JOIN departments d ON de.dept_no = d.dept_no
    JOIN salaries s ON de.emp_no = s.emp_no
)

SELECT department, AVG(salary) AS average_salary
FROM EmployeeSalaries
GROUP BY department;

-- 2026-11-09 15:56:31
SELECT d.dept_name as department, AVG(s.salary) AS average_salary
FROM dept_emp de
JOIN departments d ON de.dept_no = d.dept_no
JOIN salaries s ON de.emp_no = s.emp_no
GROUP BY d.dept_name;

-- 2026-11-09 15:59:14
WITH EmployeeData AS (
    SELECT d.dept_name AS department, s.salary
    FROM employees e
    JOIN dept_emp de ON e.emp_no = de.emp_no
    JOIN departments d ON de.dept_no = d.dept_no
    JOIN salaries s ON e.emp_no = s.emp_no
)
SELECT department, AVG(salary) AS average_salary
FROM EmployeeData
GROUP BY department;

-- 2026-11-09 16:01:02
WITH DepartmentSalaries AS (
    SELECT d.dept_name AS department, s.salary
    FROM dept_emp de
    JOIN departments d ON de.dept_no = d.dept_no
    JOIN salaries s ON de.emp_no = s.emp_no
)
SELECT department, AVG(salary) AS average_salary
FROM DepartmentSalaries
GROUP BY department;

-- 2026-11-09 17:03:26
WITH DepartmentSalaries AS (
    SELECT dept_emp.dept_no, salaries.salary
    FROM dept_emp
    JOIN salaries ON dept_emp.emp_no = salaries.emp_no
)

SELECT DepartmentSalaries.dept_no, AVG(DepartmentSalaries.salary) AS average_salary
FROM DepartmentSalaries
GROUP BY DepartmentSalaries.dept_no;

-- 2026-11-09 17:09:59
WITH DepartmentSalaries AS (
    SELECT d.dept_name as department, s.salary
    FROM dept_emp de
    JOIN departments d ON de.dept_no = d.dept_no
    JOIN salaries s ON de.emp_no = s.emp_no
)
SELECT department, AVG(salary) AS average_salary
FROM DepartmentSalaries
GROUP BY department;

-- 2026-11-09 17:29:38
WITH EmployeeSalaries AS (
    SELECT d.dept_name AS department, s.salary
    FROM employees e
    JOIN dept_emp de ON e.emp_no = de.emp_no
    JOIN departments d ON de.dept_no = d.dept_no
    JOIN salaries s ON e.emp_no = s.emp_no
)

SELECT department, AVG(salary) AS average_salary
FROM EmployeeSalaries
GROUP BY department;

-- 2026-11-09 17:37:06
WITH EmployeeSalaries AS (
    SELECT d.dept_name as department, s.salary
    FROM employees e
    JOIN dept_emp de ON e.emp_no = de.emp_no
    JOIN departments d ON de.dept_no = d.dept_no
    JOIN salaries s ON e.emp_no = s.emp_no
)

SELECT department, AVG(salary) as average_salary
FROM EmployeeSalaries
GROUP BY department;

-- 2026-11-09 17:45:54
SELECT d.dept_name, AVG(s.salary) as average_salary 
FROM departments d 
JOIN dept_emp de ON d.dept_no = de.dept_no 
JOIN salaries s ON de.emp_no = s.emp_no 
GROUP BY d.dept_name;

-- 2026-11-09 17:47:22
WITH DepartmentSalaries AS (
    SELECT d.dept_name AS department, s.salary
    FROM dept_emp de
    JOIN departments d ON de.dept_no = d.dept_no
    JOIN salaries s ON de.emp_no = s.emp_no
)

SELECT department, AVG(salary) AS average_salary
FROM DepartmentSalaries
GROUP BY department;

-- 2026-11-09 19:45:08
WITH DepartmentSalaries AS (
    SELECT d.dept_name AS department, s.salary
    FROM dept_emp de
    JOIN departments d ON de.dept_no = d.dept_no
    JOIN salaries s ON de.emp_no = s.emp_no
)

SELECT department, AVG(salary) AS average_salary
FROM DepartmentSalaries
GROUP BY department;

-- 2026-11-09 19:48:03
SELECT d.dept_name, AVG(s.salary) as average_salary 
FROM departments d 
JOIN dept_emp de ON d.dept_no = de.dept_no 
JOIN salaries s ON de.emp_no = s.emp_no 
GROUP BY d.dept_name;

-- 2026-11-09 19:50:25
WITH DepartmentSalaries AS (
    SELECT d.dept_name AS department, s.salary
    FROM dept_emp de
    JOIN departments d ON de.dept_no = d.dept_no
    JOIN salaries s ON de.emp_no = s.emp_no
)

SELECT department, AVG(salary) AS average_salary
FROM DepartmentSalaries
GROUP BY department;

-- 2026-11-09 19:52:42
WITH DepartmentSalaries AS (
    SELECT d.dept_name AS department, s.salary
    FROM dept_emp de
    JOIN departments d ON de.dept_no = d.dept_no
    JOIN salaries s ON de.emp_no = s.emp_no
)
SELECT department, AVG(salary) AS average_salary
FROM DepartmentSalaries
GROUP BY department;

-- 2026-11-09 20:01:14
SELECT d.dept_name, AVG(s.salary) as average_salary 
FROM salaries s 
JOIN dept_emp de ON s.emp_no = de.emp_no 
JOIN departments d ON de.dept_no = d.dept_no 
GROUP BY d.dept_name;

-- 2026-11-09 20:04:03
WITH EmployeeSalaries AS (
    SELECT d.dept_name, s.salary
    FROM employees e
    JOIN dept_emp de ON e.emp_no = de.emp_no
    JOIN departments d ON de.dept_no = d.dept_no
    JOIN salaries s ON e.emp_no = s.emp_no
)

SELECT dept_name, AVG(salary) AS average_salary
FROM EmployeeSalaries
GROUP BY dept_name;

-- 2026-11-09 21:10:27
WITH MaxSalaries AS (
    SELECT d.dept_name AS department, e.emp_no AS employee_id, MAX(s.salary) AS highest_salary
    FROM employees e
    JOIN dept_emp de ON e.emp_no = de.emp_no
    JOIN departments d ON de.dept_no = d.dept_no
    JOIN salaries s ON e.emp_no = s.emp_no
    GROUP BY d.dept_name, e.emp_no
)
SELECT department, employee_id, highest_salary
FROM MaxSalaries;

-- 2026-11-09 21:11:24
WITH EmployeeSalaries AS (
    SELECT 
        e.emp_no,
        MAX(s.salary) AS highest_salary
    FROM 
        employees e
    JOIN 
        salaries s ON e.emp_no = s.emp_no
    GROUP BY 
        e.emp_no
),
DepartmentEmployees AS (
    SELECT 
        de.emp_no,
        d.dept_name
    FROM 
        dept_emp de
    JOIN 
        departments d ON de.dept_no = d.dept_no
)
SELECT 
    de.dept_name AS department, 
    es.emp_no AS employee_id, 
    es.highest_salary
FROM 
    EmployeeSalaries es
JOIN 
    DepartmentEmployees de ON es.emp_no = de.emp_no;

-- 2026-11-09 21:14:38
WITH EmployeeSalaries AS (
    SELECT d.dept_no, e.emp_no, s.salary
    FROM employees e
    JOIN dept_emp de ON e.emp_no = de.emp_no
    JOIN departments d ON de.dept_no = d.dept_no
    JOIN salaries s ON e.emp_no = s.emp_no
)

SELECT dept_no, emp_no, MAX(salary) AS highest_salary
FROM EmployeeSalaries
GROUP BY dept_no;

-- 2026-11-09 21:14:56
WITH EmployeeDepartment AS (
    SELECT e.emp_no, de.dept_no
    FROM employees e
    JOIN dept_emp de ON e.emp_no = de.emp_no
),
EmployeeSalaries AS (
    SELECT ed.dept_no, ed.emp_no, s.salary
    FROM EmployeeDepartment ed
    JOIN salaries s ON ed.emp_no = s.emp_no
)

SELECT dept_no, emp_no, MAX(salary) AS highest_salary
FROM EmployeeSalaries
GROUP BY dept_no;

-- 2026-11-09 21:15:25
WITH EmployeeDetails AS (
    SELECT e.emp_no, de.dept_no, s.salary
    FROM employees e
    JOIN dept_emp de ON e.emp_no = de.emp_no
    JOIN salaries s ON e.emp_no = s.emp_no
)

SELECT dept_no, MAX(salary) AS highest_salary
FROM EmployeeDetails
GROUP BY dept_no;

-- 2026-11-11 15:58:43
WITH DepartmentEmployees AS (
    SELECT 
        de.emp_no,
        de.dept_no
    FROM 
        dept_emp de
),
EmployeeSalaries AS (
    SELECT 
        s.emp_no,
        s.salary
    FROM 
        salaries s
),
DepartmentInfo AS (
    SELECT 
        d.dept_no,
        d.dept_name
    FROM 
        departments d
)

SELECT 
    di.dept_name, 
    AVG(es.salary) AS average_salary
FROM 
    DepartmentEmployees de
JOIN 
    EmployeeSalaries es ON de.emp_no = es.emp_no
JOIN 
    DepartmentInfo di ON de.dept_no = di.dept_no
GROUP BY 
    di.dept_name;

-- 2026-11-11 16:25:16
WITH CurrentEmployees AS (SELECT emp_no, dept_no FROM dept_emp WHERE to_date = '9999-01-01'), CurrentSalaries AS (SELECT emp_no, salary FROM salaries WHERE to_date = '9999-01-01') SELECT d.dept_name AS department, ROUND(AVG(cs.salary), 2) AS average_salary FROM departments d JOIN CurrentEmployees ce ON ce.dept_no = d.dept_no JOIN CurrentSalaries cs ON cs.emp_no = ce.emp_no GROUP BY d.dept_no, d.dept_name ORDER BY average_salary DESC;

-- 2026-11-11 17:25:12
WITH CurrentEmployees AS (SELECT emp_no, dept_no FROM dept_emp WHERE to_date = '9999-01-01'), CurrentSalaries AS (SELECT emp_no, salary FROM salaries WHERE to_date = '9999-01-01') SELECT d.dept_name AS department, ROUND(AVG(cs.salary), 2) AS average_salary FROM departments d JOIN CurrentEmployees ce ON ce.dept_no = d.dept_no JOIN CurrentSalaries cs ON cs.emp_no = ce.emp_no GROUP BY d.dept_no, d.dept_name ORDER BY average_salary DESC;

-- 2026-11-11 17:27:07
WITH CurrentEmployees AS (SELECT emp_no, dept_no FROM dept_emp WHERE to_date = '9999-01-01'), CurrentSalaries AS (SELECT emp_no, salary FROM salaries WHERE to_date = '9999-01-01') SELECT d.dept_name AS department, ROUND(AVG(cs.salary), 2) AS average_salary FROM departments d JOIN CurrentEmployees ce ON ce.dept_no = d.dept_no JOIN CurrentSalaries cs ON cs.emp_no = ce.emp_no GROUP BY d.dept_no, d.dept_name ORDER BY average_salary DESC;

-- 2026-11-11 17:47:24
WITH ActiveAssignments AS (SELECT emp_no, dept_no FROM dept_emp WHERE to_date = '9999-01-01'), ActiveSalaries AS (SELECT emp_no, salary FROM salaries WHERE to_date = '9999-01-01') SELECT d.dept_name AS department, ROUND(AVG(s.salary), 2) AS average_salary FROM departments d JOIN ActiveAssignments de ON de.dept_no = d.dept_no JOIN ActiveSalaries s ON s.emp_no = de.emp_no GROUP BY d.dept_no, d.dept_name ORDER BY average_salary DESC;

-- 2026-11-11 17:48:22
WITH CurrentEmployees AS (SELECT emp_no, dept_no FROM dept_emp WHERE to_date = '9999-01-01'), CurrentSalaries AS (SELECT emp_no, salary FROM salaries WHERE to_date = '9999-01-01') SELECT d.dept_name AS department, ROUND(AVG(cs.salary), 2) AS average_salary FROM departments d JOIN CurrentEmployees ce ON ce.dept_no = d.dept_no JOIN CurrentSalaries cs ON cs.emp_no = ce.emp_no GROUP BY d.dept_no, d.dept_name ORDER BY average_salary DESC;

-- 2026-11-11 17:49:11
WITH CurrentEmployees AS (SELECT emp_no, dept_no FROM dept_emp WHERE to_date = '9999-01-01'), CurrentSalaries AS (SELECT emp_no, salary FROM salaries WHERE to_date = '9999-01-01') SELECT d.dept_name AS department, ROUND(AVG(cs.salary), 2) AS average_salary FROM departments d JOIN CurrentEmployees ce ON ce.dept_no = d.dept_no JOIN CurrentSalaries cs ON cs.emp_no = ce.emp_no GROUP BY d.dept_no, d.dept_name ORDER BY average_salary DESC;

-- 2026-11-11 17:50:45
WITH CurrentEmployees AS (SELECT emp_no, dept_no FROM dept_emp WHERE to_date = '9999-01-01'), CurrentSalaries AS (SELECT emp_no, salary FROM salaries WHERE to_date = '9999-01-01') SELECT d.dept_name AS department, ROUND(AVG(cs.salary), 2) AS average_salary FROM departments d JOIN CurrentEmployees ce ON ce.dept_no = d.dept_no JOIN CurrentSalaries cs ON cs.emp_no = ce.emp_no GROUP BY d.dept_no, d.dept_name ORDER BY average_salary DESC;

-- 2026-11-11 17:55:58
WITH CurrentEmployees AS (SELECT emp_no, dept_no FROM dept_emp WHERE to_date = '9999-01-01'), CurrentSalaries AS (SELECT emp_no, salary FROM salaries WHERE to_date = '9999-01-01') SELECT d.dept_name AS department, ROUND(AVG(cs.salary), 2) AS average_salary FROM departments d JOIN CurrentEmployees ce ON ce.dept_no = d.dept_no JOIN CurrentSalaries cs ON cs.emp_no = ce.emp_no GROUP BY d.dept_no, d.dept_name ORDER BY average_salary DESC;

-- 2026-11-11 18:03:30
WITH CurrentEmployees AS (SELECT emp_no, dept_no FROM dept_emp WHERE to_date = '9999-01-01'), CurrentSalaries AS (SELECT emp_no, salary FROM salaries WHERE to_date = '9999-01-01') SELECT d.dept_name AS department, ROUND(AVG(cs.salary), 2) AS average_salary FROM departments d JOIN CurrentEmployees ce ON ce.dept_no = d.dept_no JOIN CurrentSalaries cs ON cs.emp_no = ce.emp_no GROUP BY d.dept_no, d.dept_name ORDER BY average_salary DESC;

-- 2026-11-11 18:06:18
WITH ActiveAssignments AS (SELECT emp_no, dept_no FROM dept_emp WHERE to_date = '9999-01-01'), ActiveSalaries AS (SELECT emp_no, salary FROM salaries WHERE to_date = '9999-01-01') SELECT d.dept_name AS department, ROUND(AVG(s.salary), 2) AS average_salary FROM departments d JOIN ActiveAssignments de ON de.dept_no = d.dept_no JOIN ActiveSalaries s ON s.emp_no = de.emp_no GROUP BY d.dept_no, d.dept_name ORDER BY average_salary DESC;

-- 2026-11-11 18:08:16
WITH current_salaries AS (SELECT emp_no, salary FROM salaries WHERE to_date = '9999-01-01'), current_dept_assignments AS (SELECT emp_no, dept_no FROM dept_emp WHERE to_date = '9999-01-01'), employee_details AS (SELECT e.emp_no, e.first_name, e.last_name, ds.dept_no FROM employees e JOIN current_dept_assignments ds ON e.emp_no = ds.emp_no), department_salaries AS (SELECT d.dept_no, d.dept_name, ed.emp_no, CONCAT(ed.first_name, ' ', ed.last_name) AS employee_name, cs.salary FROM current_salaries cs JOIN employee_details ed ON cs.emp_no = ed.emp_no JOIN departments d ON ed.dept_no = d.dept_no), ranked_salaries AS (SELECT dept_no, employee_name, salary, DENSE_RANK() OVER(PARTITION BY dept_no ORDER BY salary DESC) AS salary_rank FROM department_salaries) SELECT d.dept_name AS department, r.employee_name, r.salary AS `highest salary` FROM ranked_salaries r JOIN departments d ON r.dept_no = d.dept_no WHERE r.salary_rank = 1 ORDER BY department, employee_name;

-- 2026-11-11 18:11:39
WITH current_salaries AS (SELECT emp_no, salary FROM salaries WHERE to_date = '9999-01-01'), current_dept_assignments AS (SELECT emp_no, dept_no FROM dept_emp WHERE to_date = '9999-01-01'), employee_details AS (SELECT e.emp_no, e.first_name, e.last_name, ds.dept_no FROM employees e JOIN current_dept_assignments ds ON e.emp_no = ds.emp_no), department_salaries AS (SELECT d.dept_no, d.dept_name, ed.emp_no, CONCAT(ed.first_name, ' ', ed.last_name) AS employee_name, cs.salary FROM current_salaries cs JOIN employee_details ed ON cs.emp_no = ed.emp_no JOIN departments d ON ed.dept_no = d.dept_no), ranked_salaries AS (SELECT dept_no, employee_name, salary, DENSE_RANK() OVER(PARTITION BY dept_no ORDER BY salary DESC) AS salary_rank FROM department_salaries) SELECT d.dept_name AS department, r.employee_name, r.salary AS `highest salary` FROM ranked_salaries r JOIN departments d ON r.dept_no = d.dept_no WHERE r.salary_rank = 1 ORDER BY department, employee_name;

-- 2026-11-11 18:15:45
WITH current_salaries AS (SELECT emp_no, salary FROM salaries WHERE to_date = '9999-01-01'), current_dept_assignments AS (SELECT emp_no, dept_no FROM dept_emp WHERE to_date = '9999-01-01'), employee_details AS (SELECT e.emp_no, e.first_name, e.last_name, ds.dept_no FROM employees e JOIN current_dept_assignments ds ON e.emp_no = ds.emp_no), department_salaries AS (SELECT d.dept_no, d.dept_name, ed.emp_no, CONCAT(ed.first_name, ' ', ed.last_name) AS employee_name, cs.salary FROM current_salaries cs JOIN employee_details ed ON cs.emp_no = ed.emp_no JOIN departments d ON ed.dept_no = d.dept_no), ranked_salaries AS (SELECT dept_no, employee_name, salary, DENSE_RANK() OVER(PARTITION BY dept_no ORDER BY salary DESC) AS salary_rank FROM department_salaries) SELECT d.dept_name AS department, r.employee_name, r.salary AS `highest salary` FROM ranked_salaries r JOIN departments d ON r.dept_no = d.dept_no WHERE r.salary_rank = 1 ORDER BY department, employee_name;

-- 2026-11-11 21:25:18
WITH CurrentEmployees AS (SELECT emp_no, dept_no FROM dept_emp WHERE to_date = '9999-01-01'), CurrentSalaries AS (SELECT emp_no, salary FROM salaries WHERE to_date = '9999-01-01') SELECT d.dept_name AS department, ROUND(AVG(cs.salary), 2) AS average_salary FROM departments d JOIN CurrentEmployees ce ON ce.dept_no = d.dept_no JOIN CurrentSalaries cs ON cs.emp_no = ce.emp_no GROUP BY d.dept_no, d.dept_name ORDER BY average_salary DESC;

-- 2026-11-11 21:29:08
WITH current_salaries AS (SELECT emp_no, salary FROM salaries WHERE to_date = '9999-01-01'), current_dept_assignments AS (SELECT emp_no, dept_no FROM dept_emp WHERE to_date = '9999-01-01'), employee_details AS (SELECT e.emp_no, e.first_name, e.last_name, ds.dept_no FROM employees e JOIN current_dept_assignments ds ON e.emp_no = ds.emp_no), department_salaries AS (SELECT d.dept_no, d.dept_name, ed.emp_no, CONCAT(ed.first_name, ' ', ed.last_name) AS employee_name, cs.salary FROM current_salaries cs JOIN employee_details ed ON cs.emp_no = ed.emp_no JOIN departments d ON ed.dept_no = d.dept_no), ranked_salaries AS (SELECT dept_no, employee_name, salary, DENSE_RANK() OVER(PARTITION BY dept_no ORDER BY salary DESC) AS salary_rank FROM department_salaries) SELECT d.dept_name AS department, r.employee_name, r.salary AS `highest salary` FROM ranked_salaries r JOIN departments d ON r.dept_no = d.dept_no WHERE r.salary_rank = 1 ORDER BY department, employee_name;

-- 2026-11-11 21:30:24
WITH CurrentDeptEmp AS (SELECT emp_no, dept_no FROM dept_emp WHERE to_date = '9999-01-01'), CurrentTitles AS (SELECT emp_no, title FROM titles WHERE to_date = '9999-01-01'), CurrentSalaries AS (SELECT emp_no, salary FROM salaries WHERE to_date = '9999-01-01') SELECT d.dept_name AS department, t.title, ROUND(AVG(s.salary), 2) AS average_salary FROM departments d JOIN CurrentDeptEmp de ON de.dept_no = d.dept_no JOIN CurrentTitles t ON t.emp_no = de.emp_no JOIN CurrentSalaries s ON s.emp_no = de.emp_no GROUP BY d.dept_no, d.dept_name, t.title ORDER BY d.dept_name, t.title;

-- 2026-11-12 12:55:01
WITH ActiveDepartments AS (SELECT dept_no, dept_name FROM departments), ActiveDeptEmp AS (SELECT emp_no, dept_no FROM dept_emp WHERE to_date = '9999-01-01'), ActiveSalaries AS (SELECT emp_no, salary FROM salaries WHERE to_date = '9999-01-01'), DeptSalary AS (SELECT a.dept_no, AVG(b.salary) AS average_salary FROM ActiveDeptEmp a JOIN ActiveSalaries b ON a.emp_no = b.emp_no GROUP BY a.dept_no) SELECT d.dept_name AS department, ROUND(ds.average_salary, 2) AS average_salary FROM ActiveDepartments d JOIN DeptSalary ds ON d.dept_no = ds.dept_no ORDER BY average_salary DESC;

-- 2026-11-12 13:08:43
WITH ActiveDepartments AS (SELECT dept_no, dept_name FROM departments), ActiveDeptEmp AS (SELECT emp_no, dept_no FROM dept_emp WHERE to_date = '9999-01-01'), ActiveSalaries AS (SELECT emp_no, salary FROM salaries WHERE to_date = '9999-01-01'), DeptSalary AS (SELECT a.dept_no, AVG(b.salary) AS average_salary FROM ActiveDeptEmp a JOIN ActiveSalaries b ON a.emp_no = b.emp_no GROUP BY a.dept_no) SELECT d.dept_name AS department, ROUND(ds.average_salary, 2) AS average_salary FROM ActiveDepartments d JOIN DeptSalary ds ON d.dept_no = ds.dept_no ORDER BY average_salary DESC;

-- 2026-11-12 13:10:31
WITH ActiveDepartments AS (SELECT dept_no, dept_name FROM departments), ActiveDeptEmp AS (SELECT emp_no, dept_no FROM dept_emp WHERE to_date = '9999-01-01'), ActiveSalaries AS (SELECT emp_no, salary FROM salaries WHERE to_date = '9999-01-01'), DeptSalary AS (SELECT a.dept_no, AVG(b.salary) AS average_salary FROM ActiveDeptEmp a JOIN ActiveSalaries b ON a.emp_no = b.emp_no GROUP BY a.dept_no) SELECT d.dept_name AS department, ROUND(ds.average_salary, 2) AS average_salary FROM ActiveDepartments d JOIN DeptSalary ds ON d.dept_no = ds.dept_no ORDER BY average_salary DESC;

-- 2026-11-12 13:20:45
WITH ActiveDepartments AS (SELECT dept_no, dept_name FROM departments), ActiveDeptEmp AS (SELECT emp_no, dept_no FROM dept_emp WHERE to_date = '9999-01-01'), ActiveSalaries AS (SELECT emp_no, salary FROM salaries WHERE to_date = '9999-01-01'), DeptSalary AS (SELECT a.dept_no, AVG(b.salary) AS average_salary FROM ActiveDeptEmp a JOIN ActiveSalaries b ON a.emp_no = b.emp_no GROUP BY a.dept_no) SELECT d.dept_name AS department, ROUND(ds.average_salary, 2) AS average_salary FROM ActiveDepartments d JOIN DeptSalary ds ON d.dept_no = ds.dept_no ORDER BY average_salary DESC;

-- 2026-11-12 13:34:33
WITH ActiveDepartments AS (SELECT emp_no, dept_no FROM dept_emp WHERE to_date = '9999-01-01'), ActiveSalaries AS (SELECT emp_no, salary FROM salaries WHERE to_date = '9999-01-01') SELECT d.dept_name AS department, ROUND(AVG(s.salary), 2) AS average_salary FROM departments d JOIN ActiveDepartments de ON de.dept_no = d.dept_no JOIN ActiveSalaries s ON s.emp_no = de.emp_no GROUP BY d.dept_no, d.dept_name ORDER BY d.dept_name;

-- 2026-11-12 13:35:03
WITH ActiveDepartments AS (SELECT dept_no, dept_name FROM departments), ActiveDeptEmp AS (SELECT emp_no, dept_no FROM dept_emp WHERE to_date = '9999-01-01'), ActiveSalaries AS (SELECT emp_no, salary FROM salaries WHERE to_date = '9999-01-01'), DeptSalary AS (SELECT a.dept_no, AVG(b.salary) AS average_salary FROM ActiveDeptEmp a JOIN ActiveSalaries b ON a.emp_no = b.emp_no GROUP BY a.dept_no) SELECT d.dept_name AS department, ROUND(ds.average_salary, 2) AS average_salary FROM ActiveDepartments d JOIN DeptSalary ds ON d.dept_no = ds.dept_no ORDER BY average_salary DESC;

-- 2026-11-12 15:23:01
WITH ActiveDepartments AS (SELECT dept_no, dept_name FROM departments), ActiveDeptEmp AS (SELECT emp_no, dept_no FROM dept_emp WHERE to_date = '9999-01-01'), ActiveSalaries AS (SELECT emp_no, salary FROM salaries WHERE to_date = '9999-01-01'), DeptSalary AS (SELECT a.dept_no, AVG(b.salary) AS average_salary FROM ActiveDeptEmp a JOIN ActiveSalaries b ON a.emp_no = b.emp_no GROUP BY a.dept_no) SELECT d.dept_name AS department, ROUND(ds.average_salary, 2) AS average_salary FROM ActiveDepartments d JOIN DeptSalary ds ON d.dept_no = ds.dept_no ORDER BY average_salary DESC;

-- 2026-11-12 18:17:12
WITH ActiveDepartments AS (SELECT dept_no, dept_name FROM departments), ActiveDeptEmp AS (SELECT emp_no, dept_no FROM dept_emp WHERE to_date = '9999-01-01'), ActiveSalaries AS (SELECT emp_no, salary FROM salaries WHERE to_date = '9999-01-01') SELECT d.dept_name AS department, ROUND(AVG(s.salary), 2) AS average_salary FROM ActiveDepartments d JOIN ActiveDeptEmp de ON de.dept_no = d.dept_no JOIN ActiveSalaries s ON s.emp_no = de.emp_no GROUP BY d.dept_no, d.dept_name ORDER BY average_salary DESC;

-- 2026-11-12 18:20:02
WITH ActiveDepartments AS (SELECT dept_no, dept_name FROM departments), ActiveDeptEmp AS (SELECT emp_no, dept_no FROM dept_emp WHERE to_date = '9999-01-01'), ActiveSalaries AS (SELECT emp_no, salary FROM salaries WHERE to_date = '9999-01-01') SELECT d.dept_name AS department, ROUND(AVG(s.salary), 2) AS average_salary FROM ActiveDepartments d JOIN ActiveDeptEmp de ON de.dept_no = d.dept_no JOIN ActiveSalaries s ON s.emp_no = de.emp_no GROUP BY d.dept_no, d.dept_name ORDER BY average_salary DESC;

-- 2026-11-12 18:20:50
WITH ActiveDepartments AS (SELECT dept_no, dept_name FROM departments), ActiveDeptEmp AS (SELECT emp_no, dept_no FROM dept_emp WHERE to_date = '9999-01-01'), ActiveSalaries AS (SELECT emp_no, salary FROM salaries WHERE to_date = '9999-01-01') SELECT d.dept_name AS department, ROUND(AVG(s.salary), 2) AS average_salary FROM ActiveDepartments d JOIN ActiveDeptEmp de ON de.dept_no = d.dept_no JOIN ActiveSalaries s ON s.emp_no = de.emp_no GROUP BY d.dept_no, d.dept_name ORDER BY average_salary DESC;

-- 2026-11-12 18:24:34
WITH ActiveDepartments AS (SELECT d.dept_no, d.dept_name FROM departments d), ActiveDeptEmp AS (SELECT de.dept_no, de.emp_no FROM dept_emp de WHERE de.to_date = '9999-01-01'), ActiveSalaries AS (SELECT s.emp_no, s.salary FROM salaries s WHERE s.to_date = '9999-01-01') SELECT d.dept_name AS department, ROUND(AVG(s.salary), 2) AS average_salary FROM ActiveDepartments d JOIN ActiveDeptEmp de ON de.dept_no = d.dept_no JOIN ActiveSalaries s ON s.emp_no = de.emp_no GROUP BY d.dept_no, d.dept_name ORDER BY average_salary DESC;

-- 2026-11-12 18:31:21
WITH ActiveDepartments AS (SELECT d.dept_no, d.dept_name FROM departments d), ActiveDeptEmp AS (SELECT de.dept_no, de.emp_no FROM dept_emp de WHERE de.to_date = '9999-01-01'), ActiveSalaries AS (SELECT s.emp_no, s.salary FROM salaries s WHERE s.to_date = '9999-01-01') SELECT d.dept_name AS department, ROUND(AVG(s.salary), 2) AS average_salary FROM ActiveDepartments d JOIN ActiveDeptEmp de ON de.dept_no = d.dept_no JOIN ActiveSalaries s ON s.emp_no = de.emp_no GROUP BY d.dept_no, d.dept_name ORDER BY average_salary DESC;

-- 2026-11-12 18:32:32
WITH ActiveDepartments AS (SELECT dept_no, dept_name FROM departments), ActiveDeptEmp AS (SELECT emp_no, dept_no FROM dept_emp WHERE to_date = '9999-01-01'), ActiveSalaries AS (SELECT emp_no, salary FROM salaries WHERE to_date = '9999-01-01') SELECT d.dept_name AS department, ROUND(AVG(s.salary), 2) AS average_salary FROM ActiveDepartments d JOIN ActiveDeptEmp de ON de.dept_no = d.dept_no JOIN ActiveSalaries s ON s.emp_no = de.emp_no GROUP BY d.dept_no, d.dept_name ORDER BY average_salary DESC;

-- 2026-11-12 18:36:35
WITH ActiveDepartments AS (SELECT dept_no, dept_name FROM departments), ActiveDeptEmp AS (SELECT emp_no, dept_no FROM dept_emp WHERE to_date = '9999-01-01'), ActiveSalaries AS (SELECT emp_no, salary FROM salaries WHERE to_date = '9999-01-01') SELECT d.dept_name AS department, ROUND(AVG(s.salary), 2) AS average_salary FROM ActiveDepartments d JOIN ActiveDeptEmp de ON de.dept_no = d.dept_no JOIN ActiveSalaries s ON s.emp_no = de.emp_no GROUP BY d.dept_no, d.dept_name ORDER BY average_salary DESC;

-- 2026-11-12 18:40:05
WITH ActiveDepartments AS (SELECT dept_no, dept_name FROM departments), ActiveDeptEmp AS (SELECT emp_no, dept_no FROM dept_emp WHERE to_date = '9999-01-01'), ActiveSalaries AS (SELECT emp_no, salary FROM salaries WHERE to_date = '9999-01-01') SELECT d.dept_name AS department, ROUND(AVG(s.salary), 2) AS average_salary FROM ActiveDepartments d JOIN ActiveDeptEmp de ON de.dept_no = d.dept_no JOIN ActiveSalaries s ON s.emp_no = de.emp_no GROUP BY d.dept_no, d.dept_name ORDER BY average_salary DESC;

-- 2026-11-12 18:42:39
WITH ActiveDepartments AS (SELECT dept_no, dept_name FROM departments), ActiveDeptEmp AS (SELECT emp_no, dept_no FROM dept_emp WHERE to_date = '9999-01-01'), ActiveSalaries AS (SELECT emp_no, salary FROM salaries WHERE to_date = '9999-01-01') SELECT d.dept_name AS department, ROUND(AVG(s.salary), 2) AS average_salary FROM ActiveDepartments d JOIN ActiveDeptEmp de ON de.dept_no = d.dept_no JOIN ActiveSalaries s ON s.emp_no = de.emp_no GROUP BY d.dept_no, d.dept_name ORDER BY average_salary DESC;

-- 2026-11-12 18:51:56
WITH ActiveDepartments AS (SELECT dept_no, dept_name FROM departments), ActiveDeptEmp AS (SELECT emp_no, dept_no FROM dept_emp WHERE to_date = '9999-01-01'), ActiveSalaries AS (SELECT emp_no, salary FROM salaries WHERE to_date = '9999-01-01') SELECT d.dept_name AS department, ROUND(AVG(s.salary), 2) AS average_salary FROM ActiveDepartments d JOIN ActiveDeptEmp de ON de.dept_no = d.dept_no JOIN ActiveSalaries s ON s.emp_no = de.emp_no GROUP BY d.dept_no, d.dept_name ORDER BY average_salary DESC;

-- 2026-11-12 18:54:20
SELECT d.dept_name AS department, ROUND(AVG(s.salary), 2) AS average_salary FROM departments d JOIN dept_emp de ON de.dept_no = d.dept_no AND de.to_date = '9999-01-01' JOIN salaries s ON s.emp_no = de.emp_no AND s.to_date = '9999-01-01' GROUP BY d.dept_no, d.dept_name ORDER BY average_salary DESC;

-- 2026-11-12 18:56:05
SELECT d.dept_name AS department, ROUND(AVG(s.salary), 2) AS average_salary FROM departments d JOIN dept_emp de ON de.dept_no = d.dept_no AND de.to_date = '9999-01-01' JOIN salaries s ON s.emp_no = de.emp_no AND s.to_date = '9999-01-01' GROUP BY d.dept_no, d.dept_name ORDER BY average_salary DESC;

-- 2026-11-12 18:56:52
WITH active_dept_emp AS (SELECT dept_no, emp_no FROM dept_emp WHERE to_date = '9999-01-01'), active_salaries AS (SELECT emp_no, salary FROM salaries WHERE to_date = '9999-01-01') SELECT d.dept_name AS department, ROUND(AVG(s.salary), 2) AS average_salary FROM departments d JOIN active_dept_emp de ON de.dept_no = d.dept_no JOIN active_salaries s ON s.emp_no = de.emp_no GROUP BY d.dept_no, d.dept_name ORDER BY average_salary DESC;

-- 2026-11-12 20:47:25
WITH active_dept_emp AS (SELECT emp_no, dept_no FROM dept_emp WHERE to_date = '9999-01-01'), active_salaries AS (SELECT emp_no, salary FROM salaries WHERE to_date = '9999-01-01') SELECT d.dept_name AS department, ROUND(AVG(s.salary), 2) AS average_salary FROM departments d JOIN active_dept_emp de ON de.dept_no = d.dept_no JOIN active_salaries s ON s.emp_no = de.emp_no GROUP BY d.dept_no, d.dept_name ORDER BY average_salary DESC;

-- 2026-11-12 20:49:54
SELECT d.dept_name AS department, ROUND(AVG(s.salary), 2) AS average_salary FROM departments d JOIN dept_emp de ON d.dept_no = de.dept_no JOIN salaries s ON de.emp_no = s.emp_no WHERE de.to_date = '9999-01-01' AND s.to_date = '9999-01-01' GROUP BY d.dept_no, d.dept_name ORDER BY average_salary DESC;

-- 2026-11-12 20:58:56
WITH ActiveDepartments AS (SELECT d.dept_no, d.dept_name FROM departments d), ActiveDeptEmp AS (SELECT de.emp_no, de.dept_no FROM dept_emp de WHERE de.to_date = '9999-01-01'), ActiveSalaries AS (SELECT s.emp_no, s.salary FROM salaries s WHERE s.to_date = '9999-01-01') SELECT ad.dept_name AS department, ROUND(AVG(asalary.salary), 2) AS average_salary FROM ActiveDepartments ad JOIN ActiveDeptEmp ade ON ade.dept_no = ad.dept_no JOIN ActiveSalaries asalary ON asalary.emp_no = ade.emp_no GROUP BY ad.dept_no, ad.dept_name ORDER BY average_salary DESC;

-- 2026-11-12 21:02:09
WITH ActiveDepartments AS (SELECT d.dept_no, d.dept_name FROM departments d), ActiveDeptEmp AS (SELECT de.emp_no, de.dept_no FROM dept_emp de WHERE de.to_date = '9999-01-01'), ActiveSalaries AS (SELECT s.emp_no, s.salary FROM salaries s WHERE s.to_date = '9999-01-01') SELECT ad.dept_name AS department, ROUND(AVG(asalary.salary), 2) AS average_salary FROM ActiveDepartments ad JOIN ActiveDeptEmp ade ON ade.dept_no = ad.dept_no JOIN ActiveSalaries asalary ON asalary.emp_no = ade.emp_no GROUP BY ad.dept_no, ad.dept_name ORDER BY average_salary DESC;

-- 2026-11-12 21:06:11
WITH ActiveDepartments AS (SELECT d.dept_no, d.dept_name FROM departments d), ActiveDeptEmp AS (SELECT de.emp_no, de.dept_no FROM dept_emp de WHERE de.to_date = '9999-01-01'), ActiveSalaries AS (SELECT s.emp_no, s.salary FROM salaries s WHERE s.to_date = '9999-01-01') SELECT ad.dept_name AS department, ROUND(AVG(asalary.salary), 2) AS average_salary FROM ActiveDepartments ad JOIN ActiveDeptEmp ade ON ade.dept_no = ad.dept_no JOIN ActiveSalaries asalary ON asalary.emp_no = ade.emp_no GROUP BY ad.dept_no, ad.dept_name ORDER BY average_salary DESC;

-- 2026-11-12 21:09:26
SELECT d.dept_name AS department, ROUND(AVG(s.salary), 2) AS average_salary FROM departments d JOIN dept_emp de ON de.dept_no = d.dept_no JOIN salaries s ON s.emp_no = de.emp_no WHERE de.to_date = '9999-01-01' AND s.to_date = '9999-01-01' GROUP BY d.dept_no, d.dept_name ORDER BY average_salary DESC;

-- 2026-11-12 21:16:57
WITH active_departments AS (SELECT d.dept_no, d.dept_name FROM departments d), active_emp_dept AS (SELECT de.emp_no, de.dept_no FROM dept_emp de WHERE de.to_date = '9999-01-01'), active_salaries AS (SELECT s.emp_no, s.salary FROM salaries s WHERE s.to_date = '9999-01-01') SELECT d.dept_name AS department, ROUND(AVG(s.salary), 2) AS average_salary FROM active_departments d JOIN active_emp_dept de ON d.dept_no = de.dept_no JOIN active_salaries s ON de.emp_no = s.emp_no GROUP BY d.dept_no, d.dept_name ORDER BY average_salary DESC;