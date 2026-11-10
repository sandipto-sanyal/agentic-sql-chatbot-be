

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