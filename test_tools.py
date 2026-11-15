from employee_agentic_chatbot import get_database_schema, \
simplify_query, \
generate_plotly_vizualizer_code
from mysql_connectivity import MySQLConnector

db = MySQLConnector(database_name="employees")
try:
    query = """select
with active_dept_emp as (
	emp_no,
	dept_no
from
	dept_emp
where
	to_date = '9999-01-01'),
active_salaries as (
select
	emp_no,
	salary
from
	salaries
where
	to_date = '9999-01-01'),
employee_details as (
select
	e.emp_no,
	e.gender,
	d.dept_name
from
	employees e
join active_dept_emp de on
	de.emp_no = e.emp_no
join departments d on
	d.dept_no = de.dept_no)
select
	ed.dept_name as department,
	ed.gender,
	ROUND(AVG(asalary.salary), 2) as average_salary
from
	employee_details ed
join active_salaries asalary on
	asalary.emp_no = ed.emp_no
group by
	ed.dept_name,
	ed.gender
order by
	ed.dept_name,
	ed.gender;"""
 
    task = "Department wise Average Salaries for every gender"
    print(generate_plotly_vizualizer_code.invoke({
        "query":query,
        "task": task
        }))    
finally:
    db.close()
