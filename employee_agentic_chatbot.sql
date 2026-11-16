

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

-- 2026-11-13 12:17:57
WITH ActiveDeptEmp AS (SELECT dept_no, emp_no FROM dept_emp WHERE to_date = '9999-01-01'), ActiveSalaries AS (SELECT emp_no, salary FROM salaries WHERE to_date = '9999-01-01') SELECT d.dept_name AS department, ROUND(AVG(s.salary), 2) AS average_salary FROM departments d JOIN ActiveDeptEmp de ON de.dept_no = d.dept_no JOIN ActiveSalaries s ON s.emp_no = de.emp_no GROUP BY d.dept_no, d.dept_name ORDER BY average_salary DESC;

-- 2026-11-13 12:19:48
WITH ranked AS (SELECT d.dept_no, d.dept_name AS department, e.emp_no, CONCAT(e.first_name, ' ', e.last_name) AS employee_name, s.salary, DENSE_RANK() OVER (PARTITION BY d.dept_no ORDER BY s.salary DESC) AS salary_rank FROM departments d JOIN dept_emp de ON de.dept_no = d.dept_no AND de.to_date = '9999-01-01' JOIN employees e ON e.emp_no = de.emp_no JOIN salaries s ON s.emp_no = e.emp_no AND s.to_date = '9999-01-01') SELECT department, employee_name, salary FROM ranked WHERE salary_rank = 1 ORDER BY department, employee_name;

-- 2026-11-13 16:20:42
WITH current_assignments AS (SELECT de.emp_no, d.dept_name FROM dept_emp de JOIN departments d ON de.dept_no = d.dept_no WHERE de.to_date = '9999-01-01'), current_salaries AS (SELECT emp_no, salary FROM salaries WHERE to_date = '9999-01-01'), ranked_salaries AS (SELECT ca.dept_name, ca.emp_no, e.first_name, e.last_name, cs.salary, DENSE_RANK() OVER (PARTITION BY ca.dept_name ORDER BY cs.salary DESC) AS salary_rank FROM current_assignments ca JOIN employees e ON ca.emp_no = e.emp_no JOIN current_salaries cs ON ca.emp_no = cs.emp_no) SELECT dept_name, emp_no, first_name, last_name, salary FROM ranked_salaries WHERE salary_rank = 1 ORDER BY dept_name, emp_no;

-- 2026-11-13 16:43:09
WITH current_assignments AS (SELECT de.emp_no, d.dept_name FROM dept_emp de JOIN departments d ON de.dept_no = d.dept_no WHERE de.to_date = '9999-01-01'), current_salaries AS (SELECT emp_no, salary FROM salaries WHERE to_date = '9999-01-01'), ranked_salaries AS (SELECT ca.dept_name, ca.emp_no, e.first_name, e.last_name, cs.salary, DENSE_RANK() OVER (PARTITION BY ca.dept_name ORDER BY cs.salary DESC) AS salary_rank FROM current_assignments ca JOIN employees e ON ca.emp_no = e.emp_no JOIN current_salaries cs ON ca.emp_no = cs.emp_no) SELECT dept_name, emp_no, first_name, last_name, salary FROM ranked_salaries WHERE salary_rank = 1 ORDER BY dept_name, emp_no;

-- 2026-11-13 16:56:37
WITH active_salaries AS (SELECT d.dept_name AS department, CONCAT(e.first_name, ' ', e.last_name) AS full_name, s.salary FROM departments d JOIN dept_emp de ON de.dept_no = d.dept_no JOIN employees e ON e.emp_no = de.emp_no JOIN salaries s ON s.emp_no = e.emp_no WHERE de.to_date = '9999-01-01' AND s.to_date = '9999-01-01'), ranked_salaries AS (SELECT department, full_name, salary, DENSE_RANK() OVER (PARTITION BY department ORDER BY salary DESC) AS salary_rank FROM active_salaries) SELECT department, full_name, salary FROM ranked_salaries WHERE salary_rank = 1 ORDER BY department, full_name;

-- 2026-11-13 17:02:19
WITH active_dept_emp AS (SELECT dept_no, emp_no FROM dept_emp WHERE from_date <= CURRENT_DATE() AND to_date > CURRENT_DATE()), active_salaries AS (SELECT emp_no, salary FROM salaries WHERE from_date <= CURRENT_DATE() AND to_date > CURRENT_DATE()), ranked AS (SELECT d.dept_no, d.dept_name, e.emp_no, CONCAT(e.first_name, ' ', e.last_name) AS full_name, s.salary, DENSE_RANK() OVER (PARTITION BY d.dept_no ORDER BY s.salary DESC) AS salary_rank FROM departments d JOIN active_dept_emp de ON de.dept_no = d.dept_no JOIN employees e ON e.emp_no = de.emp_no JOIN active_salaries s ON s.emp_no = e.emp_no) SELECT dept_name, full_name, salary FROM ranked WHERE salary_rank = 1 ORDER BY dept_name, full_name, emp_no;

-- 2026-11-13 18:48:55
WITH valid_dept_emp AS (SELECT de.emp_no, d.dept_name FROM dept_emp de JOIN departments d ON de.dept_no = d.dept_no WHERE de.to_date = '9999-01-01'), valid_salaries AS (SELECT emp_no, salary FROM salaries WHERE to_date = '9999-01-01'), ranked_salaries AS (SELECT vde.dept_name, e.emp_no, CONCAT(e.first_name, ' ', e.last_name) AS employee_name, vs.salary, DENSE_RANK() OVER (PARTITION BY vde.dept_name ORDER BY vs.salary DESC) AS salary_rank FROM valid_dept_emp vde JOIN employees e ON e.emp_no = vde.emp_no JOIN valid_salaries vs ON vs.emp_no = e.emp_no) SELECT dept_name AS department, employee_name, salary FROM ranked_salaries WHERE salary_rank = 1 ORDER BY department, employee_name;

-- 2026-11-13 18:53:21
WITH valid_dept_emp AS (SELECT de.emp_no, d.dept_name FROM dept_emp de JOIN departments d ON de.dept_no = d.dept_no WHERE de.to_date = '9999-01-01'), valid_salaries AS (SELECT emp_no, salary FROM salaries WHERE to_date = '9999-01-01'), ranked_salaries AS (SELECT vde.dept_name, e.emp_no, CONCAT(e.first_name, ' ', e.last_name) AS employee_name, vs.salary, DENSE_RANK() OVER (PARTITION BY vde.dept_name ORDER BY vs.salary DESC) AS salary_rank FROM valid_dept_emp vde JOIN employees e ON e.emp_no = vde.emp_no JOIN valid_salaries vs ON vs.emp_no = e.emp_no) SELECT dept_name AS department, employee_name, salary FROM ranked_salaries WHERE salary_rank = 1 ORDER BY department, employee_name;

-- 2026-11-13 18:54:59
WITH valid_dept_emp AS (SELECT de.emp_no, d.dept_name FROM dept_emp de JOIN departments d ON de.dept_no = d.dept_no WHERE de.to_date = '9999-01-01'), valid_salaries AS (SELECT emp_no, salary FROM salaries WHERE to_date = '9999-01-01'), ranked_salaries AS (SELECT vde.dept_name, e.emp_no, CONCAT(e.first_name, ' ', e.last_name) AS employee_name, vs.salary, DENSE_RANK() OVER (PARTITION BY vde.dept_name ORDER BY vs.salary DESC) AS salary_rank FROM valid_dept_emp vde JOIN employees e ON e.emp_no = vde.emp_no JOIN valid_salaries vs ON vs.emp_no = e.emp_no) SELECT dept_name AS department, employee_name, salary FROM ranked_salaries WHERE salary_rank = 1 ORDER BY department, employee_name;

-- 2026-11-13 18:58:35
WITH valid_dept_emp AS (SELECT de.emp_no, d.dept_name FROM dept_emp de JOIN departments d ON de.dept_no = d.dept_no WHERE de.to_date = '9999-01-01'), valid_salaries AS (SELECT emp_no, salary FROM salaries WHERE to_date = '9999-01-01'), ranked_salaries AS (SELECT vde.dept_name, e.emp_no, CONCAT(e.first_name, ' ', e.last_name) AS employee_name, vs.salary, DENSE_RANK() OVER (PARTITION BY vde.dept_name ORDER BY vs.salary DESC) AS salary_rank FROM valid_dept_emp vde JOIN employees e ON e.emp_no = vde.emp_no JOIN valid_salaries vs ON vs.emp_no = e.emp_no) SELECT dept_name AS department, employee_name, salary FROM ranked_salaries WHERE salary_rank = 1 ORDER BY department, employee_name;

-- 2026-11-13 19:05:22
WITH active_dept_emp AS (SELECT dept_no, emp_no FROM dept_emp WHERE from_date <= CURRENT_DATE() AND to_date > CURRENT_DATE()), active_salaries AS (SELECT emp_no, salary FROM salaries WHERE from_date <= CURRENT_DATE() AND to_date > CURRENT_DATE()), ranked AS (SELECT d.dept_no, d.dept_name, e.emp_no, CONCAT(e.first_name, ' ', e.last_name) AS full_name, s.salary, DENSE_RANK() OVER (PARTITION BY d.dept_no ORDER BY s.salary DESC) AS salary_rank FROM departments d JOIN active_dept_emp de ON de.dept_no = d.dept_no JOIN employees e ON e.emp_no = de.emp_no JOIN active_salaries s ON s.emp_no = e.emp_no) SELECT dept_name, full_name, salary FROM ranked WHERE salary_rank = 1 ORDER BY dept_name, full_name, emp_no;

-- 2026-11-13 19:45:38
WITH ranked AS (SELECT e.gender, s.salary, ROW_NUMBER() OVER (PARTITION BY e.gender ORDER BY s.salary) AS rn, COUNT(*) OVER (PARTITION BY e.gender) AS cnt FROM employees e JOIN salaries s ON s.emp_no = e.emp_no WHERE s.to_date = '9999-01-01'), median_calculation AS (SELECT gender, salary FROM ranked WHERE rn IN (FLOOR((cnt + 1) / 2), FLOOR((cnt + 2) / 2))) SELECT gender, AVG(salary) AS median_salary FROM median_calculation GROUP BY gender ORDER BY gender;

-- 2026-11-13 19:51:16
WITH current_salaries AS (SELECT e.gender, s.salary FROM employees e JOIN salaries s ON s.emp_no = e.emp_no WHERE s.to_date = '9999-01-01'), ranked AS (SELECT gender, salary, ROW_NUMBER() OVER (PARTITION BY gender ORDER BY salary) AS rn, COUNT(*) OVER (PARTITION BY gender) AS cnt FROM current_salaries) SELECT gender, AVG(salary) AS median_salary FROM ranked WHERE rn IN (FLOOR((cnt + 1) / 2), FLOOR((cnt + 2) / 2)) GROUP BY gender ORDER BY gender;

-- 2026-11-13 19:54:38
WITH current_salaries AS (SELECT e.gender, s.salary FROM employees e JOIN salaries s ON s.emp_no = e.emp_no WHERE s.to_date = '9999-01-01'), ranked_salaries AS (SELECT gender, salary, ROW_NUMBER() OVER (PARTITION BY gender ORDER BY salary) AS rn, COUNT(*) OVER (PARTITION BY gender) AS cnt FROM current_salaries) SELECT gender, AVG(salary) AS median_salary FROM ranked_salaries WHERE rn IN (FLOOR((cnt + 1) / 2), FLOOR((cnt + 2) / 2)) GROUP BY gender ORDER BY gender;

-- 2026-11-13 21:25:41
WITH ActiveSalaries AS (SELECT emp_no, salary FROM salaries WHERE from_date <= CURDATE() AND to_date > CURDATE()), EmployeeAges AS (SELECT emp_no, TIMESTAMPDIFF(YEAR, birth_date, CURDATE()) AS age FROM employees) SELECT ea.age, COUNT(*) AS employee_count, ROUND(AVG(s.salary), 2) AS average_salary, MIN(s.salary) AS minimum_salary, MAX(s.salary) AS maximum_salary, ROUND(STDDEV_POP(s.salary), 2) AS salary_stddev FROM EmployeeAges ea JOIN ActiveSalaries s ON ea.emp_no = s.emp_no GROUP BY ea.age ORDER BY ea.age;

-- 2026-11-13 21:27:32
WITH EmployeeAges AS (SELECT emp_no, TIMESTAMPDIFF(YEAR, birth_date, CURDATE()) AS age FROM employees), ActiveSalaries AS (SELECT emp_no, salary FROM salaries WHERE from_date <= CURDATE() AND to_date > CURDATE()) SELECT ea.age, AVG(s.salary) AS mean_salary, COUNT(*) AS employee_count FROM EmployeeAges ea JOIN ActiveSalaries s ON ea.emp_no = s.emp_no GROUP BY ea.age ORDER BY ea.age;

-- 2026-11-13 21:36:01
WITH CurrentSalaries AS (SELECT e.emp_no, e.birth_date, s.salary FROM employees e JOIN salaries s ON e.emp_no = s.emp_no WHERE s.from_date <= CURDATE() AND s.to_date > CURDATE()), AgeSalary AS (SELECT TIMESTAMPDIFF(YEAR, birth_date, CURDATE()) AS age, salary FROM CurrentSalaries) SELECT age, AVG(salary) AS mean_salary FROM AgeSalary GROUP BY age ORDER BY age;

-- 2026-11-13 21:36:47
WITH CurrentSalaries AS (SELECT e.emp_no, e.birth_date, s.salary FROM employees e JOIN salaries s ON e.emp_no = s.emp_no WHERE s.from_date <= CURDATE() AND s.to_date > CURDATE()), AgeSalary AS (SELECT TIMESTAMPDIFF(YEAR, birth_date, CURDATE()) AS age, salary FROM CurrentSalaries) SELECT age, AVG(salary) AS mean_salary FROM AgeSalary GROUP BY age ORDER BY age;

-- 2026-11-13 21:41:35
WITH CurrentSalaries AS (SELECT e.emp_no, e.birth_date, s.salary FROM employees e JOIN salaries s ON e.emp_no = s.emp_no WHERE s.from_date <= CURDATE() AND s.to_date > CURDATE()), AgeSalary AS (SELECT TIMESTAMPDIFF(YEAR, birth_date, CURDATE()) AS age, salary FROM CurrentSalaries) SELECT age, AVG(salary) AS mean_salary FROM AgeSalary GROUP BY age ORDER BY age;

-- 2026-11-13 21:43:31
WITH EmployeeAges AS (SELECT emp_no, TIMESTAMPDIFF(YEAR, birth_date, CURDATE()) AS age FROM employees), CurrentSalaries AS (SELECT emp_no, salary FROM salaries WHERE from_date <= CURDATE() AND to_date > CURDATE()) SELECT age, AVG(cs.salary) AS mean_salary FROM EmployeeAges ea JOIN CurrentSalaries cs ON cs.emp_no = ea.emp_no GROUP BY age ORDER BY age;

-- 2026-11-13 21:44:24
WITH EmployeeAges AS (SELECT emp_no, TIMESTAMPDIFF(YEAR, birth_date, CURDATE()) AS age FROM employees), CurrentSalaries AS (SELECT emp_no, salary FROM salaries WHERE from_date <= CURDATE() AND to_date > CURDATE()) SELECT age, AVG(cs.salary) AS mean_salary FROM EmployeeAges ea JOIN CurrentSalaries cs ON cs.emp_no = ea.emp_no GROUP BY age ORDER BY age;

-- 2026-11-15 10:03:53
WITH active_dept_emp AS (SELECT emp_no, dept_no FROM dept_emp WHERE to_date = '9999-01-01'), active_salaries AS (SELECT emp_no, salary FROM salaries WHERE to_date = '9999-01-01'), employee_details AS (SELECT e.emp_no, e.gender, d.dept_name FROM employees e JOIN active_dept_emp de ON de.emp_no = e.emp_no JOIN departments d ON d.dept_no = de.dept_no) SELECT ed.dept_name AS department, ed.gender, ROUND(AVG(asalary.salary), 2) AS average_salary FROM employee_details ed JOIN active_salaries asalary ON asalary.emp_no = ed.emp_no GROUP BY ed.dept_name, ed.gender ORDER BY ed.dept_name, ed.gender;

-- 2026-11-15 10:30:07
WITH active_dept_emp AS (SELECT emp_no, dept_no FROM dept_emp WHERE to_date = '9999-01-01'), active_salaries AS (SELECT emp_no, salary FROM salaries WHERE to_date = '9999-01-01'), employee_details AS (SELECT e.emp_no, e.gender, d.dept_name FROM employees e JOIN active_dept_emp de ON de.emp_no = e.emp_no JOIN departments d ON d.dept_no = de.dept_no) SELECT ed.dept_name AS department, ed.gender, ROUND(AVG(asalary.salary), 2) AS average_salary FROM employee_details ed JOIN active_salaries asalary ON asalary.emp_no = ed.emp_no GROUP BY ed.dept_name, ed.gender ORDER BY ed.dept_name, ed.gender;

-- 2026-11-15 10:52:12
WITH active_dept_emp AS (SELECT emp_no, dept_no FROM dept_emp WHERE to_date = '9999-01-01'), active_salaries AS (SELECT emp_no, salary FROM salaries WHERE to_date = '9999-01-01'), employee_details AS (SELECT e.emp_no, e.gender, d.dept_name FROM employees e JOIN active_dept_emp de ON de.emp_no = e.emp_no JOIN departments d ON d.dept_no = de.dept_no) SELECT ed.dept_name AS department, ed.gender, ROUND(AVG(asalary.salary), 2) AS average_salary FROM employee_details ed JOIN active_salaries asalary ON asalary.emp_no = ed.emp_no GROUP BY ed.dept_name, ed.gender ORDER BY ed.dept_name, ed.gender;

-- 2026-11-15 11:22:03
WITH active_dept_emp AS (SELECT emp_no, dept_no FROM dept_emp WHERE to_date = '9999-01-01'), active_salaries AS (SELECT emp_no, salary FROM salaries WHERE to_date = '9999-01-01'), employee_details AS (SELECT e.emp_no, e.gender, d.dept_name FROM employees e JOIN active_dept_emp de ON de.emp_no = e.emp_no JOIN departments d ON d.dept_no = de.dept_no) SELECT ed.dept_name AS department, ed.gender, ROUND(AVG(asalary.salary), 2) AS average_salary FROM employee_details ed JOIN active_salaries asalary ON asalary.emp_no = ed.emp_no GROUP BY ed.dept_name, ed.gender ORDER BY ed.dept_name, ed.gender;

-- 2026-11-15 14:11:54
WITH snapshot AS (SELECT MAX(from_date) AS as_of_date FROM salaries), ranked AS (SELECT TIMESTAMPDIFF(YEAR, e.birth_date, d.as_of_date) AS age, e.gender, s.salary, ROW_NUMBER() OVER (PARTITION BY TIMESTAMPDIFF(YEAR, e.birth_date, d.as_of_date), e.gender ORDER BY s.salary, e.emp_no) AS rn, COUNT(*) OVER (PARTITION BY TIMESTAMPDIFF(YEAR, e.birth_date, d.as_of_date), e.gender) AS n FROM employees e JOIN salaries s ON s.emp_no = e.emp_no CROSS JOIN snapshot d WHERE s.from_date <= d.as_of_date AND s.to_date > d.as_of_date) SELECT age, gender, AVG(salary) AS median_salary, MAX(n) AS employee_count, (SELECT as_of_date FROM snapshot) AS as_of_date FROM ranked WHERE rn IN (FLOOR((n + 1) / 2), FLOOR((n + 2) / 2)) GROUP BY age, gender ORDER BY age, gender;

-- 2026-11-15 14:25:52
WITH ranked_salaries AS (SELECT d.dept_name, e.gender, s.salary, ROW_NUMBER() OVER (PARTITION BY d.dept_no, e.gender ORDER BY s.salary, e.emp_no) AS rn, COUNT(*) OVER (PARTITION BY d.dept_no, e.gender) AS cnt FROM employees e JOIN dept_emp de ON de.emp_no = e.emp_no AND de.to_date = '9999-01-01' JOIN departments d ON d.dept_no = de.dept_no JOIN salaries s ON s.emp_no = e.emp_no AND s.to_date = '9999-01-01'), median_salaries AS (SELECT dept_name, gender, salary FROM ranked_salaries WHERE rn IN (FLOOR((cnt + 1) / 2), FLOOR((cnt + 2) / 2))) SELECT dept_name, gender, AVG(salary) AS median_salary FROM median_salaries GROUP BY dept_name, gender ORDER BY dept_name, gender;

-- 2026-11-15 14:26:50
WITH ranked_salaries AS (SELECT d.dept_name, e.gender, s.salary, ROW_NUMBER() OVER (PARTITION BY d.dept_no, e.gender ORDER BY s.salary, e.emp_no) AS rn, COUNT(*) OVER (PARTITION BY d.dept_no, e.gender) AS cnt FROM employees e JOIN dept_emp de ON de.emp_no = e.emp_no AND de.to_date = '9999-01-01' JOIN departments d ON d.dept_no = de.dept_no JOIN salaries s ON s.emp_no = e.emp_no AND s.to_date = '9999-01-01'), median_salaries AS (SELECT dept_name, gender, salary FROM ranked_salaries WHERE rn IN (FLOOR((cnt + 1) / 2), FLOOR((cnt + 2) / 2))) SELECT dept_name, gender, AVG(salary) AS median_salary FROM median_salaries GROUP BY dept_name, gender ORDER BY dept_name, gender;

-- 2026-11-15 14:28:38
WITH snapshot AS (SELECT MAX(from_date) AS as_of_date FROM salaries), filtered_data AS (SELECT d.dept_no, d.dept_name, e.emp_no, e.gender, s.salary FROM employees e JOIN salaries s ON s.emp_no = e.emp_no JOIN dept_emp de ON de.emp_no = e.emp_no JOIN departments d ON d.dept_no = de.dept_no CROSS JOIN snapshot snap WHERE s.from_date <= snap.as_of_date AND s.to_date > snap.as_of_date AND de.from_date <= snap.as_of_date AND de.to_date > snap.as_of_date), ranked AS (SELECT dept_no, dept_name, gender, salary, ROW_NUMBER() OVER (PARTITION BY dept_no, gender ORDER BY salary, emp_no) AS rn, COUNT(*) OVER (PARTITION BY dept_no, gender) AS n FROM filtered_data) SELECT dept_no, dept_name, gender, AVG(salary) AS median_salary, MAX(n) AS employee_count, (SELECT as_of_date FROM snapshot) AS as_of_date FROM ranked WHERE rn IN (FLOOR((n + 1) / 2), FLOOR((n + 2) / 2)) GROUP BY dept_no, dept_name, gender ORDER BY dept_name, gender;

-- 2026-11-15 15:44:20
WITH department_counts AS (SELECT e.emp_no, e.first_name, e.last_name, COUNT(DISTINCT de.dept_no) AS department_count FROM employees e JOIN dept_emp de ON de.emp_no = e.emp_no GROUP BY e.emp_no, e.first_name, e.last_name HAVING COUNT(DISTINCT de.dept_no) > 1), department_names AS (SELECT de.emp_no, GROUP_CONCAT(DISTINCT d.dept_name ORDER BY d.dept_name SEPARATOR ', ') AS departments FROM dept_emp de JOIN departments d ON d.dept_no = de.dept_no GROUP BY de.emp_no) SELECT dc.emp_no, dc.first_name, dc.last_name, dc.department_count, dn.departments FROM department_counts dc JOIN department_names dn ON dc.emp_no = dn.emp_no ORDER BY dc.emp_no;

-- 2026-11-15 15:49:14
WITH events AS (SELECT dept_no, from_date AS event_date, COUNT(*) AS delta FROM dept_emp WHERE from_date <= CURDATE() GROUP BY dept_no, from_date UNION ALL SELECT dept_no, to_date AS event_date, -COUNT(*) AS delta FROM dept_emp WHERE to_date <= CURDATE() AND to_date <> '9999-01-01' GROUP BY dept_no, to_date), daily_changes AS (SELECT dept_no, event_date, SUM(delta) AS delta FROM events GROUP BY dept_no, event_date) SELECT c.event_date, d.dept_name, SUM(c.delta) OVER (PARTITION BY c.dept_no ORDER BY c.event_date ROWS UNBOUNDED PRECEDING) AS employee_count FROM daily_changes c JOIN departments d ON d.dept_no = c.dept_no ORDER BY c.event_date, d.dept_name;

-- 2026-11-15 15:52:02
WITH RECURSIVE bounds AS (SELECT MIN(from_date) AS first_date, GREATEST(MAX(from_date), COALESCE(MAX(CASE WHEN to_date < '9999-01-01' THEN to_date END), MAX(from_date))) AS last_date FROM dept_emp), years AS (SELECT YEAR(first_date) AS yr FROM bounds UNION ALL SELECT yr + 1 FROM years CROSS JOIN bounds WHERE yr < YEAR(last_date)), snapshots AS (SELECT LEAST(STR_TO_DATE(CONCAT(yr, '-12-31'), '%Y-%m-%d'), last_date) AS snapshot_date FROM years CROSS JOIN bounds) SELECT s.snapshot_date, d.dept_name, COUNT(DISTINCT de.emp_no) AS employee_count FROM snapshots s CROSS JOIN departments d LEFT JOIN dept_emp de ON de.dept_no = d.dept_no AND de.from_date <= s.snapshot_date AND de.to_date > s.snapshot_date GROUP BY s.snapshot_date, d.dept_name ORDER BY s.snapshot_date, d.dept_name;

-- 2026-11-15 15:53:01
WITH RECURSIVE bounds AS (SELECT YEAR(MIN(from_date)) AS first_year, GREATEST(MAX(from_date), COALESCE(MAX(CASE WHEN to_date < '9999-01-01' THEN to_date END), MAX(from_date))) AS last_date FROM dept_emp), years AS (SELECT first_year AS yr FROM bounds UNION ALL SELECT yr + 1 FROM years CROSS JOIN bounds WHERE yr < YEAR(last_date)), events AS (SELECT dept_no, YEAR(from_date) AS yr, 1 AS delta FROM dept_emp UNION ALL SELECT dept_no, YEAR(to_date) AS yr, -1 AS delta FROM dept_emp WHERE to_date < '9999-01-01'), annual AS (SELECT dept_no, yr, SUM(delta) AS delta FROM events GROUP BY dept_no, yr) SELECT LEAST(STR_TO_DATE(CONCAT(y.yr, '-12-31'), '%Y-%m-%d'), b.last_date) AS snapshot_date, d.dept_name, SUM(COALESCE(a.delta,0)) OVER (PARTITION BY d.dept_no ORDER BY y.yr) AS employee_count FROM years y CROSS JOIN departments d CROSS JOIN bounds b LEFT JOIN annual a ON a.dept_no = d.dept_no AND a.yr = y.yr ORDER BY snapshot_date, d.dept_name;

-- 2026-11-15 16:58:52
WITH start_snapshot AS (SELECT d.dept_name, AVG(s.salary) AS avg_salary_start, COUNT(DISTINCT de.emp_no) AS employee_count_start FROM departments d JOIN dept_emp de ON d.dept_no = de.dept_no JOIN salaries s ON de.emp_no = s.emp_no WHERE de.from_date <= DATE_SUB(CURRENT_DATE, INTERVAL 5 YEAR) AND de.to_date > DATE_SUB(CURRENT_DATE, INTERVAL 5 YEAR) AND s.from_date <= DATE_SUB(CURRENT_DATE, INTERVAL 5 YEAR) AND s.to_date > DATE_SUB(CURRENT_DATE, INTERVAL 5 YEAR) GROUP BY d.dept_name), end_snapshot AS (SELECT d.dept_name, AVG(s.salary) AS avg_salary_end, COUNT(DISTINCT de.emp_no) AS employee_count_end FROM departments d JOIN dept_emp de ON d.dept_no = de.dept_no JOIN salaries s ON de.emp_no = s.emp_no WHERE de.from_date <= CURRENT_DATE AND de.to_date > CURRENT_DATE AND s.from_date <= CURRENT_DATE AND s.to_date > CURRENT_DATE GROUP BY d.dept_name) SELECT ss.dept_name, DATE_SUB(CURRENT_DATE, INTERVAL 5 YEAR) AS start_snapshot_date, CURRENT_DATE AS end_snapshot_date, ss.avg_salary_start, es.avg_salary_end, es.avg_salary_end - ss.avg_salary_start AS absolute_increase, (es.avg_salary_end - ss.avg_salary_start) / ss.avg_salary_start * 100 AS percentage_increase, ss.employee_count_start, es.employee_count_end FROM start_snapshot ss JOIN end_snapshot es ON ss.dept_name = es.dept_name ORDER BY absolute_increase DESC;

-- 2026-11-15 17:08:38
WITH ranked_salaries AS (SELECT TIMESTAMPDIFF(YEAR, e.birth_date, CURDATE()) AS age, e.gender, s.salary, ROW_NUMBER() OVER (PARTITION BY TIMESTAMPDIFF(YEAR, e.birth_date, CURDATE()), e.gender ORDER BY s.salary, e.emp_no) AS rn, COUNT(*) OVER (PARTITION BY TIMESTAMPDIFF(YEAR, e.birth_date, CURDATE()), e.gender) AS cnt FROM employees e JOIN salaries s ON e.emp_no = s.emp_no WHERE s.from_date <= CURDATE() AND s.to_date > CURDATE()), median_calculation AS (SELECT age, gender, salary FROM ranked_salaries WHERE rn IN (FLOOR((cnt + 1) / 2), FLOOR((cnt + 2) / 2))) SELECT age, gender, AVG(salary) AS median_salary FROM median_calculation GROUP BY age, gender ORDER BY age, gender;

-- 2026-11-15 17:13:17
WITH active_dept_emp AS (SELECT emp_no, dept_no FROM dept_emp WHERE to_date = '9999-01-01'), active_salaries AS (SELECT emp_no, salary FROM salaries WHERE to_date = '9999-01-01') SELECT d.dept_name AS department, ROUND(AVG(s.salary), 2) AS average_salary FROM departments d JOIN active_dept_emp de ON d.dept_no = de.dept_no JOIN active_salaries s ON de.emp_no = s.emp_no GROUP BY d.dept_no, d.dept_name ORDER BY average_salary DESC;

-- 2026-11-15 17:16:38
WITH active_managers AS (SELECT emp_no, dept_no FROM dept_manager WHERE from_date <= CURRENT_DATE() AND to_date > CURRENT_DATE()), active_departments AS (SELECT dept_no, dept_name FROM departments), reporting_employees AS (SELECT de.dept_no, de.emp_no FROM dept_emp de WHERE de.from_date <= CURRENT_DATE() AND de.to_date > CURRENT_DATE()) SELECT dm.emp_no AS manager_id, e.first_name, e.last_name, d.dept_name, COUNT(DISTINCT re.emp_no) AS reporting_employees FROM active_managers dm JOIN employees e ON e.emp_no = dm.emp_no JOIN active_departments d ON d.dept_no = dm.dept_no LEFT JOIN reporting_employees re ON re.dept_no = dm.dept_no AND re.emp_no <> dm.emp_no GROUP BY dm.emp_no, e.first_name, e.last_name, d.dept_name ORDER BY reporting_employees DESC, dm.emp_no ASC LIMIT 10;

-- 2026-11-15 17:27:49
WITH active_managers AS (SELECT emp_no, dept_no FROM dept_manager WHERE from_date <= CURRENT_DATE() AND to_date > CURRENT_DATE()), active_departments AS (SELECT dept_no, dept_name FROM departments), reporting_employees AS (SELECT de.dept_no, de.emp_no FROM dept_emp de WHERE de.from_date <= CURRENT_DATE() AND de.to_date > CURRENT_DATE()) SELECT dm.emp_no AS manager_id, e.first_name, e.last_name, d.dept_name, COUNT(DISTINCT re.emp_no) AS reporting_employees FROM active_managers dm JOIN employees e ON e.emp_no = dm.emp_no JOIN active_departments d ON d.dept_no = dm.dept_no LEFT JOIN reporting_employees re ON re.dept_no = dm.dept_no AND re.emp_no <> dm.emp_no GROUP BY dm.emp_no, e.first_name, e.last_name, d.dept_name ORDER BY reporting_employees DESC, dm.emp_no ASC LIMIT 10;

-- 2026-11-15 17:29:33
WITH manager_employees AS (SELECT e.emp_no AS manager_emp_no, CONCAT(e.first_name, ' ', e.last_name) AS manager_name, de.emp_no AS reporting_emp_no FROM dept_manager dm JOIN employees e ON e.emp_no = dm.emp_no LEFT JOIN dept_emp de ON de.dept_no = dm.dept_no AND de.from_date < dm.to_date AND dm.from_date < de.to_date AND de.emp_no <> dm.emp_no) SELECT manager_name, COUNT(DISTINCT reporting_emp_no) AS reporting_employees FROM manager_employees GROUP BY manager_emp_no, manager_name ORDER BY reporting_employees DESC, manager_name ASC, manager_emp_no ASC LIMIT 10;

-- 2026-11-15 17:37:01
WITH annual_hires AS (SELECT YEAR(hire_date) AS year, gender FROM employees), employee_counts AS (SELECT year, gender, COUNT(*) AS employee_count FROM annual_hires GROUP BY year, gender) SELECT year, gender, employee_count FROM employee_counts ORDER BY year, gender;

-- 2026-11-15 18:06:51
WITH active_dept_emp AS (SELECT emp_no, dept_no FROM dept_emp WHERE to_date = '9999-01-01'), active_salaries AS (SELECT emp_no, salary FROM salaries WHERE to_date = '9999-01-01') SELECT d.dept_name AS department, ROUND(AVG(s.salary), 2) AS average_salary FROM departments d JOIN active_dept_emp de ON d.dept_no = de.dept_no JOIN active_salaries s ON de.emp_no = s.emp_no GROUP BY d.dept_no, d.dept_name ORDER BY average_salary DESC;

-- 2026-11-15 18:49:59
SELECT * FROM x

-- 2026-11-15 20:14:34
SELECT table_name, column_name, column_type, is_nullable, column_key FROM information_schema.columns WHERE table_schema = 'employees' ORDER BY table_name, ordinal_position

-- 2026-11-15 20:21:02
SELECT e.emp_no, e.first_name, e.last_name, s.salary FROM employees e JOIN salaries s ON e.emp_no = s.emp_no WHERE s.to_date = '9999-01-01' ORDER BY s.salary DESC LIMIT 10

-- 2026-11-15 20:24:38
SELECT e.emp_no, e.first_name, e.last_name, s.salary FROM employees e JOIN salaries s ON e.emp_no = s.emp_no WHERE s.to_date = '9999-01-01' ORDER BY s.salary DESC LIMIT 10

-- 2026-11-15 23:04:51
WITH annual_hires AS (SELECT YEAR(hire_date) AS hire_year, COUNT(*) AS hires FROM employees GROUP BY YEAR(hire_date)), hiring_changes AS (SELECT hire_year, hires, LAG(hires) OVER (ORDER BY hire_year) AS previous_year_hires FROM annual_hires) SELECT hire_year, hires, hires - previous_year_hires AS yoy_change, ROUND(100.0 * (hires - previous_year_hires) / NULLIF(previous_year_hires, 0), 2) AS yoy_change_pct FROM hiring_changes ORDER BY hire_year;

-- 2026-11-15 23:14:11
WITH RECURSIVE bounds AS (SELECT YEAR(MIN(from_date)) AS start_year, YEAR(MAX(CASE WHEN to_date < '9999-01-01' THEN to_date ELSE from_date END)) AS end_year FROM dept_emp), years AS (SELECT start_year AS yr FROM bounds UNION ALL SELECT yr + 1 FROM years CROSS JOIN bounds WHERE yr < end_year), snapshots AS (SELECT yr, STR_TO_DATE(CONCAT(yr, '-12-31'), '%Y-%m-%d') AS snapshot_date FROM years) SELECT s.yr AS year, e.gender, COUNT(DISTINCT e.emp_no) AS active_employees FROM snapshots s JOIN dept_emp d ON d.from_date <= s.snapshot_date AND d.to_date > s.snapshot_date JOIN employees e ON e.emp_no = d.emp_no GROUP BY s.yr, e.gender ORDER BY s.yr, e.gender;

-- 2026-11-16 12:03:07
WITH ActiveDepartments AS (SELECT d.dept_no, d.dept_name FROM departments d), ActiveDeptEmp AS (SELECT de.emp_no, de.dept_no FROM dept_emp de WHERE de.to_date = '9999-01-01'), ActiveSalaries AS (SELECT s.emp_no, s.salary FROM salaries s WHERE s.to_date = '9999-01-01') SELECT d.dept_name AS department, ROUND(AVG(s.salary), 2) AS average_salary FROM ActiveDepartments d JOIN ActiveDeptEmp de ON de.dept_no = d.dept_no JOIN ActiveSalaries s ON s.emp_no = de.emp_no GROUP BY d.dept_no, d.dept_name ORDER BY average_salary DESC;

-- 2026-11-16 12:06:46
WITH ActiveDeptEmp AS (SELECT dept_no, emp_no FROM dept_emp WHERE to_date = '9999-01-01'), ActiveSalaries AS (SELECT emp_no, salary FROM salaries WHERE to_date = '9999-01-01'), DeptAvgSalaries AS (SELECT d.dept_no, d.dept_name, ROUND(AVG(s.salary), 2) AS average_salary FROM departments d JOIN ActiveDeptEmp de ON de.dept_no = d.dept_no JOIN ActiveSalaries s ON s.emp_no = de.emp_no GROUP BY d.dept_no, d.dept_name) SELECT dept_name AS department, average_salary FROM DeptAvgSalaries ORDER BY average_salary DESC;

-- 2026-11-16 12:10:32
WITH RECURSIVE years AS (SELECT YEAR(MIN(from_date)) AS y FROM dept_emp WHERE from_date <= CURDATE() UNION ALL SELECT y + 1 FROM years WHERE y < YEAR(CURDATE())), snapshots AS (SELECT CASE WHEN y = YEAR(CURDATE()) THEN CURDATE() ELSE STR_TO_DATE(CONCAT(y, '-12-31'), '%Y-%m-%d') END AS snapshot_date FROM years WHERE y IS NOT NULL), annual_deltas AS (SELECT dept_no, YEAR(from_date) AS y, COUNT(*) AS delta FROM dept_emp WHERE from_date <= CURDATE() GROUP BY dept_no, YEAR(from_date) UNION ALL SELECT dept_no, YEAR(to_date) AS y, -COUNT(*) AS delta FROM dept_emp WHERE to_date <= CURDATE() GROUP BY dept_no, YEAR(to_date)), net_deltas AS (SELECT dept_no, y, SUM(delta) AS delta FROM annual_deltas GROUP BY dept_no,y) SELECT s.snapshot_date, d.dept_name, SUM(COALESCE(n.delta,0)) OVER (PARTITION BY d.dept_no ORDER BY s.snapshot_date ROWS UNBOUNDED PRECEDING) AS active_employee_count FROM snapshots s CROSS JOIN departments d LEFT JOIN net_deltas n ON n.dept_no=d.dept_no AND n.y=YEAR(s.snapshot_date) ORDER BY s.snapshot_date,d.dept_name;

-- 2026-11-16 12:11:47
WITH ActiveDeptEmp AS (SELECT dept_no, emp_no FROM dept_emp WHERE to_date = '9999-01-01'), ActiveSalaries AS (SELECT emp_no, salary FROM salaries WHERE to_date = '9999-01-01'), DeptAvgSalaries AS (SELECT d.dept_no, d.dept_name, ROUND(AVG(s.salary), 2) AS average_salary FROM departments d JOIN ActiveDeptEmp de ON de.dept_no = d.dept_no JOIN ActiveSalaries s ON s.emp_no = de.emp_no GROUP BY d.dept_no, d.dept_name) SELECT dept_name AS department, average_salary FROM DeptAvgSalaries ORDER BY average_salary DESC;