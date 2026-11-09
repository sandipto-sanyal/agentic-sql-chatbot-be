

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