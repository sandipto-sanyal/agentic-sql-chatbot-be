

-- 2026-11-23 15:57:32
SELECT d.dept_name, e.gender, COUNT(*) AS active_employees, ROUND(AVG(TIMESTAMPDIFF(YEAR, e.birth_date, CURDATE())), 1) AS avg_age_today, ROUND(AVG(TIMESTAMPDIFF(YEAR, e.birth_date, '2002-12-31')), 1) AS avg_age_at_2002 FROM dept_emp de JOIN employees e ON e.emp_no = de.emp_no JOIN departments d ON d.dept_no = de.dept_no WHERE de.to_date >= CURDATE() GROUP BY d.dept_no, d.dept_name, e.gender ORDER BY d.dept_name, e.gender

-- 2026-11-23 16:01:29
SELECT d.dept_name, e.gender, COUNT(*) AS active_employees, ROUND(AVG(TIMESTAMPDIFF(YEAR, e.birth_date, CURDATE())), 1) AS avg_age_today, ROUND(AVG(TIMESTAMPDIFF(YEAR, e.birth_date, '2002-12-31')), 1) AS avg_age_at_2002 FROM dept_emp de JOIN employees e ON e.emp_no = de.emp_no JOIN departments d ON d.dept_no = de.dept_no WHERE de.to_date >= CURDATE() GROUP BY d.dept_no, d.dept_name, e.gender ORDER BY d.dept_name, e.gender