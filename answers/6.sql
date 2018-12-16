--1
with cte as 
( 
	select 1 as num
		union all
	select c.num + 1 
		from cte c
		where c.num < 10
)
select * from cte;

--2
SELECT
	o.custid,
	o.empid
FROM Sales.Orders o
WHERE
	YEAR(o.orderdate) = 2008 AND
	MONTH(o.orderdate) = 1
	EXCEPT
SELECT
	o.custid,
	o.empid
FROM Sales.Orders o
WHERE
	YEAR(o.orderdate) = 2008 AND
	MONTH(o.orderdate) = 2

--3
SELECT
	o.custid,
	o.empid
FROM Sales.Orders o
WHERE
	YEAR(o.orderdate) = 2008 AND
	MONTH(o.orderdate) = 1
	INTERSECT
SELECT
	o.custid,
	o.empid
FROM Sales.Orders o
WHERE
	YEAR(o.orderdate) = 2008 AND
	MONTH(o.orderdate) = 2

--4
(
SELECT
	o.custid,
	o.empid
FROM Sales.Orders o
WHERE
	YEAR(o.orderdate) = 2008 AND
	MONTH(o.orderdate) = 1
	INTERSECT
SELECT
	o.custid,
	o.empid
FROM Sales.Orders o
WHERE
	YEAR(o.orderdate) = 2008 AND
	MONTH(o.orderdate) = 2
)
	EXCEPT
SELECT
	o.custid,
	o.empid
FROM Sales.Orders o
WHERE
	YEAR(o.orderdate) = 2007

--5
with resultCTE as
(SELECT country, region, city, 0 as num
FROM HR.Employees
UNION ALL
SELECT country, region, city, 1 as num
FROM Production.Suppliers)
select country, region, city from resultCTE
order by num, country, region, city;